#!/bin/sh
set -ex

## ETCD IP，如果是ETCD集群，需要将所有节点的IP都写上去,请修改etcd-csr.json
ETCD0_IP="172.21.7.50"
ETCD1_IP="172.21.7.51"
ETCD2_IP="172.21.7.52"

## kubernetes master节点IP，如果是多master高可用集群，填写负载均衡IP,并且修改kubernetes-csr.json,将所有的master节点ip都写上去
MASTER_IP="172.21.7.53"

## docker registry 仓库IP, 如果原来仓库没有使用ssl证书或没有私服仓库，忽视此配置
REGISTRY_IP="172.21.7.100"

## etcd 证书IP配置
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "$ETCD0_IP",
    "$ETCD1_IP",
    "$ETCD2_IP"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

## kubernetes master ip 配置，
## 如果是负载均衡的高可用集群，需要将所有ip地址都写上去，包括loadbalance ip, 所有的master节点ip
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "$MASTER_IP",
    "10.254.0.1",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF



cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem \
           -ca-key=ca-key.pem \
           -config=ca-config.json \
           -profile=kubernetes admin-csr.json | cfssljson -bare admin


cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

cfssl-certinfo -cert kubernetes.pem

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem \
           -ca-key=ca-key.pem \
           -config=ca-config.json \
           -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
           
cat > registry-csr.json <<EOF
{
  "CN": "registry",
  "hosts": [
      "127.0.0.1",
      "$REGISTRY_IP"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem \
             -ca-key=ca-key.pem \
             -config=ca-config.json \
             -profile=kubernetes registry-csr.json | cfssljson -bare registry



cfssl gencert -ca=ca.pem -ca-key=ca-key.pem  -config=ca-config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd

cat > flanneld-csr.json <<EOF
{
  "CN": "flanneld",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF


cfssl gencert -ca=ca.pem \
           -ca-key=ca-key.pem \
           -config=ca-config.json \
           -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld

