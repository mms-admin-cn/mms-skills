---
name: playwright-mcp
description: 基于 MCP 的浏览器自动化测试入口（E2E、截图、回归）
---

# Playwright MCP

## 来源
- GitHub: https://github.com/anthropics/mcp-server-playwright

## 适用场景
- Web/收银台流程自动回归
- UI 交互验证与截图留证

## 使用约定
1. 先定义关键用户路径（点餐、结算、核销）。
2. 再编排自动化步骤与断言。
3. 保留截图/日志作为回归基线。