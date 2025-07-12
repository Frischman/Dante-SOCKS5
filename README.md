
# 🚀 Dante SOCKS5 Proxy 一键安装脚本

轻量、稳定、即插即用的 **Dante SOCKS5 一键安装脚本**，适合 **内网穿透、游戏 UDP 加速、科学上网、流量中转代理**使用。

---

## ✨ 功能特性

- 一键自动化安装 Dante SOCKS5
- 用户名 + 密码认证
- 支持 UDP 转发（游戏/流媒体加速）
- 自动配置 Fail2Ban 防暴破
- 自动开机自启
- 支持 IPv4 / IPv6 双栈
- 安装完成即插即用

---

## 🛠️ 安装流程

### 1️⃣ 更新系统

可选但推荐：

```bash
apt update && apt upgrade -y
```

### 2️⃣ 一键安装 Dante SOCKS5

执行以下命令：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Frischman/Dante-SOCKS5/main/install_socks5.sh)
```

3️⃣ 安装过程中将提示：

- 代理端口（默认：1080，可自定义）
- 代理用户名（默认：proxyuser，可自定义）
- 代理密码（必填）

脚本会自动完成安装 Dante、Fail2Ban、配置 UDP 转发、自动开机自启及显示 IPv4/IPv6。

---

## 🛡️ 常用管理命令

### Dante 服务管理

查看状态：

```bash
systemctl status danted
```

启动服务：

```bash
systemctl start danted
```

停止服务：

```bash
systemctl stop danted
```

重启服务：

```bash
systemctl restart danted
```

查看实时日志：

```bash
journalctl -u danted -f
```

---

## 2️⃣ Fail2Ban 防暴破管理

查看 Fail2Ban 状态：

```bash
systemctl status fail2ban
```

启动 Fail2Ban：

```bash
systemctl start fail2ban
```

停止 Fail2Ban：

```bash
systemctl stop fail2ban
```

重启 Fail2Ban：

```bash
systemctl restart fail2ban
```

查看封禁 IP：

```bash
fail2ban-client status danted
```

解封指定 IP：

```bash
fail2ban-client set danted unbanip <IP地址>
```

查看 Fail2Ban 日志：

```bash
tail -f /var/log/fail2ban.log
```

---

## 🗑️ 卸载方法

完全卸载 Dante 和 Fail2Ban：

```bash
systemctl stop danted fail2ban
systemctl disable danted fail2ban

apt remove --purge dante-server fail2ban -y

userdel -r <proxyuser>   # 替换为你的代理用户名

rm -f /etc/danted.conf /var/log/danted.log
rm -f /etc/fail2ban/jail.d/danted.conf /etc/fail2ban/filter.d/danted.conf
```

---

## 📑 文件位置

| 文件                    | 路径                              |
|-------------------------|---------------------------------|
| Dante 配置文件          | /etc/danted.conf                 |
| Dante 日志              | /var/log/danted.log              |
| Fail2Ban 日志           | /var/log/fail2ban.log            |
| Fail2Ban Dante Jail 配置 | /etc/fail2ban/jail.d/danted.conf |
| Fail2Ban Dante Filter 配置 | /etc/fail2ban/filter.d/danted.conf |

> 如修改配置后需重启生效：

```bash
systemctl restart danted
systemctl restart fail2ban
```

---

## 🖥️ 适用环境

系统：

- Debian 10 / 11 / 12
- Ubuntu 18.04 / 20.04 / 22.04

架构：

- x86_64
- ARM (armv7 / arm64)

---

⚠️ 使用须知

本脚本仅供 内网加速 / 合法合规场景 / 科学研究 / 学习测试用途。

严禁用于任何违反当地法律法规的用途。

使用本脚本即代表同意自行承担使用风险及一切后果，与作者无关。

---

❤️ 支持

如果本项目对你有帮助，请在 GitHub 帮我点个 ⭐️：

👉 [点此跳转 GitHub 仓库](https://github.com/Frischman/Dante-SOCKS5)

---

🪪 License

本项目基于 MIT License 开源发布。
