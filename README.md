# my-opencode-stack

我的 OpenCode 全栈开发环境 — 配置、插件、脚本、模板的一键复刻包。

> **🤖 AI 指令**：当你（AI）读到这个项目时，你的任务是帮助用户在新电脑上安装这个全栈开发环境。
>
> 1. 读取 `environment-setup-guide.md` — 这是你将要逐行执行的安装文档
> 2. 遇到 `<PLACEHOLDER_XXX>` 时停下来问用户要真实值，不要猜测
> 3. 按文档顺序执行所有命令，每步跑完验证
> 4. 安装完成后，读取 `docs/replication-checklist.md` 第八节「AI 一键验证」，执行其中的 bash 脚本自动验证环境完整性
> 5. 全部验证通过后，告诉用户重启 OpenCode
> 6. 安装完成后，`docs/spec/architecture.md` 有完整架构说明，`docs/pipeline.md` 有开发流程和实战样例

## 用法

**手动安装**：

```bash
git clone https://github.com/<USER>/my-opencode-stack.git
cd my-opencode-stack
# 先编辑 config/* 填入 API Key
bash scripts/setup-all.sh
```

## 结构

```
my-opencode-stack/
├── environment-setup-guide.md   ← AI 可执行的复刻文档
├── config/                       ← 全部配置文件（API Key 用占位符）
├── plugins/                      ← OpenCode 插件（rtk + agentmemory-capture）
├── skills/                       ← 魔改版 brainstorming skill
├── scripts/
│   ├── lib/manifest.sh           ← 安装记录 manifest 读写
│   ├── install-system.sh         ← brew + npm + pip
│   ├── install-codebase-memory.sh← 代码知识图谱二进制
│   ├── install-config.sh         ← 复制配置文件
│   ├── install-skills.sh         ← 批量安装 skills
│   ├── install-docker.sh         ← Docker 验证
│   ├── setup-all.sh              ← 一键安装全部
│   └── uninstall.sh              ← 一键卸载（基于 manifest）
├── templates/
│   └── trail-templates/          ← trail 产物模板
├── docs/
│   ├── spec/
│   │   └── architecture.md       ← 完整架构说明（分层、组件、数据流、设计决策）
│   ├── overview.md               ← 项目介绍 + 能力清单
│   ├── pipeline.md               ← 10 步管道 + 实战样例
│   └── trail/VERSIONING.md       ← 跨版本分支策略
├── .githooks/
│   └── pre-commit                ← 秘钥防误提交 hook
└── start-env.sh                  ← 日常启动
```

## 需要什么

| 资源 | 说明 | 必填 |
|:----|:-----|:----:|
| OpenCode Go API Key | 多种开源模型 | ✅ |
| Git 用户名 + 邮箱 | — | ✅ |
| macOS | 当前仅支持 macOS | ✅ |
| Docker Desktop | 可选，项目需要时安装 | ❌ |

## 保持同步

本地环境有变更后，对 AI 说**「全栈环境同步」**。

AI 会对比本地环境和仓库的差异，列出清单，你确认后才写入并 push。

## 文档索引

| 文档 | 读者 | 内容 |
|:----|:----|:-----|
| [完整架构说明](docs/spec/architecture.md) | 想理解系统的人 | 分层架构、组件关系、数据流、设计决策、术语表 |
| [环境复刻指南](environment-setup-guide.md) | AI（新电脑安装） | 逐行执行的安装文档，遇占位符停下问用户 |
| [项目概览](docs/overview.md) | 初次接触的人 | 这是什么、能力清单、引用的开源项目 |
| [10 步管道](docs/pipeline.md) | 开发者 | 8 agent 分工 + 10 步流水线 + 实战样例 |
| [orchestrator 路由](config/orchestrator_append.md) | AI（orchestrator） | 所有路由规则、质量门禁、回溯回路、token 控制 |
| [版本策略](docs/trail/VERSIONING.md) | 维护者 | 分支约定、cherry-pick、产物目录版本化 |

## 保持同步

## License

MIT
