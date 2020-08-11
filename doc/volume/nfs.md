## 官方方案

`https://github.com/kubernetes-retired/external-storage/tree/master/nfs`



## nfs服务搭建

创建nfs-server
```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nfs-server
  namespace: nfs
spec:
  replicas: 1
  selector:
    role: nfs-server
  template:
    metadata:
      labels:
        role: nfs-server
    spec:
      nodeSelector:
        kubernetes.io/hostname: test1
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Equal"
        value: ""
        effect: "NoSchedule"
      containers:
      - name: nfs-server
        image: gcr.azk8s.cn/google-containers/volume-nfs:0.8
        ports:
          - name: nfs
            containerPort: 2049
          - name: mountd
            containerPort: 20048
          - name: rpcbind
            containerPort: 111
        securityContext:
          privileged: true
        volumeMounts:
          - mountPath: /exports
            name: mypvc
      volumes:
        - name: mypvc
          hostPath:
            path: /mnt/nfs
            type: Directory
```

创建service
```
kind: Service
apiVersion: v1
metadata:
  name: nfs-server
  namespace: nfs
spec:
  ports:
    - name: nfs
      port: 2049
    - name: mountd
      port: 20048
    - name: rpcbind
      port: 111
  selector:
    role: nfs-server
 ```


安装nfs provider
```
helm install --set nfs.server=x.x.x.x --set nfs.path=/exported/path stable/nfs-client-provisioner
```

设置默认storageclass
```
 kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
