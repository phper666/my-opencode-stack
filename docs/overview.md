# my-opencode-stack 是什么

一套**开箱即用的 OpenCode 全栈开发环境**。装完后你得到的是一个 AI 开发团队，不是单个聊天窗口。

## 能力清单

装完 `my-opencode-stack` 后，你在 OpenCode 里拥有：

| 能力 | 由谁提供 | 数量 |
|:----|:---------|:----:|
| **专业 AI 角色** | 8 个 agent：orchestrator / oracle / designer / fixer / librarian / explorer / observer / council | 8 |
| **工程技能** | Matt Pocock skills + Superpowers brainstorming（需求探索 → PRD → 实现 → 审查 → 回验） | 16 |
| **鞭策/生产力** | PUA 鞭策 + 大厂方法论路由 — 穷尽方案后再放弃 | 12 |
| **领域技能** | PostgreSQL / SQLite / Tauri / Rust / Playwright E2E / shadcn UI / REST API 设计 / 前端设计系统 | 20+ |
| **长期记忆** | agentmemory（L0-L3，51 个 MCP 工具）| 1 |
| **代码理解** | codebase-memory-mcp（代码知识图谱 + 调用关系追踪）| 1 |
| **工具集成** | GitHub / 浏览器调试 / 文件转 Markdown / 结构化推理 | 4 MCP |
| **质量门禁** | open-code-review + semgrep + 自修复 lint | 3 |
| **输出压缩** | caveman（语言精简，省 ~54% 中文输出 token）+ ponytail（代码最小化） | 2 |
| **开发流程** | 10 步管道（PRD → 知识回写 + 回溯回路 + DAG）| 1 |

> **语言支持**：10 步管道（PRD → 实现 → 审查 → 安全扫描）是**语言无关**的，Java、Python、Go、TypeScript、Rust 等都能用。列出的 PostgreSQL / Tauri / Rust 等是额外安装的领域技能，不是限制。`open-code-review` 原生支持 Java/TS/JS/Python/Go，`semgrep` 支持 30+ 语言。

## 跟普通 OpenCode 的区别

| 维度 | 普通 OpenCode | my-opencode-stack |
|:----|:-------------|:------------------|
| 角色分工 | 1 个通用 agent | 8 个专业 agent 各司其职 |
| 开发流程 | 无规范，你说一句 AI 做一步 | 10 步管道：先 PRD → 设计 → 架构 → TDD 实现 → 审查 → 回验 |
| 质量控制 | 靠提示词临场发挥 | 自修复 lint（3 轮）+ code review + semgrep + 验收回验 |
| 记忆 | 当前会话 | agentmemory 长期记忆（跨会话） |
| 代码理解 | 无 | codebase-memory-mcp 知识图谱 |
| 工程纪律 | 无 | TDD 强制（8 条例外）+ 回溯回路 + DAG 依赖图 |
| 接手中途项目 | 从零读代码 | BASELINE.md 基线 + 4 步接入流程 |

## 适用场景

**适合你，如果：**
- 你用 OpenCode 做全栈开发，想要有工程纪律而非自由对话
- 你想让 AI 写代码前先写 PRD、先设计、先写测试
- 你需要在多个项目间保持一致的开发流程和代码质量
- 你接手过别人的项目看不懂代码结构

**不适合你，如果：**
- 你只用 OpenCode 做简单问答（"这个代码什么意思"）
- 你不想让 AI 帮你做架构决策
- 你不需要跨会话记忆和代码知识图谱

## 引用的项目

| 项目 | 用途 | 链接 | 安装方式 |
|:----|:-----|:----|:---------|
| **OpenCode** | AI 编码 IDE，本环境的基础 | https://github.com/opencode-ai/opencode | 手动下载 |
| **oh-my-opencode-slim** | 8 agent 编排插件 + 路由规则 | https://github.com/code-yeongyu/oh-my-opencode-slim | `opencode.jsonc` 插件声明，自动加载 |
| **context-mode** | 上下文保护（ctx_* 工具）| https://github.com/mksglu/context-mode | `opencode.jsonc` 插件声明，自动加载 |
| **opencode-token-monitor** | token 用量监控 | https://www.npmjs.com/package/opencode-token-monitor | `opencode.jsonc` 插件声明，自动加载 |
| **ponytail** | 代码最小化原则 | https://github.com/DietrichGebert/ponytail | `opencode.jsonc` 插件声明，自动加载 |
| **rtk** | CLI 输出 token 压缩 | https://github.com/rtk-ai/rtk | `install-system.sh` brew install |
| **agentmemory** | 长期记忆（51 MCP 工具）| https://www.npmjs.com/package/@agentmemory/agentmemory | `install-system.sh` npm install -g |
| **@xenova/transformers** | 本地向量嵌入 | https://www.npmjs.com/package/@xenova/transformers | `install-system.sh` npm install -g |
| **semgrep** | 多语言安全扫描（30+ 语言）| https://github.com/semgrep/semgrep | `install-system.sh` brew install |
| **open-code-review** | 阿里巴巴线级代码审查 | https://github.com/alibaba/open-code-review | `install-system.sh` npm install -g |
| **codebase-memory-mcp** | 代码知识图谱 | https://github.com/DeusData/codebase-memory-mcp | `install-codebase-memory.sh` GitHub Release |
| **mattpocock/skills** | 14 个工程 skill（to-prd、tdd 等）— **全部** | https://github.com/mattpocock/skills | `install-skills.sh` |
| **anthropics/skills** | 40+ skill 中用了其中 11 个（taste-skill、minimalist-ui、shadcn、api-design、e2e-testing、frontend-design、docx、xlsx、pdf、pptx）| https://github.com/anthropics/skills | `install-skills.sh` |
| **rohitg00/agentmemory** | 6 个 skill（agentmemory-mcp-tools、recall、remember 等）— **全部** | https://github.com/rohitg00/agentmemory | `install-skills.sh` |
| **dietrichgebert/ponytail** | 1 个 skill（ponytail）— **全部** | https://github.com/DietrichGebert/ponytail | `install-skills.sh` |
| **tanweai/pua** | 12 个 PUA 鞭策 skill（pua、p10、p7、p9、pro、yes、mama、ding 等）— **全部** | https://github.com/tanweai/pua | `install-skills.sh` 克隆仓库 + symlink |
| **KKKKhazix/khazix-skills** | hv-analysis 横纵分析法深度研究 skill | https://github.com/KKKKhazix/khazix-skills | `install-skills.sh` npx install |
| **nodnarbnitram/claude-code-extensions** | 多个 skill 中用了其中 1 个（tauri-v2）| https://github.com/nodnarbnitram/claude-code-extensions | `install-skills.sh` |
| **jeffallan/claude-skills** | 多个 skill 中用了其中 1 个（rust-engineer）| https://github.com/jeffallan/claude-skills | `install-skills.sh` |
| **martinholovsky/claude-skills-generator** | 多个 skill 中用了其中 1 个（sqlite-database-expert）| https://github.com/martinholovsky/claude-skills-generator | `install-skills.sh` |
| **timescale/pg-aiguide** | 多个 skill 中用了其中 1 个（postgres）| https://github.com/timescale/pg-aiguide | `install-skills.sh` |
| **vercel-labs/skills** | 多个 skill 中用了其中 1 个（find-skills）| https://github.com/vercel-labs/skills | `install-skills.sh` |
| **chrome-devtools-mcp** | 浏览器调试 | https://github.com/ChromeDevTools/chrome-devtools-mcp | `opencode.jsonc` MCP 配置，首次调用时 npx 自动装 |
| **markitdown-mcp** | 文件转 Markdown | https://github.com/microsoft/markitdown | `install-system.sh` pip 安装 |
| **server-sequential-thinking** | 结构化推理 — 取自 modelcontextprotocol/servers（50+ MCP 中用了 1 个）| https://github.com/modelcontextprotocol/servers | `opencode.jsonc` MCP 配置，npx 自动装 |
| **server-github** | GitHub API 操作 — 取自 modelcontextprotocol/servers（50+ MCP 中用了 1 个）| https://github.com/modelcontextprotocol/servers | `opencode.jsonc` MCP 配置，npx 自动装 |

### 语言覆盖

| 语言 | 工程 skill | 审查 | 安全扫描 |
|:----|:----------:|:----:|:--------:|
| TypeScript / JavaScript | ✅ /tdd + /implement | ✅ open-code-review | ✅ semgrep |
| Java | ✅ 管道通用 | ✅ open-code-review（阿里原生）| ✅ semgrep |
| Python | ✅ 管道通用 | ✅ open-code-review | ✅ semgrep |
| Go | ✅ 管道通用 | ✅ open-code-review | ✅ semgrep |
| Rust | ✅ rust-engineer | ✅ open-code-review | ✅ semgrep |
| 其他 | ✅ 管道通用 | ⚠️ open-code-review 部分支持 | ✅ semgrep

## 项目结构

```
my-opencode-stack/
├── environment-setup-guide.md   ← AI 可执行的复刻文档（新电脑交给 AI）
├── config/                       ← 全部配置文件（API Key 用占位符）
├── plugins/                      ← OpenCode 插件
├── scripts/                      ← 一键安装脚本
├── templates/                    ← trail 产物模板
├── docs/                         ← 说明文档
└── start-env.sh                  ← 日常启动
```

## 快速开始

```bash
git clone https://github.com/phper666/my-opencode-stack.git
cd my-opencode-stack
# 编辑 config/opencode.jsonc → 填入 ECHOBRAID_API_KEY + OPENCODE_GO_API_KEY
# 编辑 config/agentmemory.env → 填入 LLM_KEY
bash scripts/setup-all.sh
# 启动 OpenCode Desktop → opencode auth login → 开始使用
```

## License

MIT
