# mms-doc-authoring · 速查片段

## 自定义容器（中文标签由 `config.mts` 提供）

````md
::: tip
读者可跳过的补充说明。
:::

::: warning
易错配置、破坏性变更、安全相关。（`warning` 块已带标题「注意」，正文不要再写「**注意：**」。）
:::

::: info
背景或定义，降低正文打断感。
:::

::: details
折叠的补充步骤或长输出
```bash
echo example
```
:::
````

## Badge（默认主题）

```md
<Badge type="info" text="Spring Boot 3.5" />
<Badge type="warning" text="需 JDK 21" />
```

## 会员可读块

```md
<mms-vip-content type="vip">
仅 VIP 可见的正文。
</mms-vip-content>
```

`type`：`user`（登录即可）| `vip` | `super`；默认 `user`。

## 官方文档直达（撰写时查阅）

- [Markdown 容器与亮点](https://vitepress.dev/zh/guide/markdown)
- [图片与资源、`@` 导入](https://vitepress.dev/zh/guide/asset-handling)
- [页面 frontmatter](https://vitepress.dev/zh/guide/frontmatter)
- [在 MD 中用 Vue、组件](https://vitepress.dev/zh/guide/using-vue)
- [主题 Badge / Team / 布局](https://vitepress.dev/zh/reference/default-theme-config)
