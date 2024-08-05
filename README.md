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
2. etc-flannel目錄下的config.json檔案, 主要是flannel 的網段設定 << 以使用Dockerflie +環境變數處理
3. 啟動後， `cat subnet-file/subnet.env` 內容，需要修改docker daemon.json，加入以下內容
```
{
  "bip": "< FLANNEL_SUBNET Value >",
  "mtu": < FLANNEL_MTU VALUE >,
  "iptables": true,
  "ip-masq": true
}

{
  "bip": "10.0.23.1/24",
  "mtu": 1450,
  "iptables": true,
  "ip-masq": true
}
```
iptables 設置決定 Docker 是否應自動配置 iptables 規則來管理容器的網絡流量
ip-masq 設置決定 Docker 是否應對從容器發出的流量進行 IP 偽裝（IP Masquerading），這是一種特殊的 NAT 用於隱藏內部網絡的 IP。
iptables 和 ip-masq 預設值都是true, 故可以省略

### 注意事項
- 若容器服務無法取得flannel 網路，可以在`docker-compose.yml`內指定`network_mode: bridge`

- 有些有些OS有設定iptable, 會造成容器連不到外面，或是容器無法跨主機通訊，則需加入以下
```
# 允許 Flannel 子網間的直接通信
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -d 10.0.0.0/8 -j RETURN

#為外部通信設置 MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/8 ! -d 10.0.0.0/8 -j MASQUERADE
```

### aws almolinux
- 備份
```
sudo iptables-save > /etc/sysconfig/iptables
```

- rc.local 還原
```
sudo iptables-restore < /etc/sysconfig/iptables
```





### 建立rc.local 服務
- 創建文件 /etc/systemd/system/rc-local.service
```
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
```

- 啟用並啟動服務
```
chmod +x /etc/rc.local
sudo systemctl enable rc-local
sudo systemctl start rc-local
```
