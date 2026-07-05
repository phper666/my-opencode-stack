#!/bin/bash
# my-opencode-stack 同步脚本
# 本地环境有变更后，跑这个脚本把变更同步回仓库
# 用法: bash scripts/sync.sh [--dry-run]

set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true

echo "=== my-opencode-stack 同步 ==="
$DRY_RUN && echo "（预演模式，不会实际写入）"
echo ""

sync_file() {
  local src="$1"
  local dst="$2"
  local desc="$3"

  if [ ! -f "$src" ]; then
    echo "  ⚠️  源文件不存在: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if $DRY_RUN; then
    if [ -f "$dst" ]; then
      if ! diff -q "$src" "$dst" >/dev/null 2>&1; then
        echo "  📝 $desc — 有变更"
      else
        echo "  ✅ $desc — 无变化"
      fi
    else
      echo "  🆕 $desc — 新增"
    fi
  else
    cp "$src" "$dst"
    # 替换真实 API Key 为占位符
    # opencode.jsonc: 替换 echobraid key
    if echo "$dst" | grep -q "opencode.jsonc"; then
      sed -i '' 's|"apiKey": "sk-ant-eb01-[^"]*"|"apiKey": "<PLACEHOLDER_ECHOBRAID_API_KEY>"|g' "$dst" 2>/dev/null || true
      sed -i '' 's|"apiKey": "sk-[^"]*"|"apiKey": "<PLACEHOLDER_OPENCODE_GO_API_KEY>"|g' "$dst" 2>/dev/null || true
      # 替换 codebase-memory-mcp 路径为占位符
      sed -i '' 's|/Users/[^/]*/.local/bin/codebase-memory-mcp|<PLACEHOLDER_HOME>/.local/bin/codebase-memory-mcp|g' "$dst" 2>/dev/null || true
    fi
    # agentmemory.env: 替换 LLM key
    if echo "$dst" | grep -q "agentmemory.env"; then
      # 只替换看起来像 key 的值，不替换注释行
      sed -i '' 's/^OPENAI_API_KEY=.*/OPENAI_API_KEY=<PLACEHOLDER_LLM_KEY>/' "$dst" 2>/dev/null || true
    fi
    # opencodereview-config.json: 替换 key
    if echo "$dst" | grep -q "opencodereview-config.json"; then
      sed -i '' 's|"apiKey": "[^"]*"|"apiKey": "<PLACEHOLDER_ECHOBRAID_API_KEY>"|g' "$dst" 2>/dev/null || true
    fi
    echo "  ✅ $desc"
  fi
}

sync_dir() {
  local src="$1"
  local dst="$2"
  local desc="$3"

  if [ ! -d "$src" ]; then
    echo "  ⚠️  源目录不存在: $src"
    return
  fi

  if $DRY_RUN; then
    local diff_count=$(diff -rq "$src" "$dst" 2>/dev/null | grep -c "differ\|Only in" || true)
    if [ "$diff_count" -gt 0 ]; then
      echo "  📝 $desc — $diff_count 处变更"
    else
      echo "  ✅ $desc — 无变化"
    fi
  else
    cp -r "$src"/* "$dst"/ 2>/dev/null || true
    echo "  ✅ $desc"
  fi
}

echo "--- 配置文件 ---"
sync_file "$HOME/.config/opencode/opencode.jsonc" "$REPO_DIR/config/opencode.jsonc" "opencode.jsonc"
sync_file "$HOME/.config/opencode/oh-my-opencode-slim.json" "$REPO_DIR/config/oh-my-opencode-slim.json" "oh-my-opencode-slim.json"
sync_file "$HOME/.config/opencode/oh-my-opencode-slim/orchestrator_append.md" "$REPO_DIR/config/orchestrator_append.md" "orchestrator_append.md"
sync_file "$HOME/.agentmemory/.env" "$REPO_DIR/config/agentmemory.env" "agentmemory.env"
sync_file "$HOME/.opencodereview/config.json" "$REPO_DIR/config/opencodereview-config.json" "opencodereview-config.json"

echo ""
echo "--- 插件 ---"
sync_file "$HOME/.config/opencode/plugins/rtk.js" "$REPO_DIR/plugins/rtk.js" "rtk.js"
sync_file "$HOME/.config/opencode/plugins/agentmemory-capture.ts" "$REPO_DIR/plugins/agentmemory-capture.ts" "agentmemory-capture.ts"

echo ""
echo "--- Trail 模板 ---"
sync_dir "$HOME/.config/opencode/trail-templates/" "$REPO_DIR/templates/trail-templates/" "trail-templates"

if ! $DRY_RUN; then
  echo ""
  echo "--- 检查变更 ---"
  cd "$REPO_DIR"
  if [ -n "$(git status --porcelain)" ]; then
    echo "有变更，准备提交..."
    git add -A
    git commit -m "sync: $(date +%Y-%m-%d) 环境同步

自动同步自本地开发环境。
$(git diff --cached --stat --name-only | head -20)"
    git push origin main
    echo "✅ 已提交并推送"
  else
    echo "✅ 无变更，环境是最新的"
  fi
fi
