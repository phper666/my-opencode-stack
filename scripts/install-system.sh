#!/bin/bash
set -e

echo "=== 1. Homebrew 系统依赖 ==="
brew install node docker git curl rtk semgrep

echo "=== 2. npm 全局包 ==="
npm install -g @agentmemory/agentmemory @alibaba-group/open-code-review @xenova/transformers

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
echo "✅ 系统依赖安装完成"
