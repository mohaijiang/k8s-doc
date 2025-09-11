#!/bin/bash
set -e

## 备注 ，执行此脚本前，需要提前准备 /root/kubeadm.yaml,  最好通过kubectl -n kube-system get cm kubeadm-config -o yaml > /root/kubeadm_cm.yaml 方式导出

OLD_IP="192.168.122.123"
NEW_IP="192.168.122.124"
KUBEADM_CONFIG="/root/kubeadm.yaml"

echo "正在将 Kubernetes IP 从 $OLD_IP 更换为 $NEW_IP"

# 1. 校验 /root/kubeadm.yaml 是否存在
if [ ! -f "$KUBEADM_CONFIG" ]; then
    echo "错误：$KUBEADM_CONFIG 不存在，请先准备 kubeadm 配置文件"
    exit 1
fi

# 2. 替换 kubeadm.yaml 中的 IP，如果没有新的 IP，追加上
sed -i "/- $OLD_IP/c\  - $NEW_IP" "$KUBEADM_CONFIG"

# 3. 替换 manifests 目录下的静态 Pod 配置文件
for file in /etc/kubernetes/manifests/*.yaml; do
  if grep -q "$OLD_IP" "$file"; then
    echo "更新 $file"
    sed -i "s/$OLD_IP/$NEW_IP/g" "$file"
  fi
done

# 4. 替换 kubeconfig 文件
for file in /etc/kubernetes/*.conf; do
  if grep -q "$OLD_IP" "$file"; then
    echo "更新 $file"
    sed -i "s/$OLD_IP/$NEW_IP/g" "$file"
  fi
done

# 5. 更新 kubelet 启动参数（如果有 Node IP 绑定）
if grep -q "$OLD_IP" /var/lib/kubelet/kubeadm-flags.env; then
  echo "更新 kubeadm-flags.env"
  sed -i "s/$OLD_IP/$NEW_IP/g" /var/lib/kubelet/kubeadm-flags.env
fi

# 6. 重新生成 apiserver 证书和 kubeconfig
echo "重新生成 apiserver 证书和 kubeconfig"
mv /etc/kubernetes/pki/apiserver.* /tmp/ || true
kubeadm init phase certs apiserver --config="$KUBEADM_CONFIG"
kubeadm init phase kubeconfig all --config="$KUBEADM_CONFIG"

# 7. 重启 kubelet
echo "重启 kubelet"
systemctl daemon-reexec
systemctl restart kubelet

cp /etc/kubernetes/admin.conf ~/.kube/config

# 8. 等待静态 Pod 重建
echo "等待静态 Pod 重建..."
sleep 20

# 9. 修改proxy config
echo "更新 kube-proxy ConfigMap 中的 kubeconfig"
KUBE_PROXY_CM="kube-proxy"
KUBE_PROXY_NS="kube-system"

kubectl -n $KUBE_PROXY_NS get cm $KUBE_PROXY_CM -o yaml > /tmp/kube-proxy-cm.yaml

# 替换旧 IP 为新 IP
sed -i "s/$OLD_IP/$NEW_IP/g" /tmp/kube-proxy-cm.yaml

# 应用更新
kubectl -n $KUBE_PROXY_NS apply -f /tmp/kube-proxy-cm.yaml

echo "kube-proxy ConfigMap 已更新"

# 10. 清理 controller-manager、scheduler、kube-proxy 容器，防止加载旧配置
echo "清理旧的静态 Pod 容器"
for pod in kube-controller-manager kube-scheduler kube-proxy; do
    container_id=$(docker ps -a --filter "name=$pod" -q)
    if [ -n "$container_id" ]; then
        echo "移除容器 $pod ($container_id)"
        docker rm -f $container_id
    fi
done


echo "完成！请使用新的 admin.conf 验证连接："
echo "  KUBECONFIG=/etc/kubernetes/admin.conf kubectl get nodes"
