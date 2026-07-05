#!/bin/bash
echo "=== Docker ==="
echo "本环境不依赖 Docker 容器。"
echo "如有项目需要 Docker（MySQL/Redis 等），由项目自行管理。"
echo "验证 Docker 可用性："
docker info >/dev/null 2>&1 && echo "✅ Docker 已安装" || echo "❌ Docker 未安装"
