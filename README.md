# mms-skills

![version](https://img.shields.io/badge/version-v1.10.0-blue)
![language](https://img.shields.io/badge/language-zh--CN-green)
![skills](https://img.shields.io/badge/skills-84-orange)

`mms-skills` 是 MMS 研发体系的共享技能库，供 `Cursor`、`Codex`、`Claude Code` 等 Agent 工具统一加载。项目约定 `skills-shared/` 是唯一技能来源，入口文件只负责告诉 Agent 到哪里读技能、按什么流程执行。

## 快速识别

| 项目 | 值 |
|------|----|
| 当前版本 | `v1.10.0` |
| 版本标识 | `PROJECT_VERSION` |
| 机器可读清单 | `mms-skills.json` |
| 技能根目录 | `skills-shared/` |
| 默认工作流 | `skills-shared/mms-dev-workflow/SKILL.md` |
| 版本文档目录 | `version/` |
| 当前技能数量 | `84` |

## 目录结构

```text
mms-skills/
├── PROJECT_VERSION
├── mms-skills.json
├── README.md
├── AGENTS.md
├── CLAUDE.md
├── .cursorrules
├── .cursor/rules/00-project-bootstrap.mdc
├── skills-shared/
│   └── <skill>/SKILL.md
├── tools/
│   ├── codex/README.md
│   ├── cursor/README.md
│   └── claude-code/README.md
└── version/
    └── vX.Y.Z-功能说明.md
```

## 安装

先把本仓库放到一个固定目录。当前推荐路径是：

```bash
export MMS_SKILLS_HOME="/Volumes/SXPCWLKJ/MyWork/mms-skills"
```

如果你的仓库在其他位置，把变量改成真实路径即可：

```bash
export MMS_SKILLS_HOME="/absolute/path/to/mms-skills"
```

### Codex

在目标项目根目录执行：

```bash
cp -f "$MMS_SKILLS_HOME/AGENTS.md" "AGENTS.md"
```

验证：

```bash
test -f AGENTS.md && sed -n '1,40p' AGENTS.md
```

### Cursor

在目标项目根目录执行：

```bash
mkdir -p .cursor/rules
cp -f "$MMS_SKILLS_HOME/.cursor/rules/00-project-bootstrap.mdc" ".cursor/rules/00-project-bootstrap.mdc"
cp -f "$MMS_SKILLS_HOME/.cursorrules" ".cursorrules"
```

验证：

```bash
ls -la .cursor/rules/00-project-bootstrap.mdc .cursorrules
```

### Claude Code

在目标项目根目录执行：

```bash
cp -f "$MMS_SKILLS_HOME/CLAUDE.md" "CLAUDE.md"
```

验证：

```bash
test -f CLAUDE.md && sed -n '1,40p' CLAUDE.md
```

## 使用

Agent 接入后，按以下流程工作：

1. 根据用户任务匹配 `skills-shared/<skill>/SKILL.md`。
2. 先读取主技能，再按需要读取关联技能。
3. 新功能先做需求分析。
4. 分析后先创建 `version/vX.Y.Z-功能说明.md`。
5. 再开发、验证、同步进度。
6. 完成后复盘，把可复用经验沉淀回 `skills-shared/`。

默认主流程技能是：

```text
skills-shared/mms-dev-workflow/SKILL.md
```

常用入口：

| 场景 | 优先技能 |
|------|----------|
| MMS 统一研发流程 | `mms-dev-workflow` |
| uni-app Vue3 全流程交付 | `uniapp-vue3-workflow` |
| HBuilderX 编译、运行、打包 | `hbuilderx-automation` |
| MMS JAR 插件开发 | `mms-plugin`（含 `mms-plugin-check` 验收流程） |
| 技能创建、优化、评估 | `skill-creator`（已合并 `writing-skills`） |
| Codex 插件市场排障 | `codex-plugin-marketplace` |

更多索引见：

```text
skills-shared/README.md
```

## 20 款特色实用技能

这些技能分成两层：**MMS 核心技能**负责日常研发主链路，**生态增强技能**负责多智能体协作、质量保障、UI 优化、自动化测试、资料检索和内容治理。使用时不需要写复杂命令，直接让 Agent 读取对应 `SKILL.md`，或在任务里说出触发语义即可。

### MMS 核心技能

| 技能 | 特色能力 | 适用场景 | 使用方法 |
|------|----------|----------|----------|
| `mms-dev-workflow` | 把需求分析、版本文档、开发、进度同步、复盘沉淀串成统一流程 | 任意新功能、规范开发、技能沉淀 | 说“按 mms-dev-workflow 开发”，或先读 `skills-shared/mms-dev-workflow/SKILL.md` |
| `uniapp-vue3-workflow` | 一句话需求推进到 uni-app Vue3 开发、测试、运行、打包和部署 | 普通 uni-app Vue3、uv-ui、H5/App/小程序项目 | 说“做一个 uni-app Vue3 页面/项目”，优先读取该技能，再按需联动 HBuilderX、API、部署技能 |
| `hbuilderx-automation` | 通过 HBuilderX CLI 自动导入、运行、打包、看日志和截图 | uni-app H5、App、小程序编译运行排障 | 说“用 HBuilderX 跑一下/打包/看真机日志”，读取该技能后执行对应 CLI |
| `mms-plugin` | MMS JAR 插件开发、封装、联邦前端打包、安装 SQL 与插件市场规范 | 新增或改版 MMS 插件 | 说“开发一个 MMS 插件”，先读该技能，检查模块命名、plugin.json、install.sql、联邦资源 |
| `mms-plugin-check` | 插件安装前验收、菜单不显示、remoteEntry、权限和 SQL 常见坑排查（`mms-plugin` 配套技能） | 插件检查、安装失败、菜单有库无界面 | 说“检查插件/菜单不显示”，与 `mms-plugin` 配合做验收和问题定位 |
| `mms-db-connect` | 解析 MMS 数据源配置、RSA/ENC 解密路径、拼接安全 MySQL 命令 | 连接 local/dev/prod 库、排查数据源 | 说“连 dev 库查一下”，只读 SQL 可执行，写操作需用户确认 |
| `mms-ssh-connect` | 读取 `.mms/config/ssh-info.yml` 或旧配置，生成 SSH/rsync/部署排障命令 | 连接服务器、部署、远端 Docker 排查 | 说“连接服务器/执行部署”，先读配置，再生成非交互 SSH 或部署命令 |
| `mms-doc-authoring` | VitePress 中文文档结构、容器、Badge、代码块、高亮和版式优化 | 写 mms-doc 文档、教程、技术说明 | 说“更新/润色文档”，按该技能组织标题、目录、代码组和自检清单 |
| `mms-desktop` | 把 Vue/Vite/Vue CLI 的 dist 接入 Tauri 2 桌面壳 | H5 打包成 exe/dmg/app 桌面程序 | 说“把 dist 打成桌面包”，读取该技能检查 dist、Tauri 配置和路由白屏问题 |
| `api-tester` | 解析 OpenAPI、生成请求用例、集成测试和接口 smoke test | 接口联调、回归测试、API 验收 | 说“给这个接口生成测试/跑 API 验证”，按契约生成 curl、脚本或测试用例 |

### 生态增强技能

| 技能 | 特色能力 | 适用场景 | 使用方法 |
|------|----------|----------|----------|
| `oh-my-claudecode` | 多角色协同开发编排，适合把复杂任务拆给架构、实现、评审、测试等角色 | 前后端分离、复杂业务系统、多模块并行 | 说“用 oh-my-claudecode 拆分这个任务”，先定义边界、角色和交付物 |
| `superpowers` | 强制先匹配技能、调试、TDD、计划、评审等工程纪律 | 长期维护项目、避免一次性代码 | 说“按 superpowers 流程做”，实际技能名为 `using-superpowers`，入口在 `skills-shared/superpowers/SKILL.md` |
| `everything-claude-code` | 一站式增强入口，覆盖需求、实现、测试、安全、文档等全流程 | 需要快速组合多类能力的任务 | 说“用 everything-claude-code 做全流程”，先裁剪需要的模块，避免一次性全量加载 |
| `frontend-design` | ⚠️ 已弃用 → 请使用 `ui-ux-pro-max`（功能完全覆盖并大幅增强） | 任何前端 UI 需求 | 直接使用 `ui-ux-pro-max` |
| `ui-ux-pro-max` | 提供 50+ UI/UX 风格、161 配色、57 字体搭配、99 UX 准则、10 技术栈支持（已替代 `frontend-design`） | 初稿完成后专业化美化、交互细节优化 | 说“用 ui-ux-pro-max 深度优化界面”，用于精修而不是所有任务默认开启 |
| `playwright-mcp` | 基于浏览器自动化做 E2E、截图和回归验证 | 点餐、结算、核销、打印等用户路径测试 | 说“用 Playwright 跑回归/截图验证”，先定义关键路径和断言 |
| `agent-reach` | 联网检索最新文档、规范和示例，并结构化归纳 | 查 Uni-App、接口平台、第三方 SDK 最新资料 | 说“查一下最新文档”，给出技术名、版本和时间范围，输出来源和结论边界 |
| `humanizer-zh` | 中文去 AI 腔，保留事实同时提升自然度 | 文档、说明、公告、产品文案润色 | 说“把这段中文润色自然一点”，要求保留关键术语、参数和事实 |
| `content-risk-detector` | 扫描中文文案风险、敏感词和发布风险表达 | 营销文案、公告、用户协议、对外说明 | 说“检查这段文案风险”，输出风险级别、命中点和替代表达 |
| `skill-creator` | 创建、修改、优化技能，设计触发词和评估用例（已合并 `writing-skills` 的 TDD 方法论） | 把稳定流程沉淀成新 Skill | 说“把这个流程做成技能”，按该技能抽取意图、写 `SKILL.md`、设计测试提示 |

组合建议：先用 `mms-dev-workflow` 定主流程，再按任务选择领域技能和生态增强技能。例如 uni-app 项目常用 `uniapp-vue3-workflow + hbuilderx-automation + ui-ux-pro-max + api-tester`；复杂系统可加 `oh-my-claudecode` 做任务拆分；浏览器回归再加 `playwright-mcp`。

## 版本规则

版本号写在：

```text
PROJECT_VERSION
mms-skills.json
version/vX.Y.Z-功能说明.md
```

递增规则：

| 变更类型 | 规则 | 示例 |
|----------|------|------|
| 大版本 | 主版本 +1 | `v1.10.0 -> v2.0.0` |
| 新能力 | 次版本 +1 | `v1.9.0 -> v1.10.0` |
| 修复 | 修订版本 +1 | `v1.10.0 -> v1.10.1` |

说明：根目录已经存在 `version/` 目录，在部分大小写不敏感文件系统上无法再创建传统 `VERSION` 文件，因此本项目使用 `PROJECT_VERSION` 作为人可读版本标识。

## 维护规范

- 技能只维护在 `skills-shared/`。
- 一个技能一个目录，最少包含 `SKILL.md`。
- 入口文件只维护加载规则，不复制技能正文。
- 新功能必须先建 `version/vX.Y.Z-功能说明.md`。
- 同步外部技能时按 frontmatter 的 `name:` 判重，保留项目已有同名技能。
- 插件镜像技能只代表当前快照，实际使用仍需要对应工具或插件环境支持。

## 当前仓库自检

```bash
test "$(cat PROJECT_VERSION)" = "v1.10.0"
node -e 'const m=require("./mms-skills.json"); if (m.version !== "v1.10.0") process.exit(1); console.log(m.name, m.version)'
find skills-shared -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l
find skills-shared -mindepth 1 -maxdepth 1 -type d ! -exec test -f "{}/SKILL.md" \; -print
```

期望结果：版本一致、技能数量为 `84`、最后一条命令无输出。
