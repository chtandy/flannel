# 使用方式
需要有etcd的服務才能使用
防火牆規則以允許 Flannel 流量（通常是 UDP 8472 端口for VXLAN）
所有節點的 Flannel 配置一致, 即/etc/flannel/config.json與etcd資訊

# etcd
```
# 安裝etcd client
sudo apt  install etcd-client

# 必要, 使用etcd version 3 的api
export ETCDCTL_API=3
etcdctl version

## 設置 Flannel 網絡配置
etcdctl --endpoints=http://192.168.5.40:2379 put /coreos.com/network/config '{"Network":"10.0.0.0/8", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'
# etcdctl --endpoints=http://192.168.5.40:2379 put /coreos.com/network/config '{"Network":"10.0.0.0/8", "SubnetLen": 20, "Backend": {"Type": "vxlan"}}'
## 檢查 etcd 中的網絡配置
etcdctl --endpoints=http://192.168.5.40:2379 get /coreos.com/network/config
## 檢查 etcd 中的子網分配
etcdctl --endpoints=http://192.168.5.40:2379 get --prefix /coreos.com/network/subnets
```


### 必要
1. etcd 的資訊
2. etc-flannel目錄下的config.json檔案, 主要是flannel 的網段設定
3. 啟動後， `cat config/run-flannel/subnet.env` 內容，需要修改docker daemon.json，加入以下內容
```
{
  "bip": "< FLANNEL_SUBNET Value >",
  "mtu": < FLANNEL_MTU VALUE >,
  "iptables": false,
  "ip-masq": false
}
```
