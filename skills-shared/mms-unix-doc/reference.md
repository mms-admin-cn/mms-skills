# mms-unix-doc · 参考模板与片段

## 新组件空白模板（复制后替换 {{…}}）

将下列整段保存为 `{{slug}}.md`（例如 `button.md`），替换所有 `{{…}}`。

```markdown
---
# preview: false
# previewPath: pages_demo/{{slug}}/{{slug}}
---

# {{TAG}} {{中文名}}

## 简述

{{用一两句话说明组件用途与典型场景}}

::: warning
{{易错点、端差异、权限；若暂无则写：请以 `uni_modules/m-unix` 与本文为准，各端行为以官方文档为准。（勿再写「**注意：**」——本站 `::: warning` 已显示标题「注意」。）}}
:::

## 平台差异说明

| App（vue） | App（nvue） | H5 | 小程序 |
| :--------: | :---------: | :-: | :----: |
| √ | √ | √ | √ |

## 演示地址

与线上 [H5 演示基座](https://unix.mmsadmin.cn) 分包一致（文档站右下角预览 iframe 亦指向同一路径）。

| 类型 | 地址 |
|------|------|
| 分包路径 | `pages_demo/{{slug}}/{{slug}}` |
| 线上 H5（hash） | [打开演示](https://unix.mmsadmin.cn/#/pages_demo/{{slug}}/{{slug}}) |

（若 `preview: false`：改为说明「无独立分包演示」，勿写可点击链接。pathMap 特殊项以 `config.mts` 为准。）

## 基本使用

```uvue
<template>
	<view>
		<{{TAG}} />
	</view>
</template>
```

## Props

| 参数 | 说明 | 类型 | 默认值 |
|------|------|------|--------|
|  |  |  |  |

## Events

| 事件名 | 说明 | 回调参数 |
|--------|------|----------|
|  |  |  |

## 插槽

| 名称 | 说明 |
|------|------|
| `default` |  |
```

示例替换：`TAG=m-button`，`中文名=按钮`，`slug=button`，`演示路径=pages_demo/button/button`。

---

## VitePress 侧栏条目（示例）

按项目 sidebar 结构插入一项（链接前缀随 `base` 调整）：

```ts
{ text: '按钮', link: '/mms-unix/button' },
```

---

## H5 预览 pathMap（mms-doc 风格）

在 `themeConfig.mmsUnixH5Preview.pathMap` 中增加（无演示则文档 frontmatter `preview: false`，可省略此项）：

```ts
'your-slug': 'pages_demo/your-slug/your-slug',
```

---

## 索引表一行（components-catalog.md）

```markdown
| [your-slug.md](./your-slug.md) | m-your-tag | pages_demo/your-slug/your-slug |
```

---

## 粘贴外部 md 时的 slug 推导

| 标题行 | 推导 slug（默认规则） |
|--------|------------------------|
| `# m-button 按钮` | `button` |
| `# m-datetime-picker 日期时间选择器` | `datetime-picker` |
| `# request 网络请求` | `request`（无 `m-` 前缀组件名时文件名常与英文关键词一致） |

若项目约定「文件名 = 完整组件名」，则以项目约定为准。

---

## 归一化前后对照（节选）

**Before（外部稿）**：仅有 `# 标题` + `## 使用` + 代码 + `## Props`。

**After（本站版式）**：在标题后插入 `## 简述`、`::: warning`、`## 平台差异说明` 表格，并把 `## 使用` 改为 `## 基本使用`；**不删**原有 Props/示例内容。

---

## 本站文风示例（mms-doc）

新增或改版时，**语气、章节顺序、warning 写法、`uvue` 示例与 Props 表密度** 建议对齐同仓库内成稿，例如：`docs/mms-unix/button.md`。  
细则见 **`.cursor/skills/mms-unix-doc/SKILL.md` 第 4.2 节**（文风与排版）。
