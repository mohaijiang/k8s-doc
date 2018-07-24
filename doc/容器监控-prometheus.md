# prometheus

## 概念以及介绍

### 概念
 
Prometheus 是源于 Google Borgmon 的一个系统监控和报警工具，用 Golang 语言开发。基本原理是通过 HTTP 协议周期性地抓取被监控组件的状态（pull 方式），这样做的好处是任意组件只要提供 HTTP 接口就可以接入监控系统，不需要任何 SDK 或者其他的集成过程。
 
这样做非常适合虚拟化环境比如 VM 或者 Docker ，故其为为数不多的适合 Docker、Mesos 、Kubernetes 环境的监控系统之一，被很多人称为下一代监控系统。
 
### pull 方式
 
Prometheus 采集数据用的是 pull 也就是拉模型,通过 HTTP 协议去采集指标，只要应用系统能够提供 HTTP 接口就可以接入监控系统，相比于私有协议或二进制协议来说开发简单。
 
### push 方式
 
对于定时任务这种短周期的指标采集，如果采用 pull 模式，可能造成任务结束了 Prometheus 还没有来得及采集的情况，这个时候可以使用加一个中转层，客户端推数据到 Push Gateway 缓存一下，由 Prometheus 从 push gateway pull 指标过来。
 
### 组成及架构
 
+ Prometheus server：主要负责数据采集和存储，提供 PromQL 查询语言的支持；
+ Push Gateway：支持临时性 Job 主动推送指标的中间网关；
+ exporters：提供被监控组件信息的 HTTP 接口被叫做 exporter ，目前互联网公司常用的组件大部分都有 exporter 可以直接使用，比如 Varnish、Haproxy、Nginx、MySQL、Linux 系统信息 (包括磁盘、内存、CPU、网络等等)；
+ PromDash：使用 rails 开发的 dashboard，用于可视化指标数据；
+ WebUI：9090 端口提供的图形化功能；
+ alertmanager：实验性组件、用来进行报警；
+ APIclients：提供 HTTPAPI 接口

![组成及架构](https://images2018.cnblogs.com/blog/1253350/201806/1253350-20180601155803299-1770966954.jpg)


## prometheus 安装

使用容器安装

### 安装前提

+ kubernetes 集群
+ kubernetes helm 部署完成
+ registry 镜像准备

### 安装

下载 prometheus-6.2.1.tgz

执行命令
```$xslt
helm install --name prometheus prometheus-6.2.1.tgz --namespace kube-system --set kubeStateMetrics.image.repository=registry.xonestep.com/google_containers/kube-state-metrics
```

