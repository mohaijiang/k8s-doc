# kubernetes 1.24 安装

## containerd install

* install 

```

curl -fsSL -o get_docker.sh get.docker.com
bash get_docker.sh --mirror aliyun

```

## 配置cri 

```
systemctl stop containerd
rm -rf /etc/containerd/config.toml
containerd config default |  tee /etc/containerd/config.toml
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml
sed -i 's#sandbox_image = "k8s.gcr.io/pause:3.6"#sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.7"#g' /etc/containerd/config.toml
systemctl restart containerd
```

## 安装 kubeadm kubectl kubelet

```shell
apt-get update && sudo apt-get install -y apt-transport-https
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
```


## 初始化集群
```
kubeadm init --pod-network-cidr=10.244.0.0/16 --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
### 安装flannel 网络插件
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```


## helm 安装
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
bash get_helm.sh
```

## ingress-nginx
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.image.registry=k8s.dockerproxy.com,controller.admissionWebhooks.patch.image.registry=k8s.dockerproxy.com
```
