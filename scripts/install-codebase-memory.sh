#!/bin/bash
set -e

echo "=== 安装 codebase-memory-mcp ==="

# 检测架构
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  FILE="codebase-memory-mcp-x86_64-apple-darwin" ;;
  arm64)   FILE="codebase-memory-mcp-aarch64-apple-darwin" ;;
  *)       echo "不支持的架构: $ARCH"; exit 1 ;;
esac

VERSION="v0.8.1"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/codebase-memory-mcp"

if [ -f "$BIN_PATH" ]; then
  echo "✅ 已存在: $BIN_PATH"
  exit 0
fi

mkdir -p "$BIN_DIR"

echo "下载 $FILE $VERSION ..."
curl -L -o "$BIN_PATH" \
  "https://github.com/DeusData/codebase-memory-mcp/releases/download/$VERSION/$FILE"

chmod +x "$BIN_PATH"
echo "✅ 安装完成: $BIN_PATH ($(du -h "$BIN_PATH" | cut -f1))"
