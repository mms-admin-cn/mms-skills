---
name: codex-plugin-marketplace
description: Codex 插件市场安装与排障；用于检查 ~/.codex/config.toml marketplace、注册本地/远程插件市场、处理 openai-curated 保留名、让插件条目显示为可安装。
---

# Codex 插件市场安装与排障

## 使用场景

- 用户说 Codex 插件不能安装、插件页没有安装入口、想让插件都能安装。
- 需要检查或修复 `~/.codex/config.toml` 中的 `[marketplaces.*]` 配置。
- 需要把本地插件市场目录注册进 Codex，或把插件放进默认个人市场。
- 遇到 `marketplace 'openai-curated' is reserved` 之类的保留市场错误。

## 核心判断

1. 先看默认个人市场是否存在：`~/.agents/plugins/marketplace.json`。
2. 再看 `~/.codex/config.toml` 是否已有 `[marketplaces.*]`。
3. 再看 marketplace JSON：`<marketplace-root>/.agents/plugins/marketplace.json`，或默认个人市场文件本身。
4. 插件条目要可安装，通常需要：
   - `policy.installation = "AVAILABLE"`
   - `policy.authentication = "ON_INSTALL"` 或 `"ON_USE"`
   - `category` 存在
   - `source.path` 指向存在的插件目录，且有 `.codex-plugin/plugin.json`

## 常用命令

查看 CLI 能力：

```bash
codex plugin --help
codex plugin marketplace --help
```

注册非默认本地市场：

```bash
codex plugin marketplace add /absolute/path/to/marketplace-root
```

注意：非默认本地市场可能被 CLI 接受，但桌面插件页不一定展示在下拉中。要让桌面插件页稳定发现本机插件，优先使用默认个人市场：

```text
~/.agents/plugins/marketplace.json -> ~/plugins/<plugin-name>
```

移除市场：

```bash
codex plugin marketplace remove <marketplace-name>
```

升级 Git 市场：

```bash
codex plugin marketplace upgrade <marketplace-name>
```

## openai-curated 保留名处理

`openai-curated` 是 Codex 保留 marketplace 名称。即使本地存在 `~/.codex/.tmp/plugins/.agents/plugins/marketplace.json`，也不要强行把该目录按 `openai-curated` 注册；CLI 会报：

```text
Error: marketplace 'openai-curated' is reserved and cannot be added from this source
```

如果目标是“让官方缓存里的插件都能安装”，不要只做自定义 marketplace 注册。实践中自定义 `codex-all-plugins` 可以写入 `~/.codex/config.toml`，但桌面插件页可能不展示该市场。

优先改用默认个人市场入口：

```bash
mkdir -p ~/plugins ~/.agents/plugins
rsync -a --delete ~/.codex/.tmp/plugins/plugins/ ~/plugins/
```

然后基于官方缓存的 marketplace 生成默认个人市场：

```bash
node - <<'NODE'
const fs = require('fs');
const src = `${process.env.HOME}/.codex/.tmp/plugins/.agents/plugins/marketplace.json`;
const dest = `${process.env.HOME}/.agents/plugins/marketplace.json`;
const m = JSON.parse(fs.readFileSync(src, 'utf8'));
m.name = 'personal';
m.interface = { displayName: 'Personal' };
for (const plugin of m.plugins) {
  plugin.policy = plugin.policy || {};
  plugin.policy.installation = 'AVAILABLE';
  plugin.policy.authentication = plugin.policy.authentication || 'ON_INSTALL';
  plugin.category = plugin.category || 'Productivity';
}
fs.mkdirSync(`${process.env.HOME}/.agents/plugins`, { recursive: true });
fs.writeFileSync(dest, JSON.stringify(m, null, 2) + '\n');
NODE
```

默认个人市场解析规则：

```text
~/.agents/plugins/marketplace.json 中的 ./plugins/<plugin-name>
=> ~/plugins/<plugin-name>
```

顶层字段应为：

```json
{
  "name": "personal",
  "interface": {
    "displayName": "Personal"
  }
}
```

默认个人市场不需要执行 `codex plugin marketplace add`；Codex 会隐式发现它。生成后完整退出并重启 Codex 桌面 App。

## 验证脚本

统计安装策略：

```bash
node -e 'const fs=require("fs"); const p=process.argv[1]; const m=JSON.parse(fs.readFileSync(p,"utf8")); const s={}; for (const x of m.plugins){s[x.policy?.installation||"(none)"]=(s[x.policy?.installation||"(none)"]||0)+1;} console.log(JSON.stringify({name:m.name,count:m.plugins.length,installation:s},null,2));' ~/.agents/plugins/marketplace.json
```

检查条目对应插件目录是否存在：

```bash
node -e 'const fs=require("fs"); const home=process.env.HOME; const m=JSON.parse(fs.readFileSync(`${home}/.agents/plugins/marketplace.json`,"utf8")); const missing=m.plugins.filter(x=>!fs.existsSync(`${home}/${x.source.path.replace(/^\.\//,"")}/.codex-plugin/plugin.json`)).map(x=>x.name); console.log(JSON.stringify({count:m.plugins.length,missingCount:missing.length,missing},null,2));'
```

验证新进程是否能发现个人市场：

```bash
(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-debug","version":"0.0.0"}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"plugin/list","params":{"marketplaceKinds":["local"]}}'; \
  sleep 2) | codex app-server --listen stdio://
```

输出中应包含：`"name":"personal"`，以及类似 `"id":"linear@personal"` 的插件。

## 注意事项

- `~/.codex/.tmp/` 是临时缓存，不适合直接作为长期 marketplace 源。
- 官方插件即使显示可安装，也可能在安装或使用时要求第三方账号授权；不要绕过认证流程。
- 不要手动改 `~/.codex/plugins/cache/` 中已安装插件源码，除非用户明确要求调试缓存副本。
- 默认个人 marketplace `~/.agents/plugins/marketplace.json` 属于自建插件入口；在用户没有个人插件时可用于批量镜像官方插件。若用户已有个人插件，先备份并合并条目，不要覆盖。
- 当前运行中的桌面 App 可能不会热加载新建的个人市场；需要完整退出 Codex 后重新打开。
