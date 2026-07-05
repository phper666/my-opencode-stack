# my-opencode-stack — 全栈环境复刻指南

> **使用方式**：新电脑上，把本文档交给 AI。AI 读完后按步骤自动执行命令，遇到 `<PLACEHOLDER_>` 停下来询问用户填值。
>
> **最少准备**：2 个 API Key（Echobraid + OpenCode Go）+ git 用户名/邮箱。共 4 个必填项。

---

## 0. 准备工作

从用户处获取以下信息：

| # | 需要 | 示例 | 去哪拿 | 必填 |
|:---:|------|------|--------|:---:|
| 1 | Echobraid API Key | `sk-ant-eb01-...` | opencode.ai → Echobraid | ✅ |
| 2 | OpenCode Go API Key | `sk-...` | opencode.ai → Go plan | ✅ |
| 3 | Git 用户名 | `zhangsan` | 用户自己 | ✅ |
| 4 | Git 邮箱 | `user@example.com` | 用户自己 | ✅ |

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

## 2. Docker 容器

```bash
# Nginx 反向代理
docker run -d --name api-redirect --restart unless-stopped \
  -p 80:80 -p 443:443 nginx:alpine

# TaskBoard
docker run -d --name taskboard-mysql --restart unless-stopped \
  -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0
docker run -d --name taskboard-redis --restart unless-stopped \
  -p 6379:6379 redis:7-alpine
```

验证：

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

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

## 7. MCP 服务

MCP 服务已配置在 `opencode.jsonc` 的 `mcp` 段，由 OpenCode 自动管理（npx），无需手动启动：

- `chrome-devtools-mcp` — 浏览器调试
- `markitdown-mcp` — 文件转 Markdown
- `sequential-thinking` — 结构化推理
- `github-mcp` — GitHub API 操作
- `codebase-memory-mcp` — 代码知识图谱
- `agentmemory` — 记忆系统

---

## 8. 验证清单

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

echo "===== 复刻完成 ====="
```

---

## 9. 日常启动

```bash
bash start-env.sh
```

或复制到 `~/start-ai-env.sh` 方便使用。

---

## 10. 端口总览

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

## 11. 备份

```bash
tar czf my-opencode-stack-backup-$(date +%Y%m%d).tar.gz \
  ~/.config/opencode/ \
  ~/.agentmemory/ \
  ~/.opencodereview/
```
