#!/bin/sh

# 把临时目录重定向到可写路径
mkdir -p /data/tmp
export TMPDIR=/data/tmp

VNC_PASS="${VNC_PASS:-wispforbud}"
WEB_USER="${WEB_USER:-wisp}"
WEB_PASS="${WEB_PASS:-wispforbud}"
MCP_USER="${MCP_USER:-mcp}"
MCP_PASS="${MCP_PASS:-wisp-mcp-815}"

# 网页入口的账号密码
printf '%s:%s\n' "$WEB_USER" "$(openssl passwd -apr1 "$WEB_PASS")" > /etc/nginx/.htpasswd

# MCP 接口单独一套
printf '%s:%s\n' "$MCP_USER" "$(openssl passwd -apr1 "$MCP_PASS")" > /etc/nginx/.htpasswd-mcp

# 远程桌面本身的密码：每次启动都按环境变量重写，改了密码才会生效
x11vnc -storepasswd "$VNC_PASS" /data/vncpass >/dev/null 2>&1

# 上次如果被强杀，虚拟屏的锁会留下来卡住下一次启动，先清掉
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null

# 浏览器 profile 的死锁同理，指向的是上一个容器的名字
rm -f /data/browser-profile/Singleton* 2>/dev/null

# 启动虚拟显示器
Xvfb :99 -screen 0 1280x900x24 &
export DISPLAY=:99
sleep 3

# 启动 VNC 服务（带密码）
x11vnc -display :99 -rfbauth /data/vncpass -forever -shared -rfbport 5900 &
sleep 2

# 启动 noVNC
websockify --web=/usr/share/novnc 6080 localhost:5900 &
sleep 1

# 启动 nginx
nginx &

# 启动 MCP 服务
PORT=8081 python main.py
