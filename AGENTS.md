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
2. 纯问候/状态确认（"在吗""Hi""Hello""好的""谢谢"等）直接自然回复，不加载技能、不检查技能。
3. 按任务复杂度匹配工作流深度（参照 superpowers TASK-TIERING）：
   - 琐碎修改（改颜色/改配置/修拼写）：直接改，不走流程
   - 简单任务（单一 bug 修复/加一个字段）：快速分析 → 直接实施
   - 中等功能（新页面/新功能）：mms-dev-workflow 完整流程
   - 复杂系统（新子系统/架构变更）：brainstorming → writing-plans 流水线
4. 用户说"快速改"/"just do it"时，直接实施，不强制走流程。
5. 每开发一个新功能，先分析需求。
6. 分析后先创建版本文档：`version/vX.Y.Z-功能说明.md`。
7. 版本号必须递增，不允许跳过文档直接开发。
8. 开发过程中持续同步任务进度。
9. 完成后做复盘，并沉淀为 skill（自我进化）。

## 标准执行顺序
1. 匹配任务类型。
2. 在 `skills-shared/` 定位技能目录。
3. 先读取 `SKILL.md`。
4. 按 `mms-dev-workflow` 流程执行：分析 -> version 文档 -> 开发 -> 进度同步 -> 复盘沉淀。
5. 若任务显式要求与技能冲突，以任务要求优先。