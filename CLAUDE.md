# Claude Code 引导

本仓库技能统一维护在共享目录，避免多处重复维护。

## 技能根目录
`/Volumes/SXPCWLKJ/MyWork/mms-skills/skills-shared`

## 引入方式（可直接让 Agent 执行）

```bash
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/CLAUDE.md" "CLAUDE.md"
```

## 核心规范（强制）
1. 全部中文回答（代码/命令/日志原文除外）。
2. 新功能必须先分析需求。
3. 分析通过后，先创建 `version/vX.Y.Z-功能说明.md`。
4. 版本号按规则递增。
5. 开发过程同步任务进度维护。
6. 完成后复盘并更新可复用 skill（自我进化）。

## 标准执行顺序
1. 根据任务选技能。
2. 读取目标 `SKILL.md`。
3. 默认执行 `mms-dev-workflow`：分析 -> 版本文档 -> 开发 -> 进度同步 -> 复盘沉淀。
4. 多技能场景先主后辅。
5. 若用户当前任务有明确要求，以任务要求优先。