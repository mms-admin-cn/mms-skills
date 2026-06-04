---
name: hbuilderx-automation
description: HBuilderX CLI 自动化技能；用于普通 uni-app 项目的 H5/Web、App Android/iOS、小程序编译运行、设备列表、日志、截图与失败排查。用户提到 HBuilderX、uni-app、运行到浏览器、运行到手机、打包、真机日志、H5 端口、manifest/pages 配置时使用。
---

# HBuilderX 自动化（普通 uni-app）

## 使用边界

使用本技能处理普通 uni-app 项目：H5/Web、本地浏览器预览、App Android/iOS、微信/支付宝等小程序目标，以及 HBuilderX CLI 驱动的编译、运行、日志和截图。

本技能只保留普通 uni-app 工作流。遇到不属于普通 uni-app 的历史项目类型时，不沿用旧项目规则，先与用户确认当前目标栈。

## CLI 定位

macOS 默认优先使用：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli
```

如果不存在，先定位 HBuilderX：

```bash
mdfind 'kMDItemFSName == "HBuilderX.app"'
```

确认 CLI 能力：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli help
```

## 常用命令

打开或导入项目：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli project open --path /absolute/path/to/project
```

查看已导入项目：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli project list
```

运行 H5/Web：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli launch web --project /absolute/path/to/project --compile true --continue-on-error false --browser Built
```

查看 Android 设备：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli devices list --platform android
```

运行到 Android：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli launch app-android --project /absolute/path/to/project --deviceId <device-id> --compile false --native-log true --continue-on-error false
```

读取最近一次 Android 日志：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli logcat app-android --project /absolute/path/to/project --mode lastBuild
```

截图：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli screencap app-android --project /absolute/path/to/project --deviceId <device-id> --saveFile /absolute/path/screenshot.png --fullPage false
```

## 执行流程

1. 先确认项目类型是普通 uni-app。
2. 读取项目脚本、`manifest.json`、`pages.json`、`package.json`，判断目标端和构建命令。
3. 如果项目有现成测试或 lint，先跑快速本地检查。
4. 按用户目标运行 HBuilderX H5/Web、App 或小程序目标。
5. 编译失败时读取第一段真实错误，优先定位到文件、行列、插件名、目标平台。
6. 修改后重跑失败目标；涉及 UI 或设备行为时补截图或日志佐证。
7. 回报时给出实际命令、目标端、运行 URL/设备 ID、错误是否已消除、剩余风险。

## H5/Web 端口处理

HBuilderX Web 通常从 `http://localhost:5173/` 开始，但端口被占用时可能漂移到 `5174` 或其他端口。始终以 HBuilderX 输出的实际 URL 为准，不要固定假设 5173。

如果页面打不开，按顺序检查：

- HBuilderX 输出的 Vite URL 是否仍在监听。
- 路由模式是否与访问路径匹配，尤其是 hash/history 差异。
- 控制台是否有资源 404、跨域、运行时异常。
- `manifest.json`、`pages.json` 是否能被 JSON 解析，入口页面是否存在。

## 普通 uni-app 常见排查点

- `pages.json` 页面路径大小写、分包路径、tabBar 页面是否与文件一致。
- `manifest.json` appid、平台配置、权限、横竖屏、图标与启动页配置是否完整。
- H5 静态资源路径与 `publicPath` / `base` 是否匹配部署环境。
- App 端原生插件、权限、Android 包名、证书、离线 SDK 版本是否匹配。
- 小程序端条件编译、平台 API、分包大小、隐私权限声明是否符合目标平台要求。
- Sass/Less、Babel、Vite/Webpack、uni_modules 依赖缺失时，先按包管理器恢复依赖，再重跑 HBuilderX。

## 失败判断

失败信号：

- CLI 直接返回非 0 退出码。
- 日志中出现明确 `error`、`Module not found`、`Cannot find module`、语法错误、平台插件编译失败。
- H5/Web 没有输出可访问 URL，或 URL 访问后入口脚本加载失败。
- App 真机运行没有启动成功标记，且 `logcat` 有崩溃或安装失败原因。

警告不默认视为失败，但如果警告涉及即将废弃、权限、签名、隐私合规或目标平台审核，应在结果中单独列出。

## 交付说明

回报时包含：

- HBuilderX CLI 路径与版本信息，如果日志可见。
- 实际执行的目标端和命令。
- H5/Web 实际 URL，或 App 设备 ID。
- 是否编译/运行成功。
- 关键错误摘要与修复点。
- 已运行的测试、日志检查或截图验证。
