# Codex Agent 引导

本仓库采用共享技能库模式，`skills-shared/` 是唯一技能来源（SSOT）。

## 技能根目录
`/Volumes/SXPCWLKJ/MyWork/mms-skills/skills-shared`

## 引入方式（可直接让 Agent 执行）

```bash
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/AGENTS.md" "AGENTS.md"
```

## 核心规范（强制）
1. 全部中文回答（代码/命令/日志原文除外）。
2. 每开发一个新功能，先分析需求。
3. 分析后先创建版本文档：`version/vX.Y.Z-功能说明.md`。
4. 版本号必须递增，不允许跳过文档直接开发。
5. 开发过程中持续同步任务进度。
6. 完成后做复盘，并沉淀为 skill（自我进化）。

## 标准执行顺序
1. 匹配任务类型。
2. 在 `skills-shared/` 定位技能目录。
3. 先读取 `SKILL.md`。
4. 按 `mms-dev-workflow` 流程执行：分析 -> version 文档 -> 开发 -> 进度同步 -> 复盘沉淀。
5. 若任务显式要求与技能冲突，以任务要求优先。