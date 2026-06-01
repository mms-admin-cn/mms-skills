---
name: mms-plugin
description: MMS JAR 插件**开发与封装标准**（命名、**Maven 模块目录**与 reactor `<module>` 对齐、**源码/资源目录结构**、plugin.json 的 id/name/description/dependencies、**requiresMms.revisionMin 用 `${revision}` + resources 过滤**、**市场封面 `META-INF/mms/logo.png`**、**`script/install.sql`**、C 端七域与 mms.plugin.c-member / mms.plugin.c-base、**`mms-plugin-tool-*` / `com.sxpcwlkj.tool.*`**、对外 HTTP 形态）；以及 mms-plugin-api/host、市场（含磁盘 **sysConfig** 与 **PluginDescriptorProbe.tryReadForPlugin**）、sys_plugins、ClassLoader、shade/standalone、**mms-admin logback-spring / plugin_sift**、可观测性与健康探针。**联邦前端打进 JAR**：**`META-INF/mms/web`**、**`-Pfed-web`**、**`mms-ui` `fed-plugin-ui`**（pnpm）、**`fed-plugin-ui.mjs` 过滤 `--`**；**POM 与 `package.json` name 对齐**见正文 **「联邦前端（mms-ui）与插件 JAR 一键打包」**（参考 **`mms-plugin-tool-syslog/pom.xml`**）。踩坑见 mms-plugins/插件封装踩坑与注意事项.md。详尽登记表见 version/v2.0.14。用户新增或改版插件、安装卸载、打包排错时使用。
---

# MMS JAR 插件（宿主 · 契约 · 开发）

## 宿主修改闸门（项目强制约定）

- 详见仓库根 **`.cursor/rules/mms-plugin-host-boundary.mdc`**：插件优先、**不要轻易改** `mms-plugin-host`；非改不可须 **先问项目负责人再扩展宿主**，禁止擅自改宿主来适配单个插件。

## 业务插件 vs 全端开放 HTTP（强制约定）

- 详见仓库根 **`.cursor/rules/mms-plugin-business-openapi-boundary.mdc`**：**工具类插件**除外；**业务类 C 域插件**只做 **管理端联邦 + CRUD + 能力供给**，**不**各自提供面向 C 端客户端的 **开放 `/api/...` 出口**；**`mms-plugin-c-server`（`mms-open-api.jar`）** **集中整合** 对外开放 HTTP；插件协作靠 **SPI / HostServices / tryInvokePeerPlugin** 等，**不 Maven 互依赖业务插件**（与 **v2.0.18** 一致）。

## 何时阅读本技能

- 实现或排查 **独立 JAR 插件**、**插件市场 / sys_plugins**、**上传安装 / 激活版本 / 卸载**。
- 澄清 **插件 ClassLoader** 与 **能否依赖 mms-common / mms-system**。
- **更新在线文档**时与 **`.cursor/skills/mms-doc-sync/SKILL.md`** 配合：正文在同级 `mms-doc`，路由见下文「文档」。
- **检查 / 验收 / 安装失败 / 菜单不显示** 等排障清单：见 **`.cursor/skills/mms-plugin-check/SKILL.md`**（**开发标准**仍在本技能；**自检步骤**在检查技能）。
- **脚手架演进、§7 能力矩阵与插件宿主对齐（维护者）**：见 **`.cursor/skills/mms-plugin-jar-phases/SKILL.md`**。
- **联邦动态加载链路（安装可访问 + plug 本地联调）**：先看 **`version/v2.0.25-插件联邦验收规则与联调规范.md`**，该文是当前插件前端联邦对接与验收门禁的基线。

## 插件开发标准（今后封装 JAR **须遵守**）

> **执行口径**：协作助手 **新增 / 改版可装插件** 时按本节与 **`mms-plugins/插件封装踩坑与注意事项.md`** 自检。本节是 **Cursor 内默认规范**；**逐插件能力 / 依赖 / 对外路径的完整登记表**以主仓 **`version/v2.0.14-插件命名规范与全量清单.md`** 为准（**C 端拆分**见 **`version/v2.0.13-*.md`**，清单基线见 **`version/v2.0.12-*.md`**）。仓库入口：**`mms-plugins/README.md`**、根 **`README.md`**。

### Maven 模块与目录

| 规则 | 说明 |
|------|------|
| **目录名 = 父 POM 的 `<module>` 名** | 与 **`mms-plugins/pom.xml`** 的 **`<module>`** 一致；**多数** 情况下与 **子模块 `artifactId` 所在目录** 同名。 |
| **例外：目录名 ≠ `artifactId`** | 例如 **`mms-plugin-c-server/`** 子模块 **`artifactId`** 为 **`mms-plugin-server-api`**（开放 API 聚合、产物 **`mms-open-api.jar`**）。**`-pl`**、文档路径以 **`<module>` 目录名** 为准。 |
| **C 端业务域** | **`mms-plugin-c-{域短名}`**（如 **`mms-plugin-c-member`**）；**`plugin.json` id** 一般为 **`mms.plugin.c-{域}`**。 |
| **`c-base`** | 目录 **`mms-plugin-c-base`**；**`plugin.json` id** 为 **`mms.plugin.c-base`**（**无点**，**勿**写成 `c.base`）。 |
| **工具 / 运维 / 集成（可装）** | Maven 目录统一 **`mms-plugin-tool-{短名}`**（如 **`mms-plugin-tool-syslog`**、**`mms-plugin-tool-datasource`**）；**`plugin.json` id** 推荐 **`com.sxpcwlkj.tool.{短名}`**。 |
| **公共库（不可装）** | **`mms-plugin-tool-bean-install`**：**无** `plugin.json`，仅 **shade** 进 **SPI_ONLY** fat JAR（包 **`com.sxpcwlkj.bean.install`**）。 |
| **示例** | **`mms-plugin-sample-health`**、**`mms-plugin-sample-spi`**。 |
| **其它平台插件** | 无前缀子类时仍可用 **`mms-plugin-{语义}`**（如 **`mms-plugin-doc`**、**`mms-plugin-deepl`**）。 |
| **Maven `<name>` / `<description>`** | **`<name>`** 与各模块 **`META-INF/mms/plugin.json` 的 `name`**（中文展示名）一致；**`<description>`** 首段与 **`plugin.json` 的 `description`** 对齐，可另起段落写构建命令、联邦前端等。**父 POM** **`mms-plugins/pom.xml`** 已说明例外（**`mms-plugin-c-server`** ↔ **`mms-plugin-server-api`**）。 |

### 插件源码与资源目录结构（现行规范）

> **目标**：与 **`mms-plugin-c-member`** 等现行模块一致——**入口类极薄**、**业务代码按域分包**、**资源只保留真用得到的文件**，避免空 `mapper`、空目录、历史 **`admin.*` 包名** 与 **`DomainInstallSpec` 扫描包**不一致。

#### 模块根（与 `pom.xml` 同级）

| 路径 | 约定 |
|------|------|
| **`script/schema.sql`** | 插件自建业务表时提供；构建阶段按各模块 **`pom`** 复制为 JAR 内 **`META-INF/mms/schema.sql`**（见 **`PluginConstants`**）。无表可省略。 |
| **`script/install.sql`** | **可选**；构建打入 JAR 后，宿主安装在 **`skipBundledSchemaExecution=false`（默认）** 下可**自动**执行白名单 **`INSERT [IGNORE] INTO sys_function | sys_dict | sys_dict_data`**（字典 `field_name` 须 **`mms_plugin_`** 前缀；见 **`BundledPluginInstallSqlGuard`**）。与 **`menuBootstrap`** 组合时注意主键不冲突，且 **`type=1` 行须满足动态路由字段约定**。 |
| **`README.md`** | 工具向 / 联邦前端模块建议保留「一条命令打包」说明。 |

#### `src/main/java`（分层与包名）

| 包 / 约定 | 说明 |
|-----------|------|
| **`com.sxpcwlkj.plugin.c.{域}`**（或工具插件下对等的 **`plugin` 包） | **仅放** **`MmsPlugin` 实现**（及可选与入口同类的 **`PluginHealthContributor`**），**保持极薄**；不要在其它包重复再写一个入口。 |
| **`com.sxpcwlkj.{域}`** | **业务代码根包**：**`controller`**（管理端接口放 **`{域}.controller`**，**勿**再用 **`com.sxpcwlkj.admin.controller`** 以免与 **`DomainSpringBeansInstaller` 扫描不一致**）、**`service` / `service.impl`**、**`mapper`**、**`entity`**（含 **`vo` / `bo` / `export`**）、**`enums`**、**`utils`** 等，与生成器/主工程习惯对齐。 |
| **`SPI_ONLY` + `DomainInstallSpec`** | **`mapperPackage` / `servicePackage` / `controllerPackage`** 指向上述业务包（示例：**`com.sxpcwlkj.member.mapper`**、**`com.sxpcwlkj.member.service.impl`**、**`com.sxpcwlkj.member.controller`**）。 |

#### `src/main/resources`

| 路径 | 约定 |
|------|------|
| **`META-INF/mms/plugin.json`** | 必填（可装插件）；与构建 **`${revision}`** 过滤策略配合见下文。 |
| **`META-INF/mms/logo.png`** | 插件市场封面（固定文件名）。 |
| **`META-INF/mms/web/**`** | 联邦前端打进 JAR 时由 **`fed-web`** profile 复制至此（无前端则不打）。 |
| **`META-INF/services/`** | **`com.sxpcwlkj.plugin.MmsPlugin`**、**`com.sxpcwlkj.plugin.PluginHealthContributor`**（**shade** 须 **`ServicesResourceTransformer`**）。 |
| **`mapper/**`** | **仅当**存在 **MyBatis XML** 时保留；可按子域分子目录（如 **`mapper/member/`**）。**禁止**提交空 XML 或仅用于占位的目录；以注解 Mapper 为主时可**无** `mapper/`。 |

#### 公共库 **`mms-plugin-tool-bean-install`**

- **仅** **`src/main/java`**（**无** `src/main/resources`、**无** `plugin.json`），供 C 域 **`SPI_ONLY`** fat JAR **shade** 使用。

### `plugin.json`：`requiresMms.revisionMin` 与 Maven **`revision`**（动态，对齐 mms-plugin-doc）

- **写法**：在源码 **`META-INF/mms/plugin.json`** 中使用 **`"revisionMin": ${revision}`**（**无引号**包裹占位符，过滤后为合法 JSON 数字）。
- **含义**：与根 **`mms/pom.xml`** 的 **`<revision>`**（及宿主 **`mms.plugin.host-mms-revision`**）一致；升级产品线 revision 时**勿**在各插件手写死 **`21`** 等数字。
- **POM**：在插件模块 **`pom.xml`** 采用 **`mms-plugin-doc`** 同款 **双段 `resources`**——**整个 `src/main/resources` `filtering=false`** 且 **排除** **`META-INF/mms/plugin.json`**；**另起一段** 仅 **`include` 该文件且 `filtering=true`**，避免误替换其它资源里的 **`${…}`**。
- **参考实现**：**`mms-plugins/mms-plugin-doc/pom.xml`**（及各已跟进的业务 / 示例 / 运维插件 **`pom`**）。

### POM 依赖白名单（可装业务插件 · 目标口径）

> **成文**：**`version/v2.0.18-插件POM依赖白名单与业务插件互引用口径.md`**（与 **v2.0.17** 互补）。协作助手 **新增 / 改版可售卖或域内业务插件** 时默认遵守。

- **允许**：**`mms/mms-modules`** 内模块（**`mms-common`**、**`mms-plugin-api`**、按需窄引用 **`mms-system`** 等，配合 **provided** 与 shade 策略）、**公共库**（如 **`mms-plugin-tool-bean-install`**）、**第三方**库。
- **禁止**：**`pom.xml`** 对 **其它可装业务插件** 的 Maven 依赖（典型 **`com.sxpcwlkj:mms-plugin-c-*`**、**`mms-plugin-tool-datasource`** 等 **`mms-plugins` 侧带 `plugin.json` 上架物**）。**插件间先后与必选关系**只写在 **`plugin.json` `dependencies`**（对方 **插件 `id`**）。
- **协作**：**HTTP**、**`HostServices`**、**`tryInvokePeerPlugin`**、或 **上移到 `mms-modules` / api-only** 的共享类型；**不**在业务插件间 **import** 对方实现模块。
- **现状迁出**：**`mms-plugin-c-bbs`** 已无 **`mms-plugin-c-member` `pom` 依赖**（改用 **`mms-common`** 的 **`MemberProfileProvider`**，见 **v2.0.18 §3 / §6**）。**其它 C 域**若仍有 **`provided` → member**，按同套路迁出。
- **例外**：**`mms-plugins/mms-plugin-c-server`**（artifactId：**`mms-plugin-server-api`**）聚合 **七域瘦包 + WebSocket** 等（fat **`mms-open-api.jar`**）；**不**套用「按 SKU 单独售卖」的 **七域** POM 白名单，见 **v2.0.18 §3**。**默认部署**：**`mms-admin`（8080）** + **`mms-open-api`（8060）**、共享 **`mms.plugin.root-dir`**，见 **v2.0.19**。（历史 **v2.0.16** 单一宿主备忘仍存。）

### `plugin.json`：`id` 空间（必须与磁盘 / 市场一致）

| 形式 | 用途 |
|------|------|
| **`mms.plugin.c-*`** | **C 端业务域**（**`mms.plugin.c-member`** 含 **base** + 其它六域；与 **`mms-plugin-c-*`** 目录去 **`mms-plugin-`** 对齐）。 |
| **`mms.plugin.c-base`** | **C 端基础公共**（**HOST_MVC** 约定接口）。 |
| **`mms.plugin.{段}`** | 平台、集成、示例（如 **`datasource`**、**`redis-inspect`**、**`sample-health`**）；**`id` 变更**须同步 **`sys_plugins`**、**`mms.plugin.{pluginId}.*`**、依赖边。 |
| **`com.sxpcwlkj.tool.*`** | **新建**或 **立项换 id** 的 **工具 · 运维 · 集成** 插件，与 **`plugin.c.*`** 业务语义区分。 |

**改 `id` = 新插件身份**（旧版卸载 / 迁移 / 依赖重指），**默认禁止**对已交付插件随意更名。

### `name` 与 `description`（插件市场展示）

- **`name`**：短（建议 **≤20 字**），**不要**写长技术段落。
- **`description`** 推荐顺序，便于运维扫读：**① 定位一句** → **② `runtimeMode`** + **是否须 `*-standalone.jar`**（如适用）→ **③ `dependencies`**（**必选** / **optional**，写**完整**依赖 id）→ **④ 对外能力一句**（见下节「对外服务」）。

### 市场封面与安装脚本（资源约定）

- **插件市场封面图**：宿主按 JAR 内固定路径 **`META-INF/mms/logo.png`** 提供（与 **`plugin.json` 同目录**；常量见 **`com.sxpcwlkj.plugin.PluginConstants#LOGO_PATH_IN_JAR`**）。**文件名必须为 `logo.png`**，便于市场/探针统一读取；若仅在 `META-INF/mms/assets/` 下放自定义文件名，**不会**替代封面约定，应**同时**提供 **`logo.png`**（可将定稿图复制/覆盖为该文件）。
- **业务表 DDL（schema）**：模块根目录 **`script/schema.sql`**，构建时须复制进 JAR 的 **`META-INF/mms/schema.sql`**（常量 **`PluginConstants.SCHEMA_PATH_IN_JAR`**）。安装 **`POST /system/pluginHost/install`** / **`installStream`** 在 **`skipBundledSchemaExecution=false`（默认）** 且 JAR 内有该文件时，由 **`BundledPluginSchemaExecutor`** 自动执行白名单 DDL（需 **`mms-system` + JdbcTemplate**）。日志字段 **`bundledSchemaExecutionLog`**。
- **安装 SQL（install.sql）**：构建时打入 JAR 的 **`script/install.sql`**（**`PluginConstants.INSTALL_SQL_PATH_IN_JAR`**）。与 schema 同属「包内 SQL」：默认 **`skipBundledSchemaExecution=false`** 时自动按条执行，白名单为 **`sys_function` / `sys_dict` / `sys_dict_data`**；安装失败或卸载时按解析出的主键删除（**字典数据 → 字典类型 → 菜单**）。**`schema.sql` 不再允许 INSERT 字典**，字典放 install。日志 **`bundledInstallSqlExecutionLog`**。可与 **`menuBootstrap`** 并存（注意勿重复主键）。
- **菜单与权限（menuBootstrap）**：安装登记成功后仍由 **`menuBootstrap`** 向各租户 **`sys_function`** 幂等写入/更新（**`PluginOwnedMenuBootstrapServiceImpl`**）；卸载按 **`remark=plugin:{pluginId}`** 清理。与 **`install.sql` 自动执行**二选一或组合均可，以现网主键不冲突为准。
- **`sys_function` 与动态路由（杜绝「能登录进不了系统」）**：凡 **`type=1`**（目录/菜单）且会进入 **`/common/getMenu`** 的行，**`path` 须非空**（勿写 SQL `NULL`），且 **`component` 与 `redirect_path` 至少其一非空**（纯目录无页填 **`redirect_path`**，有页填 **`component`**；无独立管理页可指向宿主 **`system/pluginPlaceholder/index`** 等占位视图）。**保存**时 **`SysFunctionServiceImpl`** 对新增/编辑做校验；**历史脏行**在 **`SysUserServiceImpl#getAdminMenuTree`** 构建树时**跳过并打 WARN**，避免拖垮超级管理员全量菜单。**`plugin.json` `menuBootstrap`** 中 **`type=1` 项须带非空 `path`**（缺则跳过写入并打日志）。

### 联邦动态加载链路（新增插件默认按本节执行）

> 基线文档：**`version/v2.0.25-插件联邦验收规则与联调规范.md`**。

#### 对接闭环（四件套）

1. **plugin.json（frontend）**
   - `modulePackage` 与 host federation scope 一致
   - `routePrefixes` 覆盖插件菜单前缀
   - `remoteEntryFile` 固定 `assets/remoteEntry.js`

2. **安装产物（磁盘）**
   - `{rootDir}/{pluginId}/{version}/web/assets/remoteEntry.js` 必须存在

3. **host 对接（mms-ui）**
   - `plugin-federation.host.ts` 增加 remote（scope/envVar/devFallback/prodFallback）
   - `src/types/plugin-federation-scopes.d.ts` 增加 `declare module '<scope>/*'`
   - `src/router/pluginFederation/plugins/<plugin>.ts` 注册 `component -> import('<scope>/<Expose>')`
   - `src/router/pluginFederation/index.ts` 引入该注册文件

4. **环境分层**
   - `development/production` 默认走同源 `/plugin-assets/{pluginId}/{version}/assets/remoteEntry.js`
   - `plug` 模式走 `http://localhost:<port>/assets/remoteEntry.js`

#### 验收门禁（提测前必须给证据）

- [ ] `/plugin-assets/{pluginId}/{version}/assets/remoteEntry.js` 返回 200
- [ ] 插件菜单页面可打开，控制台无联邦加载错误
- [ ] `plug` 模式下 host + 对应插件 UI dev server 联调可访问、可热更新
- [ ] 提供 `pluginId/version/scope` 对照、安装目录中 `remoteEntry.js` 截图、两种模式可访问证据

#### 常见失败判定

- `ERR_CONNECTION_REFUSED localhost:517x`：非 plug 模式误用了 localhost remote，或 remote dev server 未启动
- `/plugin-assets/.../remoteEntry.js` 404：运行实例的 `mms.plugin.root-dir` 与实际安装目录不一致，或安装产物不完整
- 菜单有但白屏/模块未解析：scope、`declare module`、联邦路由注册三处未对齐


### 联邦前端（mms-ui）与插件 JAR 一键打包（POM 规范）

> **目标**：把 **`mms-ui`** 里 **workspace 子包**（如 `packages/plugin-syslog-ui`）的 **build 产物**打进 JAR，宿主按 **`META-INF/mms/web`** 提供静态资源；避免「只打了 Java、忘了联邦前端」或「dist 路径写错」导致市场页空白。**参考实现**：**`mms-plugins/mms-plugin-tool-syslog/pom.xml`**（与 **`mms-ui/scripts/fed-plugin-ui.mjs`** 配套）。

#### 仓库与命名约定

| 位置 | 约定 |
|------|------|
| **mms-ui 子包目录** | `mms-ui/packages/plugin-<短名>-ui`，与业务语义一致（如 `plugin-syslog-ui`）。 |
| **`package.json` 的 `name`** | **workspace 包名**，与 Maven 里传给脚本的参数**完全一致**（如 **`@mms-ui/plugin-syslog-ui`**）。 |
| **构建产物** | 默认 **`packages/.../dist`**（Vite 输出）；若子包改 `outDir`，须同步改插件 `pom` 里 **dist 目录属性**。 |
| **plugin.json** | 声明 **`frontend`**（`modulePackage` / `routePrefixes` / `remoteEntryFile` 等），与联邦模块路由一致；见 **syslog** 的 **`plugin.json`**。 |

#### 与主工程 `src/views` 的边界（助手易混点）

| 放哪里 | 适用场景 |
|--------|----------|
| **`mms-ui/packages/plugin-<短名>-ui`** | **可装 JAR 插件**随包交付的**管理端（或插件专属）界面**：与插件同版本迭代、`-Pfed-web` 打进 **`META-INF/mms/web`**；本地开发宿主通过 **`vite` 别名 `@mms-packages` → `packages/`** 直接引用子包源码（与 **syslog** 一致），**不必**把页面抄进 **`src/views`**。 |
| **`mms-ui/src/views`** | **宿主主线**功能、与「某一可装插件」无绑定关系的通用页（如 **`system/pluginPlaceholder`**、系统字典等）。 |

- **禁止**：把**只属于某个可装插件**的业务管理页**仅**写在 **`src/views/doc/...`** 这类主工程路径当「默认做法」——会导致插件 UI 与 JAR 解耦、发版依赖整站 **`mms-ui`**，与 **v2.0.4 联邦方案**不一致。
- **菜单 `component` 字段**：可填**宿主已存在的** `views` 路径，或填与联邦子包**对齐**并在宿主侧 **`import '@mms-packages/plugin-xxx-ui/src/...'`** 映射到的页面；**新插件**请优先 **packages 子包 + `plugin.json` `frontend`** 闭环。

#### 插件模块 `pom.xml` 必备片段（新插件请复制后改名）

1. **`properties`（与 mms-plus 根目录相对路径）**  
   - **`mms.ui.root`**：固定 **`${project.basedir}/../../mms-ui`**（**`mms-plugins/<artifact>` → `mms-plus/mms-ui`**）。  
   - **`mms.fed.plugin.package`**：等于 **`mms-ui` 子包 `package.json` 的 `name`**（如 **`@mms-ui/plugin-syslog-ui`**）。  
   - **`mms.ui.<插件短名>.web.dist`**：指向 **`${mms.ui.root}/packages/<子包目录名>/dist`**（例：`plugin-syslog-ui` → `.../packages/plugin-syslog-ui/dist`）。

2. **`profile`：`id=fed-web`**（名称统一，便于文档与 CI）  
   - **`skip.fed.<插件短名>.ui.build`**：默认 **`false`**；仅复制已有 dist 时 **`mvn ... -Pfed-web -Dskip.fed.<短名>.ui.build=true`**。  
   - **`exec-maven-plugin`**：`phase=prepare-package`，**`workingDirectory=${mms.ui.root}`**，执行 **`pnpm`** **`run`** **`fed:plugin-ui:build`** **`--`** **`${mms.fed.plugin.package}`**。  
     - **`--` 不可省略**：`fed-plugin-ui.mjs` 依赖 `--` 后的包名（见 `mms-ui/scripts/fed-plugin-ui.mjs` 注释）。  
   - **`maven-resources-plugin` `copy-resources`**：`phase=prepare-package`，**`outputDirectory=${project.build.outputDirectory}/META-INF/mms/web`**，**`sourceDirectory`** 指向前述 **dist**（与宿主 **`META-INF/mms/web`** 约定一致）。

3. **前置条件**（否则 exec 失败或复制空目录）  
   - 本机 **`mms-ui`** 已 **`pnpm install`**；**`pnpm`** 在 PATH 中。  
   - 首次接入新子包时：在 **`mms-ui`** 根 **`package.json` 的 `workspaces`** 已包含该包（pnpm workspace 能 **`--filter`** 到）。

4. **一键打包命令示例**  
   - **`mvn -pl mms-plugins/mms-plugin-tool-syslog -am package -Pfed-web -DskipTests`**
   - 跳过前端构建：`-Dskip.fed.syslog.ui.build=true`（属性名按各插件 **短名** 区分，见对应 `pom`）。

5. **交付自检（联邦相关）**  
   - [ ] **`pom`** 中 **`mms.fed.plugin.package`** 与 **`mms-ui/packages/.../package.json` 的 `name`** 一致。  
   - [ ] **`dist` 路径** 与 `packages/<目录>/dist` 一致。  
   - [ ] **`plugin.json`** 含 **`frontend`** 且与联邦路由一致。  
   - [ ] 打 **`fed-web`** 时 Maven 日志出现 **真实执行** `pnpm fed:plugin-ui:build`（非 0 行、非跳过），且 JAR 内存在 **`META-INF/mms/web`** 下文件。  
   - [ ] **`mvn` 不带 `-Pfed-web`** 时 JAR 不含联邦前端（若业务要求「瘦包不带 UI」）；**带 `-Pfed-web`** 时含完整静态资源。

### `dependencies`

- **必选**：**`"optional": false`**，`id` 与被依赖插件 **`plugin.json` 的 `id` 完全一致**；**`versionRange`** 常用 **`[1.0.0,9.9.9]`**（与现网一致）。
- **optional**：**`"optional": true`**，不阻断拓扑排序；**C 端七域**普遍 **optional** → **`mms.plugin.c-base`**。
- **C 端非 `member` 的六域**：**必选** → **`mms.plugin.c-member`**（含 **API 底座**，**勿**再写「独立 foundation」）。

### 对外服务（能力如何暴露）

- **`HOST_MVC`**：**`@PluginController`**，完整 URL：**`/plugin/{pluginId}/` + 类上前缀**（现有范例：**`/cbase`**、**`/ds`**、**`/ri`**、**`/deepl`**、**`/syslog`**、**`/demo`** 等）。企微机器人工具插件为 **`SPI_ONLY`**，对外契约见 **`mms-plugin-api`** 的 **`WechatBotMessaging` / `WechatBotPeers`**。细节见下文 **「HOST_MVC HTTP」**。
- **`SPI_ONLY`**：**`MmsPlugin#onLoad`** 内 **`DomainSpringBeansInstaller`**（**`com.sxpcwlkj.bean.install`**）注册 **Mapper / Service / `@RestController`**；REST 路径多为 **管理端**与 **C 端** 既有前缀（如 **`/api/...`**），**以代码为准**，**不等同**于 **`/plugin/{id}/...`**。
- **`INDEPENDENT_PROCESS`**：**默认** 独立进程为 **`mms-open-api.jar`**（**8060**，**`mms.plugin.open-api`**），**不在**父宿主 **`/plugin/{pluginId}`** 树下；**`mms-admin`** **可** `mms.plugin.enabled=false` 仅做运维写盘而由 **8060** 装载（**v2.0.19**）。主仓 **`mms-modules/mms-plugin-api`** 为 **SPI 契约**，对外可执行模块为 **`mms-plugin-c-server`**（artifactId：**`mms-plugin-server-api`**，历史单一宿主叙事见 **v2.0.16**）。

### C 端七域（与 v2.0.13 一致）

- **先装** **`mms.plugin.c-member`**；再装 **bbs / ad / article / site / app / openapi**（均 **`*-standalone.jar`**）。
- **Java 交叉类型**：**目标**见 **v2.0.18**（契约上收 **`mms-common`** 等，**不在 `pom` 依赖其它域 artifact**）。**BBS** 已改用 **`MemberProfileProvider`**；**勿**把 **member** 实现类 **shade** 进其它域 JAR。

### 新插件交付自检（助手默认执行）

```
- [ ] 目录名 = artifactId；父 POM 已加入 <module>
- [ ] **META-INF/mms/logo.png**：插件市场封面（**固定路径与文件名**；见 **`PluginConstants.LOGO_PATH_IN_JAR`**）
- [ ] **script/schema.sql**：若插件有自建业务表则提供 DDL，且 **pom** 已打入 **`META-INF/mms/schema.sql`**；否则可省略
- [ ] **plugin.json `menuBootstrap`**：需要安装后自动出现菜单时声明；**`type=1` 须含非空 `path`**（与动态路由约定一致）
- [ ] **script/install.sql**：可选；白名单含 **`sys_dict`/`sys_dict_data`/`sys_function`**；**`type=1` 须非空 `path` 且 `component`/`redirect_path` 至少其一**
- [ ] META-INF/mms/plugin.json：id、name、description、requiresMms（**revisionMin 建议 `${revision}` + POM 过滤**）、runtimeMode、entryClass、dependencies 符合本节；契约版本与 backupOperator 等扩展字段与能力匹配
- [ ] META-INF/services：com.sxpcwlkj.plugin.MmsPlugin + com.sxpcwlkj.plugin.PluginHealthContributor；shade 须 ServicesResourceTransformer
- [ ] C 域 SPI_ONLY：依赖 mms-plugin-tool-bean-install；onLoad 仅用 DomainInstallSpec 扫描本插件包
- [ ] 已按团队约定同步 version/v2.0.14 登记表（或 v2.0.12 全表）；需要用户可见说明时走 mms-doc-sync
- [ ] **v2.0.17 / v2.0.18**：`dependency:tree` 无**非白名单**的兄弟业务插件 Maven 依赖；互用关系在 **plugin.json** 的 **dependencies（插件 id）**
- [ ] **若含联邦前端**：**子包**在 **`mms-ui/packages/plugin-<短名>-ui`**（**非**仅堆在 **`src/views`**）；已按本节 **「联邦前端（mms-ui）与插件 JAR 一键打包」** 配置 **`properties`** + **`profile fed-web`**（**`exec` + `copy-resources` → `META-INF/mms/web`**），**`mms.fed.plugin.package`** 与 **`mms-ui` 子包 `package.json` 的 `name`** 一致；**`mms-ui` 根 `package.json` 的 `workspaces`** 已包含该子包；Maven 日志中 **exec 真跑过** `pnpm fed:plugin-ui:build`（非仅复制旧 dist）
```

## mms-plugins 封装踩坑与注意事项（仓库成文）

独立打成 **shade / `*-standalone.jar`**、**文档业务在 `mms-plugin-doc` 本模块**、**手工 wire 构造注入**、**晚载 Servlet 注册 Filter** 等问题时，**必须先阅读**（再以本技能其余章节与代码为准）：

- **`mms-plugins/插件封装踩坑与注意事项.md`**

文中包含：`argument type mismatch` 与 `isInstance`、缺 `DocOrderService` 与 **`mms-plugin-doc` 须 `clean package` 重打 standalone**、应上传 **standalone** 非瘦包、**FilterRegistrationBean** 与 `DocSiteTokenBridgeFilter`、以及后续插件封装的检查清单。**健康探测**在 `health()` 里若校验 **`PluginBeanRegistrar` 已注册的 Bean**，**禁止**对裸 **logicalName** 做 **`ApplicationContext#containsBean`**（宿主实际名为 **`mms.plugin.bean.{会话ID}.{逻辑名}`**，见 **`PluginSpringBeanAttachment#fullBeanName`**）——易误判「Bean 缺失」；**必看该文 §一.5、§二 清单第 10 条**。插件市场 **UI 行为收敛**见 **§二「插件市场页」**。助手在回答「文档插件打包 / 健康检查报 Bean missing / 市场页操作入口」时应 **Read 该文件** 避免重复踩坑。

## 模块与代码位置（`mms/mms-modules`）

| 模块 | 职责 |
|------|------|
| **`mms-plugin-api`** | 契约：`MmsPlugin` SPI、`PluginDescriptor`（含可选 **`backupOperator`**）、`plugin.json`、`PluginRuntimeMode`、`HostServices`（缓存、`hostData()`、`pluginDataAccess(descriptor)`、**`pluginSchemaAccess`（v4+ 受限 DDL）**、**`pluginBackupAccess`（v5+，须 backupOperator）**、**`runInWritableTransaction` / `runInReadOnlyTransaction`**、**`hasWebPermission`**）、**`PluginBeanRegistrar`**、`HostDataService`、`PluginDataAccess`、`PluginSchemaAccess`、`PluginBackupAccess`、`PluginHostUserSnapshot`（DTO）、`PluginRuntimeContext`（含 **`tryInvokePeerPlugin`**、`pluginBeanRegistrar()`、`addUnloadHook`）、`PluginInstallationLayout`、**`PluginHealthContributor`（今后新封装插件须实现并登记 SPI）**、`META-INF/mms/plugin.example.json` |
| **`mms-plugin-host`** | 宿主：`PluginLifecycleManager`、`DefaultHostServices`、`PluginSpringBeanAttachment`（插件单例挂主容器 / 卸载销毁）、**`DefaultPluginBeanRegistrar`**、`PluginSqlGuard` / `JdbcPluginDataAccess`、`NoopHostServices`、`PluginHostController`、`PluginHostProperties`、`PluginMdc`/`PluginReflectionSupport`、`PortManager`、`PluginSubprocessManager`；可选子进程配置见下文 |
| **`mms-plugin-server`** | **`PluginHostDataServiceBridge`**：实现 `HostDataService`（当前 Web 用户、租户、`findUserByIdInCurrentScope` 走 `SysUserService.selectVoById`）；**`PluginSysConfigOperationsImpl`**、**`WechatPluginLifecycleNotifier`**（由 **mms-admin** 引入本模块；包 `com.sxpcwlkj.plugin.server`） |
| **`mms-plugin-sample-health`** | **示例插件**：`mms-plugin-api` + `spring-web`（`provided`）；`onLoad` 演示 **`pluginBeanRegistrar().registerSingleton`**；**HOST_MVC** + `/plugin/{id}/demo/ping` 等；**不**随 **`mms-admin`** 打包 |
| **`mms-plugin-sample-spi`** | **SPI_ONLY** 示例：`mms-plugin-api` only；`onLoad` 使用 **`HostServices` 缓存**；**不**随 **`mms-admin`** 打包 |
| **`mms-plugin-c-base`** | **P0 C 端基础公共**：**HOST_MVC** `/cbase/conventions`（SaaS/插件 Feign 约定）、`/cbase/ping`；无必选 `dependencies`；权限 `plugin:cbase:conventions` |
| **`mms-plugin-tool-datasource`** | **运维 + 迁移 + 备份**：契约 **v5**、`backupOperator: true`；`pluginSchemaAccess`、`pluginBackupAccess`（MySQL 逻辑备份全库/指定表）、HTTP；表前缀 `plugin_ds_`；详见 **`version/v2.0.9-插件数据源与宿主契约v4.md`**；**mms-doc** **`/mms-plugins/datasource`** |
| **`mms-plugin-tool-redis-inspect`** | **只读** Redis SCAN/类型/TTL/值截断预览；**Lettuce**；`sys_config` **`redis.inspect`**；**mms-ui** `system/redisInspect/index`；权限 **`script/install.sql`**；**mms-doc** **`/mms-plugins/redis-inspect`**；需求 **`version/v2.0.10-插件Redis可视化预览开发计划.md`** |

管理端聚合已引入宿主时，运维接口挂在本进程内（路径见下）。

## 配置（`mms/mms-admin` 的 yml）

前缀 **`mms.plugin`**（`PluginHostProperties`）：

| 键 | 含义 |
|----|------|
| `enabled` | 默认 `false`；`true` 时启动/重载会扫描并加载插件 |
| `root-dir` | 插件根目录；未配时常为 `${user.dir}` 下的 `mms-plugins`（以代码与配置为准） |
| `host-mms-revision` | 与根 `pom` 的 **`revision`** 对齐，用于校验 `plugin.json` 中 `requiresMms` |
| `data-access-query-timeout-seconds` | `PluginDataAccess` 使用的 **`JdbcTemplate#setQueryTimeout`**（秒），默认 `30`；`≤0` 表示不设置 |
| `plugin-data-access-audit-log-enabled` | 是否将插件 JDBC 访问记 **INFO** 审计日志（插件 id、操作、参数个数、截断 SQL），默认 `true` |
| `plugin-data-access-auto-tenant-enabled` | 当 **`HostDataService#tryCurrentTenantId`** 非空时，是否为 **`SELECT/UPDATE/DELETE`** 自动追加 **`tenant_id = ?`**（列名见下一项），SQL 已含该列则跳过；**INSERT 不自动改写**，默认 `true` |
| `plugin-data-access-tenant-column` | 自动租户列名（简单标识符），默认 `tenant_id` |
| `subprocess-launch-enabled` | 默认 `false`；`true` 且 `runtimeMode=INDEPENDENT_PROCESS` 时校验 **`mainClass`**，**`independentPort`** 缺省或 ≤0 时在 **`subprocess-port-range-*`** 内 **`PortManager.allocateFirstFreePort`**；**`ProcessBuilder`**（`-cp lib/*`），环境变量 `MMS_PLUGIN_ID`、`MMS_PLUGIN_PORT`、可选 **`MMS_PLUGIN_SUBPROCESS_TOKEN`**（同 `subprocess-admin-token`）、**`MMS_PLUGIN_HOST_CONTEXT_BASE`**（同 `subprocess-peer-context-base-url`）；输出追加 **`subprocess.log`** |
| `subprocess-java-binary` | 默认 `java`（PATH） |
| `subprocess-port-range-min` / `subprocess-port-range-max` | 自动分配端口扫描范围（显式配置 `independentPort` 时仍用该端口） |
| `subprocess-shutdown-grace-period-seconds` | `destroy` 后等待秒数，超时 **`destroyForcibly`** |
| `subprocess-admin-token` | 非空时子进程可带 Header **`X-Mms-Plugin-Subprocess-Token`** 调用 **`GET /system/pluginHost/subprocessPeer/context`**（`@SaIgnore`） |
| `subprocess-peer-context-base-url` | 写入子进程环境变量，便于拼宿主根 URL |
| `subprocess-peer-registry-tenant-id` | 上下文字段 `pluginRegistryTenantId`，默认 `000000` |

### `plugin.json` 扩展（与宿主加载一致）

- **`runtimeMode`**：`SPI_ONLY`（默认）/ `HOST_MVC` / `INDEPENDENT_PROCESS`（默认仍由宿主加载 SPI；若 **`subprocess-launch-enabled=true`** 则额外 fork 子进程，见上表）。
- **`pluginTablePrefix`**、**`pluginDataTables`**：声明后 `pluginDataAccess` 除关键字/前缀校验外，按 **FROM/JOIN/UPDATE/INSERT INTO** 解析表名并强制 **白名单**（物理名 = 前缀 + 相对表名）。
- **`dependencyFingerprintSha256`**：可选；若声明则 JAR 内必须有 **`META-INF/mms/deps-fingerprint.manifest`**（UTF-8 **原始字节**），且其 **SHA-256 十六进制**（忽略大小写）与声明一致。**GAV 规范**：每行 `groupId:artifactId:version`，整文件按字典序排序后写入；可用 `mvn dependency:list` 生成再排序去重。

### `plugin.json`：id / 文案 / 依赖（与「插件开发标准」一致）

**`id` 空间、`name`/`description` 模板、`dependencies` 口径、对外 HTTP 形态**见上文 **「插件开发标准」**；本节以下字段（**`runtimeMode`**、**`pluginTablePrefix`** 等）为 **宿主加载补充约定**。

### HOST_MVC HTTP

- **`@PluginController`** 类须有 **无参构造**；支持 **`@GetMapping` / `@PostMapping` / `@PutMapping` / `@DeleteMapping` / `@PatchMapping`**，以及仅 **`@RequestMapping`**（可声明 **多个 `method`**；未写 `method` 时映射 **GET/POST/PUT/DELETE/PATCH**）。类上可选 `@RequestMapping` 前缀。
- **路径变量**：模板段 **`{name}`**（声明顺序 = 方法形参中 **`String` / `int` / `long`** 与 `HttpServletRequest` 的绑定顺序，可穿插 `HttpServletRequest`）。字面量段仍 **大小写不敏感**。
- 对外路径：**`/plugin/{pluginId}/`** + 相对路径，例如：`/plugin/mms.plugin.sample-health/demo/ping`、`.../demo/echo/hello`。
- 分发器：**`PluginMvcDispatcher`**（`@ConditionalOnWebApplication(SERVLET)`）；**`sa-token.excludes` 默认未放行 `/plugin/**`**，与**普通管理端接口**一样需登录（tenant/权限随 Sa-Token）；仅在配置中显式排除时才会匿名。
- **卸载顺序**：重载前先 **`PluginMvcRegistrar#unregister`**，再 **`onUnload`** → **卸载钩子** → **`PluginSpringBeanAttachment#releaseSession`**（插件注册的单例）→ **关闭 ClassLoader**（见 **`LoadedPluginInstance`**）。
- `reload` / 全量卸载会 **`PluginMvcRegistry.unregister`**。

### `PluginBeanRegistrar`（宿主 Spring 单例）

- **`PluginRuntimeContext#pluginBeanRegistrar()`**：`registerSingleton(logicalName, bean)` 将实例挂入主 **`ConfigurableApplicationContext`**（`DefaultListableBeanFactory#registerSingleton`），容器真实名为 **`mms.plugin.bean.<loadSessionId>.<logicalName>`**；每次加载新 UUID **`loadSessionId`**，热替换同版本不会与上一加载冲突。
- 卸载时按注册 **逆序** `destroySingleton`，宜实现 **`DisposableBean`** 释放资源；`onLoad` 失败路径也会 **`releaseSession`**，避免半注册泄漏。
- 非 **`DefaultListableBeanFactory`** 的容器上会注册失败；仅信任插件使用（市场/安装源需管控）。
- 日志 **MDC**：`pluginId`、`pluginVersion`、`pluginKey`（`PluginMdc.pushPluginContext`）；**HOST_MVC** 分发、`onLoad`/`onUnload`、反射调用路径会设置；线程池执行 HOST_MVC 时 **`PluginMvcExecutorRegistry`** 会拷贝 MDC 到 worker。**`mms-admin`** 使用 **`logback-spring.xml`**：**`PluginOnlySiftingAppender`**（`plugin_sift`）将带 `pluginKey` 的日志写入 **`logs/plugins/{pluginKey}.log`**；写入该文件的最低级别由配置项 **`mms.logging.plugin-sift-min-level`** 控制（**local/dev** 常为 **DEBUG**，**prod** 为 **INFO**，与 **`application-*.yml`** 一致）。**封装约定与自检**见下文 **「封装规范：可观测性」**。
- **依赖加载顺序**：库表激活坐标与**整盘孤儿/无库表批**在加载前按 **`plugin.json` `dependencies`**（忽略 `optional=true`）拓扑排序；缺依赖、环路、磁盘批同插件多版本歧义 → **`PluginException`**。

## 磁盘布局（安装约定）

由 **`PluginInstallationLayout`** 描述：

- `<pluginsRoot>/<safePluginId>/<safeVersion>/**`
- **`lib/`**：插件及依赖 JAR（宿主从此加载）
- **`data/`**、**`tmp/`**：运行时数据与临时文件（插件应限制写入范围）
- 根下可有 **`plugin.json`** 描述副本（与 JAR 内 `META-INF/mms/plugin.json` 对齐）

`safeSegment` 会将 `id/version` 中的 `/` `\` `:` 等替换为 `_`。

## JAR 内必备元数据

- 描述文件首选：**`META-INF/mms/plugin.json`**（或兼容根路径 `plugin.json`，见 `PluginConstants`）
- SPI：**`META-INF/services/com.sxpcwlkj.plugin.MmsPlugin`** → 实现类全限定名（每行一个）
- `entryClass` 与 `MmsPlugin` 实现一致时，宿主在加载后调用 `onLoad` / `onUnload`
- **健康探测（项目约定）**：**今后新封装的插件须**提供 **`PluginHealthContributor`**（独立类或与 `MmsPlugin` **同一实现类**均可），并登记 **`META-INF/services/com.sxpcwlkj.plugin.PluginHealthContributor`**。宿主 **`collectHealth`** 调用 **`health()`**：返回字符串即记为 **`OK`**（供 **`GET /system/pluginHost/health`** 与市场 **`healthBody`**）；**关键故障须 `throw`** 才会记 **`ERROR`**，市场卡片「健康」为**异常**（仅在上层 JSON 里写 `DOWN` 而**不抛异常**时，汇总仍可能被视作「正常」，易误导）。**shade** 时使用 **`ServicesResourceTransformer`** 以免合并丢多文件 SPI。参考 **`mms-plugins/mms-plugin-doc/.../DocPluginHealthContributor`**、**`mms-plugins/mms-plugin-sample-health`**。
- **健康探测易错（与上条同读）**：若在 **`health()`** 中根据 **`ApplicationContext`** 判断 **`pluginBeanRegistrar()` 登记的 Bean** 是否就绪，须使用宿主 **`PluginSpringBeanAttachment#fullBeanName`** 命名规则：`mms.plugin.bean.{loadSessionId}.{logicalName}`。**禁止**写 **`containsBean(logicalName)`**（恒假），应 **`getBeanNamesForType`** 枚举或 **`name.endsWith("." + logicalName)`** 等。重复踩坑记录与示例：**`mms-plugins/插件封装踩坑与注意事项.md` §一.5**、清单 **§二 第 10 条**；契约说明见 **`PluginHealthContributor`**（`mms-plugin-api`）类 Javadoc。

校验逻辑在 **`PluginDescriptorValidator`**；示例 JSON 在 **`mms/mms-modules/mms-plugin-api/src/main/resources/META-INF/mms/plugin.example.json`**。

### 插件前端 · JAR 内静态资源（联邦 UI / `META-INF/mms/web` 标准）

> **结论**：**可以把 Web 静态产物与插件 JAR 一起打**；约定落在 **`META-INF/mms/web/**`**，由宿主按 **`plugin.json` `frontend`** 与 **`/plugin-assets/{pluginId}/{version}/...`**（及 **`remoteEntryFile`** 等）提供；需求背景见 **`version/v2.0.4-插件前端联邦模块开发方案.md`**（路径以仓库为准）。

#### 资源位置与访问

| 项 | 说明 |
|----|------|
| **JAR 内路径** | **`META-INF/mms/web/`** 下为构建产物根（如 **`assets/`**、**`index.html`**、**`remoteEntry.js`** 等，以 Vite 联邦 **`dist/`** 为准）。 |
| **宿主** | 静态映射与 **`PluginResourceController`** / **`PluginHostProperties`** 一致；管理端访问前缀与 **`plugin.json` → `frontend`** 对齐。 |
| **仅后端、不要联邦页** | 不打 **`fed-web`** 或不在 `resources` 中放入 **`META-INF/mms/web`** 即可；主工程可用 **Vite 别名** 直出同页（见 **syslog** 子包 README）。 |

#### 参考实现（本仓库「标准」）

| 文件 | 作用 |
|------|------|
| **`mms-plugins/mms-plugin-tool-syslog/pom.xml`** | **`fed-web`** profile：**`exec-maven-plugin`**（`pnpm`）+ **`maven-resources-plugin`**（`copy-resources` → **`target/classes/META-INF/mms/web`**）。 |
| **`mms-plugins/mms-plugin-tool-syslog/README.md`** | 一条命令、**跳过前端** 的 Maven 参数说明。 |
| **`mms-ui/scripts/fed-plugin-ui.mjs`** | **`pnpm --filter <workspace 包名> build|dev`**；**须过滤 argv 中的字面量 `--`**（见下「易错」）。 |
| **`mms-ui/package.json`** | **`fed:plugin-ui:build`** / **`fed:plugin-ui:dev`** 入口。 |
| **`mms-ui/pnpm-workspace.yaml`** | **`packages/*`**；联邦子包必须在 workspace 内，**`package.json` 的 `name`** = **`mms.fed.plugin.package`**。 |

#### Maven：`fed-web` 一条线（新插件可复制）

1. **属性**（示例名，按插件改名）  
   - **`mms.ui.root`**：指向 **`mms-ui`** 根（相对 **`mms-plugins/mms-plugin-xxx`** 多为 **`${project.basedir}/../../mms-ui`**）。  
   - **`mms.fed.plugin.package`**：与 **`mms-ui/packages/<子目录>/package.json`** 的 **`name`** 一致（如 **`@mms-ui/plugin-syslog-ui`**）。  
   - **dist 目录属性**：如 **`${mms.ui.root}/packages/plugin-syslog-ui/dist`**。  
   - **跳过前端构建**：**`skip.fed.*.ui.build`**（syslog 为 **`skip.fed.syslog.ui.build`**），默认 **`false`**；仅拷已有 **`dist`** 时 **` -Dskip.fed.syslog.ui.build=true`**（以该模块 `pom` 为准）。

2. **`exec-maven-plugin`（`prepare-package`）**  
   - **`workingDirectory`** = **`${mms.ui.root}`**  
   - **`executable`** = **`pnpm`**  
   - **`arguments`**：**`run` `fed:plugin-ui:build` `--` `${mms.fed.plugin.package}`**（Maven 传参里保留 **`--`**，与命令行 **`pnpm run fed:plugin-ui:build -- @mms-ui/...`** 一致）。

3. **`maven-resources-plugin`（`prepare-package`，`copy-resources`）**  
   - **`outputDirectory`**：**`${project.build.outputDirectory}/META-INF/mms/web`**  
   - **`resources.resource.directory`**：上述 **dist** 目录  
   - **建议为 `maven-resources-plugin` 显式声明 `version`**（如 **3.3.1**，或与父 POM **`pluginManagement`** 一致），避免未声明版本告警。

4. **验收日志**  
   - **`exec`** 段应出现 **`vite build`**（或子包 **`build` 脚本**）**成功输出**。  
   - **`copy-resources`** 应报告从 **`…/dist`** 复制若干文件到 **`META-INF/mms/web`**。  
   - **`jar`** 成功。

#### `fed-plugin-ui.mjs` 易错（Maven / pnpm）

- **`pnpm run fed:plugin-ui:build -- @scope/pkg`** 会把 **`--`** 传给 Node；若脚本把 **`--`** 当成 **包名**，会执行 **`pnpm --filter -- build`** → **`No projects matched the filters`**，**exit code 仍可能为 0**，随后 **`copy-resources`** 仍可能复制**旧的 `dist`**，出现 **BUILD SUCCESS 但前端未真正重编**。  
- **现行实现**：对 **`process.argv` 去掉 **`--`** 后再取 **`build|dev`** 与 **包名**（见 **`mms-ui/scripts/fed-plugin-ui.mjs`**）。

#### 包管理器（mms-ui）

- **联邦与子包**：以 **`pnpm`** + **`pnpm-workspace.yaml`** 为准；Maven **`exec`** 调用 **`pnpm`**。  
- **稳定性**：与「npm 与 pnpm 谁更稳」无关，关键是 **锁文件（`pnpm-lock.yaml`）进库**、**本机/CI 使用同一包管理器**、**先 `pnpm install`**。

#### 管理端 HOST_MVC 请求（与 `VITE_APP_BASE_API` 一致）

- **浏览器路径**：**`${VITE_APP_BASE_API}/plugin/{pluginId}/...`**（开发 **`/dev-api`**、生产 **`/prod-api`**），与 **`/dev-api` / `/prod-api` 单段代理**一致；网关去掉前缀后，**后端仍为** **`/plugin/...`**（**不改宿主**）。
- **实现**：**`mms-ui/src/utils/mms.ts`** 的 **`pluginHostMvcPrefix()`**；已用于 **`packages/plugin-syslog-ui/SyslogPage`**、**`views/system/redisInspect`** 等；宿主菜单直出联邦子包源码用 **`@mms-packages/<目录>/src/...`**（**`vite.config` 中 `@mms-packages` → `packages/`**，**勿**逐插件配别名）；**Vite** 仅需保留 **`/plugin-assets`** 代理，**无需**再为 **`/plugin`** 单独开代理。
- **Nginx**：仅 **`location /prod-api/` → mms-admin`** 时，**`/prod-api/plugin/...`** 会随前缀剥离落到后端 **`/plugin/...`**，**不必**再写独立 **`location /plugin/`**（除非有未走 **`prod-api`** 的直连）。

#### 新插件复用清单（联邦）

```
- [ ] mms-ui/packages 下子包 name 与 mms.fed.plugin.package、plugin.json frontend 路径一致
- [ ] 从 mms-plugin-tool-syslog 复制 fed-web 思路：改 dist 路径、skip 属性名、mms.fed.plugin.package
- [ ] mvn … -Pfed-web package 日志中 exec 有 vite build，无 No projects matched the filters（除非故意 -Dskip…）
- [ ] jar 内 META-INF/mms/web 含 remoteEntry 与 assets（与 plugin.json 一致）
```

### 插件联邦 Remote 可引用的宿主文件清单

> **背景**：插件 UI（Federation remote）通过 `/@` 别名可引用宿主 `mms-ui/src/` 下的模块。但若引用的宿主文件顶层 import 了 `crypto-js`、`vue-demi`、`/@/stores/*` 等**非 shared 重型依赖**，这些依赖会被打包进 `remoteEntry.js`，在浏览器加载时与 shared 模块（vue、pinia）产生初始化时序冲突，导致 `ReferenceError: Cannot access 'X' before initialization`（TDZ 崩溃）。**已验证案例**：从 `/@/utils/mms` 导入任何函数 → 远程模块报 TDZ 错误。

#### ✅ 安全引用（可直接 `import ... from`）

| 宿主路径 | 可用的导出 | 判断依据 |
|---------|-----------|---------|
| `/@/enums/SysEnum` | `SysEnum` | 零 import，纯 enum |
| `/@/enums/CURDEnum` | `CURDEnum` | 零 import，纯 enum |
| `/@/enums/RespEnum` | `HttpStatus` 等 | 零 import，纯 enum |
| `/@/utils/storage` | `Session`, `Local`, `Cookie` | 仅依赖 `js-cookie`（轻量，已由 syslog-ui 验证） |
| `/@/utils/errorCode` | `errorCode` | 零 import，纯常量 |
| `/@/utils/formatTime` | `formatDate` | 零 import，纯函数 |
| `/@/utils/arrayOperation` | `judementSameArr` 等 | 零 import，纯函数 |
| `/@/utils/toolsValidate` | `url` 等 | 零 import，纯校验函数 |
| `/@/utils/mitt` | mitt 事件总线 | 仅依赖 `mitt`（轻量） |
| `/@/utils/loading` | `NextLoading` | 依赖全是 shared（vue + element-plus） |

#### ❌ 禁止引用

| 宿主路径 | 为什么不能 |
|---------|-----------|
| **`/@/utils/mms`** | 顶层 import `crypto-js`(100KB+)、`vue-demi`、`/@/stores/app`（pinia store），打包进 remote 导致 TDZ 崩溃 |
| **`/@/utils/request`** | 间接引入 `mms.ts`，且拦截器依赖宿主路由/view |
| **`/@/utils/other`** | 引入 `router`、pinia stores、`i18n` |
| **`/@/utils/authFunction`** | 引入 `/@/stores/userInfo`（pinia store） |
| **`/@/utils/commonFunction`** | 引入 `vue-i18n`、`vue-clipboard3` |
| **`/@/utils/theme`** / **`themeColorPresets`** | 复杂的主题工具链，宿主特定 |

#### 组件（Vue SFC）

宿主 Vue 组件（如 `/@/components/fast-select/src/fast-select.vue` 等）依赖基本是 shared 的 vue/element-plus，通常安全。但个别复杂组件可能内部引入重型宿主模块，首次使用时需检查其 `<script>` 中的 import 链。

#### 自助判断规则

看宿主文件的**前几行 `import`**：

- 全是 `vue` / `element-plus` / `vue-router` / `pinia` → **安全**
- 有 `crypto-js`、`vue-demi`、`vue-i18n` 等**非 shared 包** → **禁止**
- 有 `/@/stores/*` → **禁止**（引入 pinia store，初始化时序不可靠）
- 有 `/@/router/*` → **禁止**
- 零 import 或只有其他已验证安全的模块 → **安全**

#### 简单函数的处理策略

若需要只使用某个文件中的**一个简单函数**（如 `generateUUID` 仅依赖 `Math.random()`），**不要从宿主导入整个文件**，应将该函数内联到插件本地的 `src/utils/` 中。这样既避免了重型依赖链，也减小了 remote 产物体积。

### 插件通用工具包（plugin-common-kit）

> **位置**：`mms-ui/packages/plugin-common-kit/`。所有插件 UI 项目均可引入此工具包，避免在每个插件中重复造轮子，且工具包内所有代码已严格验证不含 `mms.ts` 等重型宿主依赖。

#### 工具包内容

| 模块 | 导入路径 | 说明 |
|------|---------|------|
| **请求** | `…/api/request` | `createHttp`（axios 实例，自动注入 token）、`createCrudApi`（list/query/insert/edit/delete） |
| **字典** | `…/utils/dict` | `labelFromMap`、`optionsFromMap`、`SYS_STATE_MAP`、`SYS_STATE_OPTIONS` |
| **存储** | `…/utils/storage` | re-export `Session`、`Local`、`Cookie`、`SysEnum`（已验证安全的宿主工具） |
| **枚举** | `…/utils/enums` | re-export `CURDEnum`、`HttpStatus`（零 import，纯 enum） |
| **加载** | `…/utils/loading` | re-export `NextLoading`（依赖全是 shared） |
| **错误码** | `…/utils/errorCode` | re-export `errorCode`（零 import，纯常量） |
| **时间** | `…/utils/formatTime` | re-export `formatDate`、`getWeek`、`formatPast`、`formatAxis`（零 import） |
| **数组** | `…/utils/arrayOperation` | re-export `judementSameArr`、`isObjectValueEqual`、`removeDuplicate`（零 import） |
| **校验** | `…/utils/toolsValidate` | re-export `url`、`phone`、`email`、`idCard`、`password` 等全部校验函数 |
| **事件总线** | `…/utils/mitt` | re-export mitt 事件总线（仅依赖 mitt） |
| **UUID** | `…/utils/uuid` | `generateUUID`（零依赖，纯自实现） |
| **表格工具栏** | `…` 或 `…/components/PluginTableTool` | `PluginTableTool`（新增 + 批量删除） |

> 所有 `…` 为 `@mms-ui/plugin-common-kit`，上表省略重复前缀。除 `request.ts`、`dict.ts`、`uuid.ts` 为自研外，其余均为 **已验证安全的宿主模块薄包装**——文件只做 `export { X } from '/@/...'`，不引入任何重型依赖。

#### 在插件项目中引用

1. **添加依赖**：在插件 `package.json` 中加入 `"@mms-ui/plugin-common-kit": "workspace:*"`。
2. **使用**：

```ts
// 请求
import { createCrudApi } from '@mms-ui/plugin-common-kit/api/request';
const baseApi = createCrudApi('/prod-api/doc/docProduct');

// 字典
import { labelFromMap, optionsFromMap } from '@mms-ui/plugin-common-kit/utils/dict';
const MY_MAP = { 1: '启用', 0: '禁用' };
export const MY_OPTIONS = optionsFromMap(MY_MAP);

// 存储与枚举（从宿主安全 re-export）
import { Session, SysEnum, CURDEnum, HttpStatus } from '@mms-ui/plugin-common-kit';
const token = Session.get(SysEnum.TOKEN_KEY);

// 校验
import { url, phone, email } from '@mms-ui/plugin-common-kit/utils/toolsValidate';
if (!url(input)) { /* ... */ }

// 日期格式化
import { formatDate } from '@mms-ui/plugin-common-kit/utils/formatTime';

// 加载
import { NextLoading } from '@mms-ui/plugin-common-kit/utils/loading';
NextLoading.start();
// ...
NextLoading.done();

// 组件
import { PluginTableTool } from '@mms-ui/plugin-common-kit';
```

3. **pnpm workspace**：`pnpm-workspace.yaml` 已含 `packages/*`，无需额外配置。首次使用需 `pnpm install`。

#### 工具包设计原则（新增文件时遵守）

- **零重型宿主依赖**：绝对不导入 `/@/utils/mms`、`/@/stores/*`、`/@/router/*`、`crypto-js`、`vue-demi`、`vue-i18n` 等。
- **仅引用已验证安全的宿主模块**：`/@/utils/storage`（js-cookie）、`/@/enums/SysEnum`、`/@/enums/CURDEnum`、`/@/utils/loading`（NextLoading）等。
- **纯工具/组件优先**：能用纯 TypeScript 就不依赖 Vue；能用 element-plus 原生组件就不包装宿主组件。
- **需要字典时在插件本地定义映射**：通用 kit 提供 `labelFromMap` / `optionsFromMap` 辅助函数，具体业务字典（如订单状态）由各插件声明。

---

## 插件前端联邦开发硬性约束（全项目强制）

> **适用范围**：所有 `mms-ui/packages/plugin-*-ui/` 下的插件前端项目。以下规则为 **硬性门禁**，违反任意一条即导致 Federation 运行时错误或认证失败。协作助手在开发/修改任何插件 UI 时必须逐条自检。

### 一、依赖配置（必须两步）

1. **添加 common-kit 依赖**：在插件 `package.json` 中必须包含：
   ```json
   "dependencies": {
     "@mms-ui/plugin-common-kit": "workspace:*"
   }
   ```

2. **禁止遗漏 `pnpm install`**：添加依赖后须在 `mms-ui/` 目录执行 `pnpm install`，否则 vite build 找不到模块。

### 二、导入规则（禁止清单）

以下导入**绝对禁止**出现在任何插件 UI 文件中。违反即导致 `ReferenceError: Cannot access 'X' before initialization` 的 Federation TDZ 错误。

| 禁止的导入 | 原因 | 替代方案 |
|-----------|------|---------|
| `import ... from '/@/utils/mms'` | 顶层 import `crypto-js`、`vue-demi`、pinia store | 用 `@mms-ui/plugin-common-kit` 提供的工具函数 |
| `<FastSelect>` / `<FastTableColumn>` / `<FastSwitch>` / `<FastRadio>` | 内部依赖 `/@/utils/mms` + `/@/stores/app` | 用原生 element-plus（`el-select`、`el-switch`）+ 本地字典映射 |
| `<TableTool>` | 依赖 `mms.ts` + 宿主上传/导出路径 | 用 `import { PluginTableTool } from '@mms-ui/plugin-common-kit'` |
| `import ... from '/@/utils/request'` | 依赖宿主路由/拦截器/加密 | 用 `import { createHttp, createCrudApi } from '@mms-ui/plugin-common-kit/api/request'` |
| `import ... from '/@/utils/other'` | 引入 `router`、pinia stores、`i18n` | 无替代，不要在插件页面中使用 |
| `import ... from '/@/utils/authFunction'` | 引入 pinia store | 权限由后端 Sa-Token 控制，前端用 `v-auth` 指令即可 |
| `import ... from '/@/utils/commonFunction'` | 引入 `vue-i18n`、`vue-clipboard3` | 如需剪贴板，直接在插件中引入 `vue-clipboard3` |
| `import ... from '/@/utils/theme'` | 复杂的主题工具链 | 直接使用 element-plus 的主题变量 |

### 三、导入规则（允许清单）

以下导入是**安全**的，通过 `@mms-ui/plugin-common-kit` 统一入口引入：

| 所需工具 | 推荐导入 |
|---------|---------|
| 请求（axios + token） | `import { createHttp, createCrudApi } from '@mms-ui/plugin-common-kit/api/request'` |
| 存储 / 枚举 | `import { Session, Local, Cookie, SysEnum, CURDEnum, HttpStatus } from '@mms-ui/plugin-common-kit'` |
| 字典 | `import { labelFromMap, optionsFromMap, SYS_STATE_MAP, SYS_STATE_OPTIONS } from '@mms-ui/plugin-common-kit/utils/dict'` |
| UUID | `import { generateUUID } from '@mms-ui/plugin-common-kit/utils/uuid'` |
| 加载 | `import { NextLoading } from '@mms-ui/plugin-common-kit/utils/loading'` |
| 日期格式化 | `import { formatDate, formatPast } from '@mms-ui/plugin-common-kit/utils/formatTime'` |
| 校验 | `import { url, phone, email } from '@mms-ui/plugin-common-kit/utils/toolsValidate'` |
| 事件总线 | `import { mitt } from '@mms-ui/plugin-common-kit/utils/mitt'` |
| 表格工具栏 | `import { PluginTableTool } from '@mms-ui/plugin-common-kit'` |
| 日志查看器 | `import { usePluginLogViewer } from '@mms-ui/plugin-common-kit/composables/usePluginLogViewer'` |

> **原则**：插件 UI 文件中**不出现** `from '/@/` 字符串（`common-kit` 自身除外，它是薄包装层）。所有宿主工具通过 `@mms-ui/plugin-common-kit` 统一入口获取。

### 四、组件规则

- **禁止使用宿主 `Fast*` 组件家族**（`FastSelect`、`FastTableColumn`、`FastSwitch`、`FastRadio` 等）。
- **字典下拉框**：用 `el-select` + 从 `common-kit` 的 `optionsFromMap()` 生成的选项数组。
- **字典表格列**：用 `el-table-column` + template 内调用 `labelFromMap()`。
- **开关**：用 `el-switch`，直接绑定 `:active-value="1" :inactive-value="0"`。
- **表格工具栏**：用 `PluginTableTool`（来自 common-kit），支持 `@insert` 和 `@deletes` 事件。

### 五、axios / Token

- **禁止**在插件中 `axios.create()` + 自己从 `localStorage` 读 token。
- **必须**用 `createHttp()` 或 `createCrudApi()`（来自 common-kit），自动从 cookie 读取 token 并注入 `Authorization` 头。

### 六、交付前自检（助手必做）

执行 `mms-ui/` 下 `rg "from '/@/" packages/plugin-<你的插件名>-ui/src/`，输出必须为 0。

```
- [ ] 插件 package.json 包含 `"@mms-ui/plugin-common-kit": "workspace:*"`
- [ ] 插件 src/ 下无任何 `from '/@/` 的 import
- [ ] 无 `<FastSelect>` / `<FastTableColumn>` / `<FastSwitch>` / `<TableTool>` 等宿主组件
- [ ] 无 `axios.create()` + `localStorage.getItem('token')` 模式
- [ ] 请求全部通过 `createCrudApi()` 或 `createHttp()`
- [ ] 字典下拉 / 表格列使用本地映射（`labelFromMap` / `optionsFromMap`）+ el-select / el-table-column
- [ ] `pnpm install` 已执行，`vite build` 无报错
- [ ] 浏览器控制台无 Federation TDZ 错误
```

---

### 插件参数（`sys_config`，持久化）

- **键规则**：`mms.plugin.{pluginId}.{suffix}`（`suffix` 字母开头，见 **`PluginSysConfigKeys`**），与系统内置 `sys_*` 键隔离，避免冲突。
- **宿主契约**：**`HostServices#hostImplementedContractVersion()` ≥ 3** 时提供 **`pluginSysConfigGet` / `pluginSysConfigPut` / `pluginSysConfigList`**，按当前租户（无 Web 上下文时回退 **`000000`**）读写 **`sys_config`**。
- **管理端**：**`GET` / `POST`** **`/system/pluginMarket/pluginSysConfig`**（**super_admin**），插件市场 **详情弹窗**内可编辑；**`config_value` 长度受表字段限制（当前 255）**。
- **实现**：**`PluginSysConfigOperations`**（**`mms-plugin-server`** 的 **`PluginSysConfigOperationsImpl`**）+ 可选 Bean 注入 **`DefaultHostServices`**。
- **市场「插件参数」与磁盘 `sysConfig`**：**`PluginLifecycleManager#resolveSysConfigSchema`** 在未加载时从 **`lib/*.jar`** 探测 **`plugin.json`**。**`PluginDescriptorProbe.tryReadForPlugin(versionDir, pluginId)`** 会**优先**选用 **`descriptor.id` 与当前插件 id 一致** 的 JAR，再回退「首个可解析 JAR」；避免 **`lib`** 内依赖包也带 **`plugin.json`** 且字典序靠前时**错拿描述符**导致 **`sysConfig` 为空**、市场表单无行。

## 封装规范：可观测性（独立日志 · 健康探针 · 生命周期）

新封装或改版插件时，助手应按下述约定自检；与 **`mms-plugins/插件封装踩坑与注意事项.md`** 清单互补。

### 独立日志文件（`logs/plugins/{pluginId}@{version}.log`）

- **机制**：管理端 **`logback-spring.xml`** 中 **`PluginOnlySiftingAppender`**（`plugin_sift`）仅当 MDC 存在 **`pluginKey`**（`pluginId@version`，与 **`PluginMdc.PLUGIN_KEY`** 一致）时，才把该条日志写入 **`logs/plugins/{pluginKey}.log`**；文件内阈值由 **`mms.logging.plugin-sift-min-level`** 注入（详见上文 HOST_MVC 日志 MDC 小节），**控制台**仍受 **`logging.level.*`** 约束。
- **目录覆盖**：与 **`mms.plugin.plugin-log-dir`**（`PluginHostProperties`）及 **`GET /system/pluginHost/pluginLogTail`** 读取路径一致；未配置时一般为进程 **`user.dir/logs/plugins`**。
- **常见误解**：宿主在 **`popMdc` 之后**打的「插件已加载」等**不带** `pluginKey`，**不会**进入上述独立文件；若插件 **`onLoad` 内从不打日志**，且从未走 HOST_MVC/带 MDC 的路径，该文件可能长期为空——**属预期**，除非补充插件侧或宿主侧（见下）带 MDC 的日志。

### 宿主侧已提供的生命周期日志（带 `pluginKey`，会进独立文件）

宿主在 **`PluginLifecycleManager` / `PluginMvcRegistrar` / 卸载路径**等处对**每个已加载插件**写入（实现随版本演进，以代码为准）：**`onLoad` 成功/失败**、未注册 **`PluginHealthContributor`** 时的 **WARN**、**HOST_MVC 路由注册**成功/失败、**插件就绪**（runtimeMode、子进程端口等）、**卸载成功/失败**、全量卸载时的逐插件卸载等。封装插件时**可依赖**这些行作为「加载/运行/异常」基线，仍建议在插件内补充业务级日志。

### 插件侧应写的日志（SLF4J）

- **`onLoad` / `onUnload`**：至少各 **1 条 INFO**（关键资源安装/释放成功），便于独立日志与排障；异常用 **ERROR** 并带堆栈。
- **HOST_MVC 控制器**：关键接口成功路径可打 **INFO**（避免刷屏）；**`PluginMvcDispatcher`** 在分发与（若配置）线程池 **`wrapForPluginMvcWorker`** 中会传递 MDC，插件代码打出的日志可进独立文件。
- **禁止**依赖「宿主一句插件已加载」作为插件文件内容来源——那句通常**不在** MDC 内。

### 健康探针（必配）

- **必须**：实现 **`PluginHealthContributor`**，并登记 **`META-INF/services/com.sxpcwlkj.plugin.PluginHealthContributor`**（**shade** 时 **`ServicesResourceTransformer`**，避免 SPI 合并丢行）。
- **语义**：**`health()` 返回字符串**即聚合为 **`OK`**；业务不可用须 **`throw`**，宿主 **`collectHealth`** 记 **`ERROR`** 并打 **WARN** 日志；**仅返回含 `DOWN` 的 JSON 而不抛异常**易误导，**禁止**依赖这种方式表示故障。
- **无探针 SPI**：宿主聚合为 **`NO_HEALTH_SPI`**，加载时会 **WARN**「建议补充健康探针」；`collectHealth` 对无 SPI 打 **DEBUG**（避免刷屏）。
- **易错**：在 **`health()`** 里用 **`ApplicationContext#containsBean(logicalName)`** 判断插件注册的 Bean 会恒假——须按 **`PluginSpringBeanAttachment#fullBeanName`** 规则枚举 Bean 名；见上文「JAR 内必备元数据」与踩坑文 **§一.5**。
- **参考**：**`mms-plugin-doc`**（`DocPluginHealthContributor`）、**`mms-plugin-tool-syslog`**、**`mms-plugin-sample-spi`**（独立探针类）、**`mms-plugin-sample-health`**。

### 聚合与健康接口

- **`GET /system/pluginHost/health`**（**super_admin**）：行内 **`state`** 为 **`OK` / `ERROR` / `NO_HEALTH_SPI`**，**`body`** 为探针返回或异常信息。
- 探针失败时宿主侧会 **`log.warn("插件健康探针异常: …")`**，便于主日志关联。

### 封装自检清单（可观测性）

```
- [ ] META-INF/services 同时包含 MmsPlugin 与 PluginHealthContributor（或文档约定的一体化类）
- [ ] onLoad/onUnload 至少有各一条 INFO，关键异常 ERROR
- [ ] health() 用抛异常表示不可用；校验 Spring Bean 时不使用裸 logicalName 的 containsBean
- [ ] shade/standalone 合并 services 时使用 ServicesResourceTransformer
- [ ] 期望在「插件独立日志」中看到内容时：确认日志打在带 pluginKey 的线程上下文中（见上文）
```

## 运维 HTTP API

`PluginHostController`：**`@RequestMapping("system/pluginHost")`**。**除带 `@SaIgnore` 的 `subprocessPeer/*` 外**，方法均需 **`@SaCheckRole("super_admin")`**：

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/status` | 开关、配置 `rootDir`、`hostMmsRevision`、**`resolvedPluginsRoot`**、**`pluginsRootReady`**、**`activateVersionReloadScope`**（`FULL` / `SINGLE_TARGET`，与 `mms.plugin.activate-version-reload-scope` 一致）、已加载摘要 |
| POST | `/reload` | 全量重载插件 |
| GET | `/health` | 各插件健康行 |
| GET | `/manifests` | 已加载插件 manifest（含 `frontend` 提示，与 UI 协议衔接） |
| POST | `/uninstall` | 按 `pluginId` / 可选 `version` 从磁盘删除目录后重载 |
| POST | `/activateVersion` | 切换库表激活版本后：**`FULL`** 为全量 `reload()`；**`SINGLE_TARGET`** 仅 `reloadSingleActivated`（不保证依赖拓扑，见 **`version/v2.0.5-…§5`**） |
| POST | `/install` | `multipart` 字段 **`file`**，单 **`.jar`**；校验通过后落盘、可选入库、重载 |
| GET | `/pluginLogTail` | `pluginId` 必填，`version` 可选（未传则从已加载 manifest/summary 推断）；`maxBytes` 默认约 128KB，上限 2MB；读 **`logs/plugins/{pluginId}@{version}.log`** 尾部（与 logback `plugin_sift` 一致）。可用 **`mms.plugin.plugin-log-dir`** 覆盖目录 |
| POST | `/pluginLogClear` | body：`pluginId`、`version`（可选，推断规则同 tail）；**截断**该插件独立日志文件为 0 字节 |
| POST | `/invoke` | body：`pluginId`、`version`（可选）、`methodName`、**`args`**（JSON 数组，`ObjectMapper#convertValue`）；反射 **`MmsPlugin` 公有实例方法** |
| GET | `/subprocesses` | **`PluginSubprocessSnapshot`** 列表：端口、租约/TCP 探测、pid、alive、lastError |
| GET | `/subprocessPeer/context` | **`@SaIgnore`**，Header **`X-Mms-Plugin-Subprocess-Token`** = **`subprocess-admin-token`** |
| GET | `/subprocessPeer/loadedManifests` | 同上 Token；已加载 manifest 列表 |
| POST | `/subprocessPeer/invoke` | 同上 Token；body 同 **`/invoke`**（与 ops 限流/熔断共用） |

**独立子进程 ↔ 宿主 Peer 的冻结契约**（路径、Header、`hostData` 键、`R` 失败文案、兼容策略、**`SINGLE_TARGET` 边界**）：**`version/v2.0.5-插件子进程Peer契约与激活重载边界.md`**（**M-A / B-1 / B-6**）。

与业务协作、权限细节以当前 Controller 为准；**HOST_MVC** 使用 **`@PluginController`**。进程内对等调用用 **`PluginRuntimeContext#tryInvokePeerPlugin`**。装入 ClassLoader **之前**，宿主按 **`plugin.json` `dependencies`（非 optional）** 校验对等插件是否**已加载**及 **versionRange**；失败则 WARN、`PluginLifecycleEventType.PLUGIN_DEPENDENCY_MISSING`，**`WechatPluginLifecycleNotifier`** 可推企微（若机器人插件已加载）；说明见 **`version/v2.0.8-C端插件化与依赖校验落地.md`**。**插件市场**在 **`INDEPENDENT_PROCESS`** 且开启子进程时合并子进程状态字段。

### 磁盘布局探测（市场列表标记）

- **`PluginJarLocationStatus`**（`mms-plugin-host`）：`OK`、`ROOT_NOT_DIRECTORY`、`VERSION_DIR_MISSING`、`LIB_DIR_MISSING`、`JAR_NOT_FOUND`。
- **`PluginLifecycleManager`**：`isPluginsRootDirectory()`；`probeVersionLayout(pluginId, version)`（与加载时 `lib` 扫描一致）。
- **`PluginMarketCardVo.diskLayoutWarning`**：`SysPluginMarketServiceImpl` 合并卡片时写入枚举名；根不可用则**所有**卡片标记 `ROOT_NOT_DIRECTORY`；有库表激活版本则探测该版本目录；磁盘有插件目录但所有槽位无 jar 则 `JAR_NOT_FOUND`。列表枚举磁盘槽位时用**全部** `DiskPluginSlot`（含无 jar 目录），避免漏卡片。

## 插件市场（管理端 UI + 市场 API）

| 位置 | 说明 |
|------|------|
| `mms-ui/src/views/system/pluginMarket/index.vue` | 插件市场页：卡片仅 **「详情」** 打开弹窗；**卸载**=只删**磁盘**安装目录（`pluginHost/uninstall`），**不动库表**，可再 **安装**；**删除**=只清 **库表** 登记（`removeCatalog`），**不删磁盘**。二者不同，勿把卸载当成「删除插件条目」。 |
| `mms-ui/src/views/system/pluginMarket/api.ts` | `hostBase`=`/system/pluginHost`，`marketBase`=`/system/pluginMarket` |

**`PluginMarketController`**（`mms-system`，`super_admin`）：

- `GET /system/pluginMarket/cards`：合并库表与宿主状态，含 **`diskLayoutWarning`**。
- `POST /system/pluginMarket/removeCatalog`，body `{"pluginId":"..."}`：删 **`sys_plugin_version`** 该插件行 + **`sys_plugins`** 上架行（`PLUGIN_REGISTRY_TENANT`），**事务提交后** `pluginLifecycleManager.reload()`；**不删磁盘**。用户表述的「删除插件」若指去掉市场/登记记录，对应此接口；若指去掉磁盘文件，用 **`pluginHost/uninstall`**，且卸载后可重新安装。

**卡片按钮约定**（`runtimeState`，与 `mms-ui` 市场页一致）：

- **`LOADED`（运行中）**：**详情**、**停用**（`POST /system/pluginMarket/deactivate`，仅取消库表激活并重载，不删磁盘）、**删除**（`POST /system/pluginMarket/purge`，删磁盘 + 清 `sys_plugin_version` / `sys_plugins`）；不展示「安装」。
- **`ON_DISK`（已安装未加载）**：**详情**、**停用**（清除库表激活）、**删除**（purge）；可页顶上传或详情内切换激活版本。如需仅清库表、不动磁盘，用 **删除库表**（`removeCatalog`）。
- **`NOT_INSTALLED`（未安装）**：**详情**、**安装**（上传）、**删除库表**（仅 `removeCatalog`，无盘时适用）。

页顶 **上传插件包** 始终可用。运维仍保留 **`POST /system/pluginHost/uninstall`**（仅磁盘 + `onUninstallDiskFinished`），与市场「删除」（purge）区分。

## 库表与市场

- 安装成功后可经 **`PluginHostDbBridge`**（在 `mms-system` 侧实现）写入 **`sys_plugins`** 等表并维护**激活版本**；未部署库表时部分能力返回明确错误（如 `activateVersion`）。
- 增量 SQL 通常在 **`mms/script/db/`**（如 `increment_*sys_plugin*.sql`、`plugin_market_menu`）；改表或菜单后按团队流程执行并更新 **`version/`** 需求文档（**命名规范见下节**；宿主全能力总需求：**`version/v2.0.1-插件化宿主全能力落地需求.md`**）。

## version/ 需求文档命名（助手必读，避免旧格式）

与 **`.cursor/rules/project-conventions.mdc`** 一致，**全仓** Cursor 技能、规则、回复中引用 `version/` 时**只认**下列规则：

| 规则 | 说明 |
|------|------|
| **合法文件名** | `v主版本.次版本.修订-说明.md`（三段数字 + 短横线 + 中文或英文说明），例：`v1.0.0-脚手架回归与扩展基线.md`、`v2.0.1-插件化宿主全能力落地需求.md`。 |
| **禁止（已废弃）** | `v1-20260401-说明.md`、`v2-20260403-说明.md` 等 **「v + 单数字 + 日期 + 说明」**；新建、引用、 skills 内路径**一律不得**再写此形式。 |
| **大版本线** | **v1.*.***、**v2.*.*** 表示不同代需求；同线小改动递增**第三段**（`v2.0.1` → `v2.0.2`）；换代可升**主版本**（如 **v2.0.0** 起新线）。 |

**插件 / 脚手架相关现行文件（mms-plus 根目录 `version/`）**——引用时写完整相对路径：

- **v1 线**：`v1.0.0-脚手架回归与扩展基线.md`、`v1.0.1-插件市场卡片与sys_plugins.md`、`v1.0.2-插件安装入库与按库加载.md`
- **v2 线（插件化）**：`v2.0.0-…`（背景）→ `v2.0.1-…`（**总需求**）→ `v2.0.2-…`（任务清单）→ `v2.0.3-…`（必做/可选与里程碑）→ `v2.0.4-…`（前端联邦）→ **`v2.0.5-…`**（**Peer 契约 + 激活重载，M-A**）→ **`v2.0.6-独立API插件迁移与宿主安全基线B2至B5.md`**（**doc/unix B0～B3 口径 + F10/F16，M-B/M-C 文档**）→ **`v2.0.8-C端插件化与依赖校验落地.md`**（**C 端插件链、c-base / 企微**）→ **`v2.0.11-mms-servers迁出与C端插件链.md`**（**历史：原 mms-servers 单体迁出；现以 v2.0.13 七域为准**）→ **`v2.0.12-C端与全量插件清单基线.md`**（**分期对照、依赖边、`script/` SQL 现状**）→ **`v2.0.13-C端业务插件按域拆分.md`**（**C 端多域独立插件 id 与 DAG；`c.member` 含 base**）→ **`v2.0.14-插件命名规范与全量清单.md`**（**目录、id、描述模板、依赖口径、能力/对外服务表**）→ **`v2.0.15-插件本地安装调试与测试工作流.md`**（**本机落盘、reload、IDE 调试、测试分层**）→ **`v2.0.16-管理端与开放API宿主合并方案备忘.md`**（**历史：单一宿主备忘**）→ **`v2.0.17-付费插件独立交付与禁止Maven内嵌他插件.md`**（**按 SKU 独立 JAR；禁止 fat JAR 夹带未授权插件实现**）→ **`v2.0.18-插件POM依赖白名单与业务插件互引用口径.md`**（**POM 仅 mms-modules+公共库+第三方；业务互用只 `plugin.json` id**）→ **`v2.0.19-管理端与8060开放API双进程路线A.md`**（**默认：8080 + 8060、共享 root-dir**）

其他技能（`mms-kills`、`mms-modules-map` 等）凡提及 **`version/*.md`**，须与上表文件名一致；**不确定时打开 `version/` 目录以磁盘为准**。

## 启动加载与多租户（`ApplicationReadyEvent`）

- 插件在 **`PluginHostRunner`**（`ApplicationReadyEvent`）中调用 **`PluginLifecycleManager.loadAll()`**，进而通过 **`PluginHostDbBridge`** 访问 **`SysPluginVersionMapper`**。
- MyBatis **多租户拦截器**会调用 **`LoginObject.getLoginTenant()` → `getLoginId()` → `StpUtil.getSession()`**。此时无 HTTP 上下文，Sa-Token 可能抛 **`SaTokenContextException`**。
- **`LoginObject.getLoginId()`**（`mms-authority`）需与 **`NotWebContextException` 一并捕获 `SaTokenContextException`**，返回 `null`，使 `getLoginTenant()` 回退 **`"000000"`**，与 **`PluginHostDbBridgeImpl.PLUGIN_REGISTRY_TENANT`** 及租户插件默认租户一致。

## 引用 mms-modules 的开发边界

- **类加载**：插件 JAR 由宿主 **`URLClassLoader`** 加载，**父加载器一般为应用主 ClassLoader**，因此主程序已加载的类（如 **`mms-common`** 中已在宿主 classpath 的类）可被插件 **以同一类型** 使用 —— 前提是 **插件不要重复打包同名冲突版本**。
- **Maven**：对 **`mms-plugin-api`**（及仅需编译期类型的 **`mms-common`** 等）常用 **`provided`**，避免Fat JAR 与宿主版本漂移；具体以示例 `mms-plugins/mms-plugin-sample-health/pom.xml` 为准。
- **不建议**：插件直接依赖并调用 **`mms-system` 的 Spring Bean / Service / Mapper**（无 Spring 注入、生命周期与事务边界不清）。需要系统能力时优先 **HTTP 调用管理端已有接口**，或后续由官方扩展 **受控宿主 API**。
- **可复用**：纯工具类、DTO、常量等 **无状态且 ABI 稳定** 的 API；注意 **双向兼容性**（宿主升级后插件仍应能通过 `requiresMms` 校验）。

## 与健康检查

实现 **`PluginHealthContributor`**（与 `MmsPlugin` 可同时由同一 JAR 提供）可向 **`GET /system/pluginHost/health`** 汇总输出行；**必配、语义、易错与示例**见上文 **「封装规范：可观测性」** 与健康探测条目；示例工程：**`mms-plugin-sample-health`**、**`mms-plugin-sample-spi`**、**`mms-plugin-tool-syslog`**、**`mms-plugin-doc`**。

## 本地安装 · 调试 · 测试（推荐工作流）

> **成文**：主仓 **`version/v2.0.15-插件本地安装调试与测试工作流.md`**。助手回答「本地怎么装插件 / 怎么调试 / 怎么测」时优先按本节与 **v2.0.15**。

### 安装到本机（与生产相同的磁盘语义）

1. **配置**：宿主 **`mms.plugin.enabled=true`**，**`root-dir`** 建议 **`${MMS_PLUGIN_ROOT_DIR:-${user.home}/mms/plugins}`**（与 **`mms-admin`** `application.yml` 常见写法一致）。
2. **布局**：**`<root-dir>/<pluginId>/<version>/lib/*.jar`**（`pluginId` 一般保持带点号；**`/` `\` `:`** 会转 **`_`**，见 **`PluginInstallationLayout.safeSegment`**）。
3. **落盘方式（三选一）**：**`POST /system/pluginHost/install`**（multipart **`file`**，需 **super_admin**）；手工 **copy**；仓库脚本 **`mms-plugins/scripts/sync-plugin-standalone.sh`**（见 **v2.0.15 §3**）。

**说明**：管理端聚合工程为 **`mms/mms-admin`**（插件宿主运维接口在本进程内）；**`spring.profiles.active`**、**业务包与 `com.sxpcwlkj.plugin` 日志级别**、**`logging.config: classpath:logback-spring.xml`** 等见该模块 **`application*.yml`**（**`revisionMin`** 仍指 **`mms/pom.xml` `revision`**，与 **`mms.plugin.host-mms-revision`** 对齐）。

### 迭代节奏（开发期）

- **改插件代码** → **`mvn package -DskipTests`**（目标模块）→ **sync 或 copy** → **`POST /system/pluginHost/reload`** 或 **重启宿主**。
- **验收**：**`GET /system/pluginHost/status`**（**`pluginsRootReady`**、已加载列表）→ **`GET /system/pluginHost/health`** → **HOST_MVC** 再打 **`/plugin/{pluginId}/...`**；需要时 **插件独立日志** **`logs/plugins/{pluginId}@{version}.log`**。

### 调试（IDE）

- **同一仓库 / 多模块**：**Debug** 启动 **`mms-admin`**（或 **unix**），在 **插件模块** 源码打断点；插件经 **`URLClassLoader`** 加载后，多数情况下可命中（不命中时检查是否 **Run** 误用、JAR 与源码是否同构建、IDE 是否需 **调试设置** 放行为「全部」）。
- **勿依赖**「宿主一句插件已加载」代替插件内 **INFO** —— 独立文件见可观测性一节。

### 测试分层

| 层级 | 说明 |
|------|------|
| **单元** | 插件模块 **JUnit**，纯逻辑、无宿主。 |
| **联调 / 手工** | 宿主 + **status / health / HTTP / `pluginHost/invoke`**。 |
| **自动集成** | 团队另立（Testcontainers / E2E），**非**每插件强制。 |

### 仅磁盘 vs 市场库表

- **开发期**可只做磁盘 + **reload**，**不必**每次写入 **`sys_plugins`**；与「市场卡片」不一致时属预期。
- **对齐生产**再走安装/激活与各插件 **`script/install.sql`**（权限/菜单等，**v2.0.12** 清单见 **`version/v2.0.12-…`**）。

## 文档（mms-doc）

**新手阅读顺序**（在线站路径，均在 **`/mms-plugins/`**）：[JAR 开发指南 · 第 0 节闭环](https://mmsadmin.cn/mms-plugins/plugin-develop.html#plugin-first-run) → [JAR 插件入门](https://mmsadmin.cn/mms-plugins/plugin-jar-phases.html) → [JAR 开发指南](https://mmsadmin.cn/mms-plugins/plugin-develop.html) 全文 → 进阶 [JAR 插件路由协议](https://mmsadmin.cn/mms-plugins/plugin-route-protocol.html)。后端未跑通前先 [项目导入与启动](https://mmsadmin.cn/index/mmsAdmin.html)。

优先保持与代码一致；站点路径（VitePress）：

- [插件体系介绍](/mms-admin/plugin-overview)
- [JAR 开发指南](/mms-plugins/plugin-develop)（**[第 0 节](/mms-plugins/plugin-develop#plugin-first-run)**）
- [JAR 插件入门](/mms-plugins/plugin-jar-phases)
- 前端路由协议：[JAR 插件路由协议](/mms-plugins/plugin-route-protocol)

同步菜单与 **`docs/log/index.md`** 见 **`mms-doc-sync`**。

## 排查清单

```
- [ ] mms.plugin.enabled 与 root-dir 是否符合预期；status 中 pluginsRootReady、resolvedPluginsRoot
- [ ] 根 pom **`revision`** 与 **`plugin.json` `requiresMms.revisionMin`**（构建后数字）、**`host-mms-revision`** 是否一致；**`plugin.json` 是否已采用 `${revision}` 过滤**
- [ ] 目录是否为 <root>/<pluginId>/<version>/lib/*.jar，且 SPI/META-INF 齐全
- [ ] 上传/install 失败时先看校验错误（PluginDescriptorValidator）与日志
- [ ] 激活版本 / 市场展示是否已执行对应增量 SQL 与菜单
- [ ] 启动报错 SaTokenContext：查 LoginObject.getLoginId 是否捕获 SaTokenContextException
- [ ] 市场卡片 diskLayoutWarning 与「卸载 / removeCatalog」语义是否与客户预期一致
- [ ] 独立日志 `logs/plugins/{pluginId}@{version}.log`：是否需要业务 INFO；健康探针 SPI 是否已登记；`/system/pluginHost/health` 是否非长期 NO_HEALTH_SPI / ERROR
- [ ] 新插件是否符合 **「插件开发标准」**（命名、**`plugin.json`**、C 域依赖、**`README` / version 登记表**）
- [ ] **联邦进 JAR**：`-Pfed-web` 构建日志无 **`No projects matched the filters`**（除非 **`skip.fed.*.ui.build=true`** 且确认 dist 为预期版本）；**`fed-plugin-ui.mjs`** 已过滤 **`--`**
```

## 与 mms-kills 的关系

通用 **CRUD、权限、分页、mms-ui** 仍以 **`.cursor/skills/mms-kills/SKILL.md`** 为准；**仅插件隔离、SPI、宿主行为**以本技能为准。
