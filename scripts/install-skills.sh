#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/manifest.sh"
manifest_init

echo "=== 批量安装 OpenCode Skills ==="
echo "需先登录 opencode auth login"

SKILLS_DIR="$HOME/.config/opencode/skills"

# 检查技能是否已存在
skill_exists() {
  [ -d "$SKILLS_DIR/$1" ] || [ -d "$SKILLS_DIR/$1" ] 2>/dev/null
}

install_skill() {
  local name="$1"
  local repo="$2"
  shift 2
  if [ -d "$SKILLS_DIR/$name" ]; then
    echo "  ✅ skill $name 已存在"
    manifest_add skill name="$name" repo="$repo" pre_existing=true
  else
    echo "  安装 skill $name..."
    npx skills add "$repo" --skill "$name" "$@" -y
    manifest_add skill name="$name" repo="$repo" pre_existing=false
  fi
}

# Matt Pocock 核心 skills
install_skill to-prd                            mattpocock/skills
install_skill to-issues                         mattpocock/skills
install_skill implement                         mattpocock/skills
install_skill tdd                               mattpocock/skills
install_skill diagnosing-bugs                   mattpocock/skills
install_skill codebase-design                   mattpocock/skills
install_skill domain-modeling                   mattpocock/skills
install_skill grill-with-docs                   mattpocock/skills
install_skill prototype                         mattpocock/skills
install_skill ask-matt                          mattpocock/skills
install_skill setup-matt-pocock-skills          mattpocock/skills
install_skill triage                            mattpocock/skills
install_skill improve-codebase-architecture     mattpocock/skills
install_skill resolving-merge-conflicts         mattpocock/skills

# agentmemory skills（复合安装，先快照再检测新增）
echo "  安装 agentmemory skills..."
SKILLS_BEFORE=$(ls "$SKILLS_DIR" 2>/dev/null | sort)
npx skills add rohitg00/agentmemory -y
SKILLS_AFTER=$(ls "$SKILLS_DIR" 2>/dev/null | sort)
NEW_SKILLS=$(comm -13 <(echo "$SKILLS_BEFORE") <(echo "$SKILLS_AFTER") 2>/dev/null || echo "$SKILLS_AFTER")
if [ -n "$NEW_SKILLS" ]; then
  while IFS= read -r s; do
    [ -n "$s" ] && manifest_add skill name="$s" repo="rohitg00/agentmemory" pre_existing=false
  done <<< "$NEW_SKILLS"
fi

# 工具类 skills — anthropics/skills
install_skill frontend-design                   anthropics/skills
install_skill skill-creator                     anthropics/skills
install_skill api-design                        anthropics/skills
install_skill e2e-testing                       anthropics/skills
install_skill shadcn                            anthropics/skills
install_skill taste-skill                       anthropics/skills
install_skill minimalist-ui                     anthropics/skills
install_skill find-skills                       vercel-labs/skills
install_skill postgres                          timescale/pg-aiguide
# ponytail 是 plugin（已配在 opencode.jsonc），OpenCode 自动加载，无需 skill

# tag-based 安装（无 --skill 参数，用快照检测新增）
install_tag_repo() {
  local repo="$1"
  local label="$2"
  echo "  安装 $label..."
  SKILLS_BEFORE=$(ls "$SKILLS_DIR" 2>/dev/null | sort)
  npx skills add "$repo" -y
  SKILLS_AFTER=$(ls "$SKILLS_DIR" 2>/dev/null | sort)
  NEW_SKILLS=$(comm -13 <(echo "$SKILLS_BEFORE") <(echo "$SKILLS_AFTER") 2>/dev/null || echo "$SKILLS_AFTER")
  if [ -n "$NEW_SKILLS" ]; then
    while IFS= read -r s; do
      [ -n "$s" ] && manifest_add skill name="$s" repo="$repo" pre_existing=false
    done <<< "$NEW_SKILLS"
  fi
}
install_tag_repo "nodnarbnitram/claude-code-extensions@tauri-v2"     "tauri-v2"
install_tag_repo "jeffallan/claude-skills@rust-engineer"             "rust-engineer"
install_tag_repo "martinholovsky/claude-skills-generator@SQLite Database Expert" "SQLite Database Expert"

# ===== brainstorming skill（魔改版） =====
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "=== 安装 brainstorming skill ==="
if [ ! -d "$SKILLS_DIR/brainstorming" ]; then
  npx skills add obra/superpowers --skill brainstorming -y
fi
# 确保 .config 目录存在（npx skills add 可能装到 .agents/）
mkdir -p "$SKILLS_DIR/brainstorming"
# 魔改版覆盖（输出路径 + 转交逻辑）
cp "$REPO_DIR/skills/brainstorming/SKILL.md" "$SKILLS_DIR/brainstorming/SKILL.md"
cp "$REPO_DIR/skills/brainstorming/visual-companion.md" "$SKILLS_DIR/brainstorming/visual-companion.md"

echo "=== 安装 grill-me skill ==="
if [ ! -d "$SKILLS_DIR/grill-me" ]; then
  npx skills add mattpocock/skills --skill grill-me -y
fi
# 确保 .config 目录存在（npx skills add 可能装到 .agents/）
if [ ! -d "$SKILLS_DIR/grill-me" ]; then
  SRC=$(find "$HOME" -maxdepth 5 -path "*/skills/grill-me" -type d 2>/dev/null | head -1)
  if [ -n "$SRC" ]; then
    cp -r "$SRC" "$SKILLS_DIR/grill-me"
    echo "  ✅ grill-me 已复制到 .config（来自 $SRC）"
  else
    echo "  ⚠️ grill-me 未找到安装位置，请手动: npx skills add mattpocock/skills --skill grill-me -y"
  fi
fi

echo "=== Skills 安装完成 ==="
echo "实际数量：$(ls "$SKILLS_DIR" | wc -l | tr -d ' ') 个"
