#!/bin/bash
set -e

echo "========================================"
echo " my-opencode-stack — 全栈环境一键安装"
echo "========================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/manifest.sh"

# 初始化 manifest（如果已存在则复用，追加本次安装记录）
manifest_init

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

echo "1/6 安装系统依赖..."
bash scripts/install-system.sh

echo "2/6 安装 codebase-memory-mcp..."
bash scripts/install-codebase-memory.sh

echo "3/6 安装 Skills..."
bash scripts/install-skills.sh

echo "4/6 复制配置文件..."
bash scripts/install-config.sh

echo "5/6 验证 Docker..."
bash scripts/install-docker.sh

echo "6/6 启动本地服务..."
bash start-env.sh

echo ""
echo "--- 配置 git pre-commit hook ---"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
git config core.hooksPath "$REPO_DIR/.githooks"
echo "  ✅ pre-commit hook 已启用（秘钥防误提交）"

echo ""
echo "========================================"
echo "✅ 环境安装完成"
echo "========================================"
echo "下一步：启动 OpenCode Desktop 开始使用"
