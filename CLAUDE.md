# Claude Code 引导

本仓库技能统一维护在共享目录 `skills-shared/`，入口文件只负责选择技能和约束流程。

## 技能根目录

`/Volumes/SXPCWLKJ/MyWork/mms-skills/skills-shared`

若此路径不可访问，优先使用当前项目内的 `skills-shared/`，或环境变量 `MMS_SKILLS_HOME` 指向仓库下的 `skills-shared/`。

## 默认原则

默认不加载技能。先按任务复杂度分级，再决定是否读取 `SKILL.md`。

- **Level 0：纯问候 / 琐碎请求**：如 `在吗`、`谢谢`、改颜色、修拼写、改一行配置。直接回复或直接改，不读技能，不建版本文档。
- **Level 1：简单明确任务**：如单一 bug、小字段、小样式。快速分析后实施；需要时只读一个相关技能。
- **Level 2：中等功能 / 多文件变更**：读取 `mms-dev-workflow/SKILL.md`，按分析、版本文档、开发、验证、复盘执行。
- **Level 3：复杂系统 / 从零构建**：读取 `brainstorming/SKILL.md`，再按需进入 `writing-plans` 或并行开发流程。

## 技能选择

1. 只有 Level 2/3、用户明确点名技能、或明显领域任务时才读取技能。
2. 一个任务只用一个主流程技能：已有项目功能迭代用 `mms-dev-workflow`，从零设计用 `brainstorming`。
3. 用户说“快速改”“直接改”“just do it”“不用走流程”时，直接按 Level 0/1 执行。
4. 多技能场景先主后辅，例如 uni-app 打包部署可先读 `uniapp-vue3-workflow`，需要服务器时再读 `mms-ssh-connect`。

## 输出与安全

- 全程使用简体中文沟通与输出（代码、命令、日志原文除外）。
- 涉及生产发布、服务器写操作、数据库写入、删除文件、真实密钥等外部状态变更时，先说明影响并等待明确确认。
- 不复述密钥、密码、证书内容。
- 若技能与用户当前明确要求冲突，以用户当前要求优先。
