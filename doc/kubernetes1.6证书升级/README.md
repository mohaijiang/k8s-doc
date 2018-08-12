# kubernetes 1.6 证书升级

`为什么要升级证书:`

手工安装的kubernetes,(1.6版本)证书到期之后，会导致 apiserver 6443端口证书访问失效，整个集群无法操作。
证书只能重新制作,制作完成之后，覆盖原有证书

安装文档参考： https://github.com/opsnull/follow-me-install-kubernetes-cluster/blob/v1.6.2

升级步骤概述：

1. 备份当前etcd集群

防止因错误操作导致集群升级失败或数据丢失

2. 备份已有证书文件

3. 停止所有kubernetes相关服务,master节点,node 节点,包括etcd,flannel,kubernetes api,controller-manager,schedule,kubelet,kube-proxy

4. 重新生成所有相关服务的证书

5. 覆盖原有证书

6. 重启整个集群

7. 重新通过node节点的csr


## STEP 1

备份当前etcd集群

```
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.0.8:2379 \
  --cacert=/etc/kubernetes/ssl/ca.pem \
  --cert=/etc/etcd/ssl/etcd.pem \
  --key=/etc/etcd/ssl/etcd-key.pem \
  snapshot save snapshot.db
```

## STEP 2

备份已有证书文件

在master节点执行

```
tar -czvf kubernetes_ssl_bak.tar.gz /etc/kubernetes/
```

## STEP 3

停止所有kubernetes

停止各自节点上的所有服务，包括

* etcd
* flannel
* docker
* kube-api-server
* kube-controller-manager
* kube-schedule
* kubelet
* kube-proxy



```
systemctl stop <service>
```

## STEP 4

重新生成所有相关服务的证书

在master节点上执行以下内容

下载并修改 ca.sh,admin-config.sh,client-config.sh 上相关服务的ip参数

修改完成后依次执行 ca.sh,admin-config.sh,client-config.sh
重新生成证书

## STEP 5

覆盖原有证书文件

### 覆盖ETCD证书
etcd 节点

```
cp etcd*.pem /etc/etcd/ssl/
```

### 覆盖flanneld证书
所有node节点

```
cp flannel*.pem /etc/flanneld/ssl/
```

### 覆盖master证书
所有master 节点
```
cp  {ca-key.pem,ca.pem,admin-key.pem,admin.pem,kubernetes-key.pem,kubernetes.pem,kube-proxy-key.pem,kube-proxy.pem}  /etc/kubernetes/ssl/
```


### 覆盖node 证书

所有node节点上执行
```
cp  {ca-key.pem,ca.pem,admin-key.pem,admin.pem,kubernetes-key.pem,kubernetes.pem,kube-proxy-key.pem,kube-proxy.pem}  /etc/kubernetes/ssl/
cp {bootstrap.kubeconfig,kube-proxy.kubeconfig} /etc/kubernetes/
## 删除已有的kubelet证书
rm -rf /etc/kubernetes/ssl/kubelet*--
rm -rf rm -rf /etc/kubernetes/kubelet.kubeconfig
```
###

## STEP 6
按顺序重启整个集群


* etcd
* flannel
* docker
* kube-api-server
* kube-controller-manager
* kube-schedule
* kubelet
* kube-proxy



```
systemctl restart <service>
```

## STEP 7

重新通过node的csr认证

```
kubectl get csr | grep Pending | awk '{print $1}' | xargs kubectl certificate approve
```

最后检查集群状态
```
kubectl get nodes
```