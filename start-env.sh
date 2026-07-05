#!/bin/bash

echo "加载 agentmemory（launchd 开机自启，此处确保运行中）..."
if ! launchctl list | grep -q com.agentmemory; then
  launchctl load ~/Library/LaunchAgents/com.agentmemory.plist
fi

sleep 3

echo "健康检查..."
agentmemory status 2>/dev/null || echo "⚠️ agentmemory 未运行，请检查 plist"

echo "环境就绪。启动 OpenCode 即可。"
