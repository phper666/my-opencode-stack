#!/bin/bash
# manifest.sh — 安装记录 manifest 读写工具
#
# 用法:
#   source scripts/lib/manifest.sh
#   manifest_init
#   manifest_add type key=value key=value ...
#
# Manifest 格式: JSONL, 存储在 ~/.opencode-stack/manifest.jsonl
# 首行是版本头, 之后每行一个 action 记录

MANIFEST_DIR="$HOME/.opencode-stack"
MANIFEST_FILE="$MANIFEST_DIR/manifest.jsonl"

manifest_init() {
  mkdir -p "$MANIFEST_DIR"
  if [ ! -f "$MANIFEST_FILE" ]; then
    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "{\"version\":\"1.0\",\"created_at\":\"$now\"}" > "$MANIFEST_FILE"
    echo "📝 manifest 已创建: $MANIFEST_FILE"
  fi
}

manifest_add() {
  local type="$1"
  shift
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local json="{\"type\":\"$type\",\"ts\":\"$now\""
  local kv key val
  for kv in "$@"; do
    key="${kv%%=*}"
    val="${kv#*=}"
    # 转义双引号
    val="${val//\"/\\\"}"
    json="$json,\"$key\":\"$val\""
  done
  json="$json}"
  echo "$json" >> "$MANIFEST_FILE"
}

# 获取所有记录行（跳过版本头）
manifest_lines() {
  tail -n +2 "$MANIFEST_FILE" 2>/dev/null || true
}

# 获取 manifest 路径（供 uninstall.sh source）
manifest_file() {
  echo "$MANIFEST_FILE"
}
