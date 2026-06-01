---
name: mms-plugin-check
description: MMS **JAR 插件检查 / 验收 / 排障**清单：封装与安装前自检，排除常见问题（**schema.sql 分号白名单**、**install.sql 菜单动态路由字段**、**非超管须 sys_role_function**、**主键已存在则 install 跳过不更新**、**安装回滚范围**、**SPI_ONLY 与 ObjectProvider**、**联邦与 /plugin-assets**、**mms-ui Host**、**联邦 remotes 勿用 scope@url**、**remoteEntry 联调须起 Remote**）。用户说「检查插件」「菜单库里有但不显示」「联邦 / remoteEntry 报错」时使用；与 **`.cursor/skills/mms-plugin/SKILL.md`** 配合：**开发按 mms-plugin，检查按本技能**。
---

# MMS 插件检查技能（验收 · 排障）

## 何时启用

- 用户要求 **检查 / 验收 / Review** 某个插件或插件改动。
- **安装失败**（schema、install.sql、onLoad、联邦资源 404）。
- **管理端菜单不显示**但库里似乎有 `sys_function`。
- **管理端联邦页面打不开**：控制台 **`Failed to resolve module specifier`**、**`__federation__`**、**路由导航 uncaught**。
- **改宿主前**：先对照本清单确认是否应用插件侧即可解决。

维护者：**脚手架演进、§7 能力矩阵与插件宿主对照**另见 **`.cursor/skills/mms-plugin-jar-phases/SKILL.md`**。

## 1. `META-INF/mms/schema.sql`（BundledPluginSchemaSqlGuard）

- **规则**：`BundledPluginSchemaSqlGuard.assertStatementAllowed` 要求**整条语句内不得出现字符 `;`**（防多语句注入），与是否在字符串/注释中无关。
- **禁止**：`COMMENT '...;...'`、任意字面量里的 `;`。
- **允许**：语句之间仍按 `BundledPluginSqlSplitter` **行尾分号**拆句。
- **自检**：全文搜索 `schema.sql` 中的 `;`，除行尾结束符外应无分号。

**代码**：`mms-system/.../BundledPluginSchemaSqlGuard.java`、`BundledPluginSqlSplitter.java`。

## 2. `script/install.sql` → `sys_function`（管理端动态菜单）

`SysUserServiceImpl.getAdminMenuTree` 对 **`type = 1`** 的菜单行执行 **`isAdminMenuRouteRowValid`**：

| 条件 | 说明 |
|------|------|
| `path` | **非空** |
| `component` 或 `redirect_path` | **至少其一非空** |

- **`visible` 与侧栏显示**：`SysUserServiceImpl.getAdminMenuTree` 中 **`meta.isHide = (visible == 1)`**。种子库侧栏菜单（如「系统管理」）多为 **`visible = -1`**；若插件 `install.sql` 把 **`type=1` 菜单写成 `visible = 1`**，接口仍会返回该节点，但 **`isHide: true`**，前端侧栏**不展示**。侧栏菜单应 **`visible = -1`**（与 `mms.sql` 一致）。
- **典型错误**：根目录/分组行 `path`、`component`、`redirect_path` 全空 → 该行被 **跳过**，子菜单 `parent_id` 指向该 id 时 **整枝无法从根递归到**，表现为 **getMenu 里「没有 doc」**。
- **正确范例**：与平台「系统管理」一致——`path='/doc'` + `redirect_path='/doc/docConfig'`（或填 `component`）。
- **`parent_id`**：须与现网父菜单主键一致。常见写法：**`3`**（挂「系统管理」下）、**`1`**（与控制台同级、挂根「系统菜单」下，如 **`mms-plugin-doc`**）；错写则整枝无法从根递归到。

**代码**：`mms-system/.../SysUserServiceImpl.java`（`isAdminMenuRouteRowValid`、`getAdminMenuTree`）。

### 2.1 库里有 `sys_function` 但侧栏没有：角色与超管

`getMenu` → `getAdminMenuTree` 用的功能列表来自 **`getUserRoleAnfFunctionInfo`**：

| 登录用户 | 菜单数据来源 |
|----------|----------------|
| 用户拥有 **`super_admin` 角色**（`sys_role.code`，与 Sa-Token `StpUtil.hasRole` 一致） | `sys_function` 全表 **`status = 1`**（启用） |
| **其它用户** | 仅 **`sys_role_function`** 中与该用户角色绑定的 `sys_function` |

- **`LoginObject.getLoginSuper()`** 以 **`StpUtil.hasRole("super_admin")`** 为准，**不再**按 `user_id == 1` 或登录名判定。
- **`install.sql` 白名单**：`sys_dict`、`sys_dict_data`、`sys_function`（字典 `field_name` 须 `mms_plugin_` 前缀）。**不会**自动写入 **`sys_role_function`**。无 `super_admin` 角色的账号须在 **角色管理** 中勾选新菜单。
- **重装不修正旧行**：若主键 `id` 已存在，`BundledPluginSchemaExecutorImpl` 对该条 INSERT 会 **`[SKIP]`**，**不会 UPDATE**。曾写入错误 `path`/`redirect_path` 时，需 **删行后再装** 或 **手工 UPDATE**。

**代码**：`mms-system/.../SysUserServiceImpl.java`（`getUserRoleAnfFunctionInfo` 中超管分支与普通角色的 `SysRoleFunctionMapper.selectByRoleId`）；`mms-system/.../BundledPluginSchemaExecutorImpl.java`（`sysFunctionIdExists`）。

## 3. 安装流程与「回滚」预期

- **顺序**（默认）：执行 **schema.sql** → **install.sql** → **JAR 落盘**（含 `web/` 解压）→ **库表登记** → **reload**。
- **schema 失败**：**无**自动 DDL 回滚；若前面几条已成功提交，可能 **残留表**，需人工处理后再装。（**字典已迁到 install.sql**，随 install 回滚/卸载清理。）
- **install.sql**：**主键已存在的行会被跳过**（不覆盖）；「重新打包再装」**不会**自动修正已插入过的行，须删旧行或手工 `UPDATE`。
- **install.sql 失败或后续落盘/登记失败**：按 **本次实际插入成功** 的主键，顺序删除 **`sys_dict_data` → `sys_dict` → `sys_function`**（含角色绑定），见 `PluginHostDbBridge.removeBundledInstallSqlInsertRows`。
- **卸载**（市场删除或 `/uninstall`）：从 JAR 内 `install.sql` 解析出的 **字典 + 菜单** 主键一并删除（`collectBundledInstallSqlDeclaredIds`）。

**代码**：`mms-plugin-host/.../PluginHostController.java`（`runPluginInstall`）。

## 4. SPI_ONLY 插件内手工 `newInstance` 与 Spring 类型

- 若 Service 构造器含 **`ObjectProvider<T>`**、**`Optional<T>`** 等，**不能**仅按 `parameterTypes` 做 `getBeansOfType(ObjectProvider.class)`。
- **做法**：解析 **`ParameterizedType`**，对 **`ObjectProvider<X>`** 使用宿主 **`DefaultListableBeanFactory.getBeanProvider(ResolvableType.forType(...))`**（Spring 6 下 **`ResolvableType.forType(typeArg, ResolvableType.forClass(implClass))`**）。
- **参考修复**：`mms-plugin-doc` 的 **`DocPluginServiceInstantiator`**。

## 5. 联邦前端「一键安装 = JAR + 页面」

- **构建**：`-Pfed-web` 将子包 `dist` 打进 **`META-INF/mms/web/`**。
- **安装**：宿主从 JAR 解压 **`META-INF/mms/web/`** → 版本目录 **`web/`**。
- **访问**：管理端登录后可请求 **`GET /plugin-assets/{pluginId}/{version}/{*resourcePath}`**（与 `plugin.json` `frontend`、`VITE_*_REMOTE_ENTRY` 路径一致）。
- **网关**：生产若 API 带前缀，需保证浏览器对 **`/plugin-assets`** 的请求能到 **同一 Spring 应用**（或与 dev 的 Vite 代理一致）。

**契约**：`PluginConstants.WEB_BUNDLE_PREFIX_IN_JAR`、`PluginInstallationLayout.webDirectory`；控制器 **`PluginWebAssetsController`**。

## 6. mms-ui Host 侧（多插件联邦）

- **`mms-ui/plugin-federation.host.ts`**：`PLUGIN_FEDERATION_REMOTES` 每项对应一个 Remote；**`PLUGIN_FEDERATION_SHARED`** 与各子包 `shared` 主版本一致。
- **`buildOriginjsFederationRemotes`** 生成的 **`federation.remotes`**：**值只能是 remoteEntry 的完整 URL 或同源路径**（如 `http://localhost:5176/assets/remoteEntry.js` 或 `/plugin-assets/.../remoteEntry.js`）。**禁止**写成 **`scope@http://...`**：`@originjs/vite-plugin-federation` 在部分环境下会把整串交给浏览器 **`import()`**，而 **ESM 无法解析 `name@url` 说明符**，控制台报 **`TypeError: Failed to resolve module specifier 'mms_plugin_doc_ui@http://...'`**，栈里常见 **`__x00__virtual:__federation__`**，**Vue Router** 会连带 **`uncaught error during route navigation`**。改完 Host 配置后须 **重启 mms-ui dev**。
- **环境变量**：开发联调可用 **`.env.development`** 覆盖，例如 doc：**`VITE_DOC_REMOTE_ENTRY`**（默认见 `plugin-federation.host.ts` 中 `devFallback`）。
- **`mms-ui/src/router/pluginFederation/plugins/*.ts`**：`registerPluginFederationRoutes` 绑定菜单 `component` → **`import('scope/Expose')`**；**`index.ts`** 须 **`import` 该文件**。
- **`mms-ui/src/types/plugin-federation-scopes.d.ts`**：每新增 **scope** 增加 **`declare module '<scope>/*'`**。
- **`backEnd.ts`**：已先 **`resolvePluginFederatedView`** 再 `import.meta.glob`。

### 6.1 联邦联调：remoteEntry 必须可达

- **现象**：Host 已配置正确 URL，仍 404 或加载失败。
- **原因**：`@originjs/vite-plugin-federation` 下 **Remote 在纯 `vite dev` 时未必产出与生产一致的 `assets/remoteEntry.js`**（与 Vite 优化路径有关）；联调需 **另起 Remote 子包开发服务** 或 **先 build 再 `vite preview`** 提供真实 `remoteEntry.js`。
- **doc 插件 UI**：按 **`mms-ui` README / `mms-plugin` 技能「联邦前端」** 执行，例如 **`pnpm run fed:plugin-ui:dev -- @mms-ui/plugin-doc-ui`**（端口与 **`VITE_DOC_REMOTE_ENTRY`** / `devFallback` 一致，默认 **5176**）。
- **自检**：浏览器直接打开 remoteEntry URL，应返回 JS 而非 404。
- **生产**：JAR 安装后由 **`/plugin-assets/{pluginId}/{version}/assets/remoteEntry.js`** 提供，与 **`prodFallback`**、网关转发一致。

### 6.2 与 Cursor / 自动化浏览器无关的日志

- 若控制台出现 **`[CursorBrowser] Native dialog overrides installed`** 等 **IDE 注入**提示，与 **联邦、路由、remoteEntry** 无因果关系；排障时以 **`Failed to resolve module specifier`**、**网络面板 remoteEntry 状态码**为准。若仅在 Cursor 内置浏览器异常，可用 **系统 Chrome** 对照排除工具链差异。

## 7. 与「仅别名打包」的区分

- **syslog 默认**：`views/system/runtimeLog` 用 **`@mms-packages`** 直引子包源码，**主站 bundle 含页面**，**不依赖** JAR 内 `remoteEntry`。
- **doc 现行**：无 `views/doc` 壳，依赖 **联邦 Remote + `/plugin-assets`**；二者验收标准不同，检查时不要混用。

## 8. 宿主边界

- 优先在 **插件内** 满足契约；**扩展 `mms-plugin-host`** 须遵守 **`.cursor/rules/mms-plugin-host-boundary.mdc`**，先与负责人对齐。

## 9. 插件检查总清单（上线闸门）

> 用于「检查插件都检查哪些东西」的统一执行口径。默认按高风险优先，从 **可装载** → **可见性** → **可运维** 依次检查。

### 9.1 元数据与身份一致性

- [ ] **`plugin.json` 必填字段**：`id/name/version/description/entryClass/runtimeMode/requiresMms` 完整且可解析（`revisionMin` 与宿主 `revision` 对齐）。
- [ ] **模块命名一致**：目录名、父 POM `<module>`、子模块 `artifactId`、`plugin.json` `id/name/description` 对齐（例外需在 `pom` 注释明确）。
- [ ] **入口类一致**：`entryClass` 必须真实存在，且 `META-INF/services/com.sxpcwlkj.plugin.MmsPlugin` 指向该实现。

### 9.2 运行模式与依赖

- [ ] **`runtimeMode` 与代码形态匹配**：`HOST_MVC` 有 `@PluginController`；`SPI_ONLY` 不依赖宿主 MVC 路由。
- [ ] **依赖声明准确**：插件间先后关系写在 `plugin.json.dependencies`（必选/optional 区分明确），不靠“口头约定”。
- [ ] **POM 白名单合规**：可装业务插件不直接 Maven 依赖兄弟可装业务插件（按 v2.0.18 口径）。

### 9.3 资源打包与 SQL

- [ ] **JAR 资源齐全**：`META-INF/mms/plugin.json`、`META-INF/services/*`、`script/install.sql`（如有）、`META-INF/mms/schema.sql`（如有）、`META-INF/mms/logo.png`。
- [ ] **`schema.sql` 合规**：语句分割与白名单通过，避免内嵌非法分号导致 guard 拒绝。
- [ ] **`install.sql` 动态路由字段合规**：`type=1` 行 `path` 非空，且 `component`/`redirect_path` 至少其一非空；`visible` 与侧栏显示预期一致。
- [ ] **SQL 幂等可重放**：主键冲突、重装跳过、回滚清理路径可预期（尤其 `sys_function/sys_dict`）。

### 9.4 权限与菜单可见性

- [ ] **权限点闭环**：新增接口均有 `permission`，`install.sql` 已写入对应按钮权限。
- [ ] **角色授权验证**：非 `super_admin` 场景下，`sys_role_function` 已分配；否则菜单/按钮库里有但前端不可见。
- [ ] **安装/卸载后刷新验证**：当前登录态权限集合与动态路由可热刷新（无需强制重登）。

### 9.5 联邦前端与运维可观测

- [ ] **联邦资源可达**：`remoteEntry.js`（dev/prod）可访问，`/plugin-assets/{pluginId}/{version}/...` 与网关转发一致。
- [ ] **Host 配置正确**：remotes 不使用 `scope@url` 非法说明符，路由映射与 scope 声明完整。
- [ ] **健康与日志可观测**：`PluginHealthContributor` 已登记，`/system/pluginHost/health` 可读，插件独立日志可定位。

### 9.6 构建闸门

- [ ] **最小构建通过**：`mvn -pl <module> -am -DskipTests package` 成功。
- [ ] **交付物正确**：瘦包/胖包与运行模式匹配（如 `SPI_ONLY` + standalone 约定）。

## 10. 分包规范检查（含 c-base/member/doc/syslog）

> 目标：插件目录结构统一为可维护的分层风格，避免 controller 胀大、DTO 混放、实现类散落。

### 10.1 标准分层（推荐）

- `controller`：仅路由编排、鉴权、参数校验入口，不放核心业务。
- `entity`：实体与数据模型；其下建议：
  - `entity.bo`：入参对象（BO）
  - `entity.vo`：出参对象（VO）
  - `entity.export`：导出对象（Export）
- `service`：业务接口
- `service.impl`：业务实现（`impl` 统一放这里）
- `mapper`：数据访问接口（可配合 MyBatis 注解/XML）
- `plugin`：插件入口（`MmsPlugin` / `PluginHealthContributor`）

### 10.2 检查判定规则

- [ ] controller 中无大段业务逻辑、SQL、内部 DTO 类（应下沉到 `service` + `entity.*`）。
- [ ] `bo/vo` 不散落在 `controller` 内部类或顶层杂包，统一放 `entity.bo` / `entity.vo`。
- [ ] `impl` 统一在 `service.impl`（包含对 mapper 接口的实现适配类，如项目要求）。
- [ ] mapper 仅保留接口职责，避免把业务逻辑写在 mapper 层。
- [ ] 插件入口类保持“薄”，避免承载业务流程。

### 10.3 四个重点插件复盘口径

- **`mms-plugin-c-base`**：基础能力插件，按标准分层；重点检查 `controller` 是否仅转发、`bo/vo` 是否已归 `entity.*`。
- **`mms-plugin-c-member`**：C 端核心域，重点检查 `entity` 子包完整性（`bo/vo/export`）与 `service.impl` 聚合度。
- **`mms-plugin-doc`**：文档域插件，重点检查历史包名迁移后的引用一致性与健康探针实现。
- **`mms-plugin-tool-syslog`**：工具插件，重点检查联邦前端打包链路与后端分层是否保持薄入口。

## 快速 SQL 自检（本地库）

```sql
-- 是否存在 doc 插件菜单根行且字段合法（path + component/redirect）
SELECT id, parent_id, path, component, redirect_path, name, type, status
FROM sys_function
WHERE id IN ('2030320000000000500') OR parent_id IN ('2030320000000000500')
ORDER BY id;
```

根行若 `path` 空且 `component`、`redirect_path` 均空，即 **动态菜单必丢**。

## 关联

- **开发标准**：**`.cursor/skills/mms-plugin/SKILL.md`**
- **模块速查**：**`.cursor/skills/mms-modules-map/SKILL.md`**
- **联邦方案背景**：**`version/v2.0.4-插件前端联邦模块开发方案.md`**
