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

## mms-unix 调用关联

| 场景 | 优先技能 | 触发语义 |
|------|----------|----------|
| 通用 HBuilderX 自动化、编译运行闭环 | `hbuilderx-automation` | HBuilderX CLI、Uni-App X、compile、run、debug、verify、Web/H5、Android、iOS、Harmony、device logs、screenshots |
| 离线同步、接口契约、补传队列 | `mms-unix-sync-api-contract` | `syncQueue`、MMS Admin、同步接口、订单同步、会员操作、券码核销、基础资料同步、App 版本检测 |
| HBuilderX 运行、Uni-App X 排障 | `mms-unix-hbuilderx-runbook` | H5/Web、Android App、HBuilderX CLI、UTS、UVue、UCSS、横屏、logcat、ClassCastException |
| 组件 API、事件、v-model | `m-unix-component-api` | `m-*` 组件、`pages_demo`、`emits`、`v-model`、演示路由 |
| 组件文档更新 | `mms-unix-doc` | 更新 mmsUnix 文档、VitePress、演示地址、pathMap |

多技能场景先读取主技能，再读取关联技能。例如：离线同步接口联调失败且需要跑 Android 时，先读 `mms-unix-sync-api-contract`，再读 `mms-unix-hbuilderx-runbook`；需要实际驱动 HBuilderX CLI 编译、运行、看设备日志或截图时，再读 `hbuilderx-automation`。

## 维护规范
- 新增或更新技能，仅修改 `skills-shared/`
- 入口文件（`AGENTS.md` / `CLAUDE.md` / Cursor rules）只维护加载规则
- 不在多个入口重复维护技能细节