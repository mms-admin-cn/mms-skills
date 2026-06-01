---
name: mms-unix-doc
description: >-
  生成或归一化 mmsUnix 组件 VitePress 文档；先 git -C mms-unix pull 再对照 uni_modules 与 pages_demo 更新 docs/mms-unix。
  每篇含「演示地址」：分包路径 + 线上 H5 链接（pathMap）；npm run docs:mms-unix-demo-address。
  文风与版式：第 4 节；成稿参照 docs/mms-unix/button.md。触发词：「更新 mmsUnix 文档」「更新某一组件文档」。
---

# mmsUnix 组件文档 Skill

## 0. 官方仓库与「更新文档」触发流程

### 0.1 权威来源

| 项目 | 说明 |
|------|------|
| **官方仓库** | `https://gitee.com/mmsAdmin/mms-unix`（mUnix 源码、`uni_modules/m-unix`、`pages_demo` 等） |
| **本站文档** | 本仓库 `docs/mms-unix/`，需与官方迭代**对齐**；版式按本 Skill 第 2–7 节 |

### 0.2 用户触发用语（按本流程执行）

- **全量**：「更新 mmsUnix 文档」「同步 mmsUnix 官方仓库」「对齐官方组件」等 → 对比上游与 `docs/mms-unix/`，补全新增、更新已变、标记待确认项。
- **单篇**：「更新 xxx 文档」「补 button 文档」「更新 mms-unix/datetime-picker」等 → 只针对 **指定 slug/组件** 拉取上游最新实现并对照单页维护。

### 0.3 Agent 执行步骤（必须）

1. **取得上游当前状态**  
   - **本仓库已包含子模块** `mms-unix/`（`.gitmodules` 指向 `https://gitee.com/mmsAdmin/mms-unix.git`）：优先执行 `git submodule update --init --recursive`（首次克隆 mms-doc 后）以及 `git -C mms-unix pull` 或进入 `mms-unix` 后 `git pull` 拉取上游。  
   - 若无子模块/目录：对 `https://gitee.com/mmsAdmin/mms-unix.git` **浅克隆**到临时目录对比。  
   - 以**最新提交**下的代码与 `pages.json` 为准。

2. **从上游提取清单**（路径以上游实际为准，常见如下）  
   - **组件**：`uni_modules/m-unix/` 下各组件目录、入口导出或 `index`。  
   - **演示**：`pages_demo/`、`pages_demo/ext/` 等；结合 `pages.json` 确认路由。  
   - 记录：组件 **tag**（如 `m-button`）、**slug**（kebab-case）、**演示路径**（如 `pages_demo/button/button`）。

3. **与本站对比**  
   - `docs/mms-unix/*.md`（slug = 文件名去掉 `.md`）  
   - `docs/mms-unix/components-catalog.md`（若有索引表）  
   - `docs/.vitepress/config.mts`：`sidebar` 中 `/mms-unix/` 分组、`themeConfig.mmsUnixH5Preview.pathMap`

4. **差集与维护**  
   - **官方有、文档无** → 新建 `{{slug}}.md`，按第 2 节骨架与第 4 节章节顺序；**含 `## 演示地址`**；补侧栏、索引表、pathMap（无 H5 演示则 frontmatter `preview: false`）。  
   - **官方有改动**（Props / 事件 / 插槽 / 行为 / 演示路径）→ 更新对应 md，并同步 pathMap、`components-catalog` 中演示路径列。  
   - **pathMap 或演示路径变更** → 同步更新对应 `## 演示地址` 表格与 `scripts/ensure-mms-unix-demo-address.mjs` 内常量（若使用该脚本）。  
   - **文档有、上游已移除或改名** → 不擅自删除；在文档或回复中说明「待业务确认」，或按用户指示归档。

5. **信息优先级**  
   1. 上游仓库**当前代码**（`.uvue`、类型、注释）  
   2. `pages_demo` 可运行示例  
   3. 本站旧文档仅作版式参考，**实质内容以官方为准**

6. **交付前** → 执行第 7 节检查清单；**文风与表格格式** → 遵守第 4.2 节。

### 0.4 本仓库布局（已配置子模块）

- 子模块路径：**仓库根目录下的 `mms-unix/`**（`git submodule`）。克隆 mms-doc 后若目录为空，执行：`git submodule update --init --recursive`。  
- 更新上游代码：`git -C mms-unix pull --ff-only`（推荐），或 `cd mms-unix && git pull`。

### 0.5 上游与本文档站关系（重要）

- 官方仓库**已移除**内置的 `mms-unix-doc/*.md`（文档改由 **本仓库 `docs/mms-unix/`** 维护）。  
- 子模块作用：提供 **`uni_modules/m-unix` 源码**、**`pages_demo` 演示**、`pages.json` 路由；**不要**再到上游找成套组件 md。

---

## 1. 跨项目路径（先对齐再写文件）

不同仓库把下面路径换成**本仓库**实际位置（找不到则在项目中搜索 `vitepress`、`mms-unix`）：

| 变量含义 | mms-doc 参考路径 | 其他项目 |
|----------|------------------|----------|
| 组件文档目录 | `docs/mms-unix/` | 常为 `docs/.../mms-unix/` 或 `docs/components/mms-unix/` |
| 索引页（可选） | `docs/mms-unix/components-catalog.md` | 有则同步表格，无则只改 sidebar |
| VitePress 配置 | `docs/.vitepress/config.mts` | 侧栏 `sidebar`、主题里 H5 预览 `pathMap` 等 |
| 可选批量脚本 | `scripts/apply-mms-unix-doc-template.mjs` | 仅当从 mms-doc 拷贝了脚本时可用 |

**文件名规则**：与路由 slug 一致，一般用 **kebab-case**，如组件 `m-datetime-picker` → `datetime-picker.md`（与现有站点一致；若全站用别的规则则整站统一）。

---

## 2. 可直接落盘的完整 MD 骨架

把占位符换成真实值后写入「组件文档目录」；**整段可复制模板**（含 `uvue` 示例、Props/Events/插槽空表）见 **[reference.md](reference.md)** 的「新组件空白模板」。

要点：

- `{{TAG}}`：如 `m-button`（与模板标签一致）。
- `{{slug}}.md`：如 `button.md`；`link` 一般为 `/mms-unix/{{slug}}`（随项目 base 调整）。
- 无 H5 演示：`preview: false`；有演示：`previewPath: pages_demo/...` 或配置主题 `pathMap`。
- 无插槽/无事件：删除对应章节。

---

## 3. 用户粘贴「另一份 mmsUnix 组件 md」时的识别与处理

当用户提供整段或附件 md 时，按顺序执行：

### 3.1 快速识别（提取元数据）

1. **标题行**：匹配 `#\s+(m-[\w-]+)\s+(.+)$` 或 `#\s+(\S+)\s+(.+)$` → 得到 **组件标签**（如 `m-button`）与 **中文名**。
2. **文件名 slug**：优先从用户说明获取；否则用标签去掉 `m-` 前缀再转 **kebab-case**（`m-datetime-picker` → `datetime-picker.md`）。
3. **演示路径**：从文中 `pages_demo/...`、表格「演示」列、或 `previewPath` 提取；没有则标记为待补，并在 frontmatter 写 `preview: false` 直至有线上页。
4. **已有结构**：若已有 `## 简述` / `## 使用` / Props 表，**保留实质内容**，只做版式归一（见 3.2）。

### 3.2 归一化（改成本站版式）

| 情况 | 动作 |
|------|------|
| 缺 `## 简述` | 用首段说明或 Props 上文摘要补一段简述 |
| 缺 `::: warning` | 补默认注意段，并把原文里的「注意」「重要」合并进来 |
| 缺平台表 | 插入第二节「平台差异说明」标准四列表 |
| `## 使用` / `## 演示` / `## 使用流程` 等 | 第一个示例节改名为 `## 基本使用`（保留括号副标题） |
| `## 效果` 在 `## 使用` 前 | 保留 `## 效果`，只改后面的 `## 使用` → `## 基本使用` |
| 重复套话简述 | 删除「是 mmsUnix 提供的组件或能力，用法见下文…」类空洞句，只留具体描述 |
| 代码块语言不明 | 页面模板标 `uvue`，纯逻辑标 `uts` |

### 3.3 写入文档目录

1. 保存为：`{{DOCS_MMS_UNIX}}/{{slug}}.md`（路径按第 1 节）。
2. **必须同步**（在目标仓库内改）：
   - VitePress `sidebar`：增加 `{ text: '{{中文名}}', link: '/mms-unix/{{slug}}' }`（`link` 前缀随项目 base 调整）。
   - 若存在索引表：追加一行「文档 / 组件 / 演示路径」。
   - 若文档站带 H5 iframe 预览：在 `pathMap` 中增加 `{{slug}}: '{{演示路径}}'`（无演示则 frontmatter `preview: false`）。

### 3.4 用户只贴了片段（没有 `# 标题`）

- 用正则 `<(m-[\w-]+)` 或文中**第一个** `m-xxx` 推断 **TAG**；slug = 去掉 `m-` 后的 kebab-case。
- **中文名**无法确定时：向用户确认，或侧栏 text 暂用 slug，后续再改。
- 仍按 3.2 补全缺失的简述 / warning / 平台表，并把首个示例节标题改为 `## 基本使用`。

---

## 4. 固定章节顺序与文风规范

### 4.1 章节顺序（与骨架一致，勿打乱）

`# 标题` → `## 简述` → `::: warning` → `## 平台差异说明` → **`## 演示地址`** → `## 基本使用` → 其余（`## Props` / `## Events` / `## 插槽` / 更多示例 / API）。

**`## 演示地址`（必含）**

- **有 H5 预览**（默认或未写 `preview: false`）：用表格列出 **分包路径**（与 `pages_demo` 一致）与 **线上 hash 链接**（与 `themeConfig.mmsUnixH5Preview.baseUrl` + `pathMap` 一致，一般为 `https://unix.mmsadmin.cn/#/{分包路径}`）。  
- **`preview: false`**：说明无独立分包演示、以正文与源码为准（勿编造链接）。  
- 维护时 **pathMap** 与 `docs/.vitepress/config.mts` 里 `mmsUnixH5Preview.pathMap` 同步；脚本 `scripts/ensure-mms-unix-demo-address.mjs` 内 `PATH_MAP` / `EXT_SLUGS` 须与配置、预览组件一致。  
- 批量补全或校正演示地址：`npm run docs:mms-unix-demo-address`。

平台表 Markdown（表头全角括号勿改）：

```markdown
## 平台差异说明

| App（vue） | App（nvue） | H5 | 小程序 |
| :--------: | :---------: | :-: | :----: |
| √ | √ | √ | √ |
```

### 4.2 文风与排版（生成、更新时必须遵守）

| 维度 | 约定 |
|------|------|
| **语言** | 简体中文；技术词可保留英文（Props、H5、`uvue`） |
| **一级标题** | `# m-xxx 中文名`；**中文名**宜简短（2～8 字，如「按钮」） |
| **简述** | 1～3 句，写清**用途 + 典型场景**；禁止空话（「本文介绍…」「是 mmsUnix 提供的组件…」「用法见下文」） |
| **`::: warning`** | 正文直接写**易错点、端差异、兼容性**；**勿**再写 `**注意：**` 起首——VitePress 已为 `warning` 容器显示标题「注意」（见 `docs/.vitepress/config.mts` 的 `warningLabel`） |
| **平台表** | 仅用 √ / — /「待验证」；**勿编造**某端支持情况 |
| **代码块** | 页面结构用 **`uvue`**（可含 `<template>` + `<script setup lang="uts">`）；独立逻辑片段用 **`uts`**；缩进与官方 demo 一致（多为 Tab） |
| **Props / Events / 插槽表** | 列名与 [reference.md](reference.md) 一致；类型与默认值对齐源码；无则写「—」 |
| **成稿参照** | 本站已有页面如 `docs/mms-unix/button.md`：标题、warning、平台表、基本使用、`script setup lang="uts"` 写法与表格密度可作**风格基准** |

### 4.3 子模块拉取后的最短工作流（与第 0.3 节配合）

1. `git -C mms-unix pull --ff-only`  
2. 枚举 `mms-unix/uni_modules/m-unix/components/` 下 **`m-*`** 目录名 → slug = 去掉 `m-` 前缀的 **kebab-case**（与文档文件名一致）  
3. 与 `docs/mms-unix/*.md` 对比 → **缺页补文档**，**有页则打开对应 `.uvue` 核对 Props/事件**  
4. 同步 `docs/.vitepress/config.mts`（`sidebar`、`mmsUnixH5Preview.pathMap`）、`components-catalog.md`（若有）  
5. 主仓库提交子模块指针：`git add mms-unix && git commit -m "chore: bump mms-unix submodule"`（若需固定团队所见上游版本）

---

## 5. Frontmatter

```yaml
---
preview: false
previewPath: pages_demo/foo/foo
previewUrl: https://...
---
```

---

## 6. mms-doc 仓库内可选脚本

- `npm run docs:mms-unix-template`：批量补头结构（`scripts/apply-mms-unix-doc-template.mjs`）  
- `npm run docs:mms-unix-dedupe-简述`：去泛化首段  
- `npm run docs:mms-unix-demo-address`：按 `pathMap` 为各页插入或校正 **`## 演示地址`**（`scripts/ensure-mms-unix-demo-address.mjs`，与 `config.mts` 常量需同步）  

其他项目可复制脚本并改脚本内 `DOC_DIR`、`PATH_MAP`。

---

## 7. 交付前检查清单

- [ ] 已执行 `git -C mms-unix pull`（或等价），以子模块**当前提交**为对照依据
- [ ] 文件已落在组件文档目录，slug 与侧栏 `link` 一致
- [ ] 章节顺序符合第 4.1 节（含 **`## 演示地址`**）；文风符合第 4.2 节（简述非套话、warning 有 `**注意：**`、平台表四列、`uvue`/`uts` 区分）
- [ ] Props/Events 与 `uni_modules/m-unix/components/m-*/` 源码一致或已标注待验证
- [ ] 侧栏已加条目；索引表（若有）已加行
- [ ] 预览：`pathMap` 或 `preview: false` 已处理
- [ ] `::: warning` 已闭合

---

## 8. 复制本 Skill 到其他项目

1. 复制整个目录：`.cursor/skills/mms-unix-doc/`（内含 `SKILL.md` + `reference.md`）到目标仓库**相同路径**。
2. 在目标仓库打开本 Skill 第 **1 节**，把文档目录、VitePress 配置路径改成该仓库实际路径。
3. 若目标站**没有** mms-doc 的预览主题：忽略 `pathMap` 相关步骤，仅用 frontmatter `preview: false` 或删除预览逻辑。
4. 可选：从 mms-doc 拷贝 `scripts/apply-mms-unix-doc-template.mjs` 并修改其中 `DOC_DIR`，再配 `package.json` 脚本。

---

## 9. 延伸阅读

- 官方仓库：`https://gitee.com/mmsAdmin/mms-unix`（与第 0 节同步流程配合）
- 本仓库：`docs/mms-unix/components-catalog.md`
- **文风示例（成稿）**：`docs/mms-unix/button.md`（可与第 4.2 节对照）
- 空白模板与侧栏/pathMap 片段：同目录 [`reference.md`](reference.md)
- H5 预览中 `pages_demo/ext/...` 等特殊映射：见 `docs/.vitepress/theme/components/mms-unix-h5-preview.vue` 内 `EXT_SLUGS` / `pathMap` 约定
