#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/manifest.sh"

echo "=== 1. Homebrew 系统依赖 ==="
for pkg in node docker git curl rtk semgrep; do
  if brew list "$pkg" &>/dev/null 2>&1; then
    echo "  ✅ $pkg 已存在"
    manifest_add brew pkg="$pkg" pre_existing=true
  else
    echo "  安装 $pkg..."
    brew install "$pkg"
    manifest_add brew pkg="$pkg" pre_existing=false
  fi
done

echo "=== 2. npm 全局包 ==="
# 核心工具
for pkg in @agentmemory/agentmemory @alibaba-group/open-code-review @xenova/transformers; do
  if npm list -g "$pkg" &>/dev/null 2>&1; then
    echo "  ✅ $pkg 已存在"
    manifest_add npm pkg="$pkg" pre_existing=true
  else
    echo "  安装 $pkg..."
    npm install -g "$pkg"
    manifest_add npm pkg="$pkg" pre_existing=false
  fi
done

# 辅助工具（缺失时自动安装）
for pkg in bun pnpm yarn gitbook-cli anyproxy; do
  if ! command -v "$pkg" &>/dev/null; then
    echo "  安装 $pkg..."
    npm install -g "$pkg" 2>/dev/null && manifest_add npm pkg="$pkg" pre_existing=false || echo "  ⚠️ $pkg 安装失败（可选，不影响核心环境）"
  else
    echo "  ✅ $pkg 已存在"
    manifest_add npm pkg="$pkg" pre_existing=true
  fi
done

echo "=== 3. pip 工具 ==="
if pip3 show markitdown-mcp &>/dev/null 2>&1; then
  echo "  ✅ markitdown-mcp 已存在"
  manifest_add pip pkg="markitdown-mcp" pre_existing=true
else
  pip3 install markitdown-mcp
  manifest_add pip pkg="markitdown-mcp" pre_existing=false
fi

echo "=== 4. 验证 ==="
echo -n "node: "; node --version
echo -n "npm: "; npm --version
echo -n "docker: "; docker --version
echo -n "semgrep: "; semgrep --version
echo -n "rtk: "; rtk --version
echo -n "agentmemory: "; agentmemory --version
echo -n "ocr: "; ocr version
for pkg in bun pnpm yarn; do
  echo -n "$pkg: "; $pkg --version 2>/dev/null || echo "未安装"
done
echo "✅ 系统依赖安装完成"
