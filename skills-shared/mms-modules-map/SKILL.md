---
name: mms-modules-map
description: mms-modules 子模块职责与落点速查；并含 mms-plus 根 **`mms-plugins/`** 现行目录命名（**`mms-plugin-c-*` / `mms-plugin-tool-*` / `mms-plugin-c-server`**，及旧名废弃说明）。新增业务、排查依赖、接入插件 API 时优先查阅。
---

# mms-modules 模块地图

权威列表以 **`mms/mms-modules/pom.xml`** 的 `<modules>` 为准。**依赖 DAG、冒烟用例、压测接口清单** 见 **`version/v1.0.0-脚手架回归与扩展基线.md`**（mms-plus 根目录；**`version/`** 须 **semver 文件名**，禁用旧式 `v1-YYYYMMDD-…`，见 **`mms-plugin`** 技能「version/ 需求文档命名」）。以下为开发时常用对照；**对外同步**表文在 `mms-doc` [项目简介 — 子模块速览](https://mmsadmin.cn/index/introduction.html#mms-modules-map)。

| 模块 | 落点提示 |
|------|----------|
| `mms-common` | 通用属性（如 `TenantProperties`）、工具、枚举 |
| `mms-plugin-api` | JAR 插件契约：`plugin.json`、`MmsPlugin` SPI、安装路径工具类 |
| `mms-plugin-host` | JAR 插件宿主：扫描 `lib`、ClassLoader、SPI、`/system/pluginHost` |
| `mms-plugin-server` | 插件宿主服务端胶水：`HostDataService` / `PluginSysConfigOperations` 对接系统域与企微生命周期通知（由 `mms-admin` 引入） |
| `mms-framework` | `BaseServiceImpl` 等与框架协作的基类 |
| `mms-datasource` | MyBatis-Plus、多数据源、**租户拦截器**、`BaseEntity` 填充 |
| `mms-authority` | `LoginObject`、登录态与租户 Redis 读取 |
| `mms-system` | 用户、角色、菜单、字典、租户、配置等系统域 |
| `mms-gen` | 代码生成与模板 |
| `mms-log` | 操作日志 AOP |
| `mms-redis` / `mms-oss` / `mms-sms` / `mms-email` | 集成能力 |
| `mms-mq` / `mms-wx` / `mms-aliyun` / `mms-ai` / `mms-websocket` / `mms-thymeleaf` / `mms-demo` | 按业务选用 |

**管理端入口**：`mms/mms-admin` 通过 Maven 聚合依赖；新功能表优先落在 `mms-system` 或生成器配置指定包。

## mms-plus 插件工程（`mms-plugins/`，与上表 `mms/mms-modules` 并列）

权威列表以 **mms-plus 根 `mms-plugins/pom.xml`** 的 `<modules>` 为准（**不在** `mms/mms-modules` 内）。协作助手写路径、**`mvn -pl`**、README 时须用**现行目录名**：

| 形态 | Maven 目录示例 | 说明 |
|------|------------------|------|
| C 端业务域 | `mms-plugin-c-member`、`mms-plugin-c-bbs`、… | 与 **`plugin.json` id** `mms.plugin.c-*` 对应 |
| 工具 / 运维 / 集成 | `mms-plugin-tool-syslog`、`mms-plugin-tool-datasource`、`mms-plugin-tool-redis-inspect`、`mms-plugin-tool-wechat-bot` | 旧名 **`mms-plugin-syslog`** 等已废弃 |
| 公共库（不可单独安装） | `mms-plugin-tool-bean-install` | 旧名 **`mms-plugin-bean-install`** 已废弃；无 `plugin.json`，shade 进域插件 |
| 开放 API 可执行 JAR | **`mms-plugin-c-server`**（子模块 **`artifactId`**：**`mms-plugin-server-api`**，产物 **`mms-open-api.jar`**） | 旧目录 **`mms-plugin-open-api`** 已废弃 |

细则、联邦前端与 **`plugin.json`** 见 **`.cursor/skills/mms-plugin/SKILL.md`**。
