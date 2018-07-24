# 组件安装

## helm

创建helm rbac

```
cat >helm-rbac.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF

kubectl apply -f helm-rbac.yaml


```

初始化helm
```$xslt
helm init --tiller-image registry.xonestep.com/google_containers/tiller:v2.9.1  --service-account tiller
```


## nginx ingress

```$xslt
helm install stable/nginx-ingress --name nginx-ingress --set rbac.create=true --namespace=kube-system
```


## heapster

```$xslt
helm install --name heapster heapster-0.2.10.tgz  --namespace=kube-system --set image.repository=registry.xonestep.com/google_containers/heapster,rbac.create=true
```

## dashboard


## prometheus

```
helm install --name prometheus prometheus-6.2.1.tgz --namespace kube-system --set kubeStateMetrics.image.repository=registry.xonestep.com/google_containers/kube-state-metrics
```

## grafana

garfana 安装
```$xslt
helm install grafana-1.2.0.tgz --name grafana --namespace kube-system
```

garfana 配置

1: 配置数据源(datasource)

2: 配置dashboard

6417(Kubernetes Cluster (Prometheus))
6879(Analysis by Pod)