---
name: m-unix-coding-standards
description: "Maintains m-unix uni-app component library project structure and coding standards for uni-app + Vue + uni-uts. Covers pages vs subPackages, version/doc workflow, mUi theme, m-unix-doc, and m-unix-vscode. Use when working on this project, adding features, demos, releases, or moving files."
---

# mUnix（m-unix）项目编码规范与结构标准

该文件定义了 `m-unix` 项目的**项目结构约定**和**编码规范**。

> **注意**: UTS 语言规范、uvue 组件规范、CSS 规范、API 规范等通用规范请参考父工程 `.cursor/rules/` 下 **`mms-unix-*.mdc`**（由 `mms-unix` 子项目规则同步而来）。

## 项目结构约定

### 根目录结构

```
m-unix/
├── uni_modules/m-unix/          # 组件库（m-*、m-tools、libs/css、config.uts 等）
├── locale/                        # 应用级语言包（zh-Hans.json、en.json）
├── common/                        # 业务配置与业务 API（config.ts、api/）
├── pages/                         # 主包 Tab 根页（components / tools / templates / user 等）
├── pages_demo/                    # 组件演示分包（subPackages root，勿与主包路径混淆）
├── pages_Me/、pages_Article/ 等   # 业务/会员/文章等模块页面（按业务域分目录）
├── m-unix-doc/                  # 组件库 Markdown 说明（与演示页互补，非运行时依赖）
├── version/doc/                   # 版本说明、验收与待办（app-*.md、lib-*.md、qa-open-items 等）
├── m-unix-vscode/             # VS Code 扩展子工程（独立打开调试）
├── static/                        # 静态资源（含 tabbar、logo）
├── App.uvue、main.uts、pages.json
└── ...
```

### 组件库 vs 业务代码

**必须放在 `uni_modules/m-unix/` 中（可复用）：**
- 所有工具类（auth、storage、request、utils 等）
- 通用组件（button、grid、login、upload、update 等）
- 全局样式
- 类型和枚举定义

**必须放在 `common/` 中（项目业务相关）：**
- `common/config.ts` - 项目配置（API 地址、版本号等）
- `common/api/` - 业务接口（调用封装好的 request）

### 主包、分包与页面目录（建议固化）

| 区域 | 用途 | 约定 |
|------|------|------|
| `pages/*` | Tab 或应用一级入口 | 在 `pages.json` 的 `pages` 数组登记；需要整页固定高度配合 TabBar 时可用 `disableScroll: true` + 内层 `scroll-view`。 |
| `pages_demo/*` | 官方组件演示 | **分包**（`subPackages` 的 `root: "pages_demo"`）；跳转路径形如 `/pages_demo/button/button`，**不要**写成 `pages/pages_demo/...`。 |
| `pages_Me/*` 等 | 登录、资料、地址等业务 | 与演示分包分离；新增模块时保持「一个业务域一个根目录」，避免堆在 `pages/` 下。 |

### pages.json 与路径

- **新增演示页**：在 `subPackages` → `pages_demo` → `pages` 中追加一项；标题可与页面内文案一致。
- **`loginRequiredPaths`**：填写**不含 `pages/` 前缀**的路径片段，与项目里实际鉴权逻辑保持一致（改路径时同步改配置与拦截处）。
- **导航**：`uni.navigateTo({ url: '/pages_demo/...' })` 以 **`/` 开头的绝对路径**为准，避免依赖当前页相对层级出错。

### 版本与变更文档（`version/doc/`）

- **演示工程发版**：`common/config.ts` → `configInfo.versionName`（及 `versionCode`）变更后，在 `version/doc/` 按约定新增或更新 `app-{x.y.z}.md`，并在 `version/doc/README.md` 索引表中加一行。
- **组件库发版**：`uni_modules/m-unix/package.json` → `version` 与 `lib-{x.y.z}.md` 对齐，同样更新索引。
- **持续清单**：未完成项、风险、编辑器扩展待办等放在 `qa-open-items.md`、`m-unix-vscode-dev.md` 等，**不**在根目录或 `uni_modules` 下再复制一份 CHANGELOG/待办，避免双源。

### 主题与 UI 配置（`mUi`）

- 项目侧品牌色、占位图等通过 `common/config.ts` 的 **`mUi`**（类型 `MUiUserConfig`）注入，与 `uni_modules/m-unix/config.uts` 合并。
- **改主色时**：以 `uni_modules/m-unix/libs/css/m.scss`（及文档中的色值说明）为准，避免演示与真机主题漂移。

### 对外说明文档（`m-unix-doc/`）

- 面向使用者的长文说明（API、示例、注意事项）放在 `m-unix-doc/*.md`；`uni_modules/m-unix/readme.md` 保持组件库入口与安装说明即可。
- 新增组件时：**演示页（pages_demo）+ 可选 m-unix-doc 一篇**；二者描述与 props/emits 须与实现一致（细节见 component-api skill）。
- **措辞**：不引用其它商业组件库名称或外链；需要授权/合规提示时，与现有文档一致使用统一「**自研说明**」引用块（见 `input.md`、`checkbox.md` 等文首）。

### VS Code 扩展（`m-unix-vscode/`）

- 扩展为**独立子工程**：本地开发时单独用 VS Code 打开该文件夹再 F5；需求与待办以 **`version/doc/m-unix-vscode-dev.md`** 为准。

## 编码规范

### 导入路径规范

```ts
// ✅ 正确：使用组件库绝对路径
import { storage } from '@/uni_modules/m-unix/components/m-tools/Storage.uts'
import { useAuth } from '@/uni_modules/m-unix/components/m-tools/useAuth.uts'
import { t } from '@/uni_modules/m-unix/locale/index.uts'
import { config } from '@/common/config'

// ❌ 错误：不应使用 common/utils（已移动到组件库）
import { storage } from '@/common/utils/storage'
```

### 文件命名规范

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| 工具类 | `PascalCase.uts` | `Storage.uts`、`Auth.uts` |
| 组件 | `kebab-case.uvue` | `m-update.uvue` |
| 类型定义 | `PascalCase.uts` | `utype/type.uts` |

### 注释规范

- 文件头部注释说明用途
- 函数/方法添加注释说明参数和返回值
- 复杂逻辑添加行内注释说明意图
- **不要**添加显而易见的注释（如 `// 获取 token`）

## 组件规范

### easycom 自动注册

- 所有组件命名必须以 `m-` 开头
- 文件名必须匹配：`m-xxx/m-xxx.uvue`
- 不需要手动引入，pages.json 已配置 easycom

### 内联样式 `:style`（多端一致）

- **CSS 属性名**在对象/UTSJSONObject 中请用 **kebab-case 字符串键**：`'font-size'`、`'font-weight'`、`'text-align'` 等；**避免** `fontSize`、`fontWeight` 驼峰（部分小程序/渲染层对驼峰内联字样的支持不一致，易导致字号/字重不生效）。
- 动态赋值同理：`st['font-size'] = '28rpx'`，不要用 `st['fontSize']`。**Vue 组件 props** 仍用驼峰 `fontSize` 等与 CSS 无关的命名，二者不要混为一谈。

### Props 定义规范

```ts
defineProps({
  // ✅ 正确：给出默认值和注释
  title: {
    type: String,
    default: '',
    // 标题文字
  },
  // ✅ 正确：布尔值默认 false
  visible: {
    type: Boolean,
    default: false,
    // 是否显示
  },
})
```

### 事件命名规范

- 使用 kebab-case：`@update:visible` 风格
- 成功/失败：`success`、`fail`

**组件 API、v-model、演示与实现一致性**的详细清单与事故案例见：`.cursor/skills/mms-unix-component-api/SKILL.md`（新增/改版 `m-*` 或 `pages_demo` 时建议同时打开）。

### 演示页与样式归属（必选）

- **组件自带默认观感**：字号、颜色、圆角、边框、阴影、尺寸档位等**必须**在 `uni_modules/m-unix/components/m-*` 内通过 props 与组件 `scoped` 样式实现；业务页与演示页引用同一组件时应看到一致效果。
- **`pages_demo/*` 只做陈列**：页面背景、分区标题、区块间距、示例文案与插槽内容；**不得**用演示页样式去「规定」组件外观（避免深度选择器覆盖 `m-*` 内部、或在 demo 里承担本应属于组件的排版逻辑）。
- 若演示效果与预期不符，应**改组件**或**加/调 props**，而不是只在演示页补样式糊弄过去。

## 配置规范

### AppConfig 类型定义

所有后端接口地址必须统一配置在 `common/config.ts`：

```ts
type AppConfig = {
  env: 'local' | 'dev' | 'prod'
  localBaseUrl: string
  devBaseUrl: string
  prodBaseUrl: string
  baseUrl: string        // 由 env 与三者解析，Request/上传等默认使用
  storage: StorageConfig
  loginRequiredPaths: string[]
  api: ApiConfig
  configInfo: ConfigInfo
}
```

### 版本更新组件规范

后端接口返回格式：

```json
{
  "code": 0,
  "data": {
    "hasUpdate": true,
    "title": "发现新版本",
    "desc": "1. 修复已知问题\n2. 优化用户体验",
    "versionCode": 2,
    "versionName": "1.1.0",
    "force": false,
    "apkUrl": "https://example.com/app.apk"
  }
}
```

### 认证与登录规范

1. **响应式设计**：
   - 使用 `authTrigger` + `notifyAuthChange()` 触发全局更新
   - 使用 `useAuth()` 获取响应式登录状态

2. **存储位置**：
   - token 和 userInfo 存在 `uni.setStorageSync`
   - 键名从 `config.storage` 配置读取

## 请求工具规范

### 统一请求工具 Request.uts

项目使用统一的请求工具，支持灵活配置：

```ts
import { request, http, ApiResponse } from '@/uni_modules/m-unix/components/m-tools/Request.uts'
```

### RequestOptions 配置项

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `url` | string | - | 请求地址 |
| `method` | 'GET'\|'POST'\|'PUT'\|'DELETE' | 'GET' | 请求方法 |
| `data` | AnyRecord | - | 请求数据 |
| `baseUrl` | string | config.baseUrl | 基础地址 |
| `withToken` | boolean | true | 是否携带 Token |
| `showError` | boolean | true | 是否显示错误提示 |
| `showLoading` | boolean | false | 是否显示加载提示 |
| `redirectOnUnauthorized` | boolean | true | 未登录是否跳转登录页 |
| `successCodes` | number[] | [0, 200] | 成功的响应码 |
| `unauthorizedCodes` | number[] | [401, 403] | 未授权的响应码 |

### 使用示例

**1. 基本请求：**
```ts
// GET 请求
const res = await http.get('/api/user/info')

// POST 请求
const res = await http.post('/api/user/login', { phone: '13800138000' })
```

**2. 公开接口（不需要登录）：**
```ts
const res = await http.public({
  url: '/api/article/list',
  method: 'GET',
  data: { page: 1 }
})
```

**3. 静默请求（不显示任何提示）：**
```ts
const res = await http.silent({
  url: '/api/user/check',
  method: 'GET'
})
```

**4. 带加载提示的请求：**
```ts
const res = await http.loading({
  url: '/api/order/submit',
  method: 'POST',
  data: orderData
}, '提交中...')
```

**5. 自定义配置：**
```ts
const res = await request({
  url: '/api/custom',
  method: 'POST',
  data: params,
  baseUrl: 'https://api.example.com',
  withToken: true,
  showError: true,
  redirectOnUnauthorized: true,
  successCodes: [0, 200, 1],
  unauthorizedCodes: [401, 403, 405]
})
```

**6. 业务 API 封装示例：**
```ts
// common/api/userApi.uts
import { request, ApiResponse } from '@/uni_modules/m-unix/components/m-tools/Request.uts'
import { config } from '@/common/config'

/** 获取用户信息（需登录） */
export function getUserInfo() {
  return request({
    url: '/api/user/info',
    method: 'GET',
    redirectOnUnauthorized: true
  })
}

/** 获取公开文章列表 */
export function getArticleList(page: number) {
  return request({
    url: '/api/article/list',
    method: 'GET',
    data: { page },
    withToken: false,
    redirectOnUnauthorized: false
  })
}
```

### 响应结构

```ts
type ApiResponse<T = any> = {
  code: number    // 响应码
  msg: string     // 响应消息
  data: T         // 响应数据
}
```

## 国际化规范

### 语言包规范

语言键命名采用 `模块.功能` 格式：

```json
{
  "app.name": "mUnix",
  "tabbar.components": "组件",
  "page.login": "登录",
  "common.confirm": "确定",
  "validation.phoneRequired": "请输入手机号",
  "button.sendCode": "发送验证码"
}
```

### 使用方式

```ts
import { t, setLocale, useI18n } from '@/uni_modules/m-unix/locale/index.uts'

// 翻译文本
const title = t('page.login')

// 带参数翻译
const btnText = t('button.resendCode', { seconds: 60 })

// 切换语言
setLocale('en')

// 组合式 API
const { locale, t } = useI18n()
```

### pages.json / manifest.json 文案

微信小程序等**不支持** `%page.xxx%`、`%app.name%` 等占位写法，仓库内已改为**直接写中文/英文常量**（与 `locale/zh-Hans.json` 对齐）。运行时多语言仍在业务代码里用 `locale` / `t()`。

### 注意事项

- **小程序、App**：`pages.json`、`manifest.json` 勿用 `%key%`；标题与 tab 写死文案或各端条件编译
- **Web 平台**：支持 `vue-i18n`，可在 `main.uts` 中集成
- 支持的语言：`zh-Hans`（简体中文）、`en`（英文）

## 文件移动与重构规则

1. **必须更新所有导入**：
   - 更新所有引用了原文件路径的代码
   - 检查项目中所有 import 语句

2. **保持向后兼容**：
   - 如果是公开 API，考虑保留导出重新导出 from 新位置
   - 但如果用户要求清理原目录，果断删除原文件

3. **清理原目录**：
   - 移动完成后删除原文件
   - 如果目录为空，可以清空保留（便于以后项目扩展）

4. **统一到组件库**：
   - 所有可复用工具必须在 `uni_modules/m-unix/components/m-tools/`
   - 所有可复用组件必须在 `uni_modules/m-unix/components/m-xxx/`
   - `common/` 只保留业务配置和业务 API

## 新增组件 Checklist

- [ ] 组件放在 `uni_modules/m-unix/components/m-xxx/`
- [ ] 组件文件名：`m-xxx.uvue`
- [ ] 组件名称以 `m-` 开头
- [ ] 添加注释说明用法
- [ ] 如果需要接口地址，配置在 `common/config.ts`
- [ ] 如果需要工具方法，放在 `m-tools` 对应文件
- [ ] **演示**：在 `pages.json` → `subPackages` → `pages_demo` 注册页面；若需从 Tab「组件」首页进入，更新 `pages/components/components.uvue` 中分类数据
- [ ] **（可选）** 在 `m-unix-doc/` 增加说明文档，并与实现 API 一致
- [ ] **发版**：同步 `uni_modules/m-unix/package.json` 的 `version` 与 `version/doc/lib-*.md`（见上文版本约定）

## 总结

- **所有可复用代码 → `uni_modules/m-unix/`**
- **所有业务配置 → `common/`**
- **接口地址统一 → `common/config.ts`**
- **请求工具统一 → `m-tools/Request.uts`**
- **组件自动注册 → easycom 无需手动引入**
- **演示分包 → `pages_demo/`，路径以 `/pages_demo/` 跳转**
- **版本与验收文案 → `version/doc/`，与 config / 组件库 version 对齐**
- **组件 API 与演示一致 → 见 `mms-unix-component-api` skill**