#!/bin/bash
set -e

echo "=== 启动 Docker 容器 ==="

# Nginx 反向代理
docker run -d --name api-redirect --restart unless-stopped \
  -p 80:80 -p 443:443 \
  nginx:alpine

# TaskBoard 项目
docker run -d --name taskboard-mysql --restart unless-stopped \
  -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0

docker run -d --name taskboard-redis --restart unless-stopped \
  -p 6379:6379 redis:7-alpine

echo "=== Docker 容器启动完成 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
