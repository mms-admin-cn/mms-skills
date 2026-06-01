# mms-cli（全局 mms 工具脚本）项目适配技能

本技能用于让协作助手理解：全局 `mms` 命令如何识别项目（识别文件 **`.mms/bin/project.yml`**；兼容遗留路径 **`.mms/project.yml`**），以及在项目内如何调用 `.mms/bin/mms.project.sh` 完成自检、依赖、启动、打包、部署与 Git 工作流。

## 与远端服务器（`ssh-info.yml` / `ssh.conf`）

- **推荐**：**`.mms/config/ssh-info.yml`**（模板 **`ssh-info.example.yml`**）；由 **`mms-ssh-info-yml-to-env.rb`** 导出 **`DEPLOY_*`**（**需 ruby**）。  
- **兼容**：**`.mms/config/ssh.conf`** 或旧名 **`deploy.conf`**，由 **`load_deploy_conf`** **`source`**。仅当不存在 **`ssh-info.yml`** 时使用。  
- **`deploy`** 子命令使用上述变量做 **ssh/rsync** 与远端 **docker compose**。  
- 交互式 **SSH 排障**、拼 `ssh` 命令：**见 `.cursor/skills/mms-ssh-connect/SKILL.md`**。

## 与 `db-info.yml` 的关系（连库约定）

- 路径：**`.mms/config/db-info.yml`**（gitignore，模板 **`db-info.example.yml`**）。
- 单文件内 **`db.local` / `db.dev` / `db.prod`** 三套 JDBC；用顶层 **`active`** 或环境变量 **`MMS_DB_PROFILE`** 选用。
- **仅**供本机客户端、协作助手拼 mysql 命令；**不参与** Spring Boot 启动（应用仍读 **`application-*.yml`** 与 **`application-*-secret.yml`**）。
- 详情见 **`.cursor/skills/mms-db-connect/SKILL.md`**。
