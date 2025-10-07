#!/bin/bash

# 安装 sing-box
curl -fsSL https://sing-box.app/install.sh | bash

# 创建配置目录
mkdir -p /usr/local/etc/sing-box

# 生成 Reality 密钥对
KEY_PAIR=$(sing-box generate reality-keypair)
PRIVATE_KEY=$(echo "$KEY_PAIR" | grep 'Private key' | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep 'Public key' | awk '{print $3}')
UUID=$(uuidgen)
SHORT_ID=$(openssl rand -hex 8)

# 创建配置文件
cat > /usr/local/etc/sing-box/config.json <<EOF
{
  "log": {
    "level": "error"
  },
  "inbounds": [
    {
      "type": "vless",
      "listen": "::",
      "listen_port": 443,
      "users": [
        {
          "uuid": "$UUID",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "msn.yidianzixun.com",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "msn.yidianzixun.com",
            "server_port": 443
          },
          "private_key": "$PRIVATE_KEY",
          "short_id": ["$SHORT_ID"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    }
  ]
}
EOF

# 设置 systemd 服务
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=sing-box service
After=network.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /usr/local/etc/sing-box/config.json
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# 开放端口
ufw allow 443/tcp || iptables -I INPUT -p tcp --dport 443 -j ACCEPT

# 启动服务
systemctl daemon-reexec
systemctl enable sing-box
systemctl restart sing-box

# 输出信息
echo "✅ Reality 节点部署完成"
echo "伪装域名: msn.yidianzixun.com"
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
