# my-opencode-stack 架构说明

> 面向人类读者的完整架构文档。读完你应该理解：
> 这个 stack 是什么、怎么拼的、数据怎么流、为什么这么设计。

---

## 1. 概述

my-opencode-stack 是一套 **OpenCode 全栈开发环境的一键复刻包**。它在原生 OpenCode 之上叠加了 8 个专业 AI agent、一套工程开发流水线、长期记忆系统和代码质量门禁。

### 设计目标

| 目标 | 说明 |
|:----|:-----|
| **即装即用** | 新电脑上一条命令装完，立即获得完整 AI 开发环境 |
| **工程纪律** | AI 写代码前先写 PRD、先设计、先写测试——不是自由对话 |
| **质量管理** | 三道门禁：自修复 lint → code review → 安全扫描 |
| **知识沉淀** | 跨会话长期记忆 + lessons 学习，不重复踩坑 |
| **版本感知** | 多版本分支策略，bug 自动 cherry-pick |

### 和原生 OpenCode 的区别

| 维度 | 原生 OpenCode | my-opencode-stack |
|:----|:-------------|:------------------|
| 角色数 | 1-2 个通用 agent | 8 个专业 agent |
| 开发流程 | 无规范 | 10 步管道（PRD→设计→实现→审查→回验） |
| 质量控制 | 靠提示词临场发挥 | lint(3轮) + ocr review + semgrep + 回验 |
| 记忆 | 当前会话 | agentmemory 长期记忆，跨会话 |
| 代码理解 | 无 | codebase-memory-mcp 知识图谱 |
| 工程纪律 | 无 | TDD 强制 + 回溯回路 + DAG 依赖图 |

---

## 2. 分层架构

```
┌──────────────────────────────────────────────────────────────┐
│                    10 步开发流水线                           │
│  PRD → 设计 → 架构 → 代码设计 → TDD实现 → lint → review │
│  → semgrep → 回验 → 知识回写                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  横切机制：回溯回路 / DAG / 断点恢复 / Token控制 / 输出压缩│   │
│  └──────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────┤
│                    质量门禁层                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │自修复lint│  │code review│  │ semgrep  │  │ PRD回验  │   │
│  │(3轮fix)  │  │(ocr+pony) │  │安全扫描  │  │逐项核对  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
├──────────────────────────────────────────────────────────────┤
│                    输出压缩层                                  │
│  ┌──────────────┐  ┌─────────────────────┐                  │
│  │  caveman     │  │  ponytail           │                  │
│  │  语言精简    │  │  代码最小化          │                  │
│  │  省~54% token│  │  YAGNI / stdlib优先  │                  │
│  └──────────────┘  └─────────────────────┘                  │
├──────────────────────────────────────────────────────────────┤
│                    Agent 调度层                               │
│  oh-my-opencode-slim 插件                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │orchestr. │ │  oracle  │ │ designer │ │  fixer   │       │
│  │(flash)   │ │  (pro)   │ │  (pro)   │ │  (pro)   │       │
│  ├──────────┤ ├──────────┤ ├──────────┤ ├──────────┤       │
│  │librarian │ │ explorer │ │ observer │ │ council  │       │
│  │(flash)   │ │ (flash)  │ │ (mimo)   │ │  (pro)   │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
├──────────────────────────────────────────────────────────────┤
│                    技能层 (Skills)                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Matt Pocock (14)           │ anthropics (11)         │   │
│  │  to-prd / tdd / implement  │  shadcn / api-design   │   │
│  │  diagnosing-bugs / ...     │  e2e-testing / ...     │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ JuliusBrussee (1)          │ 领域专项 (5)            │   │
│  │  caveman                   │  tauri-v2 / rust       │   │
│  │                            │  postgres / sqlite     │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ agentmemory (6)            │ PUA鞭策 (12)            │   │
│  │  recall / remember / ...   │  pua / p10 / p7 / ...  │   │
│  └──────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────┤
│                    MCP 服务层                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │codebase- │ │chrome-   │ │sequential│ │  github  │       │
│  │memory-mcp│ │devtools  │ │thinking  │ │   MCP    │       │
│  ├──────────┤ ├──────────┤ ├──────────┤ ├──────────┤       │
│  │agent-    │ │markitdown│ │          │ │          │       │
│  │memory MCP│ │   MCP    │ │          │ │          │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
├──────────────────────────────────────────────────────────────┤
│                    插件层                                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐    │
│  │ oh-my-       │ │ context-mode │ │ token-monitor    │    │
│  │ opencode-slim│ │ (ctx_* 工具) │ │ (用量监控)       │    │
│  └──────────────┘ └──────────────┘ └──────────────────┘    │
│  ┌──────────────┐ ┌──────────────┐                          │
│  │    rtk       │ │ ponytail     │                          │
│  │ (CLI 压缩)   │ │ (代码最小化) │                          │
│  └──────────────┘ └──────────────┘                          │
├──────────────────────────────────────────────────────────────┤
│                    OpenCode 核心                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  1 个 Provider: OpenCode Go                        │   │
│  │  3 个模型族: deepseek-v4 / mimo / qwen / kimi / glm  │   │
│  │  LSP / Shell / Permission 系统                        │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. 组件详解

### 3.1 OpenCode 核心（IDE 基础）

| 配置 | 值 | 说明 |
|:----|:---|:-----|
| provider | opencode-go + opencode-go-anthropic + opencode-free | 3 个模型提供商 |
| 模型 | deepseek-v4-flash/pro, mimo-v2.5, qwen3.x, kimi-k2.x, glm-5.x 等 | 17 个模型 |
| permission | allow | 自动允许所有操作 |
| server port | 4096 | HTTP API |
| LSP | enabled | 语言服务器协议 |
| plugins | omo-slim, context-mode, token-monitor, ponytail | 4 个核心插件 |

### 3.2 插件层

| 插件 | 来源 | 作用 |
|:----|:----|:-----|
| **oh-my-opencode-slim** | [code-yeongyu/oh-my-opencode-slim](https://github.com/code-yeongyu/oh-my-opencode-slim) | 8 agent 编排系统：路由、子 agent 调度、system prompt 管理 |
| **context-mode** | [mksglu/context-mode](https://github.com/mksglu/context-mode) | 上下文保护：ctx_search/ctx_index/ctx_execute，自动记录 + 检索 |
| **opencode-token-monitor** | npm | token 用量监控和统计 |
| **ponytail** | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | 代码最小化：YAGNI、stdlib 优先、最短路径 |
| **agentmemory-capture** | 自研 (js/ts) | 自动捕获所有会话事件到 agentmemory |
| **rtk** | [rtk-ai/rtk](https://github.com/rtk-ai/rtk) | CLI 输出压缩，减少 token 消耗 |

### 3.3 Agent 层（8 个专业角色）

| Agent | 模型 | 技能数 | 分配 MCP | 角色 |
|:------|:----|:------:|:---------|:----|
| **orchestrator** | deepseek-v4-flash | 全部 | 所有（除 context7） | 项目经理：调度、分配、收口 |
| **oracle** | deepseek-v4-pro | 9 | markitdown, sequential-thinking | 架构师：决策、审查、回验 |
| **designer** | deepseek-v4-pro | 5 | 无 | UI/UX 设计师：组件、布局、样式 |
| **fixer** | deepseek-v4-pro | 10 | chrome, thinking, github | 开发工程师：实现、TDD、测试 |
| **librarian** | deepseek-v4-flash | 0 | websearch, context7, gh_grep, markitdown, github | 研究员：查文档、搜方案 |
| **explorer** | deepseek-v4-flash | 0 | 无 | 代码搜索员：快速定位 |
| **observer** | mimo-v2.5 | 0 | 无 | 视觉分析：看图/截图/PDF |
| **council** | deepseek-v4-pro | 0 | 无 | 顾问团：多角度决策分析 |

### 3.4 技能层（Skills）

**来源与数量**：

| 来源 | 数量 | 核心内容 |
|:----|:---:|:---------|
| mattpocock/skills | 14 | to-prd, to-issues, implement, tdd, diagnosing-bugs, codebase-design, domain-modeling, grill-with-docs, prototype, ask-matt, triage, improve-architecture, resolving-merge-conflicts, grill-me |
| anthropics/skills | 11 | frontend-design, skill-creator, api-design, e2e-testing, shadcn, taste-skill, minimalist-ui, docx, xlsx, pdf, pptx |
| JuliusBrussee/skills | 1 | caveman（输出压缩） |
| rohitg00/agentmemory | 6 | recall, remember, forget, agentmemory-mcp-tools 等 |
| obra/superpowers | 1 | brainstorming（需求探索 - 魔改版） |
| tanweai/pua | 12 | pua / p10 / p7 / p9 / pro / yes / mama / ding 等鞭策 skill |
| 其他（tauri/rust/postgres/SQLite/find-skills/hv-analysis） | 5 | 领域专项技能 |

### 3.5 MCP 服务层

| 服务 | 类型 | 端口 | 用途 |
|:----|:----|:---:|:-----|
| codebase-memory-mcp | 本地二进制 | 9749 | 代码知识图谱（函数调用关系、架构分析） |
| agentmemory | npm 全局 | 3111 (REST) / 3113 (Viewer) | 长期记忆（51 个 MCP 工具） |
| chrome-devtools | npx | 动态 | 浏览器调试 |
| markitdown | pip | 动态 | 文件转 Markdown |
| sequential-thinking | npx | 动态 | 结构化推理 |
| github | npx | 动态 | GitHub API 操作 |

### 3.6 脚本层

| 脚本 | 功能 |
|:----|:-----|
| `setup-all.sh` | 一键安装全部组件 |
| `install-system.sh` | brew + npm + pip 系统依赖 |
| `install-codebase-memory.sh` | 下载 codebase-memory-mcp 二进制 |
| `install-skills.sh` | 批量安装所有 skills |
| `install-config.sh` | 复制配置文件到正确位置 |
| `install-docker.sh` | Docker 验证 |
| `uninstall.sh` | 基于 manifest 的完整卸载 |
| `start-env.sh` | 日常启动（agentmemory 等） |
| `lib/manifest.sh` | 安装记录 JSONL 读写 |

---

## 4. 数据流

### 4.1 开发流程数据流

```
你: "我要做个小说创作工具"
  ↓
[orchestrator] 收到请求
  ↓ 按 orchestrator_append.md 路由规则判断
  ├─ 模糊新需求 → brainstorming → grill-me → to-prd → to-issues
  ├─ 明确小任务 → 直接 @fixer
  ├─ bug 排查 → @fixer + diagnosing-bugs
  └─ 架构改进 → @fixer + codebase-design
  ↓
[10 步管道] 依次调度
  步骤 1: brainstorming → /grill-me → /to-prd    产出: 01-prd.md
  步骤 2: @designer                              产出: 02-design.md
  步骤 3: @oracle                                产出: 03-architecture.md
  步骤 4: @oracle + @fixer                       产出: 04-code-design.md
  步骤 5: @fixer (tdd → implement)               产出: 代码 + 测试
  步骤 6: @fixer (lint --fix)                     产出: 无
  步骤 7: @fixer (ocr review + ponytail-review)   产出: 07-code-review.md
  步骤 8: @fixer (semgrep)                        产出: 08-security-scan.md
  步骤 9: @oracle (回验)                          产出: 09-verification.md
  步骤 10: @oracle (lessons)                      产出: lessons/*.md
```

### 4.2 Agent 间的协作模式

```
orchestrator
  │
  ├─ 调度 agent 执行子任务（spawn subagent）
  │   ├─ @explorer   → 代码检索、文件定位
  │   ├─ @librarian  → 查文档、搜方案
  │   ├─ @observer   → 看图/截图/PDF 分析
  │   ├─ @designer   → UI/UX 设计
  │   ├─ @fixer      → 实现、修复、审查
  │   └─ @oracle     → 架构决策、审查、回验
  │
  ├─ 复杂决策 -> @council（多角度分析）
  │
  └─ 所有 agent 均可通过 agentmemory MCP
      读取/写入跨会话记忆
```

### 4.3 记忆系统数据流

```
agentmemory 运行流程:
  会话开始 → POST /session/start（创建记忆空间）
     ↓
  agentmemory-capture 插件自动捕获:
    ├─ 用户 prompt
    ├─ AI 回复（token 用量、模型）
    ├─ 文件编辑
    ├─ 工具调用
    ├─ subtask 启动/完成
    └─ session 状态变更
     ↓
  会话中 → agent 用 MCP 工具查询记忆
    ├─ memory_recall → 搜索过去观察
    ├─ memory_save  → 存重要决策
    ├─ memory_lesson_save → 存经验教训
    └─ memory_file_history → 查文件历史
     ↓
  会话结束 → POST /session/end → 自动 consolidation
              ↓
        长期记忆（L0-L3 四级管线）
```

---

## 5. 输出压缩架构

### 5.1 双层压缩模型

```
用户输入 → prompt-master（可选输入精炼）
               ↓
           AI 处理
               ↓
           ┌──────────────────┐
           │ 输出语言：caveman  │ ← 去 filler、碎片化、技术精度保留
           │ 输出代码：ponytail │ ← YAGNI、stdlib 优先、最短路径
           └──────────────────┘
               ↓
           返回用户
```

### 5.2 阶段控制

| 管道步骤 | caveman | ponytail | 理由 |
|:--------:|:-------:|:--------:|:----|
| PRD / 设计 / 架构 / 代码设计 | 关闭 | ✅ | 需要完整表达 |
| 实现 (Step 5) | lite | ✅ | 精简语言加速实现 |
| lint / semgrep | 关闭 | ✅ | 工具输出非自然语言 |
| Code Review (Step 7) | lite | ✅ | 保留因果链 |
| 回验 / 知识回写 | 关闭 | ✅ | 需要完整核对 |

安全机制：
- **auto-clarity**：安全警告、不可逆操作自动恢复完整表达
- **stop caveman**：用户随时可以手动关闭
- **wenyan 模式**：per-session opt-in，不参与自动调度

---

## 6. 安装架构

### 6.1 磁盘布局

安装后，以下是文件分布：

```
~/.config/opencode/                     ← OpenCode 配置根目录
  ├── opencode.jsonc                     ← 主配置（providers/plugins/MCP/agents）
  ├── oh-my-opencode-slim.json          ← agent 编排配置（模型/技能/MCP 分配）
  ├── oh-my-opencode-slim/
  │   └── orchestrator_append.md        ← orchestrator 指令（路由 + 流程）
  ├── plugins/
  │   ├── rtk.js                        ← RTK 命令压缩插件
  │   ├── agentmemory-capture.js        ← 记忆自动捕获插件
  │   ├── agentmemory-capture.ts        ← TS 源码
  │   └── package.json                  ← 插件 npm 依赖
  ├── trail-templates/                  ← trail 产物模板
  │   ├── 02-design-template.md
  │   ├── adr-template.md
  │   └── STATE.md
  └── skills/                           ← 所有安装的 skills
       ├── to-prd/                       (mattpocock)
       ├── tdd/                          (mattpocock)
       ├── implement/                    (mattpocock)
       ├── caveman/                      (JuliusBrussee)
       ├── brainstorming/                (obra/superpowers - 魔改版)
       ├── pua/                          (tanweai - symlink)
       ├── recall/                       (rohitg00/agentmemory)
       └── ... (~40+ 个)

~/.agentmemory/                         ← agentmemory 数据
  ├── .env                              ← 环境变量（LLM Key）
  ├── stdout.log                        ← agentmemory 日志
  └── stderr.log

~/.local/bin/                           ← 本地二进制
  └── codebase-memory-mcp               ← 代码知识图谱

~/Library/LaunchAgents/                 ← 开机自启
  └── com.agentmemory.plist             ← agentmemory launchd 配置

~/.opencodereview/                      ← open-code-review 配置
  └── config.json
```

### 6.1.1 可选工具

| 工具 | 安装方式 | 用途 |
|:----|:--------|:-----|
| **CodexBar** | `brew install codexbar` | macOS 菜单栏 AI 用量监控（OpenCode Go / MiMo / DeepSeek / MiniMax 等 20+ 提供商）|

### 6.2 安装流

```
setup-all.sh
  │
  ├─ 1/6 install-system.sh
  │   ├─ brew install (node/docker/git/curl/rtk/semgrep)
  │   ├─ npm install -g (@agentmemory/agentmemory / open-code-review / transformers)
  │   └─ pip3 install (markitdown-mcp)
  │
  ├─ 2/6 install-codebase-memory.sh
  │   └─ curl 下载二进制到 ~/.local/bin/
  │
  ├─ 3/6 install-skills.sh
  │   ├─ mattpocock/skills (14)
  │   ├─ JuliusBrussee/skills (1: caveman)
  │   ├─ anthropics/skills (11)
  │   ├─ rohitg00/agentmemory (6)
  │   ├─ obra/superpowers (1: brainstorming - 魔改版)
  │   ├─ tanweai/pua (12 - symlink)
  │   ├─ vercel/skills / timescale / nodnarbnitram / jeffallan / martinholovsky / KKKKhazix (6)
  │   └─ 验证: ls skills/ | wc -l ≥ 40
  │
  ├─ 4/6 install-config.sh
  │   ├─ 复制 opencode.jsonc / oh-my-opencode-slim.json / orchestrator_append.md
  │   ├─ 复制 opencodereview-config.json
  │   ├─ 复制 agentmemory.env / agentmemory.plist
  │   ├─ 复制 plugins / trail-templates
  │   ├─ 复制 start-env.sh
  │   └─ npm install @opencode-ai/plugin context-mode (插件依赖)
  │
  ├─ 5/6 install-docker.sh
  │   └─ docker info（验证）
  │
  └─ 6/6 start-env.sh
      └─ 启动 agentmemory

  安装记录 → ~/.opencode-stack/manifest.jsonl（用于卸载）
```

---

## 7. 端口与服务

| 端口 | 服务 | 启动方式 |
|:---:|:----|:--------|
| 4096 | OpenCode HTTP API | opencode 自带 |
| 3111 | agentmemory REST API | launchd 开机自启 |
| 3113 | agentmemory Viewer | 随 agentmemory 启动 |
| 9749 | codebase-memory-mcp | opencode MCP 自动管理 |
| 80/443 | Nginx 反向代理（可选） | 手动启动 |
| 3306 | MySQL（可选） | 项目自行管理 |
| 6379 | Redis（可选） | 项目自行管理 |
| 8080 | TaskBoard（可选） | 项目自行管理 |

---

## 8. 质量门禁系统

```
实现完成（步骤 5）
  ↓
┌─────────────────────────────────────────────────────┐
│ 步骤 6: 自修复 lint（轮次按风险等级）                │
│  tsc / eslint / clippy / cargo check / ruff 等      │
│  🔴 高风险：≤3 轮  🟡 中风险：≤2 轮  🟢 低风险：≤1 轮│
│  编译 error → 退回步骤 5                            │
└─────────────────────┬───────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 步骤 7: Code Review（轮次/视觉审计按风险等级）        │
│  ① ocr review（正确性）                             │
│   🔴 修 high/medium，≤3 轮  🟡 ≤2 轮  🟢 只修 high  │
│  ② 视觉审计（UI 项目，按风险触发）                   │
│   🟢 低风险 UI 跳过                                  │
│   🟡 @designer 代码级设计审计（token/组件/响应式）   │
│   🔴 追加 @observer 截图对比（chrome-devtools）      │
│  ③ ponytail-review（过度设计）→ 所有等级            │
│  超限 → @oracle 裁定                                │
└─────────────────────┬───────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 步骤 8: 安全扫描 semgrep（轮次按风险等级）            │
│  🔴 高风险：≤3 轮  🟡 中风险：≤2 轮  🟢 低风险：≤1 轮│
│  SQL注入 / XSS / 硬编码密钥                          │
└─────────────────────┬───────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 步骤 9: PRD 回验（所有等级 ≤3 轮）                   │
│  @oracle 逐项核对 PRD + TDD合规 + 设计对照          │
└─────────────────────┬───────────────────────────────┘
                      ↓
                   ✅ 可合并
```

### 8.1 风险分级路由（快慢道）

管道按风险等级分流，不同等级走不同长度：

| 等级 | 流程长度 | 适用场景 |
|:----|:--------|:--------|
| 🔴 **高风险** | 完整 10 步（PRD→设计→架构→代码设计→TDD→lint→review→semgrep→回验→lessons） | 改DB/auth/IPC/加密/3+模块 |
| 🟡 **中风险** | 精简 5 步（PRD→TDD→lint→review→回验） | 新增业务逻辑/API/UI |
| 🟢 **低风险** | 直通 2 步（@fixer → lint+semgrep + 一句话确认） | 文案/颜色/布局/配置 |

### 8.2 批量调度

同时开发 ≥5 个独立小功能时启用批量模式：
- 依赖分析（基于文件路径交集）
- 按批次并行（@fixer × 3 默认）
- 每批完成后 git merge + 自动冲突解决
- 冲突 >5 文件 → 降级串行
- 全量集成验证在最终批完成后执行

---

## 9. 关键设计决策

| 决策 | 选择 | 理由 |
|:----|:----|:-----|
| Agent 模型分配 | oracle/designer/fixer 用 pro，orchestrator/librarian/explorer 用 flash | 昂贵模型给推理密集型任务，廉价模型给调度/检索 |
| TDD 强制（8 条例外） | 非平凡逻辑先写测试 | 减少回归，保证可测试性 |
| 回溯回路 ≤6 次 | 全局限制，超限 @oracle 裁定 | 防止无限循环消耗 token |
| caveman 默认 lite | 安全第一 | 中文压缩效果已验证，lite 保留完整语义 |
| wenyan 模式禁用 | per-session opt-in | 文言文输出不适合工程场景 |
| agentmemory 本地运行 | 不依赖云服务 | 隐私 + 离线可用 |
| manifest + uninstall | 安装记录 JSONL | 可完整卸载，无残留 |

---

## 10. 术语表

| 术语 | 说明 |
|:----|:-----|
| **OpenCode** | AI 编码 IDE，本环境的基础 |
| **oh-my-opencode-slim (OMO)** | agent 编排插件，管理 8 个子 agent 的模型/技能/MCP 分配 |
| **orchestrator** | 主 agent，负责任务调度和流程控制 |
| **oracle** | 架构师 agent，负责决策、审查、回验 |
| **designer** | UI/UX 设计师 agent |
| **fixer** | 开发工程师 agent，负责实现、TDD、测试 |
| **pipeline** | 10 步开发流水线（PRD → 知识回写） |
| **trail** | 开发过程的产物目录（docs/trail/） |
| **TDD** | 测试驱动开发，先写测试再写实现 |
| **DAG** | 有向无环图，用于子功能依赖关系 |
| **retry loop** | 回溯回路，发现问题退回问题引入级修改 |
| **caveman** | 输出语言压缩 skill，去 filler 保留技术精度 |
| **ponytail** | 代码最小化原则，YAGNI、stdlib 优先 |
| **semgrep** | 多语言静态安全扫描工具 |
| **agentmemory** | 长期记忆系统（L0-L3 四级管线） |
| **codebase-memory-mcp** | 代码知识图谱（函数调用关系、架构分析） |
| **MCP** | Model Context Protocol，AI 与外部服务的通信协议 |
| **manifest** | 安装记录（~/.opencode-stack/manifest.jsonl），用于卸载 |
| **release-checklist** | 发布检查清单（.opencode/rules/） |
| **risk-zones** | 风险分区（.opencode/rules/），指导哪些文件需谨慎修改 |
| **ocr** | open-code-review，阿里巴巴线级代码审查工具 |
| **rtk** | CLI 输出压缩工具，减少进入 LLM 的噪声 |

---

> **文档版本**: v1.0  
> **最后更新**: 2026-07-06  
> **参考文件**: `docs/pipeline.md` | `docs/overview.md` | `config/orchestrator_append.md` | `config/oh-my-opencode-slim.json`
