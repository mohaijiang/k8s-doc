# kubernetes 1.10证书升级

参考文档： https://blog.csdn.net/ywq935/article/details/88355832

## 现象

* prometheus target 报警
* kubectl 命令报 x509: certificate has expired or is not yet valid, x509: certificate has expired or is not yet valid



## 原因
安装好的kubernetes 集群证书有效期只有1年。一年证书到期导致。

## 证书续期方式

```


cd /etc/kubernetes
# 备份证书和配置
mkdir ./pki_bak
mkdir ./conf_bak
mv pki/apiserver* ./pki_bak/
mv pki/front-proxy-client.* ./pki_bak/
mv ./admin.conf ./conf_bak/
mv ./kubelet.conf ./conf_bak/
mv ./controller-manager.conf ./conf_bak/
mv ./scheduler.conf ./conf_bak/


# 创建升级配置,需要配置文件的原因： kubeadm操作(比如init,certs)不声明使用版本时,会向google发送获取最新版本请求。由于国内的网络原因，此请求失败，导致命令失败
cd /tmp
cat >cert-upgrade.yaml<<EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: v1.10.5
api:
  advertiseAddress: 192.168.X.X
  controlPlaneEndpoint: 192.168.X.X
EOF

# 创建证书
kubeadm alpha phase certs apiserver --config cert-upgrade.yaml
kubeadm alpha phase certs apiserver-kubelet-client --config cert-upgrade.yaml
kubeadm alpha phase certs front-proxy-client --config cert-upgrade.yaml

# 生成新配置文件
kubeadm alpha phase kubeconfig all --config cert-upgrade.yaml

# 将新生成的admin配置文件覆盖掉原本的admin文件
mv $HOME/.kube/config $HOME/.kube/config.old
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

```

## 升级后重启apiserver,controller-manager,schedule

直接使用docker ps 命令获取对应的容器id，使用docker restart 命令重启