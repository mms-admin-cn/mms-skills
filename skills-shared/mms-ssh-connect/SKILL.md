---
name: mms-ssh-connect
description: >-
  指导使用仓库根 .mms/config/ssh-info.yml（模板 ssh-info.example.yml）或 ssh.conf / deploy.conf：部署脚本优先解析 YAML（经 ruby 小工具导出 DEPLOY_*），否则 source 旧式 shell 配置；
  说明 .mms/bin/mms.project.sh deploy 如何通过 ssh/rsync 同步 compose 与 .env 并在远端执行 docker compose；
  协助根据同一配置拼非交互 ssh 排障命令。触发：连接服务器、SSH、部署、ssh-info.yml、ssh.conf、DEPLOY_SSH、rsync、远端 Docker、mms deploy。
---

# MMS SSH 与远端部署配置

## 1. 配置文件在哪、谁读它（优先级）

| 文件 | 说明 |
|------|------|
| **`.mms/config/ssh-info.example.yml`** | 可提交模板，**无真实机密**。 |
| **`.mms/config/ssh-info.yml`**（或 **`.mms/conf/ssh-info.yml`**） | 本机真实值，**gitignore**；从示例复制后填写。**优先**：存在时由 **`.mms/bin/mms-ssh-info-yml-to-env.rb`** 转成可 `eval` 的 **`export`**（**需本机 ruby**）。 |
| **`.mms/config/ssh.conf`**（或 **conf/**、**deploy.conf**） | **兼容**：脚本对该文件 **`source`**，导出 **`DEPLOY_*` / `MMS_*`**。仅在 **不存在** `ssh-info.yml` 时使用。 |

实现见 **`load_deploy_conf`**（**`.mms/bin/mms.project.sh`**）：先找 `ssh-info.yml`，再走 `ssh.conf` / `deploy.conf`。

## 2. YAML 结构（与 `ssh-info.example.yml` 一致）

顶层键示例：

- **`ssh`**：`host`、`user`、`port`、可选 **`key`**（私钥路径）→ 对应 **`DEPLOY_SSH_*`**。  
- **`remote_dir`** → **`DEPLOY_REMOTE_DIR`**。  
- **`local`**（可选）：`compose`、`env` → **`DEPLOY_LOCAL_*`**。  
- **`image`**（可选）：`admin`、`tag` → **`MMS_ADMIN_IMAGE` / `MMS_IMAGE_TAG`**（`docker:build` / `docker:push`）。

## 3. `deploy` 子命令做什么（基于同一配置）

入口：**`.mms/bin/mms.project.sh deploy`**，可选 **`--apply`**。

- **未传 `--apply`**：脚本内 **`DRY_RUN=true`**，`run` 只打印 **`[DRY]`**，**不**实际执行 **ssh / rsync / 远端 docker**。  
- **传入 `--apply`**：`load_deploy_conf` 读入变量后，依次 **ssh** 建远端目录、**rsync** 同步 compose（及可能存在的 `.env`）、再在远端 **`docker compose up -d`**（或 **`docker-compose`**）。Compose 来源默认优先 **`.mms/compose/docker-compose.yml`**，否则 **`mms/script/docker/docker-compose.yml`**；env 默认优先 **`.mms/compose/.env`**，否则 **`mms/script/docker/.env`**（可通过 **`DEPLOY_LOCAL_*`** 覆盖）。

因此：**`ssh-info.yml`** 或 **`ssh.conf`** 是「这套一键同步 + 远端起容器」的专用配置，**不是** Spring 或任意通用工具自动读的格式。

## 4. 助手如何「连服务器」拼 `ssh`

1. **读取**（工作区允许时）**`ssh-info.yml`** 或 **`ssh.conf`**；解析变量；**勿**在回复中复述私钥路径以外的敏感信息与完整密钥内容。  
2. 拼非交互命令示例（与脚本一致思路）：

```bash
ssh -p "${DEPLOY_SSH_PORT:-22}" ${DEPLOY_SSH_KEY:+-i "$DEPLOY_SSH_KEY"} "${DEPLOY_SSH_USER}@${DEPLOY_SSH_HOST}"
```

远端进入目录：

```bash
ssh ... "${DEPLOY_SSH_USER}@${DEPLOY_SSH_HOST}" "cd '${DEPLOY_REMOTE_DIR}' && ls -la"
```

**认证**：依赖用户本机 **`ssh-agent` / known_hosts / 密钥**；助手无法代替完成交互式密码或 2FA。

**无 ruby**：若仅有 `ssh-info.yml` 且未安装 ruby，脚本会 **`die`** 提示；应安装 ruby 或改用 **`ssh.conf`** / **`deploy.conf`**。

## 5. 执行边界（与破坏性操作）

- **只读排障**（如 `ls`、`docker ps`、`docker compose ps`、查看日志尾部、`cat` 非密钥配置）：可在用户提出排障目标后使用，并简要说明用途。  
- **会改变远端状态的操作**（如 **`deploy --apply`**、**`docker compose down`**、**删文件**、**systemctl restart** 等）：须先用**中文**说明影响范围，**征得用户明确确认**后再执行。  
- 若远端再执行 **MySQL 等写 SQL**，同时遵守 **`.cursor/rules/mms-database-sql-guard.mdc`**。

## 6. 相关条目

- **`mms-cli`** 技能：全局 **`mms`** 与 **`.mms/bin/mms.project.sh`** 总览。  
- **`.cursor/rules/mms-cli.mdc`**：`.mms/config/` 机密（**`ssh-info.yml`** / **`ssh.conf`** / **`db-info.yml`** 等）勿入库。  
- **`mms-db-connect`**：数据库连 **`db-info.yml`**，与 SSH 部署配置职责不同，可并存。
