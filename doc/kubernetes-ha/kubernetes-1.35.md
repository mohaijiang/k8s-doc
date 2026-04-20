# kubernetes 1.35 安装

## containerd install

* install 

```

curl -fsSL -o get_docker.sh get.docker.com
bash get_docker.sh --mirror Aliyun

export CONTAINER_RUNTIME_ENDPOINT=unix:///run/containerd/containerd.sock

```

## 配置cri 

### containerd
```
sudo systemctl stop containerd
sudo rm -rf /etc/containerd/config.toml
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo sed -i 's/registry\.k8s\.io/registry\.cn-hangzhou\.aliyuncs\.com\/google_containers/g' /etc/containerd/config.toml
```
# 修改 mirror 文件
vim  /etc/containerd/config.toml
# 找到 registry, 配置 config_path 为 /etc/containerd/certs.d
```
    [plugins.'io.containerd.cri.v1.images'.registry]
      config_path = '/etc/containerd/certs.d'
```

# 配置mirror源
```
mkdir -p /etc/containerd/certs.d/docker.io

cat << EOF > /etc/containerd/certs.d/docker.io/hosts.toml
server = "https://registry-1.docker.io"

[host."https://dockerproxy.net"]
  capabilities = ["pull", "resolve"]
  skip_verify = false
EOF

sudo systemctl restart containerd

```

## 安装 kubeadm kubectl kubelet

```
swapoff -a

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


## 设置所需的 sysctl 参数，参数在重新启动后保持不变
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward                 = 1
EOF

## 应用 sysctl 参数而不重新启动
sudo sysctl --system

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet
```


## 初始化集群
```
kubeadm init --pod-network-cidr=10.244.0.0/16 --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```


## helm 安装
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
bash get_helm.sh
```

## 安装calico 网络插件
```
helm repo add projectcalico https://docs.tigera.io/calico/charts
cat > values.yaml <<EOF
installation:
  cni:
    type: Calico
  calicoNetwork:
    bgp: Disabled
    ipPools:
    - cidr: 10.244.0.0/16
      encapsulation: VXLAN
EOF
helm install calico projectcalico/tigera-operator --version v3.31.4 -f values.yaml --namespace tigera-operator --create-namespace 
```

## Envoy Gateway
```
helm install eg oci://dockerproxy.net/envoyproxy/gateway-helm   --version v1.7.1   -n envoy-gateway-system   --create-namespace   --skip-crds

cat > gateway.yaml <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
EOF

kubectl apply -f gateway.yaml

cat > docker-compose.yaml <<EOF
version: "3.8"

services:
  gateway-proxy:
    image: nginx:alpine
    container_name: gateway-proxy
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - proxy-net

networks:
  proxy-net:
    driver: bridge
EOF

NODEPORT=$(kubectl -n envoy-gateway-system get svc \
  -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=default \
  -o jsonpath='{.items[0].spec.ports[0].nodePort}')

echo $NODEPORT

cat > nginx.conf <<EOF
server {
    listen 80;

    location / {
        proxy_pass http://172.17.0.1:${NODEPORT};

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

docker compose up -d
```

## cert-manager
```
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.8.1 \
  --set installCRDs=true


cat <<EOF > value.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: letsencrypt-prod
spec:
 acme:
   # The ACME server URL
   server: https://acme-v02.api.letsencrypt.org/directory
   # Email address used for ACME registration
   email: haijiang.mo@tntlinking.com
   # Name of a secret used to store the ACME account private key
   privateKeySecretRef:
     name: letsencrypt-prod
   # Enable the HTTP-01 challenge provider
   solvers:
   - http01:
       ingress:
         class: nginx
EOF

kubectl apply -f value.yaml
```

## dashboard
```
# 添加 kubernetes-dashboard 仓库
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# 使用 kubernetes-dashboard Chart 部署名为 `kubernetes-dashboard` 的 Helm Release
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

cat <<EOF > admin-user.yml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token  
EOF

kubectl apply -f admin-user.yml

kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

```

## longhorn
```
apt-get install open-iscsi nfs-common cryptsetup dmsetup
helm repo add longhorn https://charts.longhorn.io
helm repo update  
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.11.1
```


## kata-container
```
export VERSION=$(curl -sSL https://api.github.com/repos/kata-containers/kata-containers/releases/latest | jq .tag_name | tr -d '"')
export CHART="oci://ghcr.io/kata-containers/kata-deploy-charts/kata-deploy"
helm install kata-deploy "${CHART}" --version "${VERSION}" -n kube-system

```
