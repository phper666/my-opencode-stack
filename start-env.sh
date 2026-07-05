#!/bin/bash
set -e

echo "=== 启动 my-opencode-stack 服务 ==="

# agentmemory（51 个 MCP 工具）
agentmemory --tools all &

echo "等待 agentmemory 就绪..."
sleep 3

# 健康检查
echo -n "agentmemory: "
curl -s http://localhost:3111/health | python3 -c "import json,sys; print('✅' if json.load(sys.stdin).get('status')=='ok' else '❌')" 2>/dev/null || echo "⚠️ 未运行"

echo "环境就绪。启动 OpenCode Desktop 即可。"
