# kubernetes 1.10 集群安装

以测试环境为例

负载均衡id: 192.168.1.25
master: 192.168.1.15
node1: 192.168.1.16,
node2: 192.168.1.17,
node3: --
node4: --
node5: --
node6： --


高可用架构图
![ha](https://d33wubrfki0l68.cloudfront.net/907122e279e519934b8af894a68d341d60a2c3f1/5ec55/images/docs/ha-master-gce.png)

## etcd 集群安装

1. 下载cfssl 证书工具
mater,node1,node2 执行
```
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*
```


2. 创建证书配置
mater执行
```
mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd

cat >ca-config.json <<EOF
{
"signing": {
    "default": {
        "expiry": "43800h"
    },
    "profiles": {
        "server": {
            "expiry": "43800h",
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
        },
        "client": {
            "expiry": "43800h",
            "usages": [
                "signing",
                "key encipherment",
                "client auth"
            ]
        },
        "peer": {
            "expiry": "43800h",
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
        }
    }
}
}
EOF

cat >ca-csr.json <<EOF
{
"CN": "etcd",
"key": {
    "algo": "rsa",
    "size": 2048
}
}
EOF
```

3. 生成证书文件
mater执行
```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
```

4. 生成etcd客户端证书
```
cat >client.json <<EOF
{
  "CN": "client",
  "key": {
      "algo": "ecdsa",
      "size": 256
  }
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client
```

5. 打通ssh 免密登录

6. 申明主机名和主机ip变量
```
export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
```

7. 生成客户端证书
在node1,node2执行
```
 mkdir -p /etc/kubernetes/pki/etcd
 cd /etc/kubernetes/pki/etcd
 scp root@<etcd0-ip-address>:/etc/kubernetes/pki/etcd/ca.pem .
 scp root@<etcd0-ip-address>:/etc/kubernetes/pki/etcd/ca-key.pem .
 scp root@<etcd0-ip-address>:/etc/kubernetes/pki/etcd/client.pem .
 scp root@<etcd0-ip-address>:/etc/kubernetes/pki/etcd/client-key.pem .
 scp root@<etcd0-ip-address>:/etc/kubernetes/pki/etcd/ca-config.json .
```
实际上是将master的生成的etcd证书复制到另外2个节点上，可以使用复制粘贴等方式

生成config.json,并修改文件
在master,node1,node2上执行
```
 cfssl print-defaults csr > config.json
 sed -i '0,/CN/{s/example\.net/'"$PEER_NAME"'/}' config.json
 sed -i 's/www\.example\.net/'"$PRIVATE_IP"'/' config.json
 sed -i 's/example\.net/'"$PEER_NAME"'/' config.json

 cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server
 cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer
```

8. 下载etcd ,并配置systemd 文件

在所有节点上执行

下载etcd
```
export ETCD_VERSION="v3.1.12"
 curl -sSL https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/
```

配置环境变量文件
```
 touch /etc/etcd.env
 echo "PEER_NAME=${PEER_NAME}" >> /etc/etcd.env
 echo "PRIVATE_IP=${PRIVATE_IP}" >> /etc/etcd.env
```

配置systemd文件
```
cat >/etc/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
EnvironmentFile=/etc/etcd.env
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/local/bin/etcd --name <name> --data-dir /var/lib/etcd --listen-client-urls https://<etcd-listen-ip>:2379 --advertise-client-urls https://<etcd-listen-ip>:2379 --listen-peer-urls https://<etcd-listen-ip>:2380 --initial-advertise-peer-urls https://<etcd-listen-ip>:2380 --cert-file=/etc/kubernetes/pki/etcd/server.pem --key-file=/etc/kubernetes/pki/etcd/server-key.pem --client-cert-auth --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem --peer-cert-file=/etc/kubernetes/pki/etcd/peer.pem --peer-key-file=/etc/kubernetes/pki/etcd/peer-key.pem --peer-client-cert-auth --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem --initial-cluster <etcd0>=https://<etcd0-ip-address>:2380,<etcd1>=https://<etcd1-ip-address>:2380,<etcd2>=https://<etcd2-ip-address>:2380 --initial-cluster-token etcd-cluster-0 --initial-cluster-state new

[Install]
WantedBy=multi-user.target
EOF
```

<etcd0-ip-address>, <etcd1-ip-address> 和 <etcd2-ip-address>是3个节点的ip地址，
<name> 是etcd节点名,分别是etcd0,etcd1,etcd2,
<etcd-listen-ip> 是部署的节点的ip

启动etcd
```
systemctl daemon-reload
systemctl start etcd
systemctl enable etcd
```

## kubernetes 集群安装

### 配置负载均衡
在console云服务上申请一个负载均衡器，并创建一个监听器（TCP,6443端口），
将3台节点master,node1,node2的6443端口加入监听器

### kubeadm kubelet kubectl 安装

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet-1.10.5-0.x86_64 kubectl-1.10.5-0.x86_64 kubeadm-1.10.5-0.x86_64
```

### master 节点初始化

mater节点上执行

创建 kubeadm 初始化配置文件
```
cat >config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: v1.10.5
api:
  advertiseAddress: 192.168.1.25
  controlPlaneEndpoint: 192.168.1.25
etcd:
  endpoints:
  - https://192.168.1.15:2379
  - https://192.168.1.16:2379
  - https://192.168.1.17:2379
  caFile: /etc/kubernetes/pki/etcd/ca.pem
  certFile: /etc/kubernetes/pki/etcd/client.pem
  keyFile: /etc/kubernetes/pki/etcd/client-key.pem
networking:
  podSubnet: 10.244.0.0/16
apiServerCertSANs:
- 192.168.1.25
- 192.168.1.15
apiServerExtraArgs:
  apiserver-count: "3"
imageRepository: registry.xonestep.com/google_containers
featureGates:
  CoreDNS: true
EOF
```

执行初始化命令
```
kubeadm init --config=config.yaml
```

### node1和node2 初始化

复制master 的 证书文件
```
scp root@<master0-ip-address>:/etc/kubernetes/pki/* /etc/kubernetes/pki
rm /etc/kubernetes/pki/apiserver*
```

执行初始化命令
```
kubeadm init --config=config.yaml
```

### 安装flannel 网络
master 节点执行
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
```

### node节点加入
```
kubeadm join 192.168.1.25:6443 --token 5uqpig.l1bsswmmmm1br7cb --discovery-token-ca-cert-hash sha256:3e459898a1b4905d6782a8d0c8626170a23fd1d88b046b556bcc18170a2c9948
```

## 安装网络