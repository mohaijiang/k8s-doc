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
