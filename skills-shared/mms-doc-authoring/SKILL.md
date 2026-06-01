---
name: mms-doc-authoring
description: >-
  指导在 mms-doc（VitePress zh-CN）中撰写与润色可读、美观的技术文档：信息结构、Markdown 扩展、容器与 Badge、资源与 frontmatter、主题内 Vue 组件。
  写正文时须按「VitePress Markdown 必用能力」应用目录 [[toc]]、@include、代码块行号/高亮/聚焦/错误警告色、code-group 等与 config.mts 一致的能力。
  用户说「更新文档」且走 mms-doc-sync 时默认一并应用本技能，无须再说「美化」「好读」。
  在用户单独要求优化排版、或编写/改版 docs/**/*.md 但与代码同步无关时也使用。
  与 mms-doc-sync 分工：sync 负责事实与导航（config、log、对齐 mms）；本技能负责表达与版式。
---

# mms-doc 文档撰写与版式（VitePress）

**默认启用**：在 **mms-plus** 语境下用户只说 **「更新文档」** 等触发 **`mms-doc-sync`** 时，对改动过的正文**默认**按本文件执行；用户特别声明 **只改事实/不要润色** 时例外。

## 文档根与官方参考

- 内容目录：**`mms-doc/docs/`**；配置：**`mms-doc/docs/.vitepress/config.mts`**（`lang: 'zh-CN'`、`lastUpdated: true`、容器中文标签已配）。
- **事实与菜单**（新增页、侧栏、与后端对齐）：优先遵循 **[`mms-doc-sync`](../mms-doc-sync/SKILL.md)**。
- **VitePress 权威说明**（按需查阅，勿背诵）：[Markdown](https://vitepress.dev/zh/guide/markdown)（[自定义容器](https://vitepress.dev/zh/guide/markdown#custom-containers)、[TOC / 目录表](https://vitepress.dev/zh/guide/markdown#table-of-contents)、[嵌入 Markdown](https://vitepress.dev/zh/guide/markdown#markdown-file-inclusion)、代码块：[语法高亮](https://vitepress.dev/zh/guide/markdown#syntax-highlighting-in-code-blocks)、[行号](https://vitepress.dev/zh/guide/markdown#line-numbers)、[聚焦](https://vitepress.dev/zh/guide/markdown#focus-in-code-blocks)、[错误/警告行](https://vitepress.dev/zh/guide/markdown#errors-and-warnings-in-code-blocks)、[行间 diff](https://vitepress.dev/zh/guide/markdown#colored-diff-in-code-blocks)、[代码组](https://vitepress.dev/zh/guide/markdown#code-groups)） · [资源处理](https://vitepress.dev/zh/guide/asset-handling) · [Frontmatter](https://vitepress.dev/zh/guide/frontmatter) · [在 Markdown 中使用 Vue](https://vitepress.dev/zh/guide/using-vue) · [国际化](https://vitepress.dev/zh/guide/i18n) · [站点配置](https://vitepress.dev/zh/reference/site-config) · [默认主题](https://vitepress.dev/zh/reference/default-theme-config) · [Nav / Sidebar](https://vitepress.dev/zh/reference/default-theme-nav) · [侧栏](https://vitepress.dev/zh/reference/default-theme-sidebar) · [首页](https://vitepress.dev/zh/reference/default-theme-home-page) · [布局](https://vitepress.dev/zh/reference/default-theme-layout) · [Badge](https://vitepress.dev/zh/reference/default-theme-badge) · [Team Page](https://vitepress.dev/zh/reference/default-theme-team-page) · [lastUpdated](https://vitepress.dev/zh/reference/default-theme-last-updated)。
- **本站 `markdown` 配置入口**：`mms-doc/docs/.vitepress/config.mts`（`container`、`languageAlias`、`lineNumbers` 等与下节一致性以该文件注释及官方文档为准）。

## VitePress Markdown 必用能力（写 mms-doc 正文时默认遵守）

下列与 **`config.mts` → `markdown`** 块内注释同源；**新增或大幅改写教程、安装步骤、API 示例、多文件摘录时主动使用**，勿仅用纯文本围栏糊弄过去。

### 页内目录

- 长文（多节 H2/H3）在靠前位置插入 **`[[toc]]`**，便于页内跳转；深度与呈现可由 `markdown.toc` 配置（本站未单独覆盖则用默认）。见 [目录表](https://vitepress.dev/zh/guide/markdown#table-of-contents)。

### 嵌入其他 Markdown 文件

- 语法：**`<!-- @include: ./路径.md -->`**，或根相对 **`@`**（与 VitePress `srcDir` 一致）；可选行范围 **`{3,}`**、**`{,10}`**、**`{1,10}`** 紧跟路径后。
- **注意**：目标文件不存在时构建**不报错**，须在预览中自检。见 [包含 Markdown](https://vitepress.dev/zh/guide/markdown#markdown-file-inclusion)。

### 代码块（围栏）

1. **语言**：必须标注 **`bash` / `java` / `ts` / `vue` / `json` / `yaml` / `sql` / `text`** 等合法标签；**mmsUnix** 正文用 **`uvue`**、**`uts`**、**`vue-html`**（已在 `config.mts` 的 **`markdown.languageAlias`** 映射到 Shiki）。
2. **行高亮**：围栏第一行写 **` ```ts{4}`** 或 **`{4-6}`**、**`{1,7-9}`**；或在行尾用 **`// [!code highlight]`**（语言需支持 `//` 注释）。
3. **行号**：本站默认 **`markdown.lineNumbers: false`**，需要时单块写 **` ```ts:line-numbers`**；可选 **` ```ts:line-numbers=2`**（起始行号）、**`:no-line-numbers`** 关闭。组合示例：**` ```typescript:line-numbers {1,14-15}`**（先 `:line-numbers` 再空格与花括号）。见 [行号](https://vitepress.dev/zh/guide/markdown#line-numbers)。
4. **聚焦**：**`// [!code focus]`** 或 **`// [!code focus:<lines>]`**，弱化其余行。见 [聚焦](https://vitepress.dev/zh/guide/markdown#focus-in-code-blocks)。
5. **错误 / 警告着色**：**`// [!code error]`**、**`// [!code warning]`**。见 [错误与警告](https://vitepress.dev/zh/guide/markdown#errors-and-warnings-in-code-blocks)。
6. **行间 diff（着色）**：**`// [!code --]`**、**`// [!code ++]`**。见 [颜色差异](https://vitepress.dev/zh/guide/markdown#colored-diff-in-code-blocks)。
7. **代码组**：多段并列（不同文件、JS/TS 对照、`npm`/`pnpm` 等）用 **`::: code-group`** 包住多个围栏，围栏标题写 **` ```js [config.js]`** 形式。见 [代码组](https://vitepress.dev/zh/guide/markdown#code-groups)。

### 使用优先级（经验规则）

| 场景 | 建议 |
|------|------|
| 安装/配置步骤、**须按行指代的清单** | 代码块加 **`:line-numbers`**，关键步骤 **行高亮 `{…}`** |
| 易抄错的一行、废弃写法 vs 推荐写法 | **`[!code error]` / `[!code warning]`** 或 **diff `--`/`++`** |
| 长配置中只有一小段值得看 | **`[!code focus]`** |
| 同一知识点多版本并列 | **`::: code-group`** |
| 同一内容多页复用、主文过长 | **`@include`** + 必要时行范围 |

## 可读性优先（先于「语法正确」）

1. **一页一个核心问题**：`#` 与正文承诺一致；开场 1～3 句说明「谁能用上 / 解决什么」。
2. **标题阶梯**：`##` → `###`，避免跳级；侧栏长文用大节拆分，勿单节超长堆叠。超长正文可在靠前位置插入 **`[[toc]]`** 生成页内标题目录（与右侧 Outline 按需二选一或并存，见 [目录表](https://vitepress.dev/zh/guide/markdown#table-of-contents)）。
3. **段首主题句**：每段第一句承担概要；避免连续多段无小标题的「字墙」。
4. **形态选择**：并列要点用列表；多属性对照用表格；步骤用有序列表；长分支用 **`::: details`** 折叠（标签见 config：`详细信息`）。
5. **强调节制**：加粗仅标关键术语或结论；少用大段斜体。
6. **链接**：用描述性锚文（例：[多租户配置](/mms-admin/tenant)），避免裸 URL；站内用 VitePress 路径风格。
7. **代码**：语言标签、**`uvue` / `uts` / `vue-html`**、行号、高亮、聚焦、错误/警告、diff、**`code-group`**、**`@include`**、**`[[toc]]`** 等——**默认按上文「VitePress Markdown 必用能力」选用**；命令可复制、完整；过长脚本可放入 **`::: details`**。

## 本站已启用的 Markdown 容器

语法与 `::: raw`、自定义标题等见 VitePress [自定义容器](https://vitepress.dev/zh/guide/markdown#custom-containers)。`config.mts` 中 `markdown.container` 已映射中文标题，正文推荐：

- **`::: tip`** → 显示为「提示」
- **`::: warning`** → 「注意」
- **`::: danger`** → 「警告」
- **`::: info`** → 「说明」
- **`::: details`** → 「详细信息」

典型用法：**注意** 写易错点与例外；**提示** 写捷径与可选读；**说明** 写背景；折裹次要材料用 **details**。

更多snippet 与 Badge 示例见同目录 [`reference.md`](reference.md)。

## 资源与 Frontmatter

- **公共静态资源**：放在 **`docs/public`**（或项目配置的 `publicDir`），引用 `/logo.png` 形式。
- **与 md 同目录的资源**：相对路径引用，构建会处理哈希（详见官方 [资源处理](https://vitepress.dev/zh/guide/asset-handling)）。
- **Frontmatter**：可用 `title`、`description`、页面级 `outline` 等增强可读与 SEO；与正文 H1 勿严重打架（见 [Frontmatter](https://vitepress.dev/zh/guide/frontmatter)）。

## 默认主题：Badge

在 MD 中可直接用 Vue 组件标注版本、环境、技术栈，例如（与站内 `faq/Thymeleaf.md` 等一致）：

```md
Badge 组件：`<Badge type="info" text="Java 21" />`，`type` 可取 `info` | `tip` | `warning` | `danger`。
```

用于段内短标签，勿替代正文解释（见 [Badge](https://vitepress.dev/zh/reference/default-theme-badge)）。

## mms-doc 主题内全局组件（`theme/components`）

在 Markdown 中可使用（已通过 `enhanceApp` 注册，**kebab-case** 写法）：

| 标签 | 用途 |
|------|------|
| `<mms-vip-content type="user \| vip \| super">…</mms-vip-content>` | 按登录/会员类型显示或遮挡-slot 内容；缺省 `type` 为 `user`。编辑预览可看 `store` 中 VIP 可见开关。 |
| `<mms-wx-code />` | 微信相关展示位（如简介页）。 |
| `<mms-saying />` | 语录/装饰（按主题实现选用）。 |
| `<mms-sidebar-toc />` | 侧栏目录增强（按页面需要使用）。 |

**广告位**（`<amp-ad>` 等）在 **`mms-ad`** 组件内维护，**不在**正文中手写广告标签。

会员块须成对闭合；`type` 与 `components/mms-vip-content/index.vue` 中逻辑一致（勿使用未定义取值）。

## mUnix 文档专区

**`docs/mms-unix/`** 的章节顺序、演示地址表、pathMap 与文风：遵循 **[`mms-unix-doc`](../mms-unix-doc/SKILL.md)**（与本技能互补；本技能管通用可读性，mms-unix-doc 管组件文档契约）。

## 交付前自检

- [ ] 读者能否仅看 **小标题 + 列表/表** 把握全篇？
- [ ] **注意/提示** 是否用在真正值得打断阅读的地方？
- [ ] 代码块语言、命令是否可复制运行？
- [ ] **教程/步骤类**：是否已为关键围栏加上 **行号/高亮**（或 **code-group** / **@include**）——符合「VitePress Markdown 必用能力」？
- [ ] **长文**：是否按需加入 **`[[toc]]`**？
- [ ] 站内链接与侧栏入口是否仍有效（新页面是否已写入 **`config.mts`**，见 `mms-doc-sync`）？
- [ ] 使用 **`mms-vip-content`** 时类型与闭合是否正确？

## 与 mms-doc-sync 的配合

| 场景 | 主要技能 |
|------|-----------|
| 对齐后端/插件事实、增删文档路由、`log/index.md` | **`mms-doc-sync`** |
| 润色结构、容器、Badge、组件版式、降低阅读负担 | **`mms-doc-authoring`**（本技能） |

同日若既有事实更新又有大幅润色，`docs/log/index.md` 的修订说明可合并或分条，由执行者按变更量决定。
