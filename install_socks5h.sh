#!/bin/bash
# install_socks5h_full.sh - 改进版 Dante SOCKS5 + SOCKS5h 一键安装脚本 (Debian/Ubuntu)

set -e

GREEN="\033[32m"
RED="\033[31m"
NC="\033[0m"

echo -e "${GREEN}🔍 检测到 CPU 架构: $(uname -m)${NC}"

echo -e "${GREEN}🔧 更新并安装依赖...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1
apt-get install -y dante-server fail2ban curl net-tools >/dev/null 2>&1

# 获取网络接口
INTERFACE=$(ip route get 1 | awk '{print $5;exit}')
if [ -z "$INTERFACE" ]; then
    echo -e "${RED}❌ 无法获取默认网络接口${NC}"
    exit 1
fi

# 输入端口和认证信息
read -p "🛡️ 输入代理端口 (默认1080): " PORT
PORT=${PORT:-1080}

read -p "🛡️ 输入代理认证用户名 (默认proxyuser): " PROXYUSER
PROXYUSER=${PROXYUSER:-proxyuser}

echo -n "🛡️ 输入代理认证密码: "
stty -echo
read PROXYPASS
stty echo
echo
if [ -z "$PROXYPASS" ]; then
    echo -e "${RED}❌ 密码不能为空${NC}"
    exit 1
fi

# 创建或更新用户
if id "$PROXYUSER" &>/dev/null; then
    echo -e "${GREEN}✅ 用户 $PROXYUSER 已存在，更新密码${NC}"
else
    echo -e "${GREEN}✅ 创建用户 $PROXYUSER${NC}"
    useradd -r -s /usr/sbin/nologin "$PROXYUSER"
fi
echo "$PROXYUSER:$PROXYPASS" | chpasswd

# 配置日志文件
touch /tmp/danted.log
chown "$PROXYUSER":"$PROXYUSER" /tmp/danted.log || true
chmod 644 /tmp/danted.log || true
echo -e "${GREEN}📝 配置 /tmp/danted.log 日志文件权限${NC}"

# 生成 danted.conf
cat > /etc/danted.conf <<EOF
# Dante SOCKS5/5h 完整配置 (IPv4 + IPv6)
logoutput: /tmp/danted.log

internal: 0.0.0.0 port = $PORT
internal: ::0 port = $PORT
external: $INTERFACE

socksmethod: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect
}
client pass {
    from: ::/0 to: ::/0
    log: connect disconnect
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect
    socksmethod: username
}
socks pass {
    from: ::/0 to: ::/0
    command: bind connect udpassociate
    log: connect disconnect
    socksmethod: username
}
EOF

# 启动 Dante
systemctl restart danted
systemctl enable danted >/dev/null 2>&1

# 配置 Fail2Ban
echo -e "${GREEN}🛡️ 配置 Fail2Ban 防止暴力破解${NC}"
cat > /etc/fail2ban/jail.d/danted.conf <<EOF
[danted]
enabled = true
port = $PORT
filter = danted
logpath = /tmp/danted.log
maxretry = 5
bantime = 86400
findtime = 600
EOF

cat > /etc/fail2ban/filter.d/danted.conf <<EOF
[Definition]
failregex = .* pam_authenticate\(\) failed from <HOST>
ignoreregex =
EOF

systemctl restart fail2ban
systemctl enable fail2ban >/dev/null 2>&1

# 配置防火墙
echo -e "${GREEN}🔥 配置防火墙（如可用）...${NC}"
if command -v ufw &>/dev/null; then
    ufw allow $PORT/tcp >/dev/null 2>&1
elif command -v firewall-cmd &>/dev/null; then
    firewall-cmd --permanent --add-port=$PORT/tcp >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1
fi

sleep 2

# 检查 Dante 状态
if systemctl is-active --quiet danted; then
    IPV4=$(curl -s4 ifconfig.me || echo "未检测到")
    IPV6=$(curl -s6 ifconfig.me || echo "未检测到")

    echo -e "\n=============================="
    echo -e "${GREEN}✅ SOCKS5/5h 代理服务器已部署成功${NC}"
    echo "CPU 架构: $(uname -m)"
    echo "IPv4 地址: $IPV4"
    echo "IPv6 地址: $IPV6"
    echo "端口: $PORT"
    echo "用户名: $PROXYUSER"
    echo "认证: 用户名密码认证"
    echo "Fail2Ban: 已启用防暴破保护"
    echo -e "\n${GREEN}🔗 代理链接:${NC}"
    echo "socks5://$PROXYUSER:$PROXYPASS@$IPV4:$PORT"
    echo "socks5h://$PROXYUSER:$PROXYPASS@$IPV4:$PORT"
    echo "socks5://$PROXYUSER:$PROXYPASS@[$IPV6]:$PORT"
    echo "socks5h://$PROXYUSER:$PROXYPASS@[$IPV6]:$PORT"

    echo -e "\n${GREEN}🧪 测试代理可用性:${NC}"
    echo -n "IPv4 SOCKS5: "
    curl -s --socks5 $PROXYUSER:$PROXYPASS@$IPV4:$PORT http://ifconfig.me || echo "失败"
    echo
    echo -n "IPv4 SOCKS5h: "
    curl -s --socks5-hostname $PROXYUSER:$PROXYPASS@$IPV4:$PORT http://ifconfig.me || echo "失败"
    echo
    echo -n "IPv6 SOCKS5: "
    curl -s --socks5 $PROXYUSER:$PROXYPASS@[$IPV6]:$PORT http://ipv6.ip.sb -g || echo "失败"
    echo
    echo -n "IPv6 SOCKS5h: "
    curl -s --socks5-hostname $PROXYUSER:$PROXYPASS@[$IPV6]:$PORT http://ipv6.ip.sb -g || echo "失败"
    echo
    echo "=============================="
else
    echo -e "${RED}❌ 服务启动失败，请检查 /etc/danted.conf 或执行 journalctl -u danted -f 查看日志${NC}"
    exit 1
fi
