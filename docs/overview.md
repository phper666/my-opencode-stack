# my-opencode-stack 是什么

一套**开箱即用的 OpenCode 全栈开发环境**。装完后你得到的是一个 AI 开发团队，不是单个聊天窗口。

## 能力清单

装完 `my-opencode-stack` 后，你在 OpenCode 里拥有：

| 能力 | 由谁提供 | 数量 |
|:----|:---------|:----:|
| **专业 AI 角色** | 8 个 agent：orchestrator / oracle / designer / fixer / librarian / explorer / observer / council | 8 |
| **工程技能** | Matt Pocock skills（PRD → 实现 → 审查 → 回验） | 14 |
| **领域技能** | PostgreSQL / SQLite / Tauri / Rust / E2E 测试 / UI 设计系统 / REST API | 20+ |
| **长期记忆** | agentmemory（L0-L3，51 个 MCP 工具）| 1 |
| **代码理解** | codebase-memory-mcp（代码知识图谱 + 调用关系追踪）| 1 |
| **工具集成** | GitHub / 浏览器调试 / 文件转 Markdown / 结构化推理 | 4 MCP |
| **质量门禁** | open-code-review + semgrep + 自修复 lint | 3 |
| **开发流程** | 10 步管道（PRD → 知识回写 + 回溯回路 + DAG）| 1 |

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

## 技术栈

| 层 | 技术 |
|:---|:-----|
| Agent 框架 | OpenCode + oh-my-opencode-slim |
| 记忆系统 | agentmemory（SQLite + BM25 + 向量 + 知识图谱） |
| 代码理解 | codebase-memory-mcp |
| 模型 | deepseek-v4-flash / deepseek-v4-pro / MiMo-V2.5 / 开源模型（opencode.go） |
| 技能引擎 | mattpocock/skills + anthropics/skills |
| 代码审查 | open-code-review（阿里巴巴）|
| 安全扫描 | semgrep |
| Token 压缩 | rtk |
| 代码简化 | ponytail |

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
