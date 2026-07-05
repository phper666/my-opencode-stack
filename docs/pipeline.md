# 10 步开发管道

`my-opencode-stack` 的核心是 10 步流水线 + 4 个横切机制。所有功能开发都走这个流程。

## 10 步

| # | 步骤 | 谁做 | 产出 |
|:-:|:----|:-----|:-----|
| 1 | **PRD** | `/to-prd + /grill-me` | `01-prd.md` + `plan.md`（含 DAG）|
| 2 | **设计** | `@designer` 按技术栈分流 | `02-design.md` |
| 3 | **架构审查** | `@oracle` | `03-architecture.md`（含 TDD 例外裁定）|
| 4 | **代码设计** | `@oracle + @fixer` | `04-code-design.md`（必含接口类型契约）|
| 5 | **实现** | `@fixer TDD` | 代码 + 测试 |
| 6 | **自修复** | `@fixer` lint + type-check | 无产物 |
| 7 | **Code Review** | `@fixer open-code-review` | `07-code-review.md` |
| 8 | **安全扫描** | `@fixer semgrep` | `08-security-scan.md` |
| 9 | **回验** | `@oracle` | `09-verification.md` + `STATE.md` |
| 10 | **知识回写** | `@oracle` | `docs/spec/lessons/` |

## 4 个横切机制

| 机制 | 说明 |
|:----|:------|
| **回溯回路** | 步骤 3/4/5 发现问题退回到引入级，每级 ≤2 次，全局 ≤6 次 |
| **子功能 DAG** | 子功能 ≥2 个时定义依赖图，按拓扑序执行，集成验证 |
| **会话断点恢复** | 读产物列表自动推断中断步，从断点继续 |
| **Token 成本控制** | 全流程 500K token 上限，超出提示确认 |
| **版本感知** | 自动检测当前分支，按版本隔离产物目录，跨版本 bug 自动 cherry-pick |

### 版本感知

管道自动适配分支上下文：

- `main` 分支 → 新功能开发，完整 10 步
- `release/v*` 分支 → 只修 bug，诊断 → 修复 → 验证 → cherry-pick 到新版本
- `feat/*` 分支 → 新功能开发，产物归到 main

跨版本 bug 修复时，orchestrator 自动：
1. 切到最老的受影响版本
2. 修复 + 验证
3. cherry-pick 到所有较新版本
4. 每个目标分支确认无回归

详见 `docs/trail/VERSIONING.md`

## 8 个 Agent 分工

| Agent | 角色 | 模型 | 什么时候出场 |
|-------|------|------|-------------|
| **orchestrator** | 项目经理/调度 | deepseek-v4-flash | 全程——发起、分配、收口 |
| **oracle** | 架构师/技术审查 | deepseek-v4-pro | 步骤 3/4/9，复杂决策 |
| **designer** | UI/UX 设计师 | deepseek-v4-pro | 步骤 2 |
| **fixer** | 开发工程师 | deepseek-v4-pro | 步骤 5/6/7/8 |
| **librarian** | 研究员 | deepseek-v4-flash | 查文档、搜方案 |
| **explorer** | 代码搜索员 | deepseek-v4-flash | 找代码、快速定位 |
| **observer** | 视觉分析师 | mimo-v2.5 | 看图/截图/PDF |
| **council** | 顾问团 | deepseek-v4-pro | 复杂决策多角度分析 |

## 实战样例

### 样例 1：从 0 到 1 做项目

**场景**：你想做一个新的小说创作工具，需求是"支持项目管理、AI 写作、导出"

```
你（一句话） → orchestrator 自动走流程

步骤 1 PRD:
  → /to-prd 生成 PRD → /to-issues 拆成 3 个子功能
  → plan.md 含 DAG：项目管理 ─→ AI 写作 ─→ 导出
  → 产出: docs/trail/changes/novel-tool/01-prd.md

步骤 2 设计:
  → @designer 检测到 Tauri 前端 → 出设计规范 + 组件树
  → 产出: 02-design.md

步骤 3 架构审查:
  → @oracle 审 PRD → 裁定 TDD 例外
  → 判定 LLM 写作那层可豁免，prompt 构建仍需测
  → 产出: 03-architecture.md

步骤 4 代码设计:
  → @oracle + @fixer → 产出 04-code-design.md
  → 必含接口类型契约（Tauri command ↔ invoke 映射）

步骤 5 实现（按 DAG 顺序）:
  → 子功能 1 项目管理: /tdd → /implement
  → 子功能 2 AI 写作: /tdd（prompt 构建有测试，LLM 调用豁免）→ /implement
  → 子功能 3 导出: /tdd → /implement

步骤 6 自修复:
  → cargo clippy --fix → agent 逐条修 → 验证
  → 编译 error → 退回步骤 5 修正

步骤 7 Code Review:
  → ocr review --audience agent → 修复 → 重审直到无新增

步骤 8 安全扫描:
  → semgrep --config=auto → 修 → 重扫

步骤 9 回验:
  → @oracle 逐项核对 PRD checklist
  → 对照 02-design.md 的组件映射表
  → 子功能集成验证
  → 产出: 09-verification.md + 更新 STATE.md

步骤 10 知识回写:
  → @oracle 写入 docs/spec/lessons/
  → 本次踩坑记录：Tauri IPC 类型同步、LLM 测试策略
```

### 样例 2：中途接手项目

**场景**：你接手一个同事写到一半的 Spring Boot + React 项目，没有用本流水线开发过

```
你： "接手这个项目，跑起来看看"

阶段 A — 基础设施（< 1 分钟）:
  → /setup-matt-pocock-skills
  → 生成 AGENTS.md
  → 创建 .opencode/rules/（risk-zones.md + release-checklist.md）

阶段 B — 逆向工程基线（< 3 分钟）:
  → @explorer 扫描项目结构、技术栈 → docs/spec/architecture.md
  → @explorer 扫描代码风格 → docs/spec/conventions.md
  → 提取核心术语 → docs/spec/glossary.md
  → 反向工程 API 边界 → docs/trail/BASELINE.md
  → 标记已发现的不一致项（Controller 参数命名不统一等）

阶段 C — 状态锚点（< 1 分钟）:
  → git log → CHANGELOG 草稿
  → 现有测试数、lint 状态 → STATE.md
  → 现有代码标记为 risk-zones 中的"已知/稳定"

阶段 D — 第一个功能迭代:
  → 选一个小功能（"修个 404 错误"）走完整 1→10 步
  → 验证管道能跑通
  → 之后所有新功能都走 10 步
```

---

## 跟普通开发流程的区别

| 方面 | 普通方式 | 10 步管道 |
|:----|:--------|:----------|
| 需求 | 你在聊天框描述 | `/to-prd` 生成结构化 PRD |
| 设计 | 直接写代码 | `@designer` 先出设计规范 |
| 实现 | 你说"加个接口"AI 直接写 | TDD：先写测试 → 看到失败 → 写实现 → 重构 |
| 质量 | 靠你检查 | 自修复 lint + code review + semgrep 三道门 |
| 验收 | 你说"看起来可以" | `@oracle` 逐项核对 PRD checklist + 设计对照 |
| 知识沉淀 | 下次还得重说 | 步骤 10 写入 lessons，下次直接用 |
