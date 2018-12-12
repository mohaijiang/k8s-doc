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
helm install --name nginx-ingress --namespace kube-system stable/nginx-ingress --set controller.hostNetwork=true,controller.kind=DaemonSet,defaultBackend.image.repository=registry.onecloud.newtouch.com/google_containers/defaultbackend
```


## heapster

```$xslt
helm install --name heapster stable/heapster  --namespace=kube-system --set image.repository=registry.xonestep.com/google_containers/heapster,rbac.create=true,resizer.image.repository=registry.xonestep.com/google_containers/addon-resizer
```

## dashboard

```

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

kubectl create sa dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
ADMIN_SECRET=$(kubectl get secrets -n kube-system | grep dashboard-admin | awk '{print $1}')
DASHBOARD_LOGIN_TOKEN=$(kubectl describe secret -n kube-system ${ADMIN_SECRET} | grep -E '^token' | awk '{print $2}')
echo ${DASHBOARD_LOGIN_TOKEN}
```


## prometheus

```
helm install --name prometheus stable/prometheus --namespace kube-system --set kubeStateMetrics.image.repository=registry.xonestep.com/google_containers/kube-state-metrics,alertmanager.persistentVolume.enabled=false,server.persistentVolume.enabled=false
```

## grafana

garfana 安装
```$xslt
helm install stable/grafana --name grafana --namespace kube-system  --set adminPassword=strongpassword
```

garfana 配置

1: 配置数据源(datasource)

2: 配置dashboard

6417(Kubernetes Cluster (Prometheus))
6879(Analysis by Pod)
