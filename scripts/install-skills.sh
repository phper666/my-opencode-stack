#!/bin/bash
set -e

echo "=== 批量安装 OpenCode Skills ==="
echo "需先登录 opencode auth login"

# Matt Pocock 核心 skills
npx skills add mattpocock/skills --skill to-prd -y
npx skills add mattpocock/skills --skill to-issues -y
npx skills add mattpocock/skills --skill implement -y
npx skills add mattpocock/skills --skill tdd -y
npx skills add mattpocock/skills --skill diagnosing-bugs -y
npx skills add mattpocock/skills --skill codebase-design -y
npx skills add mattpocock/skills --skill domain-modeling -y
npx skills add mattpocock/skills --skill grill-with-docs -y
npx skills add mattpocock/skills --skill prototype -y
npx skills add mattpocock/skills --skill ask-matt -y
npx skills add mattpocock/skills --skill setup-matt-pocock-skills -y
npx skills add mattpocock/skills --skill triage -y
npx skills add mattpocock/skills --skill improve-codebase-architecture -y
npx skills add mattpocock/skills --skill resolving-merge-conflicts -y

# agentmemory skills
npx skills add rohitg00/agentmemory -y

# 工具类 skills — anthropics/skills
npx skills add anthropics/skills --skill frontend-design -y
npx skills add anthropics/skills --skill skill-creator -y
npx skills add anthropics/skills --skill api-design -y
npx skills add anthropics/skills --skill e2e-testing -y
npx skills add anthropics/skills --skill shadcn -y
npx skills add anthropics/skills --skill taste-skill -y
npx skills add anthropics/skills --skill minimalist-ui -y
npx skills add vercel-labs/skills --skill find-skills -y
npx skills add timescale/pg-aiguide --skill postgres -y
npx skills add nodnarbnitram/claude-code-extensions@tauri-v2 -y
npx skills add jeffallan/claude-skills@rust-engineer -y
npx skills add "martinholovsky/claude-skills-generator@SQLite Database Expert" -y
# ponytail 是 plugin（已配在 opencode.jsonc），OpenCode 自动加载，无需 skill

echo "=== Skills 安装完成 ==="
echo "实际数量：$(ls ~/.config/opencode/skills/ | wc -l | tr -d ' ') 个"
