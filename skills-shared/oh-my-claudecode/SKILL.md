---
name: oh-my-claudecode
description: 多角色协同开发编排（任务拆分、并行执行、恢复机制）
---

# Oh My Claude Code

## 来源
- GitHub: https://github.com/Yeachan-Heo/oh-my-claudecode

## 适用场景
- 复杂业务系统开发（多模块并行）
- 需求拆解为多角色流水线（架构/实现/评审/测试）

## 使用约定
1. 先定义任务边界与输入产物。
2. 再配置角色分工与交付物格式。
3. 执行时保留中间状态，便于断点恢复。

## 在本仓的定位
- 作为“多角色编排框架”入口技能使用。
- 具体实现以上游仓库文档和脚本为准。