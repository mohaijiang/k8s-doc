# kubernetes 1.24 安装

## docker install

* install 
```
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt update
sudo apt-get install     ca-certificates     curl     gnupg     lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

* post
```shell
sudo groupadd docker
sudo usermod -aG docker $USER

cat >/etc/docker/daemon.json<<EOF  
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }
}
EOF


## 配置cri 
systemctl stop containerd
rm -rf /etc/containerd/config.toml
containerd config default |  tee /etc/containerd/config.toml
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml
sed -i 's#sandbox_image = "k8s.gcr.io/pause:3.6"#sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.7"#g' /etc/containerd/config.toml
systemctl restart containerd
```

## kubeadm kubectl kubelet install

```shell
apt-get update && sudo apt-get install -y apt-transport-https
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
```

## setup cluster
```shell
cat >kubeadm-init.yml<<EOF  
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: 1.24.0
networking:
  podSubnet: 10.244.0.0/16
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
scheduler: {}
EOF


kubeadm init --config kubeadm-init.yml
```

## install network

```shell
echo "185.199.108.133 raw.githubusercontent.com" >> /etc/hosts
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml 
```

## master 允许工作节点
kubectl taint nodes mohaijiang node-role.kubernetes.io/master-
