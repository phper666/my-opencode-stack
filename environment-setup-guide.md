# my-opencode-stack — 全栈环境复刻指南

> **使用方式**：新电脑上，把本文档交给 AI。AI 读完后按步骤自动执行命令，遇到 `<PLACEHOLDER_>` 停下来询问用户填值。
>
> **最少准备**：1 个 API Key（OpenCode Go）+ git 用户名/邮箱。共 3 个必填项。

---

## 0. 准备工作

从用户处获取以下信息：

| # | 需要 | 示例 | 去哪拿 | 必填 |
|:---:|------|------|--------|:---:|
| 1 | OpenCode Go API Key | `sk-...` | opencode.ai → Go plan | ✅ |
| 2 | Git 用户名 | `zhangsan` | 用户自己 | ✅ |
| 3 | Git 邮箱 | `user@example.com` | 用户自己 | ✅ |

拿到后执行：

```bash
# clone 本仓库
git clone https://github.com/<USER>/my-opencode-stack.git
cd my-opencode-stack

# 编辑配置文件，填入 Key
# 打开以下文件替换 <PLACEHOLDER_...> 为实际值：
#   config/opencode.jsonc
#   config/agentmemory.env
#   config/opencodereview-config.json
# config/opencode.jsonc 中目前只需替换 OPENCODE_GO_API_KEY

# 开始安装
bash scripts/setup-all.sh
```

AI 如果无法执行 shell 脚本，按以下分步执行。

---

## 1. 系统依赖

```bash
# macOS
brew install node docker git curl rtk semgrep

# Node.js ≥22
node --version

# Python3（系统自带）
python3 --version
```

### npm 全局包

```bash
npm install -g @agentmemory/agentmemory
npm install -g @alibaba-group/open-code-review
npm install -g @xenova/transformers
```

### pip 工具

```bash
pip3 install markitdown-mcp
```

---

## 2. Docker

本环境不依赖 Docker。项目所需容器（MySQL/Redis 等）由对应项目自行管理。

---

## 3. agentmemory（记忆服务）

### 3.1 配置环境变量

创建 `~/.agentmemory/.env`：

```bash
cp config/agentmemory.env ~/.agentmemory/.env
# ⚠️ 编辑 ~/.agentmemory/.env，填入 <PLACEHOLDER_LLM_KEY>
```

### 3.2 启动

```bash
agentmemory --tools all &
```

验证：

```bash
curl -s http://localhost:3111/health
# 期望: {"status":"ok"}
```

### 3.3 开机自启（launchd）

```bash
cp config/agentmemory.plist ~/Library/LaunchAgents/com.agentmemory.plist
launchctl load ~/Library/LaunchAgents/com.agentmemory.plist
```

---

## 4. OpenCode 配置

### 4.1 复制配置文件

```bash
mkdir -p ~/.config/opencode/plugins
mkdir -p ~/.config/opencode/oh-my-opencode-slim
mkdir -p ~/.config/opencode/trail-templates

# 核心配置
cp config/opencode.jsonc ~/.config/opencode/opencode.jsonc
cp config/oh-my-opencode-slim.json ~/.config/opencode/oh-my-opencode-slim.json
cp config/orchestrator_append.md ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md

# open-code-review 配置
mkdir -p ~/.opencodereview
cp config/opencodereview-config.json ~/.opencodereview/config.json
```

### 4.2 复制插件

```bash
cp plugins/rtk.js ~/.config/opencode/plugins/rtk.js
cp plugins/agentmemory-capture.ts ~/.config/opencode/plugins/agentmemory-capture.ts
```

### 4.3 复制 trail 模板

```bash
cp -r templates/trail-templates/* ~/.config/opencode/trail-templates/
```

### 4.4 登录认证

```bash
opencode auth login
opencode models --refresh
```

---

## 5. Git 配置

```bash
git config --global user.name "<PLACEHOLDER_GIT_USER_NAME>"
git config --global user.email "<PLACEHOLDER_GIT_USER_EMAIL>"
```

---

## 6. Skills

```bash
# 需先登录 opencode auth login
bash scripts/install-skills.sh
```

如无法运行脚本，手动安装核心 skills：

```bash
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
npx skills add rohitg00/agentmemory -y
```

验证：

```bash
ls ~/.config/opencode/skills/ | wc -l
# 期望: ≥32 个
```

---

## 6.5 MCP 服务

MCP 服务已配置在 `opencode.jsonc` 的 `mcp` 段，由 OpenCode 自动管理（npx），无需手动启动：

- `chrome-devtools-mcp` — 浏览器调试
- `markitdown-mcp` — 文件转 Markdown
- `sequential-thinking` — 结构化推理
- `github-mcp` — GitHub API 操作
- `codebase-memory-mcp` — 代码知识图谱
- `agentmemory` — 记忆系统

---

## 7. Caveman（输出压缩插件）

输出压缩插件，让 AI 回复去 filler、省 token。装完后自动激活，无需手动操作。

```bash
# 安装 caveman 到 OpenCode（plugin + skill + AGENTS.md 规则）
npx -y github:JuliusBrussee/caveman -- --only opencode
```

验证：

```bash
ls ~/.config/opencode/plugins/caveman/plugin.js 2>/dev/null && echo "caveman plugin ✅" || echo "caveman plugin ❌"
cat ~/.config/opencode/.caveman-active 2>/dev/null || echo "flag file: 需重启 OpenCode 后生成"
grep -q 'caveman-begin' ~/.config/opencode/AGENTS.md 2>/dev/null && echo "AGENTS.md caveman ✅" || echo "AGENTS.md caveman ❌"
```

---

## 8. 可选工具

### 7.1 CodexBar（用量监控）

macOS 菜单栏应用，实时查看各 AI 平台用量。

```bash
brew install codexbar
```

支持的提供商：[OpenCode Go / MiMo / DeepSeek / MiniMax / Kimi / OpenRouter / Cursor 等 20+](https://github.com/steipete/CodexBar)

---

## 9. 验证清单

```bash
echo "===== 验证清单 ====="

echo -n "1. agentmemory: "
agentmemory status >/dev/null 2>&1 && echo "✅" || echo "❌"

echo -n "2. skills 数量: "
SKILL_COUNT=$(ls ~/.config/opencode/skills/ | wc -l | tr -d ' ')
[ "$SKILL_COUNT" -ge 32 ] && echo "✅ ($SKILL_COUNT)" || echo "❌ ($SKILL_COUNT)"

echo -n "3. opencode.jsonc: "
[ -f ~/.config/opencode/opencode.jsonc ] && echo "✅" || echo "❌"

echo -n "4. orchestrator_append.md: "
[ -f ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md ] && echo "✅" || echo "❌"

echo -n "5. semgrep: "
semgrep --version >/dev/null 2>&1 && echo "✅" || echo "❌"

echo -n "6. ocr: "
ocr version >/dev/null 2>&1 && echo "✅" || echo "❌"

echo -n "7. codexbar: "
brew list codexbar &>/dev/null 2>&1 && echo "✅" || echo "❌（可选）"

echo -n "8. caveman plugin: "
[ -f ~/.config/opencode/plugins/caveman/plugin.js ] && echo "✅" || echo "❌"

echo -n "9. caveman active: "
[ -f ~/.config/opencode/.caveman-active ] && echo "✅" || echo "⚠️（需重启 OpenCode）"

echo -n "10. AGENTS.md caveman: "
grep -q 'caveman-begin' ~/.config/opencode/AGENTS.md 2>/dev/null && echo "✅" || echo "❌"

echo -n "11. pipeline rules: "
grep -q 'caveman-commit' ~/.config/opencode/oh-my-opencode-slim/orchestrator_append.md 2>/dev/null && echo "✅" || echo "❌"

echo "===== 复刻完成 ====="
```

---

## 10. 日常启动

```bash
bash start-env.sh
```

或复制到 `~/start-ai-env.sh` 方便使用。

---

## 11. 端口总览

| 端口 | 服务 |
|:---:|------|
| 80, 443 | Nginx 反向代理 |
| 3111 | agentmemory REST API |
| 3113 | agentmemory Viewer |
| 3306 | MySQL (taskboard) |
| 6379 | Redis (taskboard) |
| 8080 | TaskBoard 后端 |
| 9749 | codebase-memory-mcp |

---

## 12. 备份

```bash
tar czf my-opencode-stack-backup-$(date +%Y%m%d).tar.gz \
  ~/.config/opencode/ \
  ~/.agentmemory/ \
  ~/.opencodereview/
```
