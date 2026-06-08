# Codex Agent 引导

本仓库采用共享技能库模式，`skills-shared/` 是唯一技能来源（SSOT）。入口文件只负责路由与优先级，不复制技能正文。

## 技能根目录

`/Volumes/SXPCWLKJ/MyWork/mms-skills/skills-shared`

若此路径不可访问，优先使用当前项目内的 `skills-shared/`，或环境变量 `MMS_SKILLS_HOME` 指向仓库下的 `skills-shared/`。

## 默认原则：不预加载技能

大多数对话不需要技能。先判断任务复杂度，再决定是否读取 `SKILL.md`。

### Level 0：纯问候 / 琐碎请求

- 示例：`在吗`、`你好`、`谢谢`、`好的`、`现在几点`、改拼写、改颜色、改一行配置。
- 行为：直接回复或直接修改，不读取任何技能，不创建版本文档。

### Level 1：简单明确任务

- 示例：单一 bug、小字段、小样式、小组件、原因明确的报错。
- 行为：快速分析后直接实施；需要时只读一个相关技能，如 `systematic-debugging` 或 `test-driven-development`。
- 不走 `mms-dev-workflow`，不强制创建版本文档。

### Level 2：中等功能 / 多文件变更

- 示例：新增页面、新增业务功能、跨模块联动、接口对接。
- 行为：读取 `mms-dev-workflow/SKILL.md`，按“分析 -> version 文档 -> 开发 -> 验证 -> 复盘”执行。

### Level 3：复杂系统 / 架构变更 / 从零构建

- 示例：新子系统、重构架构、从零搭建产品、多服务协作。
- 行为：优先读取 `brainstorming/SKILL.md`，再按需进入 `writing-plans` / `subagent-driven-development`。

## 技能选择规则

1. 只有 Level 2/3、用户明确点名技能、或明显领域任务时才读取技能。
2. 一个任务只选择一个主流程技能：已有项目功能迭代用 `mms-dev-workflow`，从零设计用 `brainstorming`，不要两套流程并行。
3. 领域技能只在命中场景时读取，例如：
   - uni-app / HBuilderX / 打包发布：`uniapp-vue3-workflow` 或 `hbuilderx-automation`
   - SSH / 服务器部署：`mms-ssh-connect`
   - MMS 插件 JAR：`mms-plugin`，检查验收用 `mms-plugin-check`
   - 数据库连接：`mms-db-connect`
4. 用户说“快速改”“直接改”“just do it”“不用走流程”时，立即跳过流程技能，按 Level 0/1 执行。

## 输出与安全规范

1. 全部中文回答（代码、命令、日志原文除外）。
2. 涉及真实密钥、服务器写操作、生产发布、数据库写入、删除文件等外部状态变更时，先说明影响并等待明确确认。
3. 不复述密钥、密码、证书内容；只说明配置文件路径和缺失项。
4. 若技能与用户当前明确要求冲突，以用户当前要求优先。

## 维护约定

- 技能正文只维护在 `skills-shared/<skill>/SKILL.md`。
- 新增或更新技能后，同步更新 `skills-shared/README.md` 或相关索引。
- 中等以上新功能按 `mms-dev-workflow` 创建递增版本文档：`version/vX.Y.Z-功能说明.md`。
