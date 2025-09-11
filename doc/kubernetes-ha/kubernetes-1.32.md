# kubernetes 1.32 安装

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

# 配置mirror源
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
           endpoint = ["https://docker.xuanyuan.me","https://docker.1panel.live"]

sudo systemctl restart containerd
```

### docker
```
# ubuntu版本，其他os 参考 https://github.com/Mirantis/cri-dockerd/releases
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.ubuntu-$(. /etc/os-release && echo $VERSION_CODENAME)_amd64.deb

sudo apt install -y ./cri-dockerd_0.3.20.3-0.ubuntu-$(. /etc/os-release && echo $VERSION_CODENAME)_amd64.deb
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
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

## 应用 sysctl 参数而不重新启动
sudo sysctl --system


## 安装kubectl kubelet kubeadm
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet
```


## 初始化集群
```
kubeadm init --pod-network-cidr=10.244.0.0/16 --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

## 使用docker 驱动
## kubeadm init --cri-socket=unix:///var/run/cri-dockerd.sock --pod-network-cidr=10.244.0.0/16 --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers 

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```


## helm 安装
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
bash get_helm.sh
```

## 安装flannel 网络插件
```
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged

helm repo add flannel https://flannel-io.github.io/flannel/
helm install flannel --set podCidr="10.244.0.0/16" --namespace kube-flannel flannel/flannel
```

## ingress-nginx
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
## k8s.dockerproxy.com 已不可用
## helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.image.registry=k8s.dockerproxy.com,controller.admissionWebhooks.patch.image.registry=k8s.dockerproxy.com
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
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm upgrade longhorn --install  longhorn/longhorn --namespace longhorn-system --create-namespace --set ingress.enabled=true,ingress.host=longhorn.192.168.xx.xx.nip.io,ingress.ingressClassName=nginx
```


## prometheus
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack  --create-namespace --namespace kube-prometheus --set prometheusOperator.admissionWebhooks.patch.image.registry=k8s.dockerproxy.com,kube-state-metrics.image.registry=k8s.dockerproxy.com,grafana.persistence.enabled=true,grafana.service.type=NodePort

## grafana 用户名: admin, 密码prom-operator
```

## ECK 日志收集
```
# 1. Install custom resource definitions:
kubectl create -f https://download.elastic.co/downloads/eck/2.15.0/crds.yaml

# 2. Install the ECK operator with its RBAC rules:
kubectl apply -f https://download.elastic.co/downloads/eck/2.15.0/operator.yaml

## 安装 ElasticSearch, Kibana, filebeat
kubectl apply -f https://raw.githubusercontent.com/elastic/cloud-on-k8s/2.15/config/recipes/beats/filebeat_autodiscover.yaml


```
参考： [k8s_filebeat_with_autodiscover](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-beat-configuration-examples.html#k8s_filebeat_with_autodiscover)


## 安装cri-docker 
release:  https://github.com/Mirantis/cri-dockerd/releases

## 安装gpu支持
安装 驱动
```bash
## ubuntu 
sudo ubuntu-drivers autoinstall
```
安装 nvidia container toolkit

```
## 参考 https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-apt

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker


cat /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "default-runtime": "nvidia",
   "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    },
    "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://docker.1panel.live"
    ]
}

```

## 安装nvidia 资源识别
```
# kubectl -n kube-system apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.12.3/nvidia-device-plugin.yml

helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --version 0.17.1

kubectl label node <gpu-node-name> nvidia.com/gpu.present=true
```
