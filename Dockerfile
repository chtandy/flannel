# 使用 Ubuntu 22.04 作為基礎鏡像
FROM ubuntu:22.04

# 更新包列表並安裝必要的工具
RUN apt-get update && \
    apt-get install -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 設置工作目錄
WORKDIR /app

# 下載 Flannel 二進制文件
RUN wget https://github.com/flannel-io/flannel/releases/download/v0.25.5/flanneld-amd64 && \
    chmod +x flanneld-amd64 && \
    mv flanneld-amd64 /usr/local/bin/flanneld

# 創建一個啟動腳本
RUN echo '#!/bin/sh\n\
exec /usr/local/bin/flanneld \
-etcd-endpoints=$ETCD_ENDPOINTS \
-etcd-prefix=$ETCD_PREFIX \
-iface=$IFACE \
"$@"' > /start.sh && \
    chmod +x /start.sh

# 設置環境變量的默認值
ENV ETCD_PREFIX="/coreos.com/network"

# 設置 ENTRYPOINT
ENTRYPOINT ["/start.sh"]

# 設置默認命令
CMD ["-v=10"]
