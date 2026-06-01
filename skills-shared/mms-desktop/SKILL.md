---
name: mms-desktop
description: >-
  指导使用仓库内 mms-desktop 工程（Tauri 2）将任意 Vue/Vite/Vue CLI 产出的 dist（含 index.html 与静态资源）打成 Windows、macOS、Linux 桌面包；
  涵盖目录约定、npm scripts、Tauri 配置、与 mms-ui dist 对接、白屏与路由排查。
  触发词：mms-desktop、Vue dist 桌面、Tauri、把 H5 包成 exe/dmg、桌面壳。
---

# mms-desktop：Vue `dist` → Win / macOS / Linux 桌面（Tauri）

## 1. 定位

- **工程路径**：仓库根 **`mms-desktop/`**。
- **技术栈**：[Tauri 2](https://v2.tauri.app/)（Rust + 系统 WebView）。
- **前端**：仍是根目录 **`dist/`**（由 Vue 构建产出；可用 **`npm run init`** 生成占位页）。

## 2. 相关技能

- 仓库内 **`mms-desktop` 仅支持 Tauri**，不再维护 NW.js 壳。
- UniApp H5 若需 **NW.js + nwjs-packager** 自建桌面包流程，见 **`.cursor/skills/mms-unix-desktop-nw-legacy/SKILL.md`**（与 **mms-desktop** 无代码复用）。

## 3. 目录（摘要）

```text
mms-desktop/
├── package.json           # npm scripts，devDependencies: @tauri-apps/cli, sirv-cli
├── dist/                  # Vue 构建产物（至少 index.html）
├── icons/                 # 品牌用 icon.png（方形）等；见 icons/README.md
├── scripts/check-rust.cjs # predev/prebuild：确认 cargo 在 PATH
├── scripts/init-dist.cjs  # 占位 dist/index.html
└── src-tauri/             # Tauri：tauri.conf.json、Cargo.toml、Rust 源码、icons/
```

## 4. 标准流程

### 4.1 拷贝 Vue dist

```bash
rm -rf mms-desktop/dist
cp -R mms-ui/dist mms-desktop/dist
```

### 4.2 安装与调试

需本机已装 **Rust** 与 **Tauri 前置**（见官网 Prerequisites）。

```bash
cd mms-desktop && npm install
npm run init        # 若尚无 dist/index.html
npm run dev         # sirv 本地静态站 + Tauri WebView
```

### 4.3 发布构建

```bash
cd mms-desktop && npm run build
```

产物通常在 **`src-tauri/target/release/bundle/`**；**交叉编译**需自行配置 Rust target，默认脚本不假定。

## 5. 配置入口

- **`src-tauri/tauri.conf.json`**：窗口、`identifier`、**`build.frontendDist`**、`beforeDevCommand`、`bundle` 等，详见 **`mms-desktop/CONFIG.md`**。
- **`src-tauri/capabilities/default.json`**：权限（当前仅 **`core:default`**）；扩展能力需同步改 Rust 与 capability。

## 6. 常见问题

1. **`dist/index.html` 是否存在**，相对 **`mms-desktop`** 根路径是否正确。
2. **Vite `base`**：通常为 **`'./'`**，避免静态资源绝对路径失效。
3. **history 路由**：生产包若 deep link 异常，优先 **hash**；见 **CONFIG.md** §4。
4. **图标**：**`npm run icons:tauri`** 要求 **`icons/icon.png` 为正方形**。
5. **Rust / WebView 依赖缺失**：按 Tauri 官方 Prerequisites 安装。

## 7. 参考文件

- **`mms-desktop/CONFIG.md`**：配置字段与 FAQ。
- **`mms-desktop/README.md`**：命令速览与说明。
- **`mms-desktop/icons/README.md`**：图标生成。

**原则**：Vue 只产出 **`dist`**；**mms-desktop** 只负责 **Tauri 壳与安装包**。
