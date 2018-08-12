#!/bin/sh
set -ex 

MASTER_IP="172.21.7.53"

kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://$MASTER_IP:6443

## 设置客户端认证参数
kubectl config set-credentials admin \
           --client-certificate=admin.pem \
           --embed-certs=true \
           --client-key=admin-key.pem

## 设置上下文参数
kubectl config set-context kubernetes \
          --cluster=kubernetes \
          --user=admin

## 设置默认上下文
kubectl config use-context kubernetes
