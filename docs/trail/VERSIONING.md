# 版本管理策略

> 10 步管道默认在 `main` 分支上工作。当项目需要同时维护多个版本时，用本策略。

## 分支约定

```
main              ← 最新开发版，新功能、新版本走这里
release/v1        ← v1 稳定版（只修 bug，不开发新功能）
release/v2        ← v2 稳定版
```

- `release/*` 从 `main` 切出来，**发布后只接受 cherry-pick 的 bug 修复**
- `main` 合并新功能前必须走完整 10 步管道

## Bug 修复（跨版本）

当同一个 bug 影响多个版本时：

```
1. 确定 bug 影响的最老版本
2. orchestrator 自动切到该 release 分支：git checkout release/v1
3. 走诊断 → 修复 → 自修复 lint → code review → semgrep
4. cherry-pick 到较新版本和 main：
   git cherry-pick <commit-hash>    # 到 release/v2
   git cherry-pick <commit-hash>    # 到 main
```

orchestrator 在修复完成后自动执行 cherry-pick，并在每个目标分支跑回归验证。

## 新功能开发

```
1. 从 main 切功能分支：git checkout -b feat/<name>
2. 走完整 10 步管道
3. 合并回 main
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
- `release/v1` → `v1`
- `feat/xxx` → `main`（功能分支归到 main）

## CHANGELOG

每次发布时累加对应版本的 CHANGELOG：
- main 的变更 → 下一个未发布版本
- release/v1 的 cherry-pick → v1.x 补丁版本
