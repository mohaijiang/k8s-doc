# kubernetes 使用rbd的storageclass

由于官方的自带的rbd-provider机制是直接调用controller-manager的rbd命令行,进行rbd
操作的，导致使用镜像部署的kubernetes集群使用rbd的storageclass出现`failed to create rbd image: executable file not found in $PATH`错误。

这里使external-storage： https://github.com/kubernetes-incubator/external-storage
来绕过上述问题，实现pvc 动态volume

##  案例环境
+ kubernetes 1.10.5 集群
+ ceph 0.94.5  集群

## 安装rbd-provider

1. 创建admin secret

```bash
ceph auth get client.admin 2>&1 |grep "key = " |awk '{print  $3'} |xargs echo -n > /tmp/secret
kubectl create secret generic ceph-admin-secret --from-file=/tmp/secret --namespace=kube-system
```

2. 创建ceph 池和用户secret
```bash
ceph osd pool create kube 8 8
ceph auth add client.kube mon 'allow r' osd 'allow rwx pool=kube'
ceph auth get-key client.admin > /tmp/secret
kubectl create secret generic ceph-secret --from-file=/tmp/secret --namespace=kube-system
```

3. 创建rbd-provider deployment
下载项目源码https://github.com/kubernetes-incubator/external-storage.git

进入目录ceph/rbd/deploy

因为kubernetes是rbac认证,我们使用rbac方式安装

```bash
NAMESPACE=kube-system # change this if you want to deploy it in another namespace
sed -r -i "s/namespace: [^ ]+/namespace: $NAMESPACE/g" ./rbac/clusterrolebinding.yaml ./rbac/rolebinding.yaml
kubectl -n $NAMESPACE apply -f ./rbac
```

等待容器启动

4. 创建storageclass
进入目录 ceph/rbd/

编辑examples/class.yaml,替换掉monitor ip

** 备注
本案例使用rbd monitor ip出现 pvc 挂载失败的问题：  missing Ceph monitors，详见
[issue#778](https://github.com/kubernetes-incubator/external-storage/issues/778)

此处monitor ip 使用 service 域名代替

```
cat >service.yaml<<EOF
kind: Service
apiVersion: v1
metadata:
  name: ceph-mon-1
  namespace: kube-system
spec:
  type: ExternalName
  externalName: 10.21.0.101.xip.io
---
kind: Service
apiVersion: v1
metadata:
  name: ceph-mon-2
  namespace: kube-system
spec:
  type: ExternalName
  externalName: 10.21.0.102.xip.io
---
kind: Service
apiVersion: v1
metadata:
  name: ceph-mon-3
  namespace: kube-system
spec:
  type: ExternalName
  externalName: 10.21.0.103.xip.io
EOF

cat >class.yaml<<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: rbd
provisioner: ceph.com/rbd
parameters:
  monitors: ceph-mon-1.kube-system.svc.cluster.local.:6789,ceph-mon-2.kube-system.svc.cluster.local.:6789,ceph-mon-3.kube-system.svc.cluster.local.:6789
  pool: kube
  adminId: admin
  adminSecretNamespace: kube-system
  adminSecretName: ceph-admin-secret
  userId: kube
  userSecretNamespace: kube-system
  userSecretName: ceph-secret
  imageFormat: "2"
  imageFeatures: layering
EOF

kubectl apply -f service.yaml -f class.yaml
```

5. 测试

创建测试用pvc卷

```
kubectl create -f examples/claim.yaml
```

使用rbd 命令观察image
```
$ rbd --pool kube ls
kubernetes-dynamic-pvc-71a874a2-9007-11e8-8607-0a580af4012a
```

创建带pvc的测试pod
```
kubectl create -f examples/test-pod.yaml
```

观察pod情况
```
$ kubectl get po
NAME                     READY     STATUS      RESTARTS   AGE
test-pod                 0/1       Completed   0          21m
```

说明pod 启动成功，并且挂载上容器

删除pod 和pvc
```
kubectl delete -f examples/test-pod.yaml -f examples/claim.yaml
```

再次使用rbd 命令观察image
```
$ rbd --pool kube ls
```

已经观察不到image,说明随着pvc的删除，rbd自动删除了
