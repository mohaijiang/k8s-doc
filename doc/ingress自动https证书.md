# ingress 自动https证书

## 前置条件 ingress-nginx 安装完成


## 安装cert-manager

```
⚡ helm install --name cert-manager \
    --namespace kube-system \
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer \
    stable/cert-manager
```


## 配置ClusterIssuer

```
⚡ cat << EOF| kubectl create -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: me@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    http01: {}
EOF
```

注意将email 替换成自己的email


## 创建服务进行测试


```
$ cat << EOF| kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    certmanager.k8s.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/tls-acme: "true"
spec:
  rules:
  - host: nginx.mhg.newtouch.com
    http:
      paths:
      - path: /
        backend:
          serviceName: nginx
          servicePort: 80
  tls:
  - secretName: tls-staging-cert
    hosts:
    - nginx.mhg.newtouch.com
EOF
```

最后 查询secret ,当查询
```
kubectl get secret
default-token-6564h   kubernetes.io/service-account-token   3         1h
letsencrypt-prod      Opaque                                1         54m
tls-staging-cert      kubernetes.io/tls                     2         23m
```

当可以查询出tls-staging-cert时，说明tls证书配置成功