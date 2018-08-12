# kubernetes 扫盲

## kubernetes 功能介绍
基于容器的管理系统,提供丰富的api

Kubernetes优势:
　　　　- 容器编排
　　　　- 轻量级
　　　　- 开源
　　　　- 弹性伸缩
　　　　- 负载均衡

Kubernetes是一个完备的分布式系统支撑平台，具有完备的集群管理能力，多扩多层次的安全防护和准入机制、多租户应用支撑能力、透明的服务注册和发现机制、內建智能负载均衡器、强大的故障发现和自我修复能力、服务滚动升级和在线扩容能力、可扩展的资源自动调度机制以及多粒度的资源配额管理能力。同时Kubernetes提供完善的管理工具，涵盖了包括开发、部署测试、运维监控在内的各个环节。

Kubernetes中，Service是分布式集群架构的核心，一个Service对象拥有如下关键特征：
拥有一个唯一指定的名字
拥有一个虚拟IP（Cluster IP、Service IP、或VIP）和端口号
能够体统某种远程服务能力
被映射到了提供这种服务能力的一组容器应用上

http://www.cnblogs.com/xhyan/p/6656062.html

## kubernetes 架构与高可用

etcd: kubernetes的数据库
kube-apiserver：　作为Kubernetes系统的入口，其封装了核心对象的增删改查操作，以RESTful API接口方式提供给外部客户和内部组件调用。维护的REST对象持久化到Etcd中存储。
kube-controller-manager:
    节点控制器：负责在节点出现故障时注意和响应。
    复制控制器：负责为系统中的每个复制控制器对象维护正确数量的pod。
    端点控制器：填充端点对象（即，连接服务和pod）。
    服务帐户和令牌控制器：为新的命名空间创建默认帐户和API访问令牌。
kube-schedule: 监控新创建的,未分配的pod,并进行分配到node上,调度决策所考虑的因素包括个人和集体资源需求，硬件/软件/策略约束，亲和力和反亲和性规范，数据位置，工作负载间干扰和最后期限。
kubelet: node节点agent,保证容器在pod中运行。确保容器按照PodSpec健康运行
kube-proxy: 通过维护主机上的网络规则并执行连接转发来启用Kubernetes服务抽象。


## 常用 kubernetes 对象

namespace:

容器运行的空间

Pod:

Kubernetes的基本操作单元，是最小的可创建、调试和管理的部署单元。把相关的一个或多个容器构成一个Pod，通常Pod里的容器运行相同的应用。Pod包含的容器运行在同一个Minion(Host)上，作业一个统一管理单元，共享相同的volumes和network namespace/IP和Port空间。

Service:

Services也是Kubernetes的基本操作单元，是真实应用服务的抽象，每一个服务后面都有很多对应的容器来支持。Kubernete用于定义一系列Pod逻辑关系与访问规则，服务的目标是为了隔绝前端与后端的耦合性。通过服务Proxy的port和服务selector决定服务请求传递给后端提供服务的容器，对外表现为一个单一访问接口，外部不需要了解后端如何运行。

Replication Controller：

Kubernete的副本控制器，确保任何时候Kubernetes集群中有指定数量的pod副本(replicas)在运行， 如果少于指定数量的pod副本(replicas)，Replication Controller会启动新的Container，反之会杀死多余的以保证数量不变。Replication Controller使用预先定义的pod模板创建pods。对于利用pod 模板创建的pods，Replication Controller根据label selector来关联。

ReplicaSet:
   与Replication Controller 没有本质不同，但是提供集合式的selector ,推荐使用代替Replication Controller

Deployment:
 根据声明，通过维护ReplicaSet和pod来达到目标状态。
 ```
 使用Deployment来创建ReplicaSet。ReplicaSet在后台创建pod。检查启动状态，看它是成功还是失败。
 然后，通过更新Deployment的PodTemplateSpec字段来声明Pod的新状态。这会创建一个新的ReplicaSet，Deployment会按照控制的速率将pod从旧的ReplicaSet移动到新的ReplicaSet中。
 如果当前状态不稳定，回滚到之前的Deployment revision。每次回滚都会更新Deployment的revision。
 扩容Deployment以满足更高的负载。
 暂停Deployment来应用PodTemplateSpec的多个修复，然后恢复上线。
 根据Deployment 的状态判断上线是否hang住了。
 清除旧的不必要的ReplicaSet。
  ```

Horizontal Pod Autoscaling：　自动扩缩组件

## kubernetes label 机制

 selector 和　nodeSelector


## kubernetes 存储

 容器卷 pv,pvc,storageclass

 PersistentVolume（PV）是集群之中的一块网络存储。跟 Node 一样，也是集群的资源。PV 跟 Volume (卷) 类似，不过会有独立于 Pod 的生命周期。这一 API 对象包含了存储的实现细节，例如 NFS、iSCSI 或者其他的云提供商的存储系统。

 PersistentVolumeClaim (PVC) 是用户的一个请求。他跟 Pod 类似。Pod 消费 Node 的资源，PVCs 消费 PV 的资源。Pod 能够申请特定的资源（CPU 和 内存）；Claim 能够请求特定的尺寸和访问模式（例如可以加载一个读写，以及多个只读实例）

```
GCEPersistentDisk
AWSElasticBlockStore
AzureFile
AzureDisk
FC (Fibre Channel)
FlexVolume
Flocker
NFS
iSCSI
RBD (Ceph Block Device)
CephFS
Cinder (OpenStack block storage)
Glusterfs
VsphereVolume
Quobyte Volumes
HostPath (Single node testing only – local storage is not supported in any way and WILL NOT WORK in a multi-node cluster)
Portworx Volumes
ScaleIO Volumes
StorageOS
```

## kubernetes 网络

![network](http://img.ptcms.csdn.net/article/201506/11/5579419f29d51_middle.jpg?_=8485)

 kubernetes 使用cni 网络接口协议，具体见(Kubernetes中的开放接口CRI、CNI、CSI)[https://zhuanlan.zhihu.com/p/33390023]

 最常用是2种网络是calico,flannel


## 常用运维命令

* etcd 数据备份

```
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.0.8:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.pem --cert=/etc/kubernetes/pki/etcd/peer.pem \
  --key=/etc/kubernetes/pki/etcd/peer-key.pem \
  snapshot save snapshot.db
```

* 检查集群状态

```
[root@master ~]# kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    10d       v1.10.5
tnode1    Ready     master    10d       v1.10.5
tnode2    Ready     master    10d       v1.10.5
tnode3    Ready     <none>    10d       v1.10.5
tnode4    Ready     <none>    10d       v1.10.5
tnode5    Ready     <none>    10d       v1.10.5
tnode6    Ready     <none>    10d       v1.10.5
```

* 集群扩展（新节点加入集群）

1. 新加入集群需要先安装 docker,kubeadm,kubelet

2. 在master节点上申请集群token

```
[root@master ~]# kubeadm token create --print-join-command
kubeadm join 192.168.1.25:6443 --token p62kvn.osriez7wfkaobjom --discovery-token-ca-cert-hash sha256:3e459898a1b4905d6782a8d0c8626170a23fd1d88b046b556bcc18170a2c9948
```

3. 在新加入的集群上执行加入命令
```
kubeadm join 192.168.1.25:6443 --token p62kvn.osriez7wfkaobjom --discovery-token-ca-cert-hash sha256:3e459898a1b4905d6782a8d0c8626170a23fd1d88b046b556bcc18170a2c9948
```


* 节点运维（禁止调度，驱逐）
```
## 禁止调度
kubectl cordon node <nodeName>

## 取消禁止调度
kubectl uncordon node <nodeName>
## 驱逐节点上的服务
kubectl drain node <nodeName>


```

* 证书升级
    - kubeadm 安装方式证书升级
    - 手工安装方式证书升级（k8s1.6[）

## 常用插件

* dashboard

  kubernetes 管理面板（ui）

* helm

  google 提供的容器包管理工具

* ingress-nginx

  外网服务域名暴露实现

* heapster

  heapster是一个监控计算、存储、网络等集群资源的工具，以k8s内置的cAdvisor作为数据源收集集群信息，并汇总出有价值的性能数据(Metrics)：cpu、内存、network、filesystem等，然后将这些数据输出到外部存储(backend)，如InfluxDB，最后再通过相应的UI界面进行可视化展示

* prometheus + grafana

  监控更多性能指标，配合grafana出监控dashboard, prometheus 还有notification组件

* efk
  容器日志收集