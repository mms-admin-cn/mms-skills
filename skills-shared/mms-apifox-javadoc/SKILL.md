---
name: mms-apifox-javadoc
description: MMS Java 后端与 Apifox IDEA 插件（Apifox Helper）对齐的 Javadoc 注释规范；用于从代码生成/同步接口说明与数据模型 Schema，减少手写文档与注解入侵。
---

# MMS × Apifox IDEA 注释规范

官方参考：[生成数据模型（IDEA）](https://docs.apifox.com/generate-data-schemas-with-idea)（Apifox 帮助文档）。插件基于 Javadoc 解析；可在 **Settings → Apifox Helper** 中配置自定义规则（如将 `@titleName` 映射为 Schema 的 `title`）。

## 1. 原则

- **优先 Javadoc**：与「零侵入」同步文档流程一致；业务说明写在注释里，由 **Upload to Apifox** / **Export API** 上传。
- **与校验注解配合**：`jakarta.validation` 的 `@NotNull`、`@NotBlank` 等仍用于运行时校验；文档侧以注释补全中文名、示例、默认值。
- **Controller 与 DTO 分工**：接口路径/摘要/参数/返回写在 **Controller 方法** Javadoc；字段语义、中文名、示例写在 **BO/DTO/VO 字段** Javadoc。

## 2. Controller / 接口类

| 位置 | 写法 |
|------|------|
| **类** | 第一段：模块职责；可用 `<p>` 说明完整 URL 前缀、鉴权方式（如插件 `/plugin/{id}/base/v1/...`、Sa-Token 权限码）。可 `@see` 关联宿主或权限常量类。 |
| **方法** | **第一行**：接口简短标题（建议同步为 Apifox 接口名）。空行后 `<p>` 写补充说明（幂等、权限、是否 `@SaIgnore` 等）。 |
| **参数** | 每个参数一行 `@param 形参名 说明`；Query 写明是否可选；`MultipartFile` 写明表单字段名（与 `@RequestParam` 一致，未标注时一般为形参名）。 |
| **返回** | `@return` 说明包装类型（如 `R&lt;T&gt;` 的 `code/msg/data`）或纯文本/文件流。 |

## 3. 数据模型（BO / DTO / VO / 枚举）

与官方「生成数据模型」一致：

| 标签 | 用途 |
|------|------|
| 字段上一段 Javadoc **首行** | 字段说明（进入 Schema 的 `description`） |
| `@titleName` | 中文名（需在 Apifox Helper 中配置规则 `field.schema.title=#titleName` 等，见官方文档） |
| `@example` | 示例值 |
| `@default` | 默认值说明 |
| `@see 枚举类名` | 枚举/引用类型，便于生成 `$ref` 或枚举值说明 |

类级可增加一段说明该模型用于哪个接口（可选）。

## 4. MMS 插件（HOST_MVC）注意

- 文档中的 **Path** 需体现 **`/plugin/{pluginId}`** 前缀 + Controller 上 **`@RequestMapping`**（如 `/base/v1/...`）。
- 权限与 **菜单/功能点** 一致时，在方法注释中写明 `plugin:...` 或指向 `XxxPermissions` 常量，便于联调排查。

## 5. 与 OpenAPI 注解的关系

若模块已引入 **springdoc / Swagger**：可并存 `@Tag`、`@Operation`、`@Schema`；**本技能不强制**使用。新建 **mms-plugins** 模块默认以本技能 Javadoc 为主，避免仅为文档增加依赖。

## 6. 维护

- 接口契约变更时：**先改代码与 Javadoc**，再执行 Apifox 同步。
- 官方文档若更新自定义标签或规则键名，以 [Apifox 文档](https://docs.apifox.com/generate-data-schemas-with-idea) 为准并修订本 SKILL 第 3 节表格。
