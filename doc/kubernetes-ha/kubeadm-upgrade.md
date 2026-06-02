# kubernetes 版本升级流程

1. 安装目标版本kubeadm
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install kubeadm
```

2. 确认升级计划
```bash
kubeadm upgrade plan

# 尝试从镜像mirror拉
kubeadm config images pull   --image-repository=registry.aliyuncs.com/google_containers
# 尝试从官方拉
kubeadm config images pull
```

3. 执行升级计划
```bash
kubeadm upgrade apply v1.3x.x
```

4. 安装kubectl kubelet, 并重启
```
apt install -y kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet
```

5. 其他节点执行
```
apt install kubeadm kubectl kubelet
kubeadm upgrade node
systemctl restart kubelet
```
