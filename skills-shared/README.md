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
- 系统/插件镜像：从 Codex 系统技能与本机插件缓存中可扫描到的技能同步而来，作为当前会话可见技能的项目快照；实际使用时仍依赖对应运行环境或插件工具支持

## 当前已同步的系统/插件镜像

| 来源 | 技能目录 |
|------|----------|
| Codex 系统技能 | `imagegen`、`openai-docs`、`plugin-creator`、`skill-installer` |
| Codex 本机技能 | `hatch-pet` |
| Browser / Chrome | `control-in-app-browser`、`control-chrome` |
| LaTeX | `latex-compile`、`latex-doctor`、`texlive-runtime-installer` |
| Figma | `figma-use`、`figma-use-figjam`、`figma-use-slides`、`figma-code-connect`、`figma-create-new-file`、`figma-generate-design`、`figma-generate-diagram`、`figma-generate-library` |
| Hyperframes | `hyperframes`、`hyperframes-cli`、`hyperframes-registry`、`gsap`、`website-to-hyperframes` |
| Supabase | `supabase`、`supabase-postgres-best-practices` |
| Superpowers 扩展 | `brainstorming`、`dispatching-parallel-agents`、`finishing-a-development-branch`、`subagent-driven-development`、`using-git-worktrees`、`verification-before-completion`、`writing-skills` |
| 文档运行时 | `documents`、`presentations`、`spreadsheets` |

## 常用技能索引

| 场景 | 优先技能 | 触发语义 |
|------|----------|----------|
| Codex 插件市场安装与排障 | `codex-plugin-marketplace` | Codex 插件不能安装、插件页无安装入口、marketplace、openai-curated、codex plugin marketplace |
| uni-app Vue3 全流程交付 | `uniapp-vue3-workflow` | uni-app Vue3、uv-ui、create-uni、HBuilderX 脚手架、环境变量、自动化测试、打包、H5/App/小程序发布、服务器部署 |
| 普通 uni-app 编译运行闭环 | `hbuilderx-automation` | HBuilderX CLI、uni-app、compile、run、debug、verify、H5/Web、Android、iOS、小程序、device logs、screenshots |

多技能场景先读取主技能，再读取关联技能。例如：用户只说一个 uni-app Vue3 需求时，先读 `uniapp-vue3-workflow` 串起分析、设计、开发、验证、测试、打包和部署；需要实际驱动 HBuilderX CLI 编译、运行、看设备日志或截图时，再读 `hbuilderx-automation`。

## 维护规范
- 新增或更新技能，仅修改 `skills-shared/`
- 入口文件（`AGENTS.md` / `CLAUDE.md` / Cursor rules）只维护加载规则
- 不在多个入口重复维护技能细节
- 同步外部技能时按 `name:` 判重，保留项目已有同名技能，只新增缺失目录
