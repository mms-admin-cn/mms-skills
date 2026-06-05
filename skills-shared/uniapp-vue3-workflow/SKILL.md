---
name: uniapp-vue3-workflow
description: uni-app Vue3 全流程开发编排技能。用户提出普通 uni-app、Vue3、uv-ui、HBuilderX、H5/App/小程序、脚手架、环境变量、自动化测试、打包、发布、服务器部署等需求时必须优先使用；从一句需求主动推进分析、设计、开发、验证、测试、打包和部署，减少反复询问命令。默认结合 hbuilderx-automation、env-manager、api-tester、ui-ux-pro-max、mms-ssh-connect、mms-desktop 等技能。
---

# uni-app Vue3 全流程工作流

## 定位

本技能是普通 `uni-app Vue3` 项目的主入口。用户只说一个需求时，先按完整交付链路推进：分析需求、设计页面和数据流、创建或识别项目、接入 uv-ui、管理环境、开发实现、自动化测试、HBuilderX 运行验证、打包发布、服务器部署。

默认少问问题。只有账号、证书、服务器写操作、真实密钥、生产发布窗口这类不可推断且会改变外部状态的信息，才停下来确认。

## 先读参考

执行前按需读取：

- `references/verified-facts.md`：已验证的 uv-ui、create-uni、HBuilderX CLI 事实和命令。

## 关联技能

按场景组合使用，不要把职责都塞进本技能：

| 场景 | 关联技能 | 用法 |
|------|----------|------|
| 新功能规范流 | `mms-dev-workflow` | 先分析，再建 `version/vX.Y.Z-功能说明.md`，再开发验证 |
| HBuilderX 运行/打包/日志 | `hbuilderx-automation` | 导入项目、运行 H5/App/小程序、看日志和截图 |
| 环境变量与配置 | `env-manager` | 生成 `.env.example`、检查缺失变量、避免密钥入库 |
| API 测试 | `api-tester` | 根据接口契约生成集成测试、mock 或 curl 验证 |
| UI 设计与视觉验证 | `ui-ux-pro-max` | 页面、组件、交互、响应式与视觉 QA |
| 服务器部署 | `mms-ssh-connect` | 读取 `.mms/config/ssh-info.yml` 或旧配置，走 SSH/rsync/docker |
| 桌面包 | `mms-desktop` | H5/Vue `dist` 接 Tauri 桌面壳 |

## 默认技术决策

- 项目类型：普通 `uni-app Vue3`，不是历史项目类型。
- 脚手架：优先 `create-uni` 创建项目，再用 HBuilderX CLI `project open` 导入。
- UI：默认使用 uv-ui，优先通过 HBuilderX 插件市场或 `uni_modules` 接入；npm 方案作为备选。
- 工具函数：优先使用 uv-ui API 工具库。常见节流防抖、对象处理、时间格式化、路由跳转、参数拼接、校验、随机值、节点信息等，不要随手重复造轮子。
- 包管理器：优先沿用项目现有 lockfile；新项目默认 `pnpm`，若 HBuilderX 或依赖不兼容再退回 `npm`。
- 目标端：没特别说明时先保证 H5/Web 可运行，再按需求扩展 App 或小程序。
- 部署：H5 默认静态资源部署；App 默认先出 WGT/本地资源包，再按证书情况云打包或本地打包。

## 一句话需求处理流程

收到需求后按顺序推进：

1. **分析**：提炼业务目标、用户角色、页面/接口/状态、目标端、验收标准。
2. **设计**：给出页面结构、路由、组件拆分、数据流、环境变量、测试点。
3. **建档**：如果是新功能，按 `mms-dev-workflow` 创建递增版本文档。
4. **准备环境**：检查 Node/npm/pnpm、HBuilderX、项目依赖、`.env*`、`manifest.json`、`pages.json`。
5. **创建或接管项目**：新项目用 `create-uni`；已有项目先读结构和脚本，不重建。
6. **接入 uv-ui**：优先插件市场/`uni_modules`，配置 easycom、`main.js`、`App.vue`、`uni.scss`。
7. **开发**：实现页面、组件、状态、接口、错误态、空态、加载态；工具函数优先用 `uni.$uv` 或 uv-ui 局部引入。
8. **测试**：跑 lint/unit/API 测试；没有测试则补关键测试或最小 smoke test。
9. **运行验证**：用 HBuilderX CLI 跑 H5/Web；需要 App/小程序时再跑目标端，读日志和截图。
10. **打包部署**：按目标执行 `publish web`、`publish app`、`pack`、云托管或 SSH 部署；写操作前确认。
11. **复盘沉淀**：记录命令、问题、修复、验证结果，必要时更新技能或版本文档。

## 脚手架与导入

HBuilderX CLI 负责打开、导入、运行、发布，不负责创建脚手架。新项目先用 `create-uni`：

```bash
npm exec create-uni -- <project-name> --ts -e
```

如果用户明确不要 TypeScript，去掉 `--ts`。如果要图形交互或模板选择，可用：

```bash
npm exec create-uni -- --gui
```

创建后导入 HBuilderX：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli open
/Applications/HBuilderX.app/Contents/MacOS/cli project open --path /absolute/path/to/project
```

## uv-ui 接入规则

优先方式：HBuilderX 插件市场导入 `uv-ui` 到项目 `uni_modules`。CLI 可尝试：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli uni_modules --download uv-ui --project /absolute/path/to/project
```

若使用 npm：

```bash
npm i @climblee/uv-ui
```

然后配置 `pages.json` easycom：

```json
{
  "easycom": {
    "autoscan": true,
    "custom": {
      "^uv-(.*)": "@climblee/uv-ui/components/uv-$1/uv-$1.vue"
    }
  }
}
```

使用 uv-ui 工具库时，先完成扩展配置。HBuilderX 导入方式：

```js
import uvUI from '@/uni_modules/uv-ui-tools'

app.use(uvUI)
```

npm 方式：

```js
import uvUI from '@climblee/uv-ui'

app.use(uvUI)
```

基础样式默认在 `App.vue` 引入：

```scss
@import '@/uni_modules/uv-ui-tools/index.scss';
```

或 npm：

```scss
@import '@climblee/uv-ui/index.scss';
```

主题变量默认在 `uni.scss` 引入：

```scss
@import '@/uni_modules/uv-ui-tools/theme.scss';
```

## uv-ui API 工具优先

能用 uv-ui 工具库时优先用：

- 全局：`uni.$uv.trim()`、`uni.$uv.random()`、`uni.$uv.os()`、`uni.$uv.sys()` 等。
- 组件实例/页面：部分方法用 `this.$uv` 或 Vue3 `getCurrentInstance().ctx.$uv`。
- 局部引入：从 `@/uni_modules/uv-ui-tools/libs/function/...` 或 `@climblee/uv-ui/libs/function/...` 引入。

常见映射：

| 需求 | 优先工具 |
|------|----------|
| 防抖/节流 | uv-ui API 的 debounce/throttle |
| 字符串去空格 | `trim` |
| 时间格式化 | uv-ui time 工具 |
| 路由跳转 | uv-ui route 工具或 `uni.navigateTo` 封装 |
| 参数拼接 | `queryParams` |
| 表单校验 | uv-ui test/规则校验 + 组件表单校验 |
| 节点尺寸 | `getRect`，注意页面生命周期 |

## 环境管理

默认交付 `.env.example`，并按目标端区分：

```text
.env.development
.env.production
.env.local
```

检查项：

- API base URL、上传地址、WebSocket 地址、静态资源域名。
- 小程序 appid、H5 base、App 包名和权限。
- 不把真实 token、证书密码、SSH 私钥写入仓库。
- 部署脚本读取环境变量，不硬编码生产配置。

## 测试与验证

最小验证矩阵：

| 层级 | 默认动作 |
|------|----------|
| 静态检查 | `npm run lint` 或项目已有检查 |
| 单元测试 | `npm test` / `vitest`，没有则补核心函数测试 |
| API 测试 | 使用 `api-tester` 根据接口或 OpenAPI 生成请求验证 |
| H5 smoke | HBuilderX `launch web --compile true`，必要时用浏览器检查页面 |
| App/小程序 | 目标端 `launch` + `logcat`，失败读首个真实错误 |
| UI 验证 | 关键页面截图，检查空态、加载态、错误态、长文本 |

## 打包与部署

H5 发布：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli publish web --project /absolute/path/to/project --webTitle <title>
```

App WGT：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli publish app --type wgt --project /absolute/path/to/project --name app.wgt
```

App 云打包：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli pack --project /absolute/path/to/project --platform android
```

微信小程序发布需要 appid、上传密钥、版本和描述，缺这些信息时必须询问：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli publish mp-weixin --project /absolute/path/to/project --appid <appid> --upload true --version <version> --privatekey /path/private.key --description <desc>
```

服务器部署默认交给 `mms-ssh-connect`：先 dry-run 或只读检查，涉及 `rsync`、`docker compose up -d`、远端覆盖文件时先向用户确认影响范围。

## 交付格式

完成后汇报：

- 需求拆解和实现范围。
- 改动文件与关键设计。
- uv-ui 接入方式和使用到的 uv-ui API 工具。
- 运行环境和配置文件处理。
- 测试、HBuilderX 运行、打包、部署命令与结果。
- 仍需用户提供的账号/证书/服务器写操作确认。

