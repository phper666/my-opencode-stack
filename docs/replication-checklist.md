# 全栈环境复刻验证清单

> 在新电脑上跑完安装后，用此清单验证环境是否完整。
> 通过全部检查项 = 可正常进入 10 步管道开发。

---

## 一、系统依赖

| # | 检查项 | 命令 | 预期 |
|:-:|:------|:-----|:-----|
| 1 | Node.js | `node --version` | ≥18 |
| 2 | npm | `npm --version` | 正常 |
| 3 | Docker | `docker info` | 正常（可选） |
| 4 | Git | `git --version` | 正常 |
| 5 | curl | `curl --version` | 正常 |
| 6 | rtk | `rtk --version` | 正常 |
| 7 | semgrep | `semgrep --version` | 正常 |

---

## 二、配置文件

| # | 检查项 | 路径 | 预期 |
|:-:|:------|:-----|:-----|
| 8 | 主配置 | `~/.config/opencode/opencode.jsonc` | 存在，API key 已填 |
| 9 | Agent 编排 | `~/.config/opencode/oh-my-opencode-slim.json` | 存在 |
| 10 | 管道规则 | `~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md` | 存在 |
| 11 | Code review 配置 | `~/.opencodereview/config.json` | 存在 |
| 12 | agentmemory env | `~/.agentmemory/.env` | 存在，LLM key 已填 |
| 13 | agentmemory 开机自启 | `~/Library/LaunchAgents/com.agentmemory.plist` | 存在 |

---

## 三、插件

| # | 检查项 | 路径 | 预期 |
|:-:|:------|:-----|:-----|
| 14 | oh-my-opencode-slim | 在 opencode.jsonc plugin 数组中 | 自动加载 |
| 15 | context-mode | 同上 | 自动加载 |
| 16 | token-monitor | 同上 | 自动加载 |
| 17 | ponytail | 同上 | 自动加载 |
| 18 | rtk.js | `~/.config/opencode/plugins/rtk.js` | 存在 |
| 19 | agentmemory-capture | `~/.config/opencode/plugins/agentmemory-capture.ts` | 存在 |
| 20 | **caveman plugin** | `~/.config/opencode/plugins/caveman/plugin.js` | **存在** |
| 21 | **caveman flag** | `~/.config/opencode/.caveman-active` | 重启 OpenCode 后含 `full` |
| 22 | **AGENTS.md caveman** | `~/.config/opencode/AGENTS.md` | 含 `<!-- caveman-begin -->` |

---

## 四、Skills

| # | 检查项 | 预期 |
|:-:|:------|:-----|
| 23 | skills 总数 | `ls ~/.config/opencode/skills/ \| wc -l` ≥ 32 |
| 24 | Matt Pocock 核心 | to-prd, to-issues, implement, tdd, diagnosing-bugs, codebase-design, domain-modeling, grill-with-docs, prototype, ask-matt, setup-matt-pocock-skills, triage, improve-architecture, resolving-merge-conflicts, grill-me |
| 25 | brainstorming | `~/.config/opencode/skills/brainstorming/SKILL.md` 存在 |
| 26 | caveman + 子 skill | caveman, caveman-commit, caveman-review, caveman-stats, caveman-compress, caveman-help, cavecrew |
| 27 | PUA 鞭策 | pua, p10, p7, p9, ding, mama, yes, pro, shot 等 |
| 28 | 领域技能 | shadcn, tauri-v2, rust-engineer, postgres, sqlite-database-expert, api-design, e2e-testing |

---

## 五、服务

| # | 检查项 | 命令 | 预期 |
|:-:|:------|:-----|:-----|
| 29 | agentmemory | `agentmemory status` | 运行中 (3111/3113) |
| 30 | codebase-memory-mcp | `~/.local/bin/codebase-memory-mcp --version` | 存在 |
| 31 | chrome-devtools | 首次调用自动 npx 安装 | — |
| 32 | sequential-thinking | 同上 | — |
| 33 | github-mcp | 同上 | — |
| 34 | markitdown-mcp | `which markitdown-mcp` | 存在 |

---

## 六、管道功能验证（关键）

启动 OpenCode 后，验证以下场景：

| # | 场景 | 验证方式 | 预期行为 |
|:-:|:-----|:---------|:---------|
| 35 | **caveman 自动激活** | 说一句话，看回复是否去 filler | 回复简短无废话 |
| 36 | **子 agent caveman** | 派 @fixer 或 @explorer 执行任务 | 子 agent 同样压缩风格 |
| 37 | **ponytail 激活** | 写一段代码建议 | 代码最小化，无多余抽象 |
| 38 | **brainstorming skill** | 说"我想要一个简单的 CRUD" | 自动进入需求探索流程 |
| 39 | **to-prd** | brainstroming 结束后 | 正常合成 PRD |
| 40 | **orchestrator 路由** | 说"修个 bug" | 直接派 @fixer，不走 PRD |

---

## 七、快速诊断

```bash
# 一键检查关键项
echo "=== 快速诊断 ==="
echo -n "agentmemory: "; agentmemory status >/dev/null 2>&1 && echo "✅" || echo "❌"
echo -n "skills: "; ls ~/.config/opencode/skills/ | wc -l | xargs echo
echo -n "caveman plugin: "; [ -f ~/.config/opencode/plugins/caveman/plugin.js ] && echo "✅" || echo "❌"
echo -n "caveman flag: "; cat ~/.config/opencode/.caveman-active 2>/dev/null || echo "⚠️ 需重启"
echo -n "AGENTS.md: "; grep -q 'caveman-begin' ~/.config/opencode/AGENTS.md 2>/dev/null && echo "✅" || echo "❌"
echo -n "ponytail: "; grep -q 'ponytail' ~/.config/opencode/opencode.jsonc 2>/dev/null && echo "✅" || echo "❌"
echo -n "pipe rules: "; grep -q 'caveman-commit' ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md 2>/dev/null && echo "✅" || echo "❌"
```

---

---

## 八、AI 一键验证

安装完成后，AI 自动执行以下全部检查并报告结果：

```bash
echo "========== 全栈环境复刻验证 =========="

# 一、系统依赖
echo "--- 系统依赖 ---"
echo -n "node: "; node --version 2>/dev/null || echo "❌"
echo -n "npm: "; npm --version 2>/dev/null || echo "❌"
echo -n "git: "; git --version 2>/dev/null || echo "❌"
echo -n "rtk: "; rtk --version 2>/dev/null || echo "❌"
echo -n "semgrep: "; semgrep --version 2>/dev/null || echo "❌"
echo -n "docker: "; docker info >/dev/null 2>&1 && echo "✅" || echo "⚠️（可选）"

# 二、配置文件
echo "--- 配置文件 ---"
for f in \
  ~/.config/opencode/opencode.jsonc \
  ~/.config/opencode/oh-my-opencode-slim.json \
  ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md \
  ~/.opencodereview/config.json \
  ~/.agentmemory/.env \
  ~/Library/LaunchAgents/com.agentmemory.plist; do
  [ -f "$f" ] && echo "✅ ${f##*/}" || echo "❌ ${f##*/}"
done

# 三、插件
echo "--- 插件 ---"
echo -n "rtk.js: "; [ -f ~/.config/opencode/plugins/rtk.js ] && echo "✅" || echo "❌"
echo -n "agentmemory-capture: "; [ -f ~/.config/opencode/plugins/agentmemory-capture.js ] && echo "✅" || echo "❌"
echo -n "caveman plugin: "; [ -f ~/.config/opencode/plugins/caveman/plugin.js ] && echo "✅" || echo "❌"
echo -n "caveman flag: "; [ -f ~/.config/opencode/.caveman-active ] && cat ~/.config/opencode/.caveman-active || echo "⚠️（需重启 OpenCode）"
echo -n "AGENTS.md caveman: "; grep -q 'caveman-begin' ~/.config/opencode/AGENTS.md 2>/dev/null && echo "✅" || echo "❌"

# 四、Skills
echo "--- Skills ---"
SKILL_COUNT=$(ls ~/.config/opencode/skills/ | wc -l | tr -d ' ')
echo -n "skills 总数: "; [ "$SKILL_COUNT" -ge 32 ] && echo "✅ ($SKILL_COUNT)" || echo "❌ ($SKILL_COUNT)"
for s in to-prd tdd implement diagnosing-bugs codebase-design brainstorming caveman caveman-review caveman-commit caveman-stats pua; do
  echo -n "  $s: "; [ -d ~/.config/opencode/skills/$s ] && echo "✅" || echo "❌"
done

# 五、服务
echo "--- 服务 ---"
echo -n "agentmemory: "; agentmemory status >/dev/null 2>&1 && echo "✅" || echo "❌"
echo -n "codebase-memory-mcp: "; [ -f ~/.local/bin/codebase-memory-mcp ] && echo "✅" || echo "❌"
echo -n "markitdown: "; which markitdown-mcp >/dev/null 2>&1 && echo "✅" || echo "❌"

# 六、管道规则
echo "--- 管道 ---"
echo -n "caveman-commit 规则: "; grep -q 'caveman-commit' ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md 2>/dev/null && echo "✅" || echo "❌"
echo -n "caveman-review 规则: "; grep -q 'caveman-review' ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md 2>/dev/null && echo "✅" || echo "❌"
echo -n "caveman-stats 规则: "; grep -q 'caveman-stats' ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md 2>/dev/null && echo "✅" || echo "❌"

echo "========== 验证完成 =========="
echo "全部 ✅ → 环境正常，可开始开发"
echo "有 ❌ → 对照 environment-setup-guide.md 重新执行对应步骤"
```

---

> **通过标准**: 全部 ✅ 或 ⚠️（可选）通过。
> **若失败**: AI 重新执行 `environment-setup-guide.md` 中对应的安装步骤。
> **管道功能验证**: 首次启动 OpenCode 后，AI 自动测试 6 个场景（caveman 激活、子 agent 压缩、brainstorming 等）。
