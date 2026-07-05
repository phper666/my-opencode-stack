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

## 跟普通开发流程的区别

| 方面 | 普通方式 | 10 步管道 |
|:----|:--------|:----------|
| 需求 | 你在聊天框描述 | `/to-prd` 生成结构化 PRD |
| 设计 | 直接写代码 | `@designer` 先出设计规范 |
| 实现 | 你说"加个接口"AI 直接写 | TDD：先写测试 → 看到失败 → 写实现 → 重构 |
| 质量 | 靠你检查 | 自修复 lint + code review + semgrep 三道门 |
| 验收 | 你说"看起来可以" | `@oracle` 逐项核对 PRD checklist + 设计对照 |
| 知识沉淀 | 下次还得重说 | 步骤 10 写入 lessons，下次直接用 |
