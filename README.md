# mms-skills

`mms-skills` 是面向 `mms` 脚手架体系的多工具共享技能库。

## 核心目标
- 三端统一：`Cursor / Codex / Claude Code`
- 统一技能源：`skills-shared/`
- 统一研发流程：`分析 -> 版本文档 -> 开发 -> 进度同步 -> 复盘沉淀`

## 三端入口
- Cursor：`.cursor/rules/00-project-bootstrap.mdc` + `.cursorrules`
- Codex：`AGENTS.md`
- Claude Code：`CLAUDE.md`

## 强制规范
1. 全部中文回答（代码/命令/日志原文除外）。
2. 每个新功能开发前必须先分析。
3. 分析完成后必须先在根目录 `version/` 创建版本文档。
4. 版本命名：`v主.次.修订-功能说明.md`，版本号递增。
5. 开发过程中持续同步任务进度。
6. 完成后复盘并沉淀 skill（自我进化）。

## 工作流（已串联）
默认工作流技能：
- `skills-shared/mms-dev-workflow/SKILL.md`

执行链路：
1. 任务识别 -> 选技能
2. 读取 `SKILL.md`
3. 新功能先创建 `version/vX.Y.Z-xxx.md`
4. 按文档实现并同步进度
5. 复盘沉淀到 skill

## version 目录
- 规范说明：`version/README.md`
- 模板文件：`version/v1.0.0-功能开发模板.md`

## 三端引入命令（给 Agent 直接执行）

```bash
# Cursor
mkdir -p .cursor/rules
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/.cursor/rules/00-project-bootstrap.mdc" ".cursor/rules/00-project-bootstrap.mdc"
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/.cursorrules" ".cursorrules"

# Codex
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/AGENTS.md" "AGENTS.md"

# Claude Code
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/CLAUDE.md" "CLAUDE.md"
```

## 维护约定
- 技能只维护在 `skills-shared/`
- 一个技能一个目录，最少包含 `SKILL.md`
- 入口文件只维护加载规则，不重复写技能细节