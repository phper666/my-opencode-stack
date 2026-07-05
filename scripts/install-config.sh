#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$HOME/.config/opencode"
PLUGIN_DIR="$CONFIG_DIR/plugins"
SKILLS_DIR="$CONFIG_DIR/skills"

echo "=== 1. 创建目录 ==="
mkdir -p "$CONFIG_DIR" "$PLUGIN_DIR" "$SKILLS_DIR"
mkdir -p "$HOME/.opencodereview"
mkdir -p "$HOME/.agentmemory"

echo "=== 2. 复制 OpenCode 配置 ==="
cp "$REPO_DIR/config/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc"
cp "$REPO_DIR/config/oh-my-opencode-slim.json" "$CONFIG_DIR/oh-my-opencode-slim.json"
mkdir -p "$CONFIG_DIR/oh-my-opencode-slim"
cp "$REPO_DIR/config/orchestrator_append.md" "$CONFIG_DIR/oh-my-opencode-slim/orchestrator_append.md"

echo "=== 3. 复制 open-code-review 配置 ==="
cp "$REPO_DIR/config/opencodereview-config.json" "$HOME/.opencodereview/config.json"

echo "=== 4. 复制 agentmemory 配置 ==="
cp "$REPO_DIR/config/agentmemory.env" "$HOME/.agentmemory/.env"

echo "=== 5. 安装插件依赖 ==="
if [ ! -f "$CONFIG_DIR/package.json" ]; then
  echo '{"type":"module","dependencies":{}}' > "$CONFIG_DIR/package.json"
fi
(cd "$CONFIG_DIR" && npm install @opencode-ai/plugin@latest context-mode@latest --save 2>/dev/null)

echo "=== 6. 复制插件 ==="
cp "$REPO_DIR/plugins/rtk.js" "$PLUGIN_DIR/rtk.js"
cp "$REPO_DIR/plugins/agentmemory-capture.js" "$PLUGIN_DIR/agentmemory-capture.js"
cp "$REPO_DIR/plugins/agentmemory-capture.ts" "$PLUGIN_DIR/agentmemory-capture.ts"

echo "=== 6. 复制 trail 模板 ==="
mkdir -p "$CONFIG_DIR/trail-templates"
cp -r "$REPO_DIR/templates/trail-templates/"* "$CONFIG_DIR/trail-templates/"

echo "=== 7. 复制启动脚本 ==="
cp "$REPO_DIR/start-env.sh" "$HOME/start-ai-env.sh"
chmod +x "$HOME/start-ai-env.sh"

echo ""
echo "⚠️  请手动编辑以下文件填入 API Key："
echo "   $CONFIG_DIR/opencode.jsonc"
echo "   $HOME/.agentmemory/.env"
echo "   $HOME/.opencodereview/config.json"
echo ""
echo "✅ 配置安装完成"
