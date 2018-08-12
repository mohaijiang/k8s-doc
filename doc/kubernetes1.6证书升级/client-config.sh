#!/bin/sh
set -ex

MASTER_IP="172.21.7.53"
TOKEN="41f7e4ba8b7be874fcff18bf5cf41a7c"

## 生成客户端证书 bootstrapt.kubeconfig,kube-proxy.kubeconfig
 kubectl config set-cluster kubernetes \
       --certificate-authority=ca.pem \
       --embed-certs=true \
       --server=https://$MASTER_IP:6443 \
       --kubeconfig=bootstrap.kubeconfig

kubectl config set-credentials kubelet-bootstrap \
       --token=$TOKEN \
       --kubeconfig=bootstrap.kubeconfig
           
## 设置上下文参数
kubectl config set-context default \
       --cluster=kubernetes \
       --user=kubelet-bootstrap \
       --kubeconfig=bootstrap.kubeconfig

## 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

## 创建 kube-proxy kubeconfig 文件
kubectl config set-cluster kubernetes \
       --certificate-authority=ca.pem \
       --embed-certs=true \
       --server=https://$MASTER_IP:6443 \
       --kubeconfig=kube-proxy.kubeconfig

##设置客户端认证参数
kubectl config set-credentials kube-proxy \
           --client-certificate=kube-proxy.pem \
           --client-key=kube-proxy-key.pem \
           --embed-certs=true \
           --kubeconfig=kube-proxy.kubeconfig

## 设置上下文参数
kubectl config set-context default \
           --cluster=kubernetes \
           --user=kube-proxy \
           --kubeconfig=kube-proxy.kubeconfig

## 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
