---
name: mms-unix-desktop-nw-legacy
description: >-
  指导将 UniApp X / uni-app x 的 H5 产物与 NW.js、nwjs-packager、nw-builder、Inno Setup 组合为 Windows/macOS/Linux 桌面应用与安装包（安装向导 .exe、.dmg、.deb/.rpm）。
  仓库内通用 Vue 工程 **`mms-desktop/` 已改用 Tauri 2**（见 skills **`mms-desktop`**），本技能仍面向 **NW.js + UniApp/自建流程**。
  涵盖目录结构、package.json、npx nwp 与 npm scripts、nw 本地调试，以及白屏、Node 集成、安装包体积、多平台图标等问题。
  在用户讨论 H5 出桌面壳、桌面端打包、NW.js、nw、nwjs-packager、nw-builder、安装程序、离线桌面包或 nwp 时使用。
---

# UniApp X + NW.js 桌面安装包（nwjs-packager）

> **仓库现状**：**`mms-plus/mms-desktop`** 已固定为 **Tauri 2** 工程；请勿在该目录按 NW.js / `nwp` 维护。NW.js 内容仅适用于 **UniApp 自建工程** 或本文档模板。

## 1. 描述与适用范围

用于 **UniApp X + NW.js** 的桌面端安装包制作：把 H5 产物包装为桌面应用，并用 **nwjs-packager**（或 nw-builder）生成带安装向导的安装包。

## 2. 触发场景

- 将 UniApp X 项目打成桌面应用
- 制作 NW.js 安装包（含安装向导）
- 生成 `.exe` 安装程序或 `.dmg` 等镜像
- 配置 `nwjs-packager` 或 `nw-builder`
- 排查桌面端打包相关问题（白屏、图标、体积等）

---

## 3. 工具选型

| 工具 | 适用场景 | 推荐度 |
|------|----------|--------|
| **nwjs-packager** | 上手快、自动拉取 NW.js，可接 Inno Setup 生成安装向导 | 高（默认首选） |
| **nw-builder** | 功能多、配置灵活 | 中高 |
| **手动 + Inno Setup** | 完全自控，脚本成本高 | 进阶 |

---

## 4. 标准目录结构

```
my-desktop-app/
├── package.json      # NW.js + nwjs-packager 配置
├── index.html        # 入口（或指向 H5 产物 / 本地服务）
├── dist/             # UniApp X H5 产物
│   ├── index.html
│   ├── assets/
│   └── ...
├── icons/            # 应用图标
│   ├── icon.ico      # Windows
│   ├── icon.icns     # macOS
│   └── icon.png      # Linux
└── build/            # 打包输出（工具生成，勿手改）
```

---

## 5. package.json 完整模板

```json
{
  "name": "my-uniapp-desktop",
  "version": "1.0.0",
  "description": "基于 UniApp X + NW.js 的桌面应用",
  "main": "dist/index.html",
  "node-remote": "*",
  "window": {
    "title": "我的 UniApp 桌面版",
    "icon": "icons/icon.png",
    "width": 1200,
    "height": 800,
    "min_width": 800,
    "min_height": 600,
    "resizable": true,
    "fullscreen": false,
    "frame": true,
    "toolbar": false,
    "position": "center"
  },
  "chromium-args": "--enable-features=SharedArrayBuffer",
  "nwjs-packager": {
    "nwVersion": "stable",
    "platforms": ["win", "mac", "linux"],
    "appFriendlyName": "我的 UniApp 桌面版",
    "appCopyright": "Copyright © 2026",
    "appCompany": "Your Company",
    "appWinIcon": "icons/icon.ico",
    "appMacIcon": "icons/icon.icns",
    "appLinuxIcon": "icons/icon.png",
    "buildDir": "./build",
    "cacheDir": "./.nw-cache",
    "builds": {
      "win": {
        "innoSetup": true,
        "innoSetupConfig": {
          "compression": "lzma2/ultra64",
          "solidCompression": "true",
          "language": "english",
          "licenseFile": "LICENSE.txt",
          "infoBeforeFile": "info.txt",
          "setupIcon": "icons/setup.ico",
          "outputDir": "./build/installers/win",
          "installerName": "MyApp-Setup-${version}.exe"
        }
      },
      "mac": {
        "dmg": true,
        "icon": "icons/icon.icns",
        "plist": {
          "CFBundleIdentifier": "com.yourcompany.myapp",
          "CFBundleVersion": "1.0.0"
        }
      },
      "linux": {
        "deb": true,
        "rpm": true,
        "icon": "icons/icon.png",
        "categories": ["Utility", "Development"]
      }
    }
  },
  "scripts": {
    "build": "npx nwp",
    "build:win": "npx nwp --platform win",
    "build:mac": "npx nwp --platform mac",
    "build:linux": "npx nwp --platform linux",
    "dev": "nw ."
  },
  "devDependencies": {
    "nwjs-packager": "^2.0.0"
  }
}
```

---

## 6. 标准操作流程

### 6.1 阶段一：准备

在 UniApp X 工程中生成 H5：

```bash
npm run build:h5
```

新建 NW.js 工程目录：

```bash
mkdir my-desktop-app
cd my-desktop-app
npm init -y
```

复制或软链接 H5 产物到本工程的 `dist/`：

```bash
# 复制
cp -r ../uniapp-project/dist/build/h5 ./dist

# 或软链接（开发时便于同步）
ln -s ../uniapp-project/dist/build/h5 ./dist
```

### 6.2 阶段二：配置

1. 安装依赖：`npm install nwjs-packager --save-dev`
2. 按第 5 节模板编辑 `package.json`（注意 `main` 与 H5 实际入口一致）。
3. 将图标放入 `icons/`。

### 6.3 阶段三：制作安装包

```bash
npm run build              # 全平台（与模板 scripts 一致时）
# 或
npx nwp                    # 全平台
npx nwp --platform win     # 仅 Windows
npx nwp --platform mac     # 仅 macOS
npx nwp --platform linux   # 仅 Linux
```

### 6.4 阶段四：验证产物（示例路径）

| 平台 | 示例产物路径 |
|------|----------------|
| Windows | `build/installers/win/MyApp-Setup-1.0.0.exe` |
| macOS | `build/installers/mac/MyApp-1.0.0.dmg` |
| Linux | `build/installers/linux/MyApp_1.0.0_amd64.deb` |

实际路径以 `nwjs-packager` 配置与版本为准。

---

## 7. 常见问题

### Q1：打包后白屏

检查 `package.json` 中 `main` 是否指向真实存在的 `index.html`（相对 NW 工程根目录）。

```json
{
  "main": "dist/index.html",
  "node-remote": "*"
}
```

### Q2：Node.js API 不可用

按需启用 Node 集成（具体能力以 NW.js 版本文档为准）。

```json
{
  "node-remote": "*",
  "node-main": "main.js"
}
```

### Q3：安装包体积过大

Windows 侧可提高 Inno Setup 压缩级别（与模板中 `compression` 等字段一致）。

```json
{
  "nwjs-packager": {
    "builds": {
      "win": {
        "innoSetupConfig": {
          "compression": "lzma2/ultra64"
        }
      }
    }
  }
}
```

### Q4：图标不显示

- **Windows**：`.ico`（建议含 256×256、48×48、32×32、16×16 等多尺寸）
- **macOS**：`.icns`（常见含 512、256、128、32、16 等）
- **Linux**：`.png`（如 512×512）

可用 [CloudConvert](https://cloudconvert.com/) 等工具做格式转换。

---

## 8. 快速命令参考

```bash
npm install nwjs-packager --save-dev
nw .                    # 本地调试（需已全局或 npx 可用 nw）
npx nwp                 # 打包（全平台，视配置）
npx nwp --platform win
npx nwp --platform mac
npx nwp --platform linux
```

---

## 9. 核心思路小结

- **UniApp X**：把业务编译为 **H5 产物**。
- **NW.js**：用原生壳加载 H5，提供桌面窗口与系统集成。
- **nwjs-packager**：在 NW.js 之上生成 **各平台安装包 / 安装向导**。

同一套业务代码可覆盖多端：移动端、小程序、H5 与桌面（本 Skill 聚焦桌面链路）。
