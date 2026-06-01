# 共享技能库（skills-shared）

`skills-shared/` 是本仓库唯一技能来源，供 `Cursor / Codex / Claude Code` 共用。

## 目录约定
- 一个技能一个目录
- 最少包含：`SKILL.md`
- 可选：`references/`、`scripts/`、`assets/`

## 默认工作流技能
- `mms-dev-workflow`
- 路径：`skills-shared/mms-dev-workflow/SKILL.md`
- 作用：串联“需求分析 -> version文档 -> 开发 -> 进度同步 -> 复盘沉淀”

## 强制规范（通过工作流执行）
1. 全部中文回答（代码/命令/日志原文除外）
2. 新功能先分析
3. 先建版本文档 `version/vX.Y.Z-功能说明.md`
4. 版本号递增
5. 开发过程同步任务进度
6. 完成后复盘并沉淀 skill

## 技能分层建议
- `mms-*`：mms 脚手架专用
- 通用工程：测试、审计、迁移、排障、文档
- 外部生态入口：MCP、编排框架、增强工具

## 维护规范
- 新增或更新技能，仅修改 `skills-shared/`
- 入口文件（`AGENTS.md` / `CLAUDE.md` / Cursor rules）只维护加载规则
- 不在多个入口重复维护技能细节