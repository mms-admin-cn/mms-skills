---
name: m-unix-component-api
description: >-
  Defines mUnix (m-unix) uni-app x component API conventions for props, emits, v-model,
  demo registration in pages.json subPackages, and Tab 组件首页入口. Use when adding
  or refactoring m-* components, writing pages_demo examples, fixing broken
  @listeners, or auditing two-way binding.
---

# mUnix 组件 API、事件与 v-model 规范

本 Skill 固化「新增/改版组件」时易错点：**演示与实现 API 不一致**、**有 `$emit` 无 `emits`**、**显隐类 props 未配套 `update:*`**、**命名别名未统一**等。与 `.cursor/skills/mms-unix-coding-standards/SKILL.md`（结构/目录/样式归属）配合使用。

## 适用场景

- 新建 `uni_modules/m-unix/components/m-*/m-*.uvue`
- 为组件补充能力或修 bug
- 编写/修改 `pages_demo/*` 演示
- 用户反馈「写了 `@xxx` 没反应」「`v-model` 不同步」

## 核心规则

### 0. 根节点外覆样式：`customStyle`

- 业务侧用 **`:customStyle`** 传入 **`UTSJSONObject`**（与内置 `rootStyle` / `boxStyle` 等合并，**后写覆盖先写**）。
- **不要**依赖在自定义组件标签上写原生 `style`（各端透传不一致）；以各组件文档与实现为准。
- 本库已支持或已合并 `customStyle` 的示例：`m-card`、`m-tag`、`m-cell`，以及带 `rootStyle` 的 `m-banner-arc`、`m-section`、`m-form`、`m-code-input`、`m-tabs`、`m-notice-bar`、`m-rolling-news`、`m-segmented-control`、`m-bubble-popup`、`m-watermark`、`m-countdown-verify` 等。

### 1. `emits` 与 `$emit` 必须一致

- 组件内每出现一种 `this.$emit('eventName', ...)`，**必须在 `emits` 数组中声明**同名事件（含 `update:modelValue`、`update:show` 等）。
- 避免演示或业务写 `@confirm`、`@after-read` 而组件从未声明、从未触发。

### 2. 受控显隐与双向绑定

若父组件通过布尔值控制显示（如弹窗、抽屉），须同时支持：

- **单向**：`:show="x"` / `:visible="x"` + `@close` 里父级改 `x`
- **双向**：`v-model:show` 或 `v-model:visible`，关闭时在组件内 **`$emit('update:show', false)`** / **`$emit('update:visible', false)`**（可与 `close` 一起发）

**常见事故**：演示用 `visible`，实现只认 `show`，导致永远不显示。处理方式二选一（已在本库部分组件采用）：

- **推荐**：对外只文档化一个主名（如 `show`），演示统一用主名；或
- **兼容**：同时提供 `show` 与 `visible`，内部合并为同一「是否打开」状态，关闭时两个 `update:*` 都发（便于 `v-model:visible` 与旧代码并存）。

关闭路径（遮罩、关闭按钮、确认后关闭等）**每条路径**都要走到上述 `update:*`，否则 `v-model` 会残留为 `true`。

### 3. 表单类/列表类：主 prop 与 v-model 命名

- 单值输入优先：**`modelValue` + `update:modelValue`**，并视需要保留 `input` 等与生态兼容的事件（如搜索框）。
- 文件/列表类若社区常用名与实现名不同（如 **`fileList` vs `files`**）：
  - 在组件内用 **`resolved*` 计算属性**统一数据源；
  - 更新时若需兼容两种绑定，可同时 **`$emit('update:files', next)`** 与 **`$emit('update:fileList', next)`**（或只文档化一种 v-model，避免双写）。

### 4. 事件别名与生态命名

- 规范层面事件名用 **kebab-case** 拼在模板上（如 `@update:visible`、`@overlay-click`）；`$emit` 字符串使用与之对应的 camelCase 段（如 `overlay-click` 保持带连字符时与 Vue 文档一致）。
- 若业务侧已使用历史事件名（如 **`afterRead` 对应选图回调**），而内部已用 `choose`：
  - **可同时 `$emit('choose', payload)` 与 `$emit('afterRead', payload)`**（同一 payload），并在 `emits` 中两者都声明，避免只改演示不改组件。

### 5. 平台差异（如选图）

`uni.chooseImage` 等 API 在不同端可能侧重 **`tempFiles`** 或 **`tempFilePaths`**。封装时应在 **一处** 归一成统一结构再 `emit`，避免演示里写死一种字段导致真机不触发。

### 6. 演示页 `pages_demo` 与组件必须同源

- 演示里出现的 **props 名、事件名、`v-model` 修饰符**须与组件实现一致；发现不一致时 **优先改组件对外 API（若已公开则做兼容）或改演示**，禁止长期「演示假接口」。
- 样式归属仍遵循 `mms-unix-coding-standards`：**外观在组件内，演示只做分区与文案**。

### 7. 演示路由登记与「组件」Tab 入口

- **分包注册**：每新增一个 `pages_demo/.../*.uvue` 演示页，必须在 `pages.json` → `subPackages` → `root: "pages_demo"` 的 `pages` 数组中增加对应 `path`；否则无法 `navigateTo`。
- **跳转路径**：使用 **`/pages_demo/...`** 形式（见 `mms-unix-coding-standards` 主包/分包约定），与主包 `pages/*` 路径区分。
- **组件首页列表**：当前工程在 `pages/components/components.uvue` 用 `componentCategories`（标题、主题色、`items`）驱动分类网格；**新组件若要从该页进入**，需在该数据中增加一项或归入已有分类，避免「有演示页但首页进不去」。

## 新增组件自检清单（建议逐项打勾）

- [ ] 所有 `$emit` 已列入 `emits`
- [ ] 需要受控显隐时：提供 `update:show` / `update:visible`（或统一文档化的一种）且所有关闭路径都会触发
- [ ] 需要 `v-model` 时：成对出现 `xxx` + `update:xxx`（或 `modelValue` / `update:modelValue`）
- [ ] 列表/文件类：prop 命名与 v-model 名在演示与 README/注释中一致；若有别名，内部已合并数据源并同步更新事件
- [ ] `pages_demo` 中示例可运行（事件有响应、双向绑定关闭后状态复位）
- [ ] `pages.json` 已登记分包页；若需从 Tab「组件」进入，已更新 `pages/components/components.uvue` 的分类数据
- [ ] 纯展示组件可不提供 v-model；若文档写了 `@click`，需有对应 `emit` 或改为外层 `view` 包裹处理

## 本库参考实现（查阅用）

| 能力 | 参考组件 |
|------|----------|
| 文本 v-model + 多事件 | `m-search` |
| 显隐 + `visible`/`show` 兼容 + `v-model` | `m-popup`、`m-dialog` |
| 列表 v-model + 事件别名 | `m-upload`（`files` / `fileList`，`choose` / `afterRead`） |
| 弹层内再包弹层 | `m-datetime-picker`（内层关闭需同步外层 `show`） |
| 业务用 `update:popupShow` | `m-login` |

## 与「仅展示」组件的边界

`m-card`、`m-price`、`m-empty` 等无状态展示组件**不强制** v-model；若要在文档中支持点击，应显式增加 `click` 的 `emit` 与 `emits` 声明，或在文档中说明由外层 `@tap` 处理。
