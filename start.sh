#!/bin/sh
 
# 把临时目录重定向到可写路径
mkdir -p /data/tmp
export TMPDIR=/data/tmp
 
# 启动虚拟显示器
Xvfb :99 -screen 0 1280x900x24 &
export DISPLAY=:99
sleep 3
 
# 启动 VNC 服务
x11vnc -display :99 -nopw -forever -shared -rfbport 5900 &
sleep 2
 
# 启动 noVNC
websockify --web=/usr/share/novnc 6080 localhost:5900 &
sleep 1
 
# 用环境变量 PORT 渲染 nginx 配置（Zeabur 注入，默认 8080），nginx 占对外端口
# main.py 固定跑 8081（nginx 反代目标），不再抢端口
export PORT=${PORT:-8080}
# nginx 不支持 env 变量直接替换，用 sed 渲染
sed -i "s/listen \${PORT}/listen ${PORT}/" /etc/nginx/sites-enabled/default
nginx &
 
# 启动 MCP 服务：固定 8081，nginx 会把 /mcp 反代过来
PORT=8081 python main.py
