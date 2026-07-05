#!/bin/bash
set -e

echo "=== 1. Homebrew 系统依赖 ==="
brew install node docker git curl rtk semgrep

echo "=== 2. npm 全局包 ==="
# 核心工具
npm install -g @agentmemory/agentmemory @alibaba-group/open-code-review @xenova/transformers

# 辅助工具（缺失时自动安装）
for pkg in bun pnpm yarn gitbook-cli anyproxy; do
  if ! command -v "$pkg" &>/dev/null; then
    echo "  安装 $pkg..."
    npm install -g "$pkg" 2>/dev/null || echo "  ⚠️ $pkg 安装失败（可选，不影响核心环境）"
  else
    echo "  ✅ $pkg 已存在"
  fi
done

echo "=== 3. pip 工具 ==="
pip3 install markitdown-mcp

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
