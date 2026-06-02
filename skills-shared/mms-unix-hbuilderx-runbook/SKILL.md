---
name: mms-unix-hbuilderx-runbook
description: >-
  Runs and troubleshoots mms-unix Uni-App X projects with HBuilderX. Use when compiling or running H5/Web, Android App, HBuilderX CLI, UTS/UVue errors, ClassCastException, Android landscape orientation, UCSS compatibility, emulator/device launch, or logcat diagnosis.
---

# mms-unix HBuilderX 运行与排障

## 调用时机

遇到以下任务先读取本技能：

- 编译、运行、验证 `mms-unix` 的 H5/Web 或 Android App。
- 排查 HBuilderX CLI、Uni-App X、UTS、UVue、UCSS 相关问题。
- 排查 Android 横屏、启动、运行时崩溃、`ClassCastException`。
- 判断 HBuilderX 日志里的“已停止运行”是否代表失败。
- 处理端口漂移、内置浏览器连接、设备运行、`logcat` 诊断。

## 权威来源

源文档：`/Users/shanpengnian/MyWork/mms-cashier/mms-unix/docs/uni-app-x-hbuilderx-runbook.md`

维护规则：HBuilderX 版本、固定命令或排障结论变化时，先对照源文档刷新本技能。

## 适用范围

- 工程：`mms-unix`
- 技术栈：uni-app x、uvue、uts、ucss、HBuilderX CLI
- 目标端：H5/Web、Android App 基座
- 常见问题：H5 端口漂移、Android 横屏、App UTS 编译错误、运行时 `ClassCastException`、组件 UCSS 兼容

## 固定命令

### Node 门禁

```bash
npm test
npm test -- tests/mms-unix-component-compat.test.js
npm test -- tests/mms-unix-component-upgrade-doc.test.js
```

### H5/Web

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli launch web \
  --project /Users/shanpengnian/MyWork/mms-cashier/mms-unix \
  --compile true \
  --continue-on-error false \
  --browser Built
```

### Android 编译

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli launch app-android \
  --project /Users/shanpengnian/MyWork/mms-cashier/mms-unix \
  --compile true \
  --continue-on-error false \
  --cleanCache false
```

### Android 设备

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli devices list --platform android

/Applications/HBuilderX.app/Contents/MacOS/cli launch app-android \
  --project /Users/shanpengnian/MyWork/mms-cashier/mms-unix \
  --deviceId emulator-5554 \
  --compile false \
  --native-log true \
  --continue-on-error false

/Applications/HBuilderX.app/Contents/MacOS/cli logcat app-android \
  --project /Users/shanpengnian/MyWork/mms-cashier/mms-unix \
  --mode lastBuild
```

## 成功标记

HBuilderX 编译成功要看到：

```text
项目 mms-unix UTS编译完毕。
ready in ...ms.
```

`--compile true` 模式下，日志末尾出现红色 `已停止运行...` 不等于编译失败。只要前面已出现 `UTS编译完毕`，通常表示编译型运行会话结束。

Android 运行成功还要查看 `lastBuild`：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli logcat app-android \
  --project /Users/shanpengnian/MyWork/mms-cashier/mms-unix \
  --mode lastBuild | rg "应用【mms-unix】已启动|ClassCastException|error:|warning:|UTS编译完毕"
```

## H5 端口判断

- HBuilderX Web 默认尝试 `5173`。
- 端口占用时会自动切到下一个端口，例如 `http://localhost:5174/`。
- 排查 H5 时以 HBuilderX 输出的 Vite URL 为准，不要固定只看 `5173`。
- `Failed to connect to /127.0.0.1:8002` 优先判断为 HBuilderX 内部调试服务断开，不直接等同于业务 H5 失败。

处理顺序：

1. 重新运行 H5/Web 命令。
2. 使用日志里最新的 Vite URL。
3. 若 `5173` 不通，检查是否切到 `5174` 或更高端口。
4. 再看浏览器控制台和页面路由，例如 `/#/pages/order/order`。

## Android 横屏规则

`mms-unix` 是横屏收银台。横屏配置必须同时满足：

- `manifest.json`：`app.screenOrientation`、`app-android.screenOrientation`、`app-ios.screenOrientation` 包含 `landscape-primary`。
- `pages.json.globalStyle.pageOrientation` 为 `landscape`。

HBuilderX 5.07 的 uni-app x Android 输出会消费 `pages.json.globalStyle.pageOrientation`，并写入 Android 产物分发配置。

编译后检查 Android 产物：

```bash
node -e "const fs=require('fs'); const m=JSON.parse(fs.readFileSync('mms-unix/unpackage/dist/dev/app-android/manifest.json','utf8')); console.log(JSON.stringify({screenOrientation:m['app-android']?.screenOrientation, uniAppX:m['app-android']?.distribute?.['_uni-app-x_'], globalStyle:m['app-android']?.distribute?.globalStyle}, null, 2));"
```

期望包含：

```json
{
  "screenOrientation": ["landscape-primary"],
  "uniAppX": { "pageOrientation": "landscape" },
  "globalStyle": { "pageOrientation": "landscape" }
}
```

不要在 `App.uvue` 里为了锁屏直接写 `plus as any` 或 `uni as any`。当前项目用 manifest + `pageOrientation` 管横屏。

## App UTS 常见根因

### Typed config 不能直接当 UTSJSONObject

如果 Android 运行时报：

```text
java.lang.ClassCastException: uni.UNI7957209.AppConfig cannot be cast to io.dcloud.uts.UTSJSONObject
```

处理原则：不要把 typed business config 直接传给会按 `UTSJSONObject` 下标读取的工具。桥接边界要显式构造 `new UTSJSONObject()` 树，再调用注入函数。

### H5 能跑不代表 App UTS 能编译

App UTS 更严格，优先检查：

- 非 boolean 条件：字符串、对象、数组、nullable 值不能直接 truthy 判断。
- 模板表达式里混用 `||`、`&&` 返回非 boolean 值。
- `.uvue` 事件参数解构。
- `Number(value)`、`String(value)` 构造器。
- `unknown`、`undefined`、类型谓词、索引签名、inline object literal types。
- 从 `UTSJSONObject` 下标值直接赋给具体 string/number。
- typed state update 中使用 object spread / array spread。
- boxed number、`Any?` 与数字使用 identity equality。

每修一个 HBuilderX 编译模式，都要补一个静态守卫到 `tests/mms-unix-component-compat.test.js`。

## UCSS 保守子集

页面和组件默认按 App 原生 UCSS 子集写：

- 使用 flex，避免 CSS Grid、float、复杂定位。
- 优先单 class 选择器，避免伪类、伪元素、属性选择器和 tag selector。
- 避免 `gap`、CSS 变量、`calc()`、viewport units、`@keyframes`、`animation`。
- 文本颜色、字号、行高写在真实渲染的 `text`、`button`、`input` 或内部内容容器上。
- `scroll-view` 区域要有明确可见高度来源，避免 App 端滚动高度塌陷。

更细规则见：`mms-unix/uni_modules/m-unix/docs/ucss-cheatsheet.md`。

## 排障顺序

1. 先跑目标 Node 测试，确认静态契约未破。
2. 再跑 H5/Web，确认页面和路由能打开。
3. 再跑 Android compile-only，读取第一段真实 App UTS 错误。
4. 若 compile-only 通过，再运行到设备。
5. 运行时崩溃看 `logcat --mode lastBuild`，搜索 `ClassCastException`、`ProjectConfig`、`error:`。
6. 横屏/启动类问题检查 Android 输出 manifest，而不是只看源 `manifest.json`。
7. 每个已修根因补测试或文档守卫。

## 关联技能

- HBuilderX CLI 自动化闭环：`hbuilderx-automation`
- 研发流程：`mms-dev-workflow`
- 同步接口契约：`mms-unix-sync-api-contract`
- `mms-unix` 编码与组件约束：`mms-unix-coding-standards`、`m-unix-component-api`、`uni-app-x-ucss`