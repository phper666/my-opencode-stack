## Matt Pocock 集成

按需求类型自动选 skill 和路由：

### 模糊新需求
"我想要 X"、"加个 Y 功能"、"做个 Z 特性"、"需求不太清晰"
→ 加载 Superpowers brainstorming skill
  → 探索上下文 → 提问澄清 → 提 2-3 方案 → 逐节展示设计 → 写 design doc
  → 如果需求过大，自动拆为多个子功能，各产独立 design.md
→ 加载 grill-me skill 拷打设计决策
  → 逐分支追问 → 如有问题修改 design.md → 确认
→ orchestrator 读 design.md 作上下文
→ 自动调 `/to-prd` 合成 PRD
→ 自动调 `/to-issues` 拆成独立任务（含 DAG 依赖图，产物 → `docs/trail/changes/<feature>/plan.md`）
→ 正常走 10 步管道

### 大需求分解（领域归属判断 + 依赖图）
当需求涉及支付、订单、用户等已有领域时，在步骤 1 之前先判断：
→ 读 `docs/spec/domains/` 下是否有对应领域目录
→ 如果有，先读领域模型（model.md）和演进路线（README.md），作为 PRD 上下文

子功能拆分规则：
→ 子功能 ≥4 个时，changes 下按域嵌套：`changes/<domain>/<sub-feature>/`
→ 子功能 ≤3 个时，保持平级，用 `<domain>-<sub-feature>` 命名

**依赖图（DAG）** — 仅当子功能 ≥2 个时强制：
→ /to-issues 拆解任务时产出，作为 `plan.md` 的必填字段
→ 格式：有向无环图，`A → B` 表示 B 依赖 A
→ orchestrator 按拓扑序调度子功能

**集成验证**：
→ DAG 所有叶子节点走完 1→10 步后，orchestrator 额外调度一次集成验证
→ 内容：跨子功能的接口集成测试
→ 失败处理：退回依赖图，重新评估子功能边界或依赖关系

### 明确的小任务
"修个 bug"、"改个样式"、"加个字段"
→ **先检测是否含版本关键词（v1/v2/release/）→ 如有，优先走跨版本路由**
→ 直接派 @fixer，不走 spec 流程
→ 修复后自动跑 lint + semgrep
→ 修复记录 → `docs/trail/fixes/<date>-<slug>.md`

### Bug 排查
"找不到原因"、"难复现"、"调了一小时没头绪"
→ 派 @fixer + 加载 `/diagnosing-bugs`
→ 走六步循环：复现→最小化→假设→仪器→修复→回归测试
→ 修复后先跑 semgrep → 有报错退回修复，直到清洁
→ 再跑回归测试 → 全绿通过
→ 修复记录 → `docs/trail/fixes/<date>-<slug>.md`（含诊断过程）

### 架构改进
"重构"、"提升质量"、"这模块太烂"
→ 派 @fixer + 加载 `/codebase-design`
→ 深度模块化思路：找接缝、做适配器、加测试
→ 重构后跑现有测试 → 必须全绿
→ 跑 lint + semgrep
→ 产出 `refactor-summary.md` 记录改动和原因
→ 写入 `docs/spec/lessons/`（架构决策、踩坑记录）

### TDD 实现（强制）
"用测试驱动"、"先写测试"、"TDD"
→ 加载 `/tdd`
→ red-green-refactor 循环
→ **所有非平凡逻辑（分支、循环、解析器、资金/安全路径）必须走 TDD，不得跳过**

### 卡片拆解
PRD/plan 已存在
→ 加载 `/implement`
→ 按依赖顺序逐个实现

### 卡壳 / 反复失败
"卡壳了"、"又错了"、"为什么还不行"、"try harder"、"别摆烂"
→ 前 2 次失败 → 正常重试
→ 第 3+ 次失败或用户不耐烦 → pua skill 自动触发
  → 加载方法论路由 → 选味道（阿里/字节/华为等）
  → 输出压力 Banner + KPI 面板 + 强制动作清单
  → 穷尽所有方案后再放弃

### 卡壳不知道下一步
→ 加载 `/ask-matt`
→ 它告诉你用谁

### 领域建模
"打磨术语"、"定义 glossary"、"更新 CONTEXT.md"
→ 加载 `/domain-modeling`

### 对照审查
review 设计/PRD/方案
→ 加载 `/grill-with-docs`
→ 对照领域模型逐项拷问

### 规则
- 不要先问用户「要不要走 spec 流程」——按上面规则自动判断
- User-invoked skill（`/to-prd` `/to-issues` `/setup-matt-pocock-skills`）由用户主动调或按规则自动调
- Model-invoked skill（`/tdd` `/diagnosing-bugs` 等）由 agent 看 description 自行加载

### 验收测试生成
PRD 审查通过后 → @oracle 从 PRD 提取所有需求项 → 生成验收 checklist → 写入 .mattpocock/prds/<id>-acceptance-checklist.md

### Code Review（open-code-review + ponytail-review）
@fixer 实现完成后 → 分两步走：

**① 正确性审查：** `ocr review --audience agent`
→ 高/中优先级问题让 @fixer 修复 → 重新审查，直到无新增问题

**② 过度设计审查：** ponytail-review
→ 列出可简化项（stdlib 替代、多余抽象、未用依赖等）
→ 追加到 `07-code-review.md`「简化建议」节
→ @oracle 逐条裁定采纳/拒绝

### 自修复 Lint + Type-check（零 token 成本）
@fixer 实现 + TDD 完成后 → 自动跑 lint + type-check：
- 检测项目类型，自动选对应工具（tsc、ESLint、Biome、cargo check、ruff 等）
- **自修复模式**：遇到错误自动修复 → 最多 3 轮迭代
  - 第 1 轮：自动修复（工具自带的 `--fix` / `--write` 等）
  - 第 2 轮：agent 逐条修复剩余错误
  - 第 3 轮：验证所有检查通过
- 3 轮后仍有错 → 列出剩余问题，进入步骤 7（code review 时会评估是否致命）
- 不跑 test（步骤 5 TDD 已保证测试覆盖）
- 如果项目没有对应的工具链，跳过并注明

### Semgrep 安全扫描
Code review 通过后 → 在项目目录执行 `semgrep --config=auto .` 扫描
→ 有报错就让 @fixer 修复并重扫，直到无报错

### PRD 回验
Semgrep 通过后 → @oracle 回验 PRD：
- 读取 PRD 的完整需求清单 + 验收 checklist + 代码变更
- 逐项核实每个需求是否被实现、有没有多余的未规划功能
- 输出验收报告：✅已实现 / ⚠️部分实现 / ❌未实现 / 🔴和 PRD 不一致 / ⚪多余功能 / ⚠️缺少测试
- **TDD 合规检查**：检查代码变更中是否包含对应的测试文件
  - 如果变更未包含测试文件，检查是否属于 TDD 跳过例外
  - 如果是例外 → 正常通过
  - 如果不是例外且没有测试文件 → 标记为 **⚠️ 缺少测试**，退回步骤 5 补测试
- 有缺口 → @fixer 修正 → 重新回验

### 知识回写（Knowledge Write-back）
回验通过后 → @oracle 把本次的架构决策和经验教训写入 `docs/spec/lessons/`：
- 写入内容：本次变更涉及的架构决策、踩坑记录、最佳实践
- 命名规范：`<日期>-<功能名>.md`
- 仅写入**可复用的知识**，不记操作流水账
- 不写的内容：纯 UI 样式调整、常规 CRUD、配置变更（无长期价值）
- 旧 lessons 由 @fixer 在每次回验后自动检查是否过期（>90 天），过期则标注 `archived`

### 全链路触发规则
当用户描述一个新功能需求时，Orchestrator 自动按以下顺序执行：

1. **需求探索+PRD** → brainstorming → /grill-me → /to-prd

2. **设计** → 按项目技术栈分流：
   - 有 UI 层（React/Vue/Svelte/Tauri 前端等）→ `@designer /prototype`
   - 纯后端/CLI/库 → `@designer` 输出设计规范 + 组件树 + 交互说明
   - 无法判断 → `@oracle` 裁定

3. **架构审查** → `@oracle`：
   - 先验 PRD 完整性（所有章节非空、无 TBD/待定）
   - `grill-with-docs + domain-modeling`（对照审查 + 领域建模）
   - **领域归属判断**：检查本功能是否属于已有领域
     · 如果是 → 读 `docs/spec/domains/<domain>/model.md`，继承共享领域模型
     · 如果新增/修改了共享实体 → 回写到 `model.md`
     · `03-architecture.md` 只写本功能特有的设计决策，共享模型用引用
   - **TDD 例外裁定**：决定本功能哪些模块可跳过 TDD，写入 `03-architecture.md`
   - 如果本功能涉及 3+ 子领域或工作量跨版本 → 拆分为多个 feature 目录
   - **产出**：`03-architecture.md`（架构决策 + 领域归属 + TDD 例外范围）

4. **代码设计** → `@oracle + @fixer /codebase-design`：
   - 产出 `04-code-design.md`
   - **必含章节「接口类型契约」**：
     · Tauri 项目：`#[tauri::command]` 签名 ↔ `invoke()` 调用的类型映射
     · REST API 项目：DTO ↔ 前端 API 函数类型映射
     · gRPC 项目：proto ↔ 实现类型映射
     · 无跨边界通信的单体项目：标记 N/A 跳过
   - 本步骤不涉及「该不该用 X」——那是步骤 3 的事

5. **实现** → `@fixer`（TDD 强制，有例外）：
   - 先尝试 `/tdd`（RED：先写测试 → 看测试失败）
   - 再 `/implement`（GREEN：写最小实现 → 测试通过 → REFACTOR）
   - **开工前**：@fixer 先扫一眼步骤 4 的「接口类型契约」，核实一致性
   - **非平凡逻辑默认必须走 TDD，先写测试再写实现**
   - 可跳过 TDD 的例外（需 @oracle 在步骤 3 裁定并写入 `03-architecture.md`）：
     · 纯 UI/样式改动（无业务逻辑）
     · 快速原型/实验性代码
     · 数据库 migration / 纯配置变更
     · 项目尚无测试框架时
     · **LLM 非确定性输出封装**（仅豁免调用 LLM 的那一层；prompt 构建/参数校验/结果解析仍要测）
     · **框架胶水代码**（纯委托/转发，无分支/循环/异常处理）
     · **自动生成的代码**（protobuf/OpenAPI gen 等）
     · **一次性迁移脚本**

6. **自修复 lint + type-check** → `@fixer`：
   - 检测项目类型，自动选对应工具（tsc、ESLint、Biome、cargo check、ruff 等）
   - **分叉路径**：
     · `clean` → 继续
     · **仅 lint warning** → 3 轮自修复：
       第 1 轮：工具自动修复（`cargo clippy --fix` / `eslint --fix` 等）
       第 2 轮：agent 逐条修剩余
       第 3 轮：验证
       — 3 轮后仍有 trivial warning（如改 40 文件的类型声明）→ 可标记 `#[allow]/eslint-disable` + 记录，放行
     · **编译 error** → 直接退回步骤 5（不浪费 3 轮自修复配额）
   - **退回配额规则**：步骤 5→6→5 退回时，清空 lint 3 轮配额，重新计数
   - **退回 ≥2 次**（同一类问题）→ @oracle 介入
   - 不跑 test（步骤 5 TDD 已覆盖）

7. **Code Review** → `@fixer` 分两步：
   - ① `ocr review --audience agent`（正确性）→ 修 high/medium → 重审干净
   - ② ponytail-review（过度设计）→ 列简化清单 → 追加到 `07-code-review.md`
   — 核对接口类型契约与代码实现的一致性（脚本自动化 diff，非人工逐条）

8. **安全扫描** → `@fixer semgrep --config=auto`（SQL注入、XSS、硬编码密钥等）
   — 有报错让 @fixer 修复并重扫，直到无报错

9. **回验** → `@oracle`：
   - 读取 PRD 需求清单 + 验收 checklist + 代码变更
   - 逐项核实：✅已实现 / ⚠️部分实现 / ❌未实现 / 🔴不一致 / ⚪多余功能 / ⚠️缺少测试
   - **TDD 合规检查**：检查变更是否包含对应测试文件
     · 如无测试文件 → 检查是否在步骤 3 裁定的例外范围内
     · 是例外 → 正常通过；非例外 → 标记 ⚠️ 退回步骤 5
   - **设计对照**：对照 `02-design.md` 的组件映射表和交互说明
   - **集成验证**：子功能 DAG 的跨子功能集成测试归入此步
   - 有缺口 → @fixer 修正 → 重新回验
   - 产出：`09-verification.md` + 更新 `docs/trail/STATE.md`

10. **知识回写** → `@oracle`（可选）：
    - 将本次架构决策、经验教训写入 `docs/spec/lessons/<date>-<feature>.md`
    - 仅写入可复用知识，不记操作流水账
    - 不写的内容：纯 UI 样式调整、常规 CRUD、配置变更（无长期价值）
    - 旧 lessons >90 天 → 标注 `archived`

#### 回溯回路（跨步骤）
步骤 3/4/5 发现问题 → 退回「问题引入级」而非机械的「上一级」：
- 每级退回 ≤2 次 → 修改后重新审查
- 超过 2 次 → @oracle 介入裁定（改设计 / 改方案 / 砍范围）
- **全局限制**：所有退回迭代总计 ≤6 次，超过则强制 @oracle 裁定

#### 步骤职责边界
- **步骤 3（架构审查）**：技术选型、模块划分、数据流、风险分析、领域归属、TDD 例外裁定
- **步骤 4（代码设计）**：接口签名、DTO 定义、类型映射表、关键类字段清单——不涉及「该不该用 X」

### 会话断点恢复（跨会话继续）
流水线可能跨多个会话执行。会话断开后重新启动时，自动恢复断点：

1. 启动时读取 `docs/trail/changes/<id>/` 下的产物文件列表
2. 按编号升序找到最后一个缺失的编号 → 从该步继续
   - 示例：存在 `01-prd.md + 02-design.md` → 从步骤 3 开始
   - 示例：存在 `01-prd.md + 02-design.md + 03-architecture.md` → 从步骤 4 开始
3. 如产物文件不完整（如文件存在但步骤未实际通过），可在 feature 目录创建 `CHECKPOINT.md` 手动标记断点：

   ```markdown
   # CHECKPOINT
   current_step: 5
   note: 步骤 5 实现中，IPC 类型已核，待 TDD
   ```

### 步骤超时/熔断
单步超时（默认值，可由用户覆盖）：
- 步骤 5（实现）: 30 分钟
- 步骤 6（自修复）: 5 分钟
- 步骤 7（code review）: 5 分钟
- 步骤 8（semgrep）: 3 分钟
- 其余步骤: 10 分钟

超时处理：步骤标记为 ⏳ 超时，记录已完成的产出，允许继续或中止裁定。

### Token 成本控制
回溯回路和重复步骤会增加 token 消耗：
- 每次退回估算该步骤的 token 消耗并累加到会话累计值
- 全流程 token 建议上限：500K token（超出后提示用户确认是否继续）
- 用户确认继续则不拦截；用户中止则标记为「已中止」并记录当前进度

只有全部 10 步通过，才标记功能为可合并。

### RTK Token 节省
- 系统已安装 `rtk`（`/usr/local/bin/rtk`），会在 bash 命令输出进入 LLM 前过滤噪声
- 对常见命令（ls, find, git, grep, cargo test, npm list 等），优先用 `rtk <command>` 替代裸命令
- 例：`rtk ls -la`、`rtk git status`、`rtk find . -name "*.ts"`、`rtk cargo check`

### 跨版本开发
涉及多个版本的场景：

**"修一下 v1 的 bug"、"这个 bug 在 v1 和 v2 都有"、"v1 有 bug"**
→ 先读 `docs/trail/VERSIONING.md` 了解分支策略
→ 确定影响的最老版本 → `git checkout release/v<版本>`
→ 走诊断 + 修复流程
→ cherry-pick 到所有受影响版本 + main
→ cherry-pick 遇到冲突 →
  1. 标记冲突文件，分析双方变更意图
  2. 自动合并无冲突部分
  3. 无法自动合并的块 → 提示用户人工介入
  4. 冲突解决后每个目标分支跑回归验证
→ 结果记录到 fix 记录中
→ 每个目标分支跑回归验证

**"新功能要在 v2 里"、"基于 v1 开发新版本"**
→ 从 main 切功能分支 → `git checkout -b feat/<name>`
→ 走完整 10 步管道 → 合并回 main
→ 发布时从 main 切出 `release/v<新版本>`

**"当前在哪个版本？"**
→ `git branch --show-current`
→ 产物路径自动加版本前缀：`docs/trail/changes/<version>/`

### 全栈环境同步
"全栈环境同步"、"全栈开发环境同步"、"同步环境配置到仓库"
→ 找到 `~/AI/my-opencode-stack/`
→ 对比本地环境和仓库的差异（配置文件、skills、npm 包、插件）
→ 列出差异清单，逐项问用户要不要同步
→ 用户确认后更新文件 → git commit + push

### 全栈环境升级
"升级全栈环境"、"全栈环境升级"、"检查环境更新"
→ 逐项检查可升级项：
   1. `brew outdated` — 列出可升级的包 + 版本变化
   2. `npm outdated -g` — 列出可升级的全局包 + 版本变化
   3. codebase-memory-mcp — 检查 GitHub Releases 是否有新版本
   4. Skills — 检查每个已安装 skill 是否有新版本
      → 读取对应仓库的 release notes / changelog
      → 如有不兼容变更（breaking changes），标注 ⚠️ 并说明
→ 汇总报告，格式：

   ```
   📦 可升级清单

   brew（3 个可升级）:
     rtk:      0.43.0 → 0.44.0 🟢 无 breaking
     semgrep:  1.168.0 → 1.172.0 🟢 无 breaking

   npm 全局（1 个可升级）:
     agentmemory: 0.9.27 → 0.10.0 ⚠️ 有 breaking（DB schema 变更）

   Skills（2 个可升级）:
     to-prd:     ⚠️ 输出格式变更，影响 orchestrator_append.md 路由规则
     tdd:        🟢 无 breaking

   codebase-memory-mcp: 已是最新 ✅

   是否全部升级？还是跳过某些项？
   ```

→ 用户勾选后，逐项执行升级 + 验证

### 全栈环境复刻
"换新电脑"、"复刻环境"、"在新机器上搭建开发环境"
→ 找到 `~/AI/my-opencode-stack/` 或用户指定的 my-opencode-stack 目录
→ 读 `README.md`（开头有 AI 指令）
→ 读 `environment-setup-guide.md` 并逐行执行
→ 遇到 `<PLACEHOLDER_>` 立即停下询问用户
→ 装完验证 → 告诉用户重启 OpenCode

### 项目初始化（新项目必做）
新项目启动时，按以下顺序执行：
1. `/init-project <name> <type>` — 初始化目录结构
2. `/setup-matt-pocock-skills` — 配置工程基础
3. 写 `.opencodereview/rule.json` — 项目代码审查规则
4. @fixer 生成 `README.md` + `CONTRIBUTING.md` — 项目文档
   - README 包含：项目简介、技术栈、快速启动、目录结构
   - CONTRIBUTING 包含：代码规范、提 PR 流程、开发环境
5. `git init && git commit -m "chore: init"` — 首次提交
6. CI 门禁（按技术栈选配）

### 非本流程项目接入（中途接手）
当中途接手一个**不是用本流水线开发**的已有项目时，走接入流程：

步骤 A — 基础设施（< 1 分钟，agent 自动执行）：
1. `/setup-matt-pocock-skills` → `.mattpocock/` + issue tracker
2. 创建 `AGENTS.md` — 项目路由规则（基于 README + 目录结构自动生成）
3. 创建 `.opencode/rules/` → `risk-zones.md` + `release-checklist.md`（模板）

步骤 B — 逆向工程基线文档（< 3 分钟，agent 自动执行）：
4. 扫描项目结构、技术栈、包依赖 → `docs/spec/architecture.md`
5. 扫描关键代码 → `docs/spec/conventions.md`
6. 提取核心领域术语 → `docs/spec/glossary.md` 或 `docs/trail/CONTEXT.md`
7. 分析现有 IPC/REST 边界 → `docs/trail/BASELINE.md`（接口契约基线）
   — 反向工程现有 `#[tauri::command]` 与 `invoke()` 签名
   — 标记已发现的不一致项

步骤 C — 状态锚点（< 1 分钟）：
8. `git log --oneline -20` → 粗略 CHANGELOG 基线
9. 现有测试数、lint 状态 → `docs/trail/STATE.md`
10. 所有现有代码标记为 risk-zones 中的「已知/稳定」区域

步骤 D — 上线：
11. 之后的第一个需求迭代走完整 1→10 步流水线

> 原则：不追溯历史——基线只记录「当前是什么样」，不做旧的 01-prd.md。

### 项目规则
- 编辑文件前：读取 `.opencode/rules/risk-zones.md`，判断风险分区
- 发布时：读取 `.opencode/rules/release-checklist.md`，按清单逐项执行

### 记录规则

流水线阶段完成后，保存产物到 `docs/trail/`：

- **步骤 1**（需求探索+PRD）→ `docs/trail/changes/<id>/01-prd.md`
  — brainstorming 产出 `brainstorm/design.md`（如拆子功能则多个文件）
  — /to-issues 产出 `plan.md`（任务拆解，子功能 ≥2 时含 DAG）
- **步骤 2**（设计）→ `docs/trail/changes/<id>/02-design.md`
- **步骤 3**（架构审查）→ `docs/trail/changes/<id>/03-architecture.md`
  — 包含：领域归属判断、TDD 例外裁定
  — 跨功能 ADR → `docs/spec/decisions/<date>-<slug>.md`
  — 如属于已有领域，同步更新 `docs/spec/domains/<domain>/model.md`
- **步骤 4**（代码设计）→ `docs/trail/changes/<id>/04-code-design.md`
  — 必含「接口类型契约」章节（无跨边界通信的项目标记 N/A 跳过）
- **步骤 5**（代码实现）→ 由 /tdd 和 /implement 的产物构成
- **步骤 6**（自修复 lint）→ 自动工具，无需手工产物
- **步骤 7**（code review）→ `docs/trail/changes/<id>/07-code-review.md`
- **步骤 8**（安全扫描）→ `docs/trail/changes/<id>/08-security-scan.md`
- **步骤 9**（验收）→ `docs/trail/changes/<id>/09-verification.md` + 更新 `docs/trail/STATE.md`
  — 子功能 DAG 的集成验证归入此步
- **步骤 10**（知识回写）→ `docs/spec/lessons/<date>-<feature>.md`

> Bug 修复记录 → `docs/trail/fixes/<date>-<slug>.md`（不走步骤编号，独立记录）

首次写入后：`ctx_index(path: "docs/spec/", source: "docs/spec")`
查询：`ctx_search(queries: ["关键词"], source: "docs/spec")`

首次写入后：`ctx_index(path: "docs/trail/", source: "docs/trail")`
查询：`ctx_search(queries: ["关键词"], source: "docs/trail")`

### 讨论与产物分离

- 脑暴讨论不生成文件（context-mode 自动捕获）
- 回顾讨论：`ctx_search(queries: ["关键词"], sort: "timeline")`

### 版本管理

- PRD 迭代：新版本头部标注变更理由、时间、关联 PRD
- 不每次功能打 tag，仅在发布时执行 release-checklist

### 设计产物规则

- **步骤 2 完成时**（UI/UX 设计后）:
  → @designer 写入 `docs/trail/changes/<id>/02-design.md`（设计规范）
  → 模板：`~/.config/opencode/trail-templates/02-design-template.md`
  → 必须包含：组件映射表（引用 shadcn 组件名 + 变体）、交互说明、设计决策

### 步骤 8 设计对照（补充）

- @oracle 回验时，除 PRD 外，还需对照 `02-design.md` 的组件映射表和交互说明
- 逐项验证代码实现是否与设计规范一致
- 验收报告新增「设计对照」表格：设计要求 / 代码实现 / 一致
