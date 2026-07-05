# my-opencode-stack

我的 OpenCode 全栈开发环境 — 配置、插件、脚本、模板的一键复刻包。

> **🤖 AI 指令**：当你（AI）读到这个项目时，你的任务是帮助用户在新电脑上安装这个全栈开发环境。
>
> 1. 读取 `environment-setup-guide.md` — 这是你将要逐行执行的安装文档
> 2. 遇到 `<PLACEHOLDER_XXX>` 时停下来问用户要真实值，不要猜测
> 3. 按文档顺序执行所有命令，每步跑完验证
> 4. 全部完成后告诉用户重启 OpenCode
> 5. 安装完成后，`docs/pipeline.md` 有完整的开发流程和实战样例

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
├── config/
│   ├── opencode.jsonc            ← OpenCode 核心配置（含 providers + MCPs）
│   ├── oh-my-opencode-slim.json  ← 8 agent 模型分配
│   ├── orchestrator_append.md    ← 路由规则 + 10 步管道
│   ├── agentmemory.env           ← 记忆服务环境变量模板
│   ├── agentmemory.plist         ← macOS 开机自启
│   └── opencodereview-config.json← code review LLM 配置
├── plugins/
│   ├── rtk.js                    ← token 压缩
│   └── agentmemory-capture.ts    ← 记忆采集
├── scripts/
│   ├── setup-all.sh              ← 一键安装全部
│   ├── install-system.sh         ← brew + npm
│   ├── install-config.sh         ← 复制配置文件
│   ├── install-skills.sh         ← 批量安装 skills
│   └── install-docker.sh         ← Docker 容器
├── templates/
│   └── trail-templates/          ← trail 产物模板
└── start-env.sh                  ← 日常启动
```

## 需要什么

| 资源 | 说明 | 必填 |
|:----|:-----|:----:|
| Echobraid API Key | DeepSeek 模型 | ✅ |
| OpenCode Go API Key | 多种开源模型 | ✅ |
| Git 用户名 + 邮箱 | — | ✅ |
| macOS | 当前仅支持 macOS | ✅ |
| Docker Desktop | 可选，项目需要时安装 | ❌ |

## 保持同步

本地环境有变更后，同步回仓库：

```bash
bash scripts/sync.sh          # 同步并推送
bash scripts/sync.sh --dry-run  # 先看看改了什么
```

脚本会自动：
- 复制配置文件（opencode.jsonc、orchestrator_append.md 等）
- 复制插件和模板
- **替换真实 API Key 为占位符**，防止泄漏
- git commit + push

## 了解更多

- [这是什么 + 能力清单](docs/overview.md)
- [10 步管道 + 8 agent 分工](docs/pipeline.md)

## License

MIT
