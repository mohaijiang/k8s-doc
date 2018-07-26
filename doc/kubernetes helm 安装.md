## helm 安装 以及 安装 nginx-ingress

#### 获取安装包
```
  wget https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz
```
解压
```
  tar -zxvf helm-v2.9.1-linux-amd64.tar.gz
```
将文件 helm 移动到 /usr/local/bin
```
  mv helm /usr/local/bin
```

#### 配置 RBAC
```
kubectl create -f rbac-config.yaml
```
镜像可能下不下来,请手动下载
```
  docker pull registry.xonestep.com/google_containers/tiller:v2.9.1
```
#### helm 初始化
```
  helm init --service-account tiller --tiller-image registry.xonestep.com/google_containers/tiller:v2.9.1
```
#### 注意事项
版本需要一致  
即下载的 helm 版本与使用的 tiller 镜像的版本要一致