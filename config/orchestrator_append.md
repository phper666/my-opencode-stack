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
→ 自动调 `/to-issues` 拆成独立任务（含 DAG 依赖图，产物 → `docs/trail/changes/<version>/<feature-id>/plan.md`）
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
→ 退回重规划 ≤2 次 → 超过后 @oracle 介入裁定
→ 计入全局 6 次退回配额

### 批量功能调度（批量模式）
当同时开发 **≥5 个独立小功能** 时，启用批量模式提升吞吐：

**依赖分析**（orchestrator 自动做）：
→ 扫描每个功能涉及的文件路径列表
→ 无文件交集的功能 → 放入同一批次，可并行
→ 有文件交集的功能 → 串行，后一个等前一个完成
→ 改 DB schema 的功能 → 阻塞所有涉及该表的功能

**分批调度**：
```
批次 1（@fixer × 3）: 功能A、功能C、功能E（全独立）
批次 2（@fixer × 3）: 功能B、功能F、功能G（依赖批次1）
批次 3（@fixer × 2）: 功能D、功能H（依赖批次2）
最终批: 集成验证
```

**并行度控制**：
→ 默认 @fixer × 3 并行（orchestrator 可根据当前 token 消耗动态调节）
→ 每批完成后：git merge + 自动冲突解决
→ 合并冲突 > 5 文件 → 该批降级为串行重跑
→ 某个 @fixer 连续失败 2 次 → 该功能退出并行改为独立串行

**集成验证**：
→ 所有批次完成后执行一次全量验证
→ 验证失败 → 定位到具体功能 → 修复后重跑该功能及其下游

**Token 预算**：
→ 并行时总 token 消耗按每功能独立 500K 计算
→ orchestrator 实时监控，接近总预算 70% 时降低并行度

### 明确的小任务
"改个样式"、"加个字段"
→ 直接派 @fixer，不走 spec 流程
→ 修复后自动跑 lint + semgrep
→ 修复记录 → `docs/trail/fixes/<version>/<date>-<slug>.md`

### Bug 修复（含排查）
"修个 bug"、"找不到原因"、"难复现"、"调了一小时没头绪"
→ **先检测是否含版本关键词（v1/v2/release/）→ 如有，优先走跨版本路由**
→ 如果当前工作区有未提交的改动 → 建议用 worktree 隔离 hotfix（不打断当前工作），用户确认后才创建：`git worktree add .slim/worktrees/<slug> main`
→ 如果已明确是简单 bug（无需诊断）→ 直接 @fixer 修复
→ 如果原因不明或反复失败 → 加载 `/diagnosing-bugs` 走六步循环
→ 派 @fixer + 加载 `/diagnosing-bugs`
→ 走六步循环：复现→最小化→假设→插桩/日志定位根因→修复→回归测试
→ 修复后先跑 semgrep → 有报错退回修复，直到清洁
→ 再跑回归测试 → 全绿通过
→ 修复记录 → `docs/trail/fixes/<version>/<date>-<slug>.md`（含诊断过程）

### 架构改进
"重构"、"提升质量"、"这模块太烂"
→ 派 @fixer + 加载 `/codebase-design`
→ 深度模块化思路：找接缝、做适配器、加测试
→ 重构后跑现有测试 → 必须全绿
→ 跑 lint + semgrep
→ 产出 `docs/trail/changes/<version>/<feature-id>/refactor-summary.md` 记录改动和原因
→ 写入 `docs/spec/lessons/`（架构决策、踩坑记录）

### Hotfix 快道
"线上 bug"、"紧急修复"、"马上修一下"
→ 专为线上紧急 bug 设计，不打断当前工作
→ 如果 dev 有未完成工作 → 建议用 worktree 隔离
→ 走 5 步快速通道：诊断 → @fixer 修复 → 回归测试 → semgrep → staging 验收 → main
→ 跳过：PRD、设计、架构、代码设计、lint、lessons
→ 修复记录 → `docs/trail/fixes/<version>/<date>-<slug>.md`
→ **合入 main 后自动 cherry-pick 到 dev**（防止回归）

### Spike 技术调研
"调研一下"、"试试方案"、"探探路"
→ 用于技术可行性验证、方案选型对比、实验性代码
→ 路径：假设 → 实验 → 结论（Go / No-Go）→ 存档
→ 实验代码放在独立分支或临时目录，不污染主分支
→ **产出不是 PRD 而是决策记录**：
  → `docs/trail/spikes/<date>-<topic>.md`
  → 格式：目标 → 方案 → 实验过程 → 结论 → 后续建议
→ 如果结论是 Go → 走正常 10 步管道做正式实现
→ 如果结论是 No-Go → 存档即可，经验存入 lessons
→ 不需要写测试、不需要 code review、不需要安全扫描

### TDD 实现（强制）
"用测试驱动"、"先写测试"、"TDD"
→ 加载 `/tdd`
→ red-green-refactor 循环
→ **所有非平凡逻辑（分支、循环、解析器、资金/安全路径）必须走 TDD，不得跳过**

### 卡片拆解
PRD/plan 已存在
→ 加载 `/implement`
→ 按依赖顺序逐个实现
→ **强制 TDD**：非平凡逻辑必须先写测试再写实现

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

### 风险分级路由（快慢道）

所有需求按风险等级分流。orchestrator 先判断风险等级，再选路由：

**风险等级判定标准**：

| 等级 | 判断规则 | 示例 |
|:----|:--------|:-----|
| 🔴 **高风险**（完整 10 步）| 改动触及数据库、auth/权限、IPC/FFI 层、加密/密钥、3+ 模块修改 | 加字段到 `projects` 表、改登录逻辑、改 Tauri command 签名 |
| 🟡 **中风险**（精简 5 步）| 新增业务逻辑、新增 API endpoint、新增 UI 组件 | 加一个设置页面、加导出格式、加搜索过滤 |
| 🟢 **低风险**（2 步直通）| 肉眼可见、错了立刻能发现：文案、颜色、布局、配置（patch）| 改按钮文案、调间距、改默认配置值 |

**分流规则**：

```
高风险 → 完整 10 步管道（PRD→设计→架构→代码设计→TDD→lint→review→semgrep→回验→lessons）
中风险 → 精简 5 步（PRD→实现(TDD)→lint→review→回验）
         跳过：设计、架构、代码设计、semgrep、lessons
低风险 → 直通 2 步（@fixer 实现 → lint + semgrep）
         但增加一句话确认锚点：
         orchestrator 用一句话总结需求让用户确认再开工
```

**用户覆盖**：开发者在任何功能启动前可以说「这个走完整流程 / 走快捷」覆盖自动分级。

**安全边界**：
- 路由规则优先于风险分级（例如明确 bug 修复永远走 bug 流程，不受风险等级影响）
- 低风险走快捷路径后，如果实现过程中发现复杂度超预期，orchestrator 自动升阶到中风险流程

### 规则
- 不要先问用户「要不要走 spec 流程」——按上面规则自动判断
- User-invoked skill（`/to-prd` `/to-issues` `/setup-matt-pocock-skills`）由用户主动调或按规则自动调
- Model-invoked skill（`/tdd` `/diagnosing-bugs` 等）由 agent 看 description 自行加载

> 以下为各质量门禁快速参考，完整执行流程见「全链路触发规则」相应步骤。

### 验收测试生成
PRD 审查通过后 → @oracle 从 PRD 提取所有需求项 → 生成验收 checklist → 写入 `.mattpocock/prds/<id>-acceptance-checklist.md`
（该文件路径会记录在步骤 9 的 `09-verification.md` 中）

### Code Review（open-code-review + ponytail-review）
@fixer 实现完成后 → 分两步走（轮次按风险等级调整）：

**① 正确性审查：** `ocr review --audience agent`
→ 高风险功能：高/中优先级问题全修，重审 ≤3 轮 → 超限 @oracle 裁定
→ 中风险功能：高/中优先级问题全修，重审 ≤2 轮 → 超限 @oracle 裁定
→ 低风险功能：只修 high 优先级问题（不修 medium），重审 ≤1 轮
→ 重审超限后统一由 @oracle 介入裁定

**② 视觉审计（UI 项目，按风险等级触发）：**
→ 🟢 低风险 UI 改动（改按钮颜色/文案/间距）：跳过
→ 🟡 中风险 UI 改动（新增页面/新组件）：执行代码级设计审计
   @designer 读前端代码，对照 02-design.md：
   - 组件树结构是否匹配设计规范
   - shadcn 组件变体是否正确
   - 设计 token 是否引用正确（无硬编码颜色/间距）
   - 响应式类名是否齐全
   - 状态覆盖（disabled/loading/empty）是否到位
→ 🔴 高风险 UI 改动（重构布局/主题/核心组件）：追加 @observer 截图对比
   如果 dev server 在运行，@observer 用 chrome-devtools 截关键页面
   分析：布局还原度、间距系统、色彩语义、状态覆盖、响应式断点
→ 发现问题 → 退回 Step 5 修正 → 重新审计

**③ 过度设计审查：** ponytail-review
→ 所有风险等级均执行
→ 列出可简化项（stdlib 替代、多余抽象、未用依赖等）
→ 追加到 `07-code-review.md`「简化建议」节
→ @oracle 逐条裁定采纳/拒绝

### 自修复 Lint + Type-check（零 token 成本）
@fixer 实现 + TDD 完成后 → 自动跑 lint + type-check（轮次按风险等级调整）：
- 检测项目类型，自动选对应工具（tsc、ESLint、Biome、cargo check、ruff 等）
- **自修复模式**：遇到错误自动修复
  - 高风险功能：最多 3 轮迭代（--fix → agent修 → 验证）
  - 中风险功能：最多 2 轮迭代（--fix → agent修）
  - 低风险功能：最多 1 轮（--fix），warning 直接 suppress + 记录
- 超轮次后仍有错 → 列出剩余问题，进入步骤 7
- 不跑 test（步骤 5 TDD 已保证测试覆盖）
- 如果项目没有对应的工具链，跳过并注明

### Semgrep 安全扫描 + 依赖审计
Code review 通过后 → 执行安全检查（两项并行）：

**① 源码扫描**：`semgrep --config=auto .`
→ 有报错让 @fixer 修复并重扫（轮次按风险等级调整）
→ 高风险：重扫 ≤3 轮 → 超限 @oracle 裁定
→ 中风险：重扫 ≤2 轮 → 超限 @oracle 裁定
→ 低风险：重扫 ≤1 轮，修完为止

**② 依赖审计**：检测项目类型后自动选对应工具
→ **Rust 项目**：`cargo deny check` 或 `cargo audit`
→ **Node 项目**：`npm audit` 或 `pnpm audit`
→ 有漏洞 → 让 @fixer 升级依赖版本 → 重新审计
→ 高风险（CVSS ≥ 7）依赖漏洞 → 阻塞流程，退回 Step 5
→ 中/低风险漏洞 → 记录到 `07-code-review.md` 简化建议节，继续流程

> 依赖审计在当前项目中可能找不到工具链（如未安装 cargo-deny），这时跳过并注明即可。

### PRD 回验
Semgrep + 依赖审计通过后 → @oracle 回验 PRD：
- 读取 PRD 的完整需求清单 + 验收 checklist + 代码变更
- 逐项核实每个需求是否被实现、有没有多余的未规划功能
- 输出验收报告：✅已实现 / ⚠️部分实现 / ❌未实现 / 🔴和 PRD 不一致 / ⚪多余功能 / ⚠️缺少测试
- **TDD 合规检查**：检查代码变更中是否包含对应的测试文件
  - 如果变更未包含测试文件，检查是否属于 TDD 跳过例外
  - 如果是例外 → 正常通过
  - 如果不是例外且没有测试文件 → 标记为 **⚠️ 缺少测试**，退回步骤 5 补测试
- **测试质量审查**：@oracle 审查测试的有效性（非生成覆盖率报告）
  → 测试是否覆盖了 PRD 中的每个需求项？
  → 测试是测了真实逻辑还是 mock 了全部？
  → 边缘/异常路径有没有测试覆盖？
  → 如果测试质量不达标（全部 mock、仅测 getter、覆盖率明显不足）→ 退回 Step 5
- 有缺口 → @fixer 修正 → 重新回验

### 知识回写（Knowledge Write-back）
步骤 9 通过后 → @oracle 把本次的架构决策和经验教训写入 `docs/spec/lessons/`：
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
  - 如发现契约与代码/PRD 不一致 → 退回步骤 4 修正契约，不自行修改
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

6. **自修复 lint + type-check** → `@fixer`（轮次按风险等级调整）：
   - 检测项目类型，自动选对应工具（tsc、ESLint、Biome、cargo check、ruff 等）
   - **分叉路径**：
     · `clean` → 继续
     · **仅 lint warning** → 自修复：
       高风险：最多 3 轮（--fix → agent修 → 验证）
       中风险：最多 2 轮（--fix → agent修）
       低风险：最多 1 轮（--fix），warning 直接 suppress + 记录
       — 超轮次后仍有 trivial warning → 标记 `#[allow]/eslint-disable` + 记录，放行
     · **编译 error** → 直接退回步骤 5
- **退回配额规则**：步骤 5→6→5 退回时，清空 lint 配额，重新计数
- 自修复轮次是步骤内部的独立限制，不计入全局 6 次退回迭代
- **退回 ≥2 次**（同一类问题）→ @oracle 介入
   - 不跑 test（步骤 5 TDD 已覆盖）

7. **Code Review** → `@fixer` 分三步（轮次按风险等级调整）：
   - ① `ocr review --audience agent`（正确性）
     高风险：修 high/medium，重审 ≤3 轮
     中风险：修 high/medium，重审 ≤2 轮
     低风险：只修 high，重审 ≤1 轮
     超限后 @oracle 裁定
   - ② 视觉审计（UI 项目，按风险触发）
     🟢 低风险 UI 跳过
     🟡 中风险：@designer 代码级设计审计（读代码 → 验 token/组件/响应式）
     🔴 高风险：追加 @observer 截图对比（chrome-devtools 截页面）
   - ③ ponytail-review（过度设计）→ 所有等级均执行
   — 核对接口类型契约与代码实现的一致性（脚本自动化 diff，非人工逐条）

8. **安全扫描 + 依赖审计** → `@fixer`（两项并行，轮次按风险等级调整）
   — ① `semgrep --config=auto`（源码扫描）
     高风险：≤3 轮  中风险：≤2 轮  低风险：≤1 轮
   — ② 依赖审计（npm audit / cargo deny / pnpm audit）
     高风险（CVSS ≥ 7）漏洞 → 阻塞流程，退回 Step 5
     中/低风险漏洞 → 记录到 `07-code-review.md`，继续流程

9. **回验** → `@oracle`：
   - 读取 PRD 需求清单 + 验收 checklist + 代码变更
   - 逐项核实：✅已实现 / ⚠️部分实现 / ❌未实现 / 🔴不一致 / ⚪多余功能 / ⚠️缺少测试
   - **TDD 合规检查**：检查变更是否包含对应测试文件
     · 如无测试文件 → 检查是否在步骤 3 裁定的例外范围内
     · 是例外 → 正常通过；非例外 → 标记 ⚠️ 退回步骤 5
   - **测试质量审查**：@oracle 检查测试是否真的有用
     · 测试是否覆盖 PRD 每个需求项？
     · 边缘/异常路径有测试吗？
     · 测试不是全部 mock 空壳？
   - **设计对照**：对照 `02-design.md` 的组件映射表和交互说明
   - **集成验证**：子功能 DAG 的跨子功能集成测试归入此步
 - 有缺口 → @fixer 修正 → 重新回验
- 回验 ≤3 轮 → 超过后 @oracle 介入裁定
   - 产出：`09-verification.md` + 更新 `docs/trail/STATE.md`

10. **知识回写** → `@oracle`（按需执行）：
    - 将本次架构决策、经验教训写入 `docs/spec/lessons/<date>-<feature>.md`
    - 仅写入可复用知识，不记操作流水账
    - 不写的内容：纯 UI 样式调整、常规 CRUD、配置变更（无长期价值）
    - 旧 lessons >90 天 → 标注 `archived`

#### 回溯回路（跨步骤）
步骤 3/4/5 发现问题 → 退回「问题引入级」而非机械的「上一级」：
- 每级退回 ≤2 次 → 修改后重新审查
- 超过 2 次 → @oracle 介入裁定（改设计 / 改方案 / 砍范围）
- **全局限制**：所有退回迭代总计 ≤6 次，超过则强制 @oracle 裁定

步骤 7/8/9 发现问题 → 各自按风险等级设有重审上限：
- 步骤 7（code review）：高风险 ≤3 轮、中风险 ≤2 轮、低风险 ≤1 轮 → 超限 @oracle 裁定
- 步骤 8（semgrep）：高风险 ≤3 轮、中风险 ≤2 轮、低风险 ≤1 轮 → 超限 @oracle 裁定
- 步骤 9（回验）：所有等级 ≤3 轮 → 超限 @oracle 裁定（回验不改风险等级）
- 步骤 7/8/9 的重试计入全局 6 次配额

#### 步骤职责边界
- **步骤 3（架构审查）**：技术选型、模块划分、数据流、风险分析、领域归属、TDD 例外裁定
- **步骤 4（代码设计）**：接口签名、DTO 定义、类型映射表、关键类字段清单——不涉及「该不该用 X」

### 会话断点恢复（跨会话继续）
流水线可能跨多个会话执行。会话断开后重新启动时，自动恢复断点：

1. 启动时读取 `docs/trail/changes/<version>/<feature-id>/` 下的产物文件列表
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

超时处理：步骤标记为 ⏳ 超时，记录已完成的产出，询问用户继续或中止。
- 用户不在线或 60 秒无响应 → @oracle 裁定：如果该步骤有部分可用产出则继续，否则中止。

### Token 成本控制
回溯回路和重复步骤会增加 token 消耗：
- 每次退回估算该步骤的 token 消耗并累加到会话累计值
- 全流程 token 建议上限：500K token（超出后提示用户确认是否继续）
- 子功能 DAG 场景下，500K 指**每个子功能**独立计算，不是所有子功能总计
- 用户确认继续则不拦截；用户中止则标记为「已中止」并记录当前进度

步骤 1-9 全部通过后，功能标记为可合并。步骤 10 按需执行，不影响合并状态。

### RTK Token 节省
- 系统已安装 `rtk`（`/usr/local/bin/rtk`），会在 bash 命令输出进入 LLM 前过滤噪声
- 对常见命令（ls, find, git, grep, cargo test, npm list 等），优先用 `rtk <command>` 替代裸命令
- 例：`rtk ls -la`、`rtk git status`、`rtk find . -name "*.ts"`、`rtk cargo check`

### 输出压缩规则（caveman + ponytail）

Ponytail（代码最小化）已全局生效。Caveman（输出语言压缩）按以下规则自动开关：

**默认模式**：`lite`（去 filler/客套话，保留完整句子和技术精度）
**切换命令**：`/caveman lite|full|stop`（用户可随时覆盖）
**永久禁用**：wenyan-* 模式（per-session opt-in，不参与管道调度）

**按步骤控制**：

| 步骤 | caveman | ponytail | 理由 |
|:---:|:-------:|:--------:|:----|
| 1 PRD（brainstorming） | 关闭 | ✅ | 需要完整叙事和需求探索 |
| 2 设计（@designer） | 关闭 | ✅ | 设计规范需要精确描述 |
| 3 架构审查（@oracle） | 关闭 | ✅ | 架构推理需要完整表达 |
| 4 代码设计（@oracle+fixer） | 关闭 | ✅ | 接口契约必须精确完整 |
| **5 实现（@fixer TDD）** | **lite** | ✅ | 代码实现阶段，精简语言加速迭代 |
| 6 自修复 lint | 关闭 | ✅ | 工具输出，非自然语言 |
| **7 Code Review** | **lite** | ✅ | 需保留因果链（"有 bug，因为 X"） |
| 8 安全扫描 | 关闭 | ✅ | 工具输出，非自然语言 |
| 9 回验（@oracle） | 关闭 | ✅ | 需要逐项核对完整需求 |
| 10 知识回写 | 关闭 | ✅ | lessons 需要完整清晰 |

**安全机制**：
- `auto-clarity`：caveman 在安全警告、不可逆操作、歧义场景自动恢复完整表达
- `stop caveman`：用户在任何时候说此命令立即切回正常模式
- orchestrator 在调度每一步前注入对应 system prompt（`caveman_mode: lite|off`）

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
6. 创建 `docs/trail/STATE.md`（测试数 0, lint 待首检, 无活跃功能）
7. CI 门禁（按技术栈选配）

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

> 原则：不追溯历史——基线只记录「当前是什么样」，不做旧的 01-prd-md。
>
> **基线文档 vs 首次迭代架构**：步骤 B 产出的 `docs/spec/architecture.md` 是**全项目级**逆向工程结果，描述<u>当前代码实际架构</u>。首次迭代步骤 3 的 `03-architecture.md` 是**功能级**设计决策。两者关系：`03-architecture.md` 引用 `architecture.md` 中的既有架构作为上下文，只写本次变更新增的决策。

### 项目规则
- 编辑文件前：读取 `.opencode/rules/risk-zones.md`，判断风险分区
- 发布时：读取 `.opencode/rules/release-checklist.md`，按清单逐项执行

### 记录规则

流水线阶段完成后，保存产物到 `docs/trail/`。路径中 `<version>` 由 `git branch --show-current` 自动推断（`main` → `main`，`release/v1` → `v1`）。详见 `docs/trail/VERSIONING.md`。

- **步骤 1**（需求探索+PRD）→ `docs/trail/changes/<version>/<feature-id>/01-prd.md`
  — brainstorming 产出 `brainstorm/design.md`（如拆子功能则多个文件）
  — /to-issues 产出 `plan.md`（任务拆解，子功能 ≥2 时含 DAG）
- **步骤 2**（设计）→ `docs/trail/changes/<version>/<feature-id>/02-design.md`
- **步骤 3**（架构审查）→ `docs/trail/changes/<version>/<feature-id>/03-architecture.md`
  — 包含：领域归属判断、TDD 例外裁定
  — 跨功能 ADR → `docs/spec/decisions/<date>-<slug>.md`
  — 如属于已有领域，同步更新 `docs/spec/domains/<domain>/model.md`
- **步骤 4**（代码设计）→ `docs/trail/changes/<version>/<feature-id>/04-code-design.md`
  — 必含「接口类型契约」章节（无跨边界通信的项目标记 N/A 跳过）
- **步骤 5**（代码实现）→ 由 /tdd 和 /implement 的产物构成
- **步骤 6**（自修复 lint）→ 自动工具，无需手工产物。如 3 轮后有 trivial warning 被 suppress，记录到 `07-code-review.md` 简化建议节
- **步骤 7**（code review）→ `docs/trail/changes/<version>/<feature-id>/07-code-review.md`
- **步骤 8**（安全扫描）→ `docs/trail/changes/<version>/<feature-id>/08-security-scan.md`
- **步骤 9**（验收）→ `docs/trail/changes/<version>/<feature-id>/09-verification.md` + 更新 `docs/trail/STATE.md`
  — 子功能 DAG 的集成验证归入此步
- **步骤 10**（知识回写）→ `docs/spec/lessons/<date>-<feature>.md`

> Bug 修复记录 → `docs/trail/fixes/<version>/<date>-<slug>.md`（不走步骤编号，独立记录）

首次写入后：`ctx_index(path: "docs/spec/", source: "docs/spec")`
查询：`ctx_search(queries: ["关键词"], source: "docs/spec")`

首次写入后：`ctx_index(path: "docs/trail/", source: "docs/trail")`
查询：`ctx_search(queries: ["关键词"], source: "docs/trail")`

### 讨论与产物分离

- 日常对话不生成文件（context-mode 自动捕获）
- **brainstorming 环节的对话会产出 `brainstorm/design.md`**（结构化的设计决策）
- 回顾讨论：`ctx_search(queries: ["关键词"], sort: "timeline")`

### 版本管理

- PRD 迭代：新版本头部标注变更理由、时间、关联 PRD
- 不每次功能打 tag，仅在发布时执行 release-checklist

### 设计产物规则

- **步骤 2 完成时**（UI/UX 设计后）:
  → @designer 写入 `docs/trail/changes/<version>/<feature-id>/02-design.md`（设计规范）
  → 模板：`~/.config/opencode/trail-templates/02-design-template.md`
  → 必须包含：组件映射表（引用 shadcn 组件名 + 变体）、交互说明、设计决策

### 步骤 8 设计对照（补充）

- @oracle 回验时，除 PRD 外，还需对照 `02-design.md` 的组件映射表和交互说明
- 逐项验证代码实现是否与设计规范一致
- 验收报告新增「设计对照」表格：设计要求 / 代码实现 / 一致
