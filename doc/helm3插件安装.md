## 增加stable仓库
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

## dashboard
```
helm install --namespace kube-system --set image.repository=gcr.azk8s.cn/google-containers/kubernetes-dashboard-amd64 kubernetes-dashboard   stable/kubernetes-dasboard
```

## metrics-server
```
helm install --namespace kube-system  --version 2.8.8 --set image.repository=gcr.azk8s.cn/google-containers/metrics-server-amd64,args[0]=--kubelet-insecure-tls,args[1]=--kubelet-preferred-address-types=InternalIP metrics-server   stable/metrics-server
```

## prometheus
```
helm install --namespace prometheus --set alertmanager.persistentVolume.storageClass=rook-ceph-block,pushgateway.persistentVolume.storageClass=rook-ceph-block,server.persistentVolume.storageClass=rook-ceph-block  prometheus stable/prometheus
helm install --namespace prometheus --set service.type=NodePort,persistence.storageClassName=rook-ceph-block,persistence.enabled=true grafana stable/grafana

```

## efk
```
helm install --namespace efk --set master.persistence.storageClass=rook-ceph-block,data.persistence.storageClass=rook-ceph-block elasticsearch stable/elasticsearch
helm install --namespace efk --set backend.type=es,backend.es.host=elasticsearch-client fluent-bit stable/fluent-bit
helm install --namespace efk --set env.ELASTICSEARCH_HOSTS=http://elasticsearch-client:9200,service.nodePort=30010,service.type=NodePort,persistentVolumeClaim.enabled=true,persistentVolumeClaim.storageClass=rook-ceph-block,readinessProbe.enabled=true kibana stable/kibana
```
## nginx-ingress
```
helm install --namespace kube-system --set controller.hostNetwork=true,controller.kind=DaemonSet,controller.dnsPolicy=ClusterFirstWithHostNet,defaultBackend.image.repository=gcr.azk8s.cn/google-containers/defaultbackend-amd64 nginx-ingress stable/nginx-ingress
```
## cert-manager
```
helm repo add jetstack https://charts.jetstack.io
helm install --namespace kube-system --version v0.12.0 --set ingressShim.defaultIssuerName=letsencrypt-prod,ingressShim.defaultIssuerKind=ClusterIssuer cert-manager jetstack/cert-manager
```
## harbor
```
helm repo add harbor https://helm.goharbor.io
helm install --namespace harbor --set expose.ingress.hosts.core=harbor-192-168-50-116.nip.io,expose.ingress.hosts.notary=notary-harbor-192-168-50-116.nip.io,persistence.resourcePolicy=,persistence.persistentVolumeClaim.registry.storageClass=rook-ceph-block,persistence.persistentVolumeClaim.chartmuseum.storageClass=rook-ceph-block,persistence.persistentVolumeClaim.jobservice.storageClass=rook-ceph-block,persistence.persistentVolumeClaim.database.storageClass=rook-ceph-block,persistence.persistentVolumeClaim.redis.storageClass=rook-ceph-block,externalURL=https://harbor-192-168-50-116.nip.io --version 1.2.3 harbor harbor/harbor 

```
