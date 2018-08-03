# kubernetes EFK 安装配置

1. 下载官方yaml文件，地址： https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch

2. 将官方文件中的镜像地址 `k8s.gcr.io/`替换为`anjia0532/google-containers.`

3. 编辑 `kibana-deployment.yaml` 文件，删除`SERVER_BASEPATH` 环境变量

4. 使用kubectl apply 命令创建所有文件

```
kubectl apply -f *.yaml
```

5. 创建带basic auth 认证的ingress

* 创建一个用户名密码
    
```
htpasswd -c auth admin
```

按照提示输入用户名密码

* 创建一个kubernetes secret

```
kubectl create secret generic basic-auth --from-file=auth -n kube-system
```

* 创建一个kibana访问的ingress

```
cat >kibana-ing.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kibana
  namespace: kube-system
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - admin"
spec:
  rules:
  - host: kibana.domain.com
    http:
      paths:
      - backend:
          serviceName: kibana-logging
          servicePort: ui
        path: /
EOF
kubectl apply -f kibana-ing.yaml
```