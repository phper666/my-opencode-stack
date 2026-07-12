#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/manifest.sh"

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
manifest_add file repo_path="config/opencode.jsonc" target="$CONFIG_DIR/opencode.jsonc"
cp "$REPO_DIR/config/oh-my-opencode-slim.json" "$CONFIG_DIR/oh-my-opencode-slim.json"
manifest_add file repo_path="config/oh-my-opencode-slim.json" target="$CONFIG_DIR/oh-my-opencode-slim.json"
mkdir -p "$CONFIG_DIR/oh-my-opencode-slim"
cp "$REPO_DIR/config/orchestrator_append.md" "$CONFIG_DIR/oh-my-opencode-slim/orchestrator_append.md"
manifest_add file repo_path="config/orchestrator_append.md" target="$CONFIG_DIR/oh-my-opencode-slim/orchestrator_append.md"

echo "=== 3. 复制 open-code-review 配置 ==="
cp "$REPO_DIR/config/opencodereview-config.json" "$HOME/.opencodereview/config.json"
manifest_add file repo_path="config/opencodereview-config.json" target="$HOME/.opencodereview/config.json"

echo "=== 4. 复制 agentmemory 配置 ==="
cp "$REPO_DIR/config/agentmemory.env" "$HOME/.agentmemory/.env"
manifest_add file repo_path="config/agentmemory.env" target="$HOME/.agentmemory/.env"
PLIST_DEST="$HOME/Library/LaunchAgents/com.agentmemory.plist"
cp "$REPO_DIR/config/agentmemory.plist" "$PLIST_DEST"
# 替换 PLACEHOLDER_HOME 为真实路径
sed -i '' "s|<PLACEHOLDER_HOME>|$HOME|g" "$PLIST_DEST"
# 如果 node 不在默认 PATH 中，追加到 plist
NODE_DIR="$(dirname "$(which node 2>/dev/null)")"
if [ -n "$NODE_DIR" ] && ! echo "$NODE_DIR" | grep -qE "^/(usr/local|usr/bin|opt/homebrew)"; then
  sed -i '' "s|<PLACEHOLDER_HOME>/.local/bin|<PLACEHOLDER_HOME>/.local/bin:$NODE_DIR|" "$PLIST_DEST"
fi
manifest_add launchd path="$PLIST_DEST"

echo "=== 5. 安装插件依赖 ==="
if [ ! -f "$CONFIG_DIR/package.json" ]; then
  echo '{"type":"module","dependencies":{}}' > "$CONFIG_DIR/package.json"
fi
(cd "$CONFIG_DIR" && npm install @opencode-ai/plugin@latest context-mode@latest --save 2>/dev/null)

echo "=== 6. 复制插件 ==="
cp "$REPO_DIR/plugins/rtk.js" "$PLUGIN_DIR/rtk.js"
manifest_add file repo_path="plugins/rtk.js" target="$PLUGIN_DIR/rtk.js"
cp "$REPO_DIR/plugins/agentmemory-capture.js" "$PLUGIN_DIR/agentmemory-capture.js"
manifest_add file repo_path="plugins/agentmemory-capture.js" target="$PLUGIN_DIR/agentmemory-capture.js"
cp "$REPO_DIR/plugins/agentmemory-capture.ts" "$PLUGIN_DIR/agentmemory-capture.ts"
manifest_add file repo_path="plugins/agentmemory-capture.ts" target="$PLUGIN_DIR/agentmemory-capture.ts"

echo "=== 6.5 安装 worktree 插件 ==="
WORKTREE_DIR="$PLUGIN_DIR/worktree"
if [ ! -d "$WORKTREE_DIR" ]; then
  cp -r "$REPO_DIR/plugins/worktree" "$WORKTREE_DIR"
  manifest_add dir repo_path="plugins/worktree/" target="$WORKTREE_DIR"
  (cd "$WORKTREE_DIR" && npm install)
  echo "worktree plugin ✅"
else
  echo "worktree plugin 已存在，跳过"
fi

echo "=== 7. 复制 trail 模板 ==="
mkdir -p "$CONFIG_DIR/trail-templates"
cp -r "$REPO_DIR/templates/trail-templates/"* "$CONFIG_DIR/trail-templates/"
manifest_add file repo_path="templates/trail-templates/" target="$CONFIG_DIR/trail-templates/"

echo "=== 7.5 复制 worktree 模板配置 ==="
WORKTREE_TEMPLATE="$REPO_DIR/templates/worktree.jsonc"
if [ -f "$WORKTREE_TEMPLATE" ] && [ ! -f "$REPO_DIR/.opencode/worktree.jsonc" ]; then
  mkdir -p "$REPO_DIR/.opencode"
  cp "$WORKTREE_TEMPLATE" "$REPO_DIR/.opencode/worktree.jsonc"
  echo "worktree config 模板 -> $REPO_DIR/.opencode/worktree.jsonc"
fi

echo "=== 8. 复制启动脚本 ==="
cp "$REPO_DIR/start-env.sh" "$HOME/start-ai-env.sh"
chmod +x "$HOME/start-ai-env.sh"
manifest_add file repo_path="start-env.sh" target="$HOME/start-ai-env.sh"

echo ""
echo "⚠️  请手动编辑以下文件填入 API Key："
echo "   $CONFIG_DIR/opencode.jsonc"
echo "   $HOME/.agentmemory/.env"
echo "   $HOME/.opencodereview/config.json"
echo ""
echo "✅ 配置安装完成"
