# kubernetes 扫盲

## kubernetes 功能介绍

基于docker的容器管理的管理系统,提供丰富的api

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

## kubernetes 存储

## kubernetes 网络

![network](http://img.ptcms.csdn.net/article/201506/11/5579419f29d51_middle.jpg?_=8485)

```

# kubectl -n newtouchone get service admin
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
admin     NodePort   10.102.253.57   <none>        8080:30004/TCP   3h

# kubectl -n newtouchone get po  admin-6b8cc6d5cc-c7h42 -o wide
NAME                     READY     STATUS    RESTARTS   AGE       IP            NODE
admin-6b8cc6d5cc-c7h42   1/1       Running   0          3h        10.244.6.21   tnode6



================================


Chain KUBE-MARK-MASQ (85 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK or 0x4000

Chain KUBE-NODEPORTS (1 references)
 pkts bytes target     prot opt in     out     source               destination
   0     0 KUBE-MARK-MASQ  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* newtouchone/admin: */ tcp dpt:30004
   0     0 KUBE-SVC-WIBWGVOGGHZNLWQN  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* newtouchone/admin: */ tcp dpt:30004

Chain KUBE-SEP-VSESX2TDFOUFNIYU (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  all  --  *      *       10.244.6.21          0.0.0.0/0            /* newtouchone/admin: */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* newtouchone/admin: */ tcp to:10.244.6.21:8080

Chain KUBE-SERVICES (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  tcp  --  *      *      !10.244.0.0/16        10.102.253.57        /* newtouchone/admin: cluster IP */ tcp dpt:8080
    0     0 KUBE-SVC-WIBWGVOGGHZNLWQN  tcp  --  *      *       0.0.0.0/0            10.102.253.57        /* newtouchone/admin: cluster IP */ tcp dpt:8080

Chain KUBE-SVC-WIBWGVOGGHZNLWQN (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-SEP-VSESX2TDFOUFNIYU  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* newtouchone/admin: */



```


## 常用运维命令
