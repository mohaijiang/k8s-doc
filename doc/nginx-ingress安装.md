# nginx ingerss 安装

## 前提

已经安装好helm


## helm 安装 nginx-ingress

执行helm 安装命令

```bash
helm install stable/nginx-ingress --name nginx-ingress --set rbac.create=true --namespace=kube-system --set defaultBackend.image.repository=registry.xonestep.com/google_containers/defaultbackend,rbac.create=true
``` 

查询pod状态

```
 kubectl -n kube-system get po | grep ingress
nginx-ingress-controller-6bb6c756d-p7xhz         1/1       Running   0          3d
nginx-ingress-default-backend-656db5996d-bxtcw   1/1       Running   0          5d

```

当容器状态拉起时，说明ingress 服务启动成功

## 域名指向配置

由于ingress使用deployment服务方式启动，服务出来的端口在30000-32767端口之间，先查询出ingress服务端口
```
kubectl get service nginx-ingress-controller -n kube-system
NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
nginx-ingress-controller   LoadBalancer   10.96.22.121   <pending>     80:30898/TCP,443:32187/TCP   5d
```

比如本案例端口为 80端口对应的nodePort 为 30898

option1 域名直接指向：

将泛域名*.domain.com 指向到 nodeIp:30898

option2 域名间接指向：

安装一个代理服务（haproxy,nginx,共有云端口转发等），地址为proxyIp，将一个新的ip地址代理到 nodeIp:30898

将泛域名 *.domain.com 指向到 proxyIp