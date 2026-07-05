#!/bin/bash
set -e

echo "========================================"
echo " my-opencode-stack — 全栈环境一键安装"
echo "========================================"
echo ""

# 检查占位符
if grep -r "PLACEHOLDER_" config/ --include="*.json" --include="*.env" --include="*.md" > /dev/null 2>&1; then
  echo "⚠️  检测到未替换的 PLACEHOLDER，请先编辑 config/ 下的文件填入 API Key"
  echo "   需要的 Key:"
  echo "   - ECHOBRAID_API_KEY（opencode.jsonc）"
  echo "   - OPENCODE_GO_API_KEY（opencode.jsonc）"
  echo "   - LLM_KEY（agentmemory.env）"
  echo ""
  echo "   编辑后重新运行本脚本"
  exit 1
fi

echo "1/5 安装系统依赖..."
bash scripts/install-system.sh

echo "2/5 安装 Skills..."
bash scripts/install-skills.sh

echo "3/5 复制配置文件..."
bash scripts/install-config.sh

echo "4/5 启动 Docker 容器..."
bash scripts/install-docker.sh

echo "5/5 启动本地服务..."
bash start-env.sh

echo ""
echo "========================================"
echo "✅ 环境安装完成"
echo "========================================"
echo "下一步：启动 OpenCode Desktop 开始使用"
