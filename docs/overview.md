# my-opencode-stack 是什么

一套**开箱即用的 OpenCode 全栈开发环境**。装完后你得到的是一个 AI 开发团队，不是单个聊天窗口。

## 能力清单

装完 `my-opencode-stack` 后，你在 OpenCode 里拥有：

| 能力 | 由谁提供 | 数量 |
|:----|:---------|:----:|
| **专业 AI 角色** | 8 个 agent：orchestrator / oracle / designer / fixer / librarian / explorer / observer / council | 8 |
| **工程技能** | Matt Pocock skills（PRD → 实现 → 审查 → 回验） | 14 |
| **领域技能** | PostgreSQL / SQLite / Tauri / Rust / Playwright E2E / shadcn UI / REST API 设计 / 前端设计系统 | 20+ |
| **长期记忆** | agentmemory（L0-L3，51 个 MCP 工具）| 1 |
| **代码理解** | codebase-memory-mcp（代码知识图谱 + 调用关系追踪）| 1 |
| **工具集成** | GitHub / 浏览器调试 / 文件转 Markdown / 结构化推理 | 4 MCP |
| **质量门禁** | open-code-review + semgrep + 自修复 lint | 3 |
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

| 项目 | 用途 | 链接 | 必须 |
|:----|:-----|:----|:----:|
| **OpenCode** | AI 编码 IDE，本环境的基础 | https://github.com/opencode-ai/opencode | ✅ |
| **oh-my-opencode-slim** | 8 agent 编排插件，路由规则 + 模型分配 | https://github.com/code-yeongyu/oh-my-opencode-slim | ✅ |
| **agentmemory** | 长期记忆系统（51 个 MCP 工具，L0-L3 记忆管道）| https://www.npmjs.com/package/@agentmemory/agentmemory | ✅ |
| **mattpocock/skills** | 14 个工程 skill（/to-prd、/tdd、/implement 等）| https://github.com/mattpocock/skills | ✅ |
| **open-code-review** | 阿里巴巴线级代码审查工具 | https://github.com/alibaba/open-code-review | ✅ |
| **semgrep** | 多语言安全扫描（30+ 语言）| https://github.com/semgrep/semgrep | ✅ |
| **codebase-memory-mcp** | 代码知识图谱（调用关系追踪、架构分析）| https://github.com/DeusData/codebase-memory-mcp | ✅ |
| **rtk** | CLI 输出 token 压缩（60-90% 节省）| https://github.com/rtk-ai/rtk | ✅ |
| **ponytail** | OpenCode 插件，代码最小化原则 | https://github.com/DietrichGebert/ponytail | ✅ |
| **context-mode** | OpenCode 插件，上下文保护（ctx_* 工具）| https://github.com/mksglu/context-mode | ✅ |
| **opencode-token-monitor** | OpenCode 插件，token 用量监控 | https://www.npmjs.com/package/opencode-token-monitor | ✅ |
| **@xenova/transformers** | 本地向量嵌入（agentmemory 本地 embedding）| https://www.npmjs.com/package/@xenova/transformers | ✅ |
| **anthropics/skills** | 前端设计 skill（taste-skill、minimalist-ui）| https://github.com/anthropics/skills | ❌ 可选 |
| **chrome-devtools-mcp** | 浏览器调试 MCP | https://github.com/ChromeDevTools/chrome-devtools-mcp | ❌ 可选 |
| **markitdown-mcp** | 文件转 Markdown MCP | https://github.com/microsoft/markitdown | ❌ 可选 |
| **server-sequential-thinking** | 结构化推理 MCP | https://github.com/modelcontextprotocol/servers | ❌ 可选 |
| **server-github** | GitHub API 操作 MCP | https://github.com/modelcontextprotocol/servers | ❌ 可选 |
| **find-skills** | Vercel skill 发现工具 | https://github.com/vercel-labs/skills | ❌ 可选 |
| **api-design** | REST API 设计模式 skill | https://github.com/anthropics/skills | ❌ 可选 |
| **e2e-testing** | Playwright E2E 测试 skill | https://github.com/anthropics/skills | ❌ 可选 |
| **shadcn** | shadcn/ui 组件管理 skill | https://github.com/anthropics/skills | ❌ 可选 |
| **tauri-v2** | Tauri v2 跨平台桌面开发 skill | https://github.com/nodnarbnitram/claude-code-extensions | ❌ 可选 |
| **rust-engineer** | Rust 工程 skill（所有权、异步、错误处理）| https://github.com/jeffallan/claude-skills | ❌ 可选 |
| **sqlite-database-expert** | SQLite 数据库 skill | https://github.com/martinholovsky/claude-skills-generator | ❌ 可选 |
| **postgres** | PostgreSQL skill（TimescaleDB）| https://github.com/timescale/pg-aiguide | ❌ 可选 |
| **skill-creator** | 创建/编辑 OpenCode skill | https://github.com/anthropics/claude-plugins-official | ❌ 可选 |

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
