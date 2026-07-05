#!/bin/bash
# uninstall.sh — 移除 my-opencode-stack 安装的所有组件
#
# 读取 ~/.opencode-stack/manifest.jsonl，区分：
#   - pre_existing=false → 本栈安装的，自动移除
#   - pre_existing=true  → 用户原有的，列清单不动
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/manifest.sh"

MANIFEST_FILE="$HOME/.opencode-stack/manifest.jsonl"

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "❌ 未找到 manifest 文件: $MANIFEST_FILE"
  echo "   无法执行卸载。请确认已运行过 setup-all.sh。"
  exit 1
fi

echo "============================================"
echo " my-opencode-stack — 卸载"
echo "============================================"
echo ""
echo "读取 manifest: $MANIFEST_FILE"
echo ""

REMOVED=()
KEPT=()
ERRORS=()

# 终止 launchd 服务（在删 plist 之前）
echo "--- 终止 launchd 服务 ---"
for plist in $(manifest_lines | grep '"type":"launchd"' | sed 's/.*"path":"\([^"]*\)".*/\1/'); do
  if [ -f "$plist" ]; then
    echo "  卸载 launchd: $plist"
    launchctl unload "$plist" 2>/dev/null && echo "  ✅ 已停止" || echo "  ⚠️  停止失败（可能未加载）"
    rm -f "$plist" && REMOVED+=("launchd: $plist") || ERRORS+=("launchd: $plist")
  fi
done

# 移除本栈安装的三方包
echo ""
echo "--- 移除工具（本栈安装）---"
for line in $(manifest_lines | grep '"pre_existing":"false"'); do
  type=$(echo "$line" | sed 's/.*"type":"\([^"]*\)".*/\1/')
  case "$type" in
    brew)
      pkg=$(echo "$line" | sed 's/.*"pkg":"\([^"]*\)".*/\1/')
      echo "  brew uninstall $pkg..."
      brew uninstall "$pkg" 2>/dev/null && { REMOVED+=("brew: $pkg"); echo "  ✅"; } || { ERRORS+=("brew: $pkg"); echo "  ⚠️  失败"; }
      ;;
    npm)
      pkg=$(echo "$line" | sed 's/.*"pkg":"\([^"]*\)".*/\1/')
      echo "  npm uninstall -g $pkg..."
      npm uninstall -g "$pkg" 2>/dev/null && { REMOVED+=("npm: $pkg"); echo "  ✅"; } || { ERRORS+=("npm: $pkg"); echo "  ⚠️  失败"; }
      ;;
    pip)
      pkg=$(echo "$line" | sed 's/.*"pkg":"\([^"]*\)".*/\1/')
      echo "  pip3 uninstall $pkg..."
      pip3 uninstall -y "$pkg" 2>/dev/null && { REMOVED+=("pip: $pkg"); echo "  ✅"; } || { ERRORS+=("pip: $pkg"); echo "  ⚠️  失败"; }
      ;;
    skill)
      name=$(echo "$line" | sed 's/.*"name":"\([^"]*\)".*/\1/')
      skill_dir="$HOME/.config/opencode/skills/$name"
      if [ -d "$skill_dir" ]; then
        rm -rf "$skill_dir" && { REMOVED+=("skill: $name"); echo "  ✅ skill $name"; } || ERRORS+=("skill: $name")
      else
        echo "  ⏭️  skill $name 目录不存在，跳过"
      fi
      ;;
    binary)
      path=$(echo "$line" | sed 's/.*"path":"\([^"]*\)".*/\1/')
      if [ -f "$path" ]; then
        rm -f "$path" && { REMOVED+=("binary: $path"); echo "  ✅ $path"; } || ERRORS+=("binary: $path")
      else
        echo "  ⏭️  $path 已不存在"
      fi
      ;;
  esac
done

# 移除本栈复制的文件（file 类型，不含 pre_existing 字段）
echo ""
echo "--- 移除配置文件 ---"
for line in $(manifest_lines | grep '"type":"file"'); do
  target=$(echo "$line" | sed 's/.*"target":"\([^"]*\)".*/\1/')
  if [ -f "$target" ]; then
    rm -f "$target" && { REMOVED+=("file: $target"); echo "  ✅ $target"; } || ERRORS+=("file: $target")
  elif [ -d "$target" ]; then
    # 目录类型只删我们明确复制的文件，不删目录本身（可能还有用户数据）
    echo "  ⏭️  跳过目录: $target（保留目录结构）"
  else
    echo "  ⏭️  $target 已不存在"
  fi
done

# 列出用户原有的、未被移除的项目
echo ""
echo "--- 以下为安装前已存在的工具，未做改动 ---"
for line in $(manifest_lines | grep '"pre_existing":"true"'); do
  type=$(echo "$line" | sed 's/.*"type":"\([^"]*\)".*/\1/')
  case "$type" in
    brew)
      pkg=$(echo "$line" | sed 's/.*"pkg":"\([^"]*\)".*/\1/')
      KEPT+=("brew: $pkg")
      echo "  ⏭️  brew $pkg（原有）"
      ;;
    npm)
      pkg=$(echo "$line" | sed 's/.*"pkg":"\([^"]*\)".*/\1/')
      KEPT+=("npm: $pkg")
      echo "  ⏭️  npm $pkg（原有）"
      ;;
    pip)
      pkg=$(echo "$line" | sed 's/.*"pkg":"\([^"]*\)".*/\1/')
      KEPT+=("pip: $pkg")
      echo "  ⏭️  pip $pkg（原有）"
      ;;
    skill)
      name=$(echo "$line" | sed 's/.*"name":"\([^"]*\)".*/\1/')
      KEPT+=("skill: $name")
      echo "  ⏭️  skill $name（原有）"
      ;;
    binary)
      path=$(echo "$line" | sed 's/.*"path":"\([^"]*\)".*/\1/')
      KEPT+=("binary: $path")
      echo "  ⏭️  binary $path（原有）"
      ;;
  esac
done

# 检查是否有未知类型的记录未被处理
echo ""
echo "--- 检查未识别记录 ---"
KNOWN_TYPES="brew npm pip skill binary file launchd"
UNKNOWN=$(manifest_lines | sed 's/.*"type":"\([^"]*\)".*/\1/' | sort -u | while read -r t; do
  found=0
  for k in $KNOWN_TYPES; do [ "$t" = "$k" ] && found=1; done
  [ "$found" -eq 0 ] && [ -n "$t" ] && echo "  ⚠️  未识别 type=\"$t\" — 需手动检查 manifest"
done)
if [ -n "$UNKNOWN" ]; then
  echo "$UNKNOWN"
  echo "  查看 manifest: $MANIFEST_FILE"
else
  echo "  ✅ 所有记录类型均已处理"
fi

# 清理空目录（只删我们创建的、已变空的目录）
echo ""
echo "--- 清理空目录 ---"
for d in "$HOME/.opencodereview" "$HOME/.agentmemory" "$HOME/.local/bin"; do
  if [ -d "$d" ] && [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
    rmdir "$d" 2>/dev/null && echo "  ✅ 删除空目录: $d"
  fi
done

echo ""
echo "============================================"
echo " 卸载完成"
echo "============================================"
echo ""
echo "✅ 已移除: ${#REMOVED[@]} 项"
for item in "${REMOVED[@]}"; do
  echo "   • $item"
done
echo ""
echo "⏭️  保留（安装前已存在）: ${#KEPT[@]} 项"
for item in "${KEPT[@]}"; do
  echo "   • $item"
done
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "⚠️  以下项移除时出错："
  for item in "${ERRORS[@]}"; do
    echo "   • $item"
  done
fi
echo ""
echo "📌 注意：以下文件需您手动编辑 / 清理："
echo "   ~/.config/opencode/opencode.jsonc（API Key 等配置）"
echo "   ~/.config/opencode/package.json（npm 依赖）"
echo "   ~/.zshrc（如果曾手动追加过 PATH）"
echo ""
echo "📌 要恢复 OpenCode 自身配置，请手动编辑 ~/.config/opencode / ~/.opencode/"
