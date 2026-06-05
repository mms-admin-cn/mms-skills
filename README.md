# mms-skills

![version](https://img.shields.io/badge/version-v1.12.5-blue)
![language](https://img.shields.io/badge/language-zh--CN-green)
![skills](https://img.shields.io/badge/skills-83-orange)

MMS 研发体系的共享技能库，让 Codex、Cursor、Claude Code 等 AI Agent 获得 MMS 项目开发所需的全部技能。

## 快速安装

```bash
# 1. 克隆技能库
git clone <repo-url> ~/mms-skills

# 2. 进入你的项目，一键安装
cd ~/my-project
~/mms-skills/install.sh
```

搞定。Agent 下次对话会自动读取对应平台的引导文件。

### 按平台安装

```bash
# 仅 Codex
~/mms-skills/install.sh --codex --target ~/my-project

# 仅 Cursor
~/mms-skills/install.sh --cursor --target ~/my-project

# 仅 Claude Code
~/mms-skills/install.sh --claude --target ~/my-project

# 安装全部 + 持久化环境变量
~/mms-skills/install.sh --all --shell
```

### 手动安装（不依赖脚本）

```bash
# Codex
cp ~/mms-skills/AGENTS.md AGENTS.md

# Cursor
mkdir -p .cursor/rules
cp ~/mms-skills/.cursor/rules/00-project-bootstrap.mdc .cursor/rules/

# Claude Code
cp ~/mms-skills/CLAUDE.md CLAUDE.md
```

## 目录结构

```
mms-skills/
├── install.sh              ← 一键安装脚本
├── AGENTS.md               ← Codex 引导文件
├── CLAUDE.md               ← Claude Code 引导文件
├── .cursorrules            ← Cursor 引导文件
├── skills-shared/          ← 83 个技能（唯一来源）
│   └── <skill>/SKILL.md
└── version/                ← 版本文档
```

## 使用方式

安装后，Agent 会自动按以下规则工作：

| 你说的话 | Agent 行为 |
|----------|-----------|
| "在吗" / "谢谢" | 秒回，零技能加载 |
| "改按钮为红色" | 直接改，零技能加载 |
| "帮我加一个登录页面" | 自动加载 `mms-dev-workflow` |
| "构建支付系统" | 自动加载 `brainstorming` |

## 技能索引

完整索引见 [skills-shared/README.md](skills-shared/README.md)。

### MMS 核心技能

| 技能 | 用途 |
|------|------|
| `mms-dev-workflow` | 统一研发流程（需求→文档→开发→复盘） |
| `uniapp-vue3-workflow` | uni-app Vue3 全流程交付 |
| `hbuilderx-automation` | HBuilderX 编译、运行、打包 |
| `mms-plugin` | MMS JAR 插件开发 |
| `mms-db-connect` | 数据库连接与查询 |
| `mms-ssh-connect` | SSH 连接与部署 |
| `mms-doc-authoring` | VitePress 文档编写 |
| `mms-desktop` | H5 打包桌面应用 |
| `api-tester` | API 接口测试 |

### 生态增强技能

| 技能 | 用途 |
|------|------|
| `ui-ux-pro-max` | 50+ 风格 UI/UX 优化 |
| `playwright-mcp` | 浏览器 E2E 自动化测试 |
| `systematic-debugging` | 系统性排障 |
| `test-driven-development` | TDD 测试驱动开发 |
| `humanizer-zh` | 中文去 AI 腔润色 |
| `agent-reach` | 联网检索最新文档 |
| `skill-creator` | 创建新技能 |

组合示例：uni-app 项目常用 `uniapp-vue3-workflow + hbuilderx-automation + ui-ux-pro-max + api-tester`。

## 版本规则

版本号在 `PROJECT_VERSION`、`mms-skills.json`、`version/` 中维护。

| 变更类型 | 规则 |
|----------|------|
| 大版本 / 新能力 | 次版本 +1 |
| 修复 / 优化 | 修订版本 +1 |

## 维护者

- 技能只维护在 `skills-shared/`
- 一个技能一个目录，最少包含 `SKILL.md`
- 入口文件只维护加载规则，不复制技能正文
- 修改后运行 `./install.sh --all` 重新安装到目标项目

## 常见问题

**Q: Agent 还是很慢，一直在分析？**

确认你的 Codex 已经安装了 Superpowers 插件，并且本仓库已包含修复后的 `using-superpowers` 技能。如果问题依旧，在项目对话中说"快速改"可跳过全部技能。

**Q: 技能库路径换了怎么办？**

重新运行 `install.sh --all --target <项目目录>`，脚本会自动替换路径。

**Q: 如何卸载？**

删除目标项目中的引导文件即可：
```bash
rm -f AGENTS.md CLAUDE.md .cursorrules
rm -rf .cursor/rules
```
