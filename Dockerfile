# 使用 alpine 作為基礎鏡像
FROM alpine:3.20.2

# 安裝必要的工具，包括 gettext 包，它提供 envsubst
RUN apk add --no-cache \
    curl \
    iproute2 \
    gettext


# 下載 Flannel 二進制文件
RUN curl -L https://github.com/flannel-io/flannel/releases/download/v0.25.5/flanneld-amd64 -o /usr/local/bin/flanneld && \
    chmod +x /usr/local/bin/flanneld

# 創建配置文件模板
RUN mkdir -p /etc/flannel && \
    echo '{' > /etc/flannel/config.json.template && \
    echo '  "Network": "${FLANNEL_NETWORK}",' >> /etc/flannel/config.json.template && \
    echo '  "SubnetLen": ${FLANNEL_SUBNETLEN},' >> /etc/flannel/config.json.template && \
    echo '  "Backend": {' >> /etc/flannel/config.json.template && \
    echo '    "Type": "vxlan"' >> /etc/flannel/config.json.template && \
    echo '  }' >> /etc/flannel/config.json.template && \
    echo '}' >> /etc/flannel/config.json.template

# 創建啟動腳本
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'envsubst < /etc/flannel/config.json.template > /etc/flannel/config.json' >> /start.sh && \
    echo 'cat /etc/flannel/config.json' >> /start.sh && \
    echo 'exec /usr/local/bin/flanneld -etcd-endpoints=$ETCD_ENDPOINTS -etcd-prefix=$ETCD_PREFIX -iface=$IFACE "$@" -subnet-file=/run/flannel/subnet.env -net-config-path=/etc/flannel/config.json' >> /start.sh && \
    chmod +x /start.sh

# 設置環境變量的默認值
ENV ETCD_PREFIX="/coreos.com/network" \
    FLANNEL_NETWORK="10.0.0.0/8" \
    FLANNEL_SUBNETLEN=20

# 設置 ENTRYPOINT
ENTRYPOINT ["/start.sh"]

# 設置默認命令
CMD ["-v=10"]
