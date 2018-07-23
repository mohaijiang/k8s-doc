# etcd数据备份与恢复

针对 v3的api

## 备份
```
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.0.4:2379,https://192.168.0.5:2379,https://192.168.0.6:2379 --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/kubernetes.pem  --key=/etc/kubernetes/ssl/kubernetes-key.pem snapshot save snapshot.db
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