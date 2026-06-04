# uniapp-vue3-workflow 已验证事实

## 来源链接

- uv-ui 组件介绍：https://www.uvui.cn/components/intro.html
- uv-ui API 工具介绍：https://www.uvui.cn/js/intro.html
- uv-ui 资源页：https://www.uvui.cn/components/resource.html
- DCloud 插件市场 uv-ui：https://ext.dcloud.net.cn/plugin?name=uv-ui
- uv-ui 安装页：https://www.uvui.cn/components/install.html
- uv-ui 快速上手：https://www.uvui.cn/components/quickstart.html
- uv-ui 扩展配置：https://www.uvui.cn/components/setting.html

## uv-ui 要点

- uv-ui 是 uni-app 生态 UI 框架，兼容 Vue2/Vue3、App、H5、小程序等多端。
- DCloud 插件市场插件 ID：`uv-ui`。
- 插件市场版本信息调研时为 `1.1.20`，更新日期 `2024-01-20`。
- npm 包：`@climblee/uv-ui`，调研时 npm 最新版本为 `1.0.25`。
- 插件市场支持 `uni_modules`，官方提示 HBuilderX 3.1.0 以上可导入 uni_modules 规范插件。
- uv-ui 推荐 easycom，组件导入后页面可直接写 `<uv-icon ...></uv-icon>`，不需要逐个 `import`。
- 安装后建议重启项目，必要时清理 `unpackage`，避免 HBuilderX 或小程序工具缓存。

## uv-ui 安装方式

### HBuilderX / uni_modules 方式

官方推荐从插件市场下载并导入 HBuilderX，导入项目的 `uni_modules` 后使用。HBuilderX CLI 有 `uni_modules` 能力，可尝试：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli uni_modules --download uv-ui --project /absolute/path/to/project
```

也可升级：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli uni_modules --upgrade uv-ui --project /absolute/path/to/project
```

### npm 方式

```bash
npm i @climblee/uv-ui
```

npm 安装后需要在 `pages.json` 配置 easycom：

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

## uv-ui 扩展配置

uv-ui 内置方法默认不再自动挂到 `uni` 对象，若要使用 `uni.$uv.xxx` 或 `$uv` 工具，需要扩展配置。

HBuilderX 导入安装：

```js
import uvUI from '@/uni_modules/uv-ui-tools'

app.use(uvUI)
```

npm 安装：

```js
import uvUI from '@climblee/uv-ui'

app.use(uvUI)
```

基础样式建议在 `App.vue` 全局引入：

```scss
@import '@/uni_modules/uv-ui-tools/index.scss';
```

npm 方式：

```scss
@import '@climblee/uv-ui/index.scss';
```

主题变量建议在 `uni.scss` 引入：

```scss
@import '@/uni_modules/uv-ui-tools/theme.scss';
```

npm 方式：

```scss
@import '@climblee/uv-ui/theme.scss';
```

## uv-ui API 工具

uv-ui API 工具包括：

- 便捷工具
- HTTP 请求
- 节流防抖
- 对象操作
- 时间格式化
- 路由跳转
- 数组乱序
- 全局唯一标识符
- 颜色转换
- 对象转 URL 参数
- 规则校验
- 随机数值
- 去除空格
- 节点布局信息
- 小程序分享

全局使用示例：

```js
console.log(uni.$uv.trim(' abc '))
console.log(uni.$uv.random(1, 3))
console.log(uni.$uv.os())
console.log(uni.$uv.sys())
```

Vue3 `script setup` 中获取实例：

```js
import { onReady } from '@dcloudio/uni-app'
import { getCurrentInstance } from 'vue'

const { ctx } = getCurrentInstance()

onReady(() => {
  ctx.$uv.getRect('.demo').then((res) => {
    console.log(res)
  })
})
```

局部引入示例：

```js
import { os, sys } from '@/uni_modules/uv-ui-tools/libs/function/index.js'
import { trim } from '@/uni_modules/uv-ui-tools/libs/function/test.js'
```

npm 方式：

```js
import { os, sys } from '@climblee/uv-ui/libs/function/index.js'
import { trim } from '@climblee/uv-ui/libs/function/test.js'
```

## create-uni

`npm exec create-uni -- --help` 已验证输出：

```text
使用: create-uni [PROJECT_NAME] [OPTION]...

选项:
-t              使用特定模板
--ts            使用TypeScript
-p              使用特定插件
-m              使用特定模块
-ui             使用特定UI库
-e              使用eslint
-h, --help      显示帮助信息
-i, --info      显示版本信息
-g, --gui       显示图形界面
```

调研时 `create-uni` npm 版本为 `2.15.0`。

## HBuilderX CLI

调研环境：HBuilderX `v5.07.2026041006`，CLI `v1.0.0.0`。

CLI 必须先打开 HBuilderX 才能稳定返回帮助：

```bash
/Applications/HBuilderX.app/Contents/MacOS/cli open
/Applications/HBuilderX.app/Contents/MacOS/cli help
```

常用能力：

- `project open` / `project list` / `project close`
- `uni_modules --download` / `--upgrade` / `--list`
- `launch web`
- `launch app-android` / `app-ios`
- `launch mp-weixin` / `mp-alipay` / 其他小程序目标
- `logcat web` / `logcat app-android` / `logcat mp-weixin`
- `screencap app-android` / `app-ios`
- `publish web`
- `publish app --type wgt`
- `publish app-android --type appResource`
- `pack --platform android,ios`
- `hosting deploy`
- `user login` / `user info`

HBuilderX CLI 帮助里没有普通项目脚手架创建命令，因此脚手架创建用 `create-uni`，HBuilderX 负责导入、运行、发布和打包。

