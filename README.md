# my-opencode-stack

我的 OpenCode 全栈开发环境 — 配置、插件、脚本、模板的一键复刻包。

## 用法

**新电脑**：把 `environment-setup-guide.md` 交给 AI，按步骤执行即可。

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
| Docker Desktop | 运行容器 | ✅ |

## License

MIT
