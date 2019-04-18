# kubernetes 1.13 集群安装

以测试环境为例

|节点|ip|
|---|---|
|负载均衡ip| 15.15.15.5|
|master1| 15.15.15.6|
|master2| 15.15.15.7|
|master3| 15.15.15.8|
|node1| --|
|node2| --|
|node3| --|
|node4| --|


高可用架构图
![ha](https://d33wubrfki0l68.cloudfront.net/907122e279e519934b8af894a68d341d60a2c3f1/5ec55/images/docs/ha-master-gce.png)


## docker 和 kubernetes 包安装
在所有kubernetes节点安装 docker和kubernetes rpm包
```
swapoff -a
## 使用阿里云 centos源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
echo "安装docker"
# step 1: 安装必要的一些系统工具
yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 更新并安装 Docker-CE
yum makecache fast

yum install docker-ce -y


echo "设置docker daemon.json"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "devicemapper"
}
EOF

systemctl enable docker && systemctl restart docker

systemctl daemon-reload
systemctl restart docker

echo "设置系统变量"
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl -p /etc/sysctl.d/k8s.conf


echo "安装kubernetes"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

systemctl daemon-reload
systemctl enable kubelet.service
```

## master1 节点初始化

```
## 生成 kubeadm init 配置文件
cat > kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: v1.13.1
apiServer:
  certSANs:
  - "15.15.15.5"
controlPlaneEndpoint: "15.15.15.5:6443"
networking:
  podSubnet: 10.244.0.0/16
imageRepository: gcr.azk8s.cn
EOF

## 初始化maseter1节点
kubeadm init --config=kubeadm-config.yaml

## 将master1节点的证书复制到master2和master3上
USER=root # customizable
CONTROL_PLANE_IPS="15.15.15.7 15.15.15.8"
for host in ${CONTROL_PLANE_IPS}; do
    ssh "${USER}"@$host "mkdir -p /etc/kubernetes/pki/etcd/"
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:/etc/kubernetes/pki/etcd/ca.crt
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:/etc/kubernetes/pki/etcd/ca.key
    scp /etc/kubernetes/admin.conf "${USER}"@$host:/etc/kubernetes/admin.conf
done

```

## master2和master3的节点初始化

执行join命令，命令为 master1 init生成的命令. 之后再加上`--experimental-control-plane`
```
kubeadm join 15.15.15.5:6443 --token j04n3m.octy8zely83cy2ts --discovery-token-ca-cert-hash sha256:84938d2a22203a8e56a787ec0c6ddad7bc7dbd52ebabc62fd5f4dbea72b14d1f --experimental-control-plane
```

## node节点的初始化

```
kubeadm join 15.15.15.5:6443 --token j04n3m.octy8zely83cy2ts --discovery-token-ca-cert-hash sha256:84938d2a22203a8e56a787ec0c6ddad7bc7dbd52ebabc62fd5f4dbea72b14d1f
```

## 安装flannel网络
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
```
