# etcd数据备份与恢复

针对 v3的api

## 备份

```
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.0.8:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.pem --cert=/etc/kubernetes/pki/etcd/peer.pem \
  --key=/etc/kubernetes/pki/etcd/peer-key.pem \
  snapshot save snapshot.db
```

## 恢复

```
ETCDCTL_API=3 ./etcdctl snapshot restore snapshot.db \
  --name etcd0 \
  --initial-cluster etcd0=http://192.168.0.8:2380 \
  --initial-cluster-token etcd-cluster-0 \
   --initial-advertise-peer-urls http://192.168.0.8:2380 \
  --data-dir /var/lib/etcd
```

重启etcd服务


## 增加member
其中 etcd2 数据名， peer-urls 是部署的etcd数据ip端口
```
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.0.8:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.pem --cert=/etc/kubernetes/pki/etcd/peer.pem \
--key=/etc/kubernetes/pki/etcd/peer-key.pem \
member add etcd2 --peer-urls="https://192.168.0.6:2380"
```

## 删除memeber

```
$ ETCDCTL_API=3 etcdctl --endpoints=https://192.168.0.8:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.pem --cert=/etc/kubernetes/pki/etcd/peer.pem \
--key=/etc/kubernetes/pki/etcd/peer-key.pem \
member list

2018-07-24 11:19:36.048074 I | warning: ignoring ServerName for user-provided CA for backwards compatibility is deprecated
2d942c641a7100b5, started, etcd0, https://192.168.0.4:2380, https://192.168.0.4:2379
a49b9d90fc68305a, started, etcd1, https://192.168.0.5:2380, https://192.168.0.5:2379
debd9e1ac5b743f0, started, etcd2, https://192.168.0.6:2380, https://192.168.0.6:2379

$ ETCDCTL_API=3 etcdctl --endpoints=https://192.168.0.8:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.pem --cert=/etc/kubernetes/pki/etcd/peer.pem \
  --key=/etc/kubernetes/pki/etcd/peer-key.pem \
member remove a49b9d90fc68305a
```