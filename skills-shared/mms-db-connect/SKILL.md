---
name: mms-db-connect
description: >-
  依据 mms-admin 的 application-local.yml、application-dev.yml、application-prod.yml 与 spring.config.import 引入的 application-*-secret.yml，梳理动态数据源（RSA + ENC）与明文本地配置；
  指导用 GeneratePassword 解密 ENC、或使用仓库根 .mms/config/db-info.yml（gitignore；内嵌 db.local/dev/prod 三套 jdbc 与 active）向助手提供明文 JDBC，便于拼 mysql 客户端命令与排障；可选用环境变量 MMS_DB_PROFILE 覆盖 active。
  执行 SQL 时遵守项目规则 mms-database-sql-guard：只读可主动执行，INSERT/UPDATE/DELETE/DDL 等须经用户明确确认。
  触发：连接 dev/生产库、数据源、jdbc、mysql、ENC、public-key、application-dev-secret、排查连库错误。
---

# MMS Admin：按环境配置连接数据库

## 1. 适用对象与边界

- **适用**：`mms/mms-admin`（及与之同结构的 Spring Boot 配置）；主键数据源一般为 **dynamic-datasource** 的 `spring.datasource.dynamic.datasource.master`。
- **边界**：助手**不能**替你发起长期数据库会话；也**不应**在聊天中索取明文密码。优先用本仓库已有约定：**本地解密工具**或 **gitignore 的 `.mms/config/db-info.yml`** 提供连接参数。  
  **注意**：`db-info.yml` **仅**用于本机/助手拼 `mysql` 等命令；Spring Boot 连库仍以 `application-{local,dev,prod}.yml` 与 `application-*-secret.yml` 为准，二者不同步、也不互相替代。

## 2. 环境文件与加载顺序（必读）

| 文件 | 典型位置 | 作用 |
|------|----------|------|
| `application.yml` | `mms/mms-admin/src/main/resources/` | 主配置分段（含业务加密 `encryption:` 等，与数据源 ENC **不是同一套**） |
| `application-local.yml` | 同上 | **local** profile：多为 **明文** `url` / `username` / `password`，一般不 `import` secret |
| `application-dev.yml` | 同上 | **dev**：常见为 `public-key` + `ENC(...)` 占位，**末段** `spring.config.import` 拉取外置机密 |
| `application-prod.yml` | 同上 | **prod**：占位或空密码，**末段** `import` **application-prod-secret.yml**（路径以文件为准） |
| `application-*-secret.yml` | `mms/mms-admin/config/`（或 `./config/` 等，见各 yml 文末注释） | **gitignore**；真实 `public-key`、带 ENC 的 `url`/`username`/`password`、Redis 等 |
| `application-*-secret.example.yml` | `mms/mms-admin/config/` | 可提交模板，**无真密码** |

**合并规则**：Spring Boot 先加载 profile yml，再按 **`spring.config.import`** 顺序加载文件；**后者覆盖同名键**。  
助手分析「当前 dev 连哪台库」时：除阅读 `application-dev.yml` 外，若用户本机存在 **`application-dev-secret.yml`**，必须以 **合并后** 的 `spring.datasource.dynamic` 为准。

## 3. 数据源 ENC 是什么

- 使用 **dynamic-datasource** 自带的 **RSA + `ENC(...)`**（工具类：`CryptoUtils`）。
- `spring.datasource.dynamic.public-key` 与各项 `ENC(...)` 必须 **同一密钥对** 生成。
- 项目内 **生成/维护 secret** 与 **解密 ENC** 的入口：`mms/mms-admin/src/main/java/com/sxpcwlkj/GeneratePassword.java`。

**运行示例**（在 **`mms`** 子模块目录下）：

```bash
mvn -pl mms-admin exec:java -Dexec.mainClass=com.sxpcwlkj.GeneratePassword
```

交互菜单含：

- **1 / 2**：写入 `application-dev-secret.yml` / `application-prod-secret.yml`（并维护同目录 `dynamic-datasource-rsa.keys`，勿提交）。
- **3**：将一段 **ENC 密文还原为明文**（按提示粘贴 **`public-key`** 与密文；公钥须与生成密文时所用配置一致）。

解密失败时：核对 `public-key` 是否与 yml 中一致、密文是否完整（可带或不带 `ENC(` `)` 外壳，工具会剥壳）。

## 4. 助手如何「连上」dev 库（推荐约定）

### 4.1 优先：`.mms/config/db-info.yml`（明文，仅本机；三环境单文件）

**路径（相对 mms-plus 仓库根）**：`.mms/config/db-info.yml`

**结构约定**（与 **`db-info.example.yml`** 一致）：

- 顶层 **`active`**：`local` | `dev` | `prod`，表示默认选用哪一套。
- 顶层 **`db`**：其下 **`local` / `dev` / `prod`** 各一块，每块含 **`jdbc.url`**、**`jdbc.user`**、**`jdbc.password`**。
- **临时覆盖**：环境变量 **`MMS_DB_PROFILE`**（取值同上）优先生效，便于脚本/会话不切文件换环境。

**助手选用逻辑**：读 `db-info.yml` → `profile="${MMS_DB_PROFILE:-$active}"` → 取 `db.$profile.jdbc.*` → 拼 `mysql -h ...`（**勿**把密码写回聊天）。

1. 复制 **`.mms/config/db-info.example.yml`** → **`.mms/config/db-info.yml`**，三套 URL/账号密码分别填好。
2. 日常默认环境改 **`active`** 即可；仅本次命令用别套时 export **`MMS_DB_PROFILE`**。
3. 该文件已 **gitignore**，**勿提交、勿贴聊天**。

**从 JDBC URL 拆 host/port/database**：`jdbc:mysql://host:port/database?...`

### 4.2 只读仓库时的结论层次

| Profile | 助手能直接从仓库读到的 |
|---------|-------------------------|
| **local** | 常为 **完整明文** `spring.datasource.dynamic.datasource.master` |
| **dev** | 多为 ENC 占位 + import 路径；**无 secret 文件则无法得到真实密码** |
| **prod** | 多为占位；真实值在 **application-prod-secret.yml**（通常不在库内） |

### 4.3 对话中的安全习惯

- **不要**在消息里发送生产明文密码。
- **不要**要求助手把解密后的密码写回可提交的 yml。
- 需要助手执行 `mysql`：使用 **`.mms/config/db-info.yml`** 或环境变量，由你在本机授权网络与客户端。

## 5. `spring.config.import` 路径备忘（避免用错文件）

以仓库当前约定为准（若 yml 注释与下表不一致，**以 yml 正文为准**）：

- **dev**：`application-dev.yml` 文末多为多条 `optional:file:...application-dev-secret.yml`（不同工作目录下的相对路径）。
- **prod**：`application-prod.yml` 文末常见 **`optional:file:./config/application-prod-secret.yml`**（相对**进程工作目录**，常把 secret 放在与 jar 同级的 `config/`）。

助手提示用户放置 secret 时：**复读对应 profile yml 文末的 `import` 列表**。

## 6. 与 HTTP「请求加解密」区分

根 `application.yml` 中 **`encryption:`**（`enable` / `types: AES,RSA` 等）面向 **接口请求体加解密**，**不要**与数据源 `ENC(...)` 混用同一套配置来「解密库密码」。

## 7. 数据库写操作闸门（项目规则）

对数据库执行 **mysql 客户端或等价终端 SQL** 时，遵守 **`.cursor/rules/mms-database-sql-guard.mdc`**：

- **只读**（`SELECT` / `SHOW` / `DESCRIBE` / `EXPLAIN` 等）可主动执行；
- **`INSERT` / `UPDATE` / `DELETE` / DDL / `TRUNCATE` 等**须先用中文说明影响，**征得用户明确确认**后再执行。

---

## 8. 相关技能

- **`mms-kills`（mms-dev-standards）**：模块边界、`mms-datasource`、表结构与 CRUD 规范。
- **`mms-tenant-saas`**：租户字段与排除表；查数时需与运行时租户策略一致。
- **`mms-modules-map`**：`mms-datasource` 模块职责速查。
- **`mms-ssh-connect`**：远端 **SSH**、**`ssh-info.yml`**（模板 **`ssh-info.example.yml`**，需 ruby）或 **`ssh.conf`** / **`deploy.conf`**、**`mms.project.sh deploy`**。
