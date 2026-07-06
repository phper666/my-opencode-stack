# 版本管理策略

> 10 步管道默认在 `main` 分支上工作。当项目需要同时维护多个版本时，用本策略。
> 分支策略是**建议而非强制**，一人开发时可灵活简化，多人协作时建议遵守。

## 分支约定

```
main              ← 线上稳定版。只接受 staging 合入 + hotfix cherry-pick。
staging           ← 版本验收版。功能/dev 合入这里测试，通过后合入 main。
dev               ← 每日开发版。所有功能开发在这里。
release/vX        ← 长期支持版。只修 bug，不开发新功能。
```

- `staging` 和 `dev` 从 `main` 切出，随版本迭代推进
- `release/*` 从 `main` 切出，**发布后只接受 cherry-pick 的 bug 修复**
- 一人开发时，简单的 hotfix 可直接在 main 上改；涉及多版本时建议走完整流程

## 日常开发流程

```
1. 在 dev 上开发功能
2. 功能完成 → 合入 staging 做验收测试
3. 验收通过 → 合入 main（上线）
```

## Bug 修复（线上 bug + dev 有未完成工作）

```
1. 从 main 拉 hotfix 分支：git checkout -b hotfix/<name> main
   → 如果 dev 有未完成工作，建议用 worktree 隔离：git worktree add .slim/worktrees/hotfix main
2. 修 bug → staging 验收
3. 合入 main
4. cherry-pick 到 dev（防止回归）：
   git cherry-pick <commit-hash>    # 到 dev
5. 清理 worktree（如果用了）
```

## Bug 修复（跨版本）

当同一个 bug 影响多个 release 版本时：

```
1. 确定 bug 影响的最老 release 版本
2. 切到该 release 分支：git checkout release/v1
3. 走诊断 → 修复 → 自修复 lint → code review → semgrep
4. cherry-pick 到较新版本和 main + dev：
   git cherry-pick <commit-hash>    # 到 release/v2
   git cherry-pick <commit-hash>    # 到 main
   git cherry-pick <commit-hash>    # 到 dev
```

orchestrator 在修复完成后自动执行 cherry-pick，并在每个目标分支跑回归验证。

## 新功能开发

```
1. 从 dev 切功能分支：git checkout -b feat/<name> dev
2. 走完整 10 步管道
3. 合回 dev → staging 验收 → main 上线
```

## 产物目录

```
docs/trail/changes/<version>/<feature-id>/
  ├── 01-prd.md
  ├── 02-design.md
  └── ...

docs/trail/fixes/<version>/<date>-<slug>.md
```

版本号由 `git branch --show-current` 自动推断：
- `main` → `main`
- `staging` → `staging`
- `dev` → `dev`
- `release/v1` → `v1`
- `feat/xxx` → `dev`（功能分支归到 dev）

## CHANGELOG

每次发布时累加对应版本的 CHANGELOG：
- main 的变更 → 当前版本
- dev/staging 的变更 → 下一个待发布版本
