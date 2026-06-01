#!/usr/bin/env bash
# MMS 统一工具 — 全部功能内联，无外部依赖
# 用法: mms

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 当前脚本路径（避免硬编码到某个用户目录）
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# 兼容旧函数：未迁移的函数仍可能引用 ROOT_DIR
ROOT_DIR="$(pwd -P 2>/dev/null || pwd)"

# === 倒计时关闭终端 ===
countdown_exit() {
    local seconds=30
    echo ""
    echo -e "  ${CYAN}终端将在 ${seconds} 秒后自动关闭...${NC}"
    for ((i=seconds; i>0; i--)); do
        printf "\r  ${YELLOW}倒计时: %2d 秒${NC}" "$i"
        sleep 1
    done
    echo ""
    echo -e "  ${GREEN}关闭终端${NC}"
    exit 0
}

# ====================================================================
#  项目识别（.mms/）
#    - 其它路径：只显示全局菜单
#    - 已初始化项目目录（含 .mms/bin/project.yml，兼容 .mms/project.yml）：显示项目菜单/支持直接命令分发
# ====================================================================

find_project_root() {
    local dir="${1:-$(pwd)}"
    dir="$(cd "$dir" 2>/dev/null && pwd -P || echo "$dir")"
    while [[ -n "$dir" && "$dir" != "/" ]]; do
        # 新标准：凭证与编排脚本均在 .mms/bin/
        if [[ -f "$dir/.mms/bin/project.yml" && -f "$dir/.mms/bin/mms.project.sh" ]]; then
            echo "$dir"
            return 0
        fi
        # 兼容旧结构：project.yml 在 .mms/ 根
        if [[ -f "$dir/.mms/project.yml" && -f "$dir/.mms/bin/mms.project.sh" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

run_project() {
    local project_root="$1"; shift || true
    local entry="$project_root/.mms/bin/mms.project.sh"
    if [[ ! -x "$entry" && -f "$entry" ]]; then
        chmod +x "$entry" 2>/dev/null || true
    fi
    if [[ ! -x "$entry" ]]; then
        echo -e "${RED}✗${NC} 未找到或不可执行: $entry"
        echo "  请先执行: mms init"
        return 1
    fi
    (cd "$project_root" && bash "$entry" "$@")
}

in_project() {
    find_project_root >/dev/null 2>&1
}

# ====================================================================
#  分组 1: 初始化 & 系统
# ====================================================================

init_mms() {
    echo -e "${BLUE}===== 初始化 MMS =====${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} 脚本文件: $SELF_PATH"
    local has_alias=false
    local has_func=false
    grep -qE '^[[:space:]]*mms[[:space:]]*\(\)[[:space:]]*\{' "$HOME/.zshrc" 2>/dev/null && has_func=true || true
    if $has_func; then
        echo -e "  ${GREEN}✓${NC} 全局 mms 命令已配置"
    else
        echo -e "  ${YELLOW}⚠${NC} 全局 mms 命令未配置"
        echo ""
        echo "  将添加到 ~/.zshrc:"
        echo "    mms() { bash \"$SELF_PATH\" \"\$@\"; }"
        echo ""
        read -r -p "  是否添加? [Y/n] " yn
        yn="${yn:-Y}"
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            {
                echo ""
                echo "mms() { bash \"$SELF_PATH\" \"\$@\"; }"
            } >> "$HOME/.zshrc"
            echo -e "  ${GREEN}✓${NC} 已添加，执行 source ~/.zshrc 生效"
        fi
    fi
    echo ""
    read -r -p "按回车返回..."
}

launch_codex() {
    echo -e "${BLUE}===== 启动 Codex + DeepSeek + CC Switch =====${NC}"
    echo ""

    PORT=8788

    # 0. 检查 DS_API_KEY 环境变量
    if [[ -z "${DS_API_KEY:-}" ]]; then
        echo -e "  ${RED}✗${NC} 未设置环境变量 DS_API_KEY"
        echo "  请先执行: export DS_API_KEY=\"sk-xxxx\""
        read -r -p "按回车返回..."
        return
    fi

    # 1. 检查 mimo2codex 是否安装
    if ! command -v mimo2codex &>/dev/null; then
        echo -e "  ${RED}✗${NC} mimo2codex 未安装，请先安装该工具"
        read -r -p "按回车返回..."
        return
    fi

    # 2. 检查并启动代理
    if lsof -i ":$PORT" -sTCP:LISTEN &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} 代理已在运行 → http://127.0.0.1:$PORT"
    else
        echo "🚀 正在启动 mimo2codex 代理 (端口 $PORT)..."
        nohup mimo2codex --model ds --port "$PORT" --api-key "$DS_API_KEY" > /tmp/mimo2codex.log 2>&1 &
        disown
        sleep 2
        if ! lsof -i ":$PORT" -sTCP:LISTEN &>/dev/null; then
            echo -e "  ${RED}✗${NC} 代理启动失败，请检查 DS_API_KEY 和网络"
            echo "  日志: /tmp/mimo2codex.log (最后5行):"
            tail -5 /tmp/mimo2codex.log
            echo ""
            read -r -p "按回车返回..."
            return
        fi
        echo -e "  ${GREEN}✓${NC} 代理已启动 → http://127.0.0.1:$PORT"

        # 健康检查：确认上游 API 可达
        echo -n "  健康检查中..."
        if curl -s --max-time 5 "http://127.0.0.1:$PORT/v1/models" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC} 代理 + 上游 DeepSeek 连通正常"
        else
            echo -e " ${YELLOW}⚠${NC} 代理端口已监听，但上游 API 可能不通"
            echo "  请检查网络或 DS_API_KEY 是否有效"
        fi
    fi

    # 3. 打开 CC Switch（先于 Codex，确保配置先生效）
    echo ""
    CCSWITCH_APP=$(mdfind -name "CC Switch" 2>/dev/null | grep "/CC Switch.app\$" | head -1)
    if [[ -n "$CCSWITCH_APP" ]]; then
        if ! pgrep -f "CC Switch.app" &>/dev/null; then
            echo "🔧 正在打开 CC Switch..."
            open "$CCSWITCH_APP"
            echo -e "  ${GREEN}✓${NC} CC Switch 已启动"
        else
            echo -e "  ${GREEN}✓${NC} CC Switch 已在运行"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} 未找到 CC Switch.app"
    fi

    # 4. 打开 Codex 桌面版
    echo ""
    CODEX_APP=$(mdfind -name "Codex" 2>/dev/null | grep "/Codex.app$" | head -1)
    if [[ -n "$CODEX_APP" ]]; then
        echo "📂 正在打开 Codex 桌面版..."
        open "$CODEX_APP"
        echo -e "  ${GREEN}✓${NC} Codex.app 已启动"
    else
        echo -e "  ${YELLOW}⚠${NC} 未找到 Codex.app"
        echo "  请确认 Codex 已安装在 /Applications 目录"
        echo "  或手动打开 Codex 桌面版"
    fi

    echo ""
    echo -e "  ${GREEN}🎉 启动完成！${NC}"
    echo "  代理地址: http://127.0.0.1:$PORT/v1"
    echo "  使用模型: deepseek-v4-pro (via mimo2codex)"
    echo ""
    echo -e "  ${CYAN}后台运行中，可安全关闭终端${NC}"
    echo "  重新进入菜单: mms"
    echo ""
    countdown_exit
}

# ====================================================================
#  网络工具 二级菜单
# ====================================================================


# ====================================================================
#  LLM-Proxy 启动（LiteLLM → DeepSeek V4 Pro，端口 4000）
# ====================================================================

launch_llm_proxy() {
    echo -e "${BLUE}===== 启动 LLM-Proxy (LiteLLM → DeepSeek V4 Pro) =====${NC}"
    echo ""

    PORT=4000
    PROXY_SCRIPT="$HOME/.claude-code/litellm-proxy.sh"

    # 0. 检查脚本是否存在
    if [[ ! -f "$PROXY_SCRIPT" ]]; then
        echo -e "  ${RED}✗${NC} 未找到代理脚本: $PROXY_SCRIPT"
        echo "  请确认 litellm-proxy.sh 已安装至 ~/.claude-code/"
        read -r -p "按回车返回..."
        return
    fi

    # 1. 检查 DEEPSEEK_API_KEY 环境变量
    if [[ -z "${DEEPSEEK_API_KEY:-}" ]]; then
        echo -e "  ${RED}✗${NC} 未设置环境变量 DEEPSEEK_API_KEY"
        echo "  请先执行: export DEEPSEEK_API_KEY=\"sk-xxxx\""
        read -r -p "按回车返回..."
        return
    fi

    # 2. 检查并启动代理
    if lsof -i ":$PORT" -sTCP:LISTEN &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} 代理已在运行 → http://localhost:$PORT"
        echo ""
        echo "  模型列表:"
        curl -s http://localhost:$PORT/v1/models 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for m in data.get('data',[]):
    print(f'    - {m[\"id\"]}')
" 2>/dev/null || echo "    (无法获取)"
    else
        echo "🚀 正在启动 LiteLLM 代理 (端口 $PORT)..."
        nohup bash "$PROXY_SCRIPT" > /tmp/litellm-proxy.log 2>&1 &
        disown
        sleep 3
        if ! lsof -i ":$PORT" -sTCP:LISTEN &>/dev/null; then
            echo -e "  ${RED}✗${NC} 代理启动失败，请检查 DEEPSEEK_API_KEY 和网络"
            echo "  日志: /tmp/litellm-proxy.log (最后10行):"
            tail -10 /tmp/litellm-proxy.log
            echo ""
            read -r -p "按回车返回..."
            return
        fi
        echo -e "  ${GREEN}✓${NC} 代理已启动 → http://localhost:$PORT"

        # 健康检查
        echo -n "  健康检查中..."
        if curl -s --max-time 10 "http://localhost:$PORT/health" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC} 代理 + 上游 DeepSeek 连通正常"
            echo ""
            echo "  模型列表:"
            curl -s http://localhost:$PORT/v1/models 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for m in data.get('data',[]):
    print(f'    - {m[\"id\"]}')
" 2>/dev/null || echo "    (无法获取)"
        else
            echo -e " ${YELLOW}⚠${NC} 代理端口已监听，但上游 API 可能不通"
            echo "  请检查网络或 DEEPSEEK_API_KEY 是否有效"
        fi
    fi

    echo ""
    echo -e "  ${CYAN}使用说明:${NC}"
    echo "    Claude Code 需设置: ANTHROPIC_BASE_URL=http://localhost:$PORT"
    echo "    代理模型: claude-opus-4-7 / claude-sonnet-4-20250514"
    echo "    实际后端: DeepSeek V4 Pro (thinking 已禁用)"
    echo ""
    echo -e "  ${CYAN}后台运行中，可安全关闭终端${NC}"
    echo "  重新进入菜单: mms"
    echo ""
    countdown_exit
}

# ====================================================================
#  分组 1b: 项目初始化 — 生成项目骨架
# ====================================================================

project_init() {
    echo -e "${BLUE}===== 项目初始化（.mms） =====${NC}"
    echo ""
    local cwd; cwd="$(pwd -P 2>/dev/null || pwd)"
    echo "  当前目录: $cwd"
    echo ""

    echo -e "  ${YELLOW}⚠${NC} 将按 **mms-plus 现行约定** 生成/覆盖（机密仅放 .mms/config/）："
    echo "    - .mms/bin/project.yml（项目标识，与脚本同目录）"
    echo "    - .mms/bin/mms.project.sh（项目菜单；不再生成 .mms/mms.project.sh）"
    echo "    - .mms/bin/mms-ssh-info-yml-to-env.rb（解析 ssh-info.yml → DEPLOY_*，需 ruby）"
    echo "    - .mms/config/{ssh-info,db-info}.example.yml、deploy.conf.example、README.md"
    echo "    - .mms/compose/.env.example、README.md"
    echo "    - .mms/README.md / .mms/.gitignore"
    echo "    - .mms/conf/README.md（仅兼容路径说明）"
    echo "    - .cursor/skills/{mms-cli,mms-db-connect,mms-ssh-connect}/SKILL.md（若已由 Git 检出则默认跳过）"
    echo "    - .cursor/rules/mms-cli.mdc（同上）"
    echo ""
    echo -e "  ${CYAN}环境变量${NC}（可选，export 后在同终端执行初始化）："
    echo "    MMS_INIT_FORCE_EMBED=1                     强制用本脚本「内嵌快照」覆盖 bin 与上述 .cursor 四件"
    echo "    MMS_INIT_FORCE_EMBED_PROJECT_BIN=1         仅强制覆盖 .mms/bin/project.yml、mms.project.sh、ruby"
    echo "    MMS_INIT_FORCE_EMBED_CURSOR=1              仅强制覆盖 .cursor 三技能 + mms-cli.mdc"
    echo "  真源分工见：**mms-plus/scripts/mms-global-init-ssot.md**"
    echo ""
    read -r -p "  确认执行初始化? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { echo "已取消"; read -r -p "按回车返回..."; return; }

    mkdir -p "$cwd/.mms/bin" "$cwd/.mms/config" "$cwd/.mms/conf" "$cwd/.mms/compose" \
        "$cwd/.cursor/skills/mms-cli" "$cwd/.cursor/skills/mms-db-connect" "$cwd/.cursor/skills/mms-ssh-connect" \
        "$cwd/.cursor/rules"

    # 嵌入式 vs 仓库真源：未强制时跳过已存在的受控文件。
    local MMS_FORCE_ALL=false MMS_FORCE_BIN=false MMS_FORCE_CURSOR=false
    [[ "${MMS_INIT_FORCE_EMBED:-}" =~ ^(1|true|yes)$ ]] && MMS_FORCE_ALL=true
    if $MMS_FORCE_ALL; then MMS_FORCE_BIN=true; MMS_FORCE_CURSOR=true; fi
    [[ "${MMS_INIT_FORCE_EMBED_PROJECT_BIN:-}" =~ ^(1|true|yes)$ ]] && MMS_FORCE_BIN=true
    [[ "${MMS_INIT_FORCE_EMBED_CURSOR:-}" =~ ^(1|true|yes)$ ]] && MMS_FORCE_CURSOR=true

    rm -f "$cwd/.mms/mms.project.sh"
    if [[ -f "$cwd/.mms/project.yml" ]]; then
      mv "$cwd/.mms/project.yml" "$cwd/.mms/project.yml.legacy-$(date +%Y%m%d%H%M%S).bak"
    fi

    # 1) .mms/bin/project.yml（与 mms.project.sh 同目录）
    if $MMS_FORCE_BIN || [[ ! -f "$cwd/.mms/bin/project.yml" ]]; then
      cat > "$cwd/.mms/bin/project.yml" <<'EOF'
name: mms-plus
type: monorepo

# 全局 mms 命令识别项目的标识文件（与本目录下的 mms.project.sh 成套）。
# 该文件不应包含任何机密信息（密码、token、私钥等）。

paths:
  backend: mms
  plugins: mms-plugins
  admin_ui: mms-ui
  docs: mms-doc
  infra: mms/script

profiles:
  - local
  - dev
  - prod

commands:
  doctor: ".mms/bin/mms.project.sh doctor"
  deps: ".mms/bin/mms.project.sh deps"
  secrets: ".mms/bin/mms.project.sh secrets"
  run: ".mms/bin/mms.project.sh run"
  build: ".mms/bin/mms.project.sh build"
  docker_build: ".mms/bin/mms.project.sh docker:build"
  docker_push: ".mms/bin/mms.project.sh docker:push"
  deploy: ".mms/bin/mms.project.sh deploy"
  git_status: ".mms/bin/mms.project.sh git:status"
  git_commit: ".mms/bin/mms.project.sh git:commit"
  git_push: ".mms/bin/mms.project.sh git:push"
EOF
    else
      echo -e "  ${GREEN}✓${NC} 跳过：.mms/bin/project.yml 已存在（默认以仓库/本地为准）。MMS_INIT_FORCE_EMBED_PROJECT_BIN=1 可覆盖。"
    fi

    # 2) .mms/config/* 模板（与 mms-plus 仓库一致）
    cat > "$cwd/.mms/config/ssh-info.example.yml" <<'EOF'
# 复制为 ssh-info.yml 后填写（ssh-info.yml 勿提交）
#   cp .mms/config/ssh-info.example.yml .mms/config/ssh-info.yml
# deploy 会优先读该 YAML（需本机 ruby）；也可改用 ssh.conf / deploy.conf。

ssh:
  host: your-server.example.com
  user: root
  port: 22
  # key: /Users/you/.ssh/id_rsa

remote_dir: /docker

# local:
#   compose: ""
#   env: ""

# image:
#   admin: registry.example.com/sxpcwlkj/mms-admin
#   tag: "1.0.0"
EOF

    cat > "$cwd/.mms/config/db-info.example.yml" <<'EOF'
# 本文件可提交仓库；复制为同级 db-info.yml 后填写真密码（db-info.yml 已 gitignore）。
#
# 单文件维护 local / dev / prod 三套 JDBC；助手或脚本通过 active 或环境变量选用一套。
#
# active：默认使用哪套（local | dev | prod）。也可临时覆盖：export MMS_DB_PROFILE=dev
# 仅用于本机客户端/协作助手拼 mysql 等命令，不参与 Spring Boot 启动（应用仍用 application-*.yml + secret）。

active: local

db:
  local:
    jdbc:
      url: jdbc:mysql://localhost:3306/mms?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true
      user: root
      password: 请替换
  dev:
    jdbc:
      url: jdbc:mysql://YOUR_DEV_HOST:3306/mms?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true
      user: mms
      password: 请替换
  prod:
    jdbc:
      url: jdbc:mysql://YOUR_PROD_HOST:3306/mms?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true
      user: mms
      password: 请替换
EOF

    cat > "$cwd/.mms/config/README.md" <<'EOF'
# config/（本地机密配置）

只提交 `*.example*`；真实机密（`ssh-info.yml`、`ssh.conf`、`db-info.yml`、私钥/token）必须忽略。**勿**在聊天或截图中带出 `db-info.yml` / `ssh-info.yml` / `*_secret*` 明文。

## 部署（SSH、`deploy`）

- **`ssh-info.yml`（推荐）**：从 **`ssh-info.example.yml`** 复制；**deploy** 优先读（经 **`../bin/mms-ssh-info-yml-to-env.rb`** 转成 **`DEPLOY_*`**，**需本机 Ruby**）。
- **`ssh.conf` / `deploy.conf`**：仍为 **`VAR="值"`**，由 **`mms.project.sh`** **`source`**。**无 Ruby / Windows 偏多**的团队可首选此方式，免去 YAML 导出工具链。

## 连库助手（不参与 Spring）

- **`db-info.yml`**：由 **`db-info.example.yml`** 复制；三套 **`jdbc`**，**`active`** 或环境变量 **`MMS_DB_PROFILE`**。详见 **`mms-db-connect`**、**`mms-ssh-connect`** 技能。**仅**用于拼本机 **`mysql`** 等命令，与运行时 **`application-*.yml`** 无关。
- 对实例执行 SQL 时遵守 **`.cursor/rules/mms-database-sql-guard.mdc`**：**写操作**须用户明示确认。
EOF

    cat > "$cwd/.mms/config/deploy.conf.example" <<'EOF'
# 兼容：shell 形式的部署变量（与 ssh.conf 二选一）。
# cp .mms/config/deploy.conf.example .mms/config/deploy.conf
#
# 推荐优先使用 ssh-info.yml（结构化）；无 ruby 或习惯 env 文件时用本示例。

DEPLOY_SSH_HOST="your-server.example.com"
DEPLOY_SSH_USER="root"
DEPLOY_SSH_PORT="22"
# DEPLOY_SSH_KEY="$HOME/.ssh/id_rsa"

DEPLOY_REMOTE_DIR="/docker"

# DEPLOY_LOCAL_COMPOSE=""
# DEPLOY_LOCAL_ENV=""

# MMS_ADMIN_IMAGE="registry.example.com/sxpcwlkj/mms-admin"
# MMS_IMAGE_TAG="1.0.0"
EOF

    # 兼容入口（历史路径指引）
    cat > "$cwd/.mms/deploy.conf.example" <<'EOF'
# 已迁移 → 请将部署变量放在：
#   - 推荐：.mms/config/ssh-info.yml（从 ssh-info.example.yml 复制）
#   - 兼容：.mms/config/deploy.conf（从 deploy.conf.example 复制）
# 旧路径 .mms/conf/deploy.conf 仍会被脚本兜底读取。
EOF

    # 解析 ssh-info.yml → export 语句（stdin 无交互）
    if $MMS_FORCE_BIN || [[ ! -f "$cwd/.mms/bin/mms-ssh-info-yml-to-env.rb" ]]; then
      cat > "$cwd/.mms/bin/mms-ssh-info-yml-to-env.rb" <<'EOFRUBY'
#!/usr/bin/env ruby
require "yaml"

path = ARGV[0]
abort "usage: mms-ssh-info-yml-to-env.rb <ssh-info.yml>" unless path && !path.empty?

begin
  data = YAML.load_file(path)
rescue Psych::SyntaxError => e
  warn "YAML 解析失败 (#{path}): #{e.message}"
  exit 1
end

data ||= {}

def q(s)
  s.to_s.gsub("'", "'\"'\"'")
end

ssh = data["ssh"] || {}

if (h = ssh["host"]) && !h.to_s.strip.empty?
  puts %(export DEPLOY_SSH_HOST='#{q(h)}')
end
if (u = ssh["user"]) && !u.to_s.strip.empty?
  puts %(export DEPLOY_SSH_USER='#{q(u)}')
end

port = ssh["port"].nil? || ssh["port"].to_s.strip.empty? ? 22 : ssh["port"]
puts %(export DEPLOY_SSH_PORT='#{q(port)}')

if (k = ssh["key"]) && !k.to_s.strip.empty?
  puts %(export DEPLOY_SSH_KEY='#{q(k)}')
end

if (rd = data["remote_dir"]) && !rd.to_s.strip.empty?
  puts %(export DEPLOY_REMOTE_DIR='#{q(rd)}')
end

loc = data["local"] || {}
if (cp = loc["compose"]) && !cp.to_s.strip.empty?
  puts %(export DEPLOY_LOCAL_COMPOSE='#{q(cp)}')
end
if (en = loc["env"]) && !en.to_s.strip.empty?
  puts %(export DEPLOY_LOCAL_ENV='#{q(en)}')
end

img = data["image"] || {}
if (ad = img["admin"]) && !ad.to_s.strip.empty?
  puts %(export MMS_ADMIN_IMAGE='#{q(ad)}')
end
if (tg = img["tag"]) && !tg.to_s.strip.empty?
  puts %(export MMS_IMAGE_TAG='#{q(tg)}')
end
EOFRUBY
      chmod +x "$cwd/.mms/bin/mms-ssh-info-yml-to-env.rb"
    else
      echo -e "  ${GREEN}✓${NC} 跳过：.mms/bin/mms-ssh-info-yml-to-env.rb 已存在。"
    fi

    # 3) .mms/.gitignore（对齐 mms-plus）
    cat > "$cwd/.mms/.gitignore" <<'EOF'
# 本地机密（模板 *.example / *.example.yml 可提交）
compose/.env
config/db-info.yml
config/deploy.conf
config/ssh-info.yml
config/ssh.conf
conf/db-config.yml
conf/db-info.yml
conf/deploy.conf
conf/ssh-info.yml
conf/ssh.conf
db-config.yml
deploy.conf
EOF

    # 4) .mms/README.md
    cat > "$cwd/.mms/README.md" <<'EOF'
# .mms/（mms 工具初始化目录）

本目录由全局 `mms` 菜单「项目初始化」生成/维护，约定与 **`mms-plus` 聚合仓** 一致：**机密模板与说明在 `config/`**，`deploy` 优先 **`ssh-info.yml` + ruby 小脚本**，其次 **`ssh.conf` / `deploy.conf`**。

## 真源与覆盖策略

若 **`bin/`** 脚本或 **`.cursor/`** 技能已随 Git 检出，首轮 init **默认不覆盖**。需用 **`Documents/mms.sh` 内嵌快照** 强制刷新时：设置 **`MMS_INIT_FORCE_EMBED=1`**，或分项 **`MMS_INIT_FORCE_EMBED_PROJECT_BIN=1`** / **`MMS_INIT_FORCE_EMBED_CURSOR=1`**。完整说明：**`scripts/mms-global-init-ssot.md`**（与 **`version/v2.0.24-mms-global-init与Cursor技能真源.md`** 备忘一致）。

> **除 `.cursor/` 外**，项目级工具脚本归档在 `.mms/`。

```text
.mms/
├── README.md
├── .gitignore
├── bin/
│   ├── project.yml               # ← 全局 mms 据此识别聚合仓根
│   ├── mms.project.sh            # 自检 / 依赖 / 运行 / 构建 / deploy
│   └── mms-ssh-info-yml-to-env.rb
├── config/
│   ├── README.md
│   ├── ssh-info.example.yml     # → 复制为 ssh-info.yml（勿提交）
│   ├── db-info.example.yml       # → 复制为 db-info.yml（勿提交）
│   └── deploy.conf.example       # 兼容 VAR=（勿提交复制后的 deploy.conf）
├── conf/                         # 仅历史兼容路径（可选）
└── compose/
    ├── docker-compose.yml        # （可选）
    ├── .env
    └── .env.example
```
EOF

    # 5) .mms/bin/mms.project.sh（项目菜单）
    # 说明：已与 mms-plus 仓库 .mms/bin 对齐入库；跳过覆盖时请用 MMS_INIT_FORCE_EMBED=1 / MMS_INIT_FORCE_EMBED_PROJECT_BIN=1。
    if $MMS_FORCE_BIN || [[ ! -f "$cwd/.mms/bin/mms.project.sh" ]]; then
      cat > "$cwd/.mms/bin/mms.project.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# 该脚本位于 .mms/bin/，项目根目录需回退两级
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

die() { printf '%s\n' "$*" >&2; exit 1; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }
need_cmd() { cmd_exists "$1" || die "缺少命令：$1"; }

DRY_RUN=false
YES=false

run() {
  if $DRY_RUN; then
    echo "[DRY] $*"
    return 0
  fi
  eval "$@"
}

confirm() {
  local msg="${1:-确认继续吗？}"
  $YES && return 0
  read -r -p "$msg [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

usage() {
  cat <<'USAGE'
用法（mms-plus 项目菜单）:
  .mms/bin/mms.project.sh [--dry-run] [--yes] doctor
  .mms/bin/mms.project.sh [--dry-run] [--yes] deps
  .mms/bin/mms.project.sh [--dry-run] [--yes] secrets [dev|prod]
  .mms/bin/mms.project.sh [--dry-run] [--yes] run <local|dev|prod>
  .mms/bin/mms.project.sh [--dry-run] [--yes] build <dev|prod> [--with-plugins]
  .mms/bin/mms.project.sh [--dry-run] [--yes] docker:build
  .mms/bin/mms.project.sh [--dry-run] [--yes] docker:push
  .mms/bin/mms.project.sh [--dry-run] [--yes] deploy [--apply]
  .mms/bin/mms.project.sh [--dry-run] [--yes] git:status
  .mms/bin/mms.project.sh [--dry-run] [--yes] git:commit "feat: message"
  .mms/bin/mms.project.sh [--dry-run] [--yes] git:push
USAGE
}

doctor() {
  echo "== mms-plus doctor =="
  local missing=0
  for c in git java mvn node; do
    if ! cmd_exists "$c"; then
      echo "[ERR] 缺少命令: $c"
      missing=1
    else
      echo "[OK ] $(command -v "$c")"
    fi
  done
  if cmd_exists pnpm; then
    echo "[OK ] $(command -v pnpm)"
  else
    echo "[WARN] 未找到 pnpm（mms-ui 建议使用 pnpm）"
  fi
  if cmd_exists docker; then
    echo "[OK ] $(command -v docker)"
  else
    echo "[WARN] 未找到 docker（可选；deploy 走 ssh/rsync，不强依赖本地 docker）"
  fi
  if [[ -f "$ROOT_DIR/.mms/config/ssh-info.yml" ]] || [[ -f "$ROOT_DIR/.mms/conf/ssh-info.yml" ]]; then
    if cmd_exists ruby; then
      echo "[OK ] $(command -v ruby)（用于解析 ssh-info.yml）"
    else
      echo "[WARN] 未找到 ruby：已存在 ssh-info.yml 时 deploy 需要 ruby；可改用 .mms/config/deploy.conf（或 ssh.conf）"
    fi
  fi
  if [[ ! -d "$ROOT_DIR/mms" ]]; then
    echo "[ERR] 未检测到 mms 子模块内容，建议执行：git submodule update --init --recursive"
    missing=1
  fi
  for d in mms mms-plugins mms-ui mms-doc; do
    [[ -d "$ROOT_DIR/$d" ]] || { echo "[ERR] 缺少目录: $d"; missing=1; }
  done
  [[ $missing -eq 0 ]] || die "doctor 未通过：请根据提示修复后重试。"
  echo "[OK] doctor 通过。"
}

deps() {
  echo "== 安装依赖 =="
  run "(cd \"$ROOT_DIR/mms\" && mvn -DskipTests clean install)"
  if cmd_exists pnpm; then run "(cd \"$ROOT_DIR/mms-ui\" && pnpm install)"; fi
  run "(cd \"$ROOT_DIR/mms-doc\" && npm install)"
}

secrets() {
  echo "== 生成机密配置（复用 GeneratePassword）=="
  run "(cd \"$ROOT_DIR/mms\" && mvn -pl mms-admin exec:java -Dexec.mainClass=com.sxpcwlkj.GeneratePassword)"
}

run_cmd() {
  local profile="${1:-}"
  [[ -n "$profile" ]] || die "用法: run <local|dev|prod>"
  run "(cd \"$ROOT_DIR/mms/mms-admin\" && mvn spring-boot:run -Dspring-boot.run.profiles=\"$profile\")"
}

build() {
  local profile="${1:-}"
  shift || true
  local with_plugins=false
  [[ "${1:-}" == "--with-plugins" ]] && with_plugins=true
  [[ -n "$profile" ]] || die "用法: build <dev|prod> [--with-plugins]"
  run "(cd \"$ROOT_DIR/mms\" && mvn -DskipTests clean package -P\"$profile\" || mvn -DskipTests clean package)"
  $with_plugins && run "(cd \"$ROOT_DIR/mms-plugins\" && mvn -DskipTests clean package)"
  cmd_exists pnpm && run "(cd \"$ROOT_DIR/mms-ui\" && pnpm build)"
  run "(cd \"$ROOT_DIR/mms-doc\" && npm run build)"
}

docker_build() { need_cmd docker; run "(cd \"$ROOT_DIR/mms/mms-admin\" && docker build -t \"${MMS_ADMIN_IMAGE:-sxpcwlkj/mms-admin}:${MMS_IMAGE_TAG:-local}\" .)"; }
docker_push() { need_cmd docker; local image="${MMS_ADMIN_IMAGE:-sxpcwlkj/mms-admin}:${MMS_IMAGE_TAG:-local}"; confirm "确认 push $image 吗？" || die "已取消"; run "docker push \"$image\""; }

git_status() { need_cmd git; run "(cd \"$ROOT_DIR\" && git status)"; }
git_commit() { need_cmd git; local msg="${1:-}"; [[ -n "$msg" ]] || die "用法: git:commit \"feat: message\""; confirm "确认提交吗？" || die "已取消"; run "(cd \"$ROOT_DIR\" && git add -A)"; run "(cd \"$ROOT_DIR\" && git commit -m \"$msg\")"; }
git_push() { need_cmd git; confirm "确认 push 当前分支到远端吗？" || die "已取消"; run "(cd \"$ROOT_DIR\" && git push)"; }

load_deploy_conf() {
  local y_primary="$ROOT_DIR/.mms/config/ssh-info.yml"
  local y_legacy="$ROOT_DIR/.mms/conf/ssh-info.yml"
  local rb="$ROOT_DIR/.mms/bin/mms-ssh-info-yml-to-env.rb"
  local cf_ssh="$ROOT_DIR/.mms/config/ssh.conf"
  local cf_dep="$ROOT_DIR/.mms/config/deploy.conf"
  local lg_dep="$ROOT_DIR/.mms/conf/deploy.conf"

  local yaml_file=""
  [[ -f "$y_primary" ]] && yaml_file="$y_primary"
  [[ -z "$yaml_file" && -f "$y_legacy" ]] && yaml_file="$y_legacy"

  if [[ -n "$yaml_file" ]]; then
    if ! cmd_exists ruby; then
      if $DRY_RUN; then
        echo "[WARN] 已找到 ssh-info.yml 但未安装 ruby（预演将使用占位 DEPLOY_*）"
        DEPLOY_SSH_HOST="your-server.example.com"
        DEPLOY_SSH_USER="root"
        DEPLOY_SSH_PORT="22"
        DEPLOY_REMOTE_DIR="/docker"
        return 0
      fi
      die "已找到 ${yaml_file}，解析需要 ruby。请安装 ruby，或删除/改名该文件后改用 ${cf_ssh} / ${cf_dep}（VAR= shell 片段，见 deploy.conf.example）。"
    fi
    [[ -f "$rb" ]] || die "未找到 ${rb}，请重新执行全局 mms 的「项目初始化」。"
    # shellcheck disable=SC1090
    eval "$(ruby "$rb" "$yaml_file")"
    [[ -n "${DEPLOY_SSH_HOST:-}" ]] || die "${yaml_file} 缺少 ssh.host"
    [[ -n "${DEPLOY_SSH_USER:-}" ]] || die "${yaml_file} 缺少 ssh.user"
    return 0
  fi

  if [[ -f "$cf_ssh" ]]; then
    # shellcheck disable=SC1090
    source "$cf_ssh"
    return 0
  fi
  if [[ -f "$cf_dep" ]]; then
    # shellcheck disable=SC1090
    source "$cf_dep"
    return 0
  fi
  if [[ -f "$lg_dep" ]]; then
    # shellcheck disable=SC1090
    source "$lg_dep"
    return 0
  fi

  if $DRY_RUN; then
    echo "[WARN] 未找到 ssh-info.yml / ssh.conf / deploy.conf（预演占位）"
    DEPLOY_SSH_HOST="your-server.example.com"
    DEPLOY_SSH_USER="root"
    DEPLOY_SSH_PORT="22"
    DEPLOY_REMOTE_DIR="/docker"
    return 0
  fi
  die "未找到部署配置。推荐：cp .mms/config/ssh-info.example.yml .mms/config/ssh-info.yml 并填写（需 ruby）。或无 ruby 时：cp .mms/config/deploy.conf.example → .mms/config/deploy.conf。旧路径 .mms/conf/deploy.conf 仍支持。"
}

deploy() {
  local apply=false
  [[ "${1:-}" == "--apply" ]] && apply=true
  need_cmd ssh
  need_cmd rsync
  load_deploy_conf

  local ssh_port="${DEPLOY_SSH_PORT:-22}"
  local ssh_key="${DEPLOY_SSH_KEY:-}"
  local ssh_opt="-p ${ssh_port}"
  [[ -n "$ssh_key" ]] && ssh_opt="$ssh_opt -i $ssh_key"
  local remote="${DEPLOY_SSH_USER}@${DEPLOY_SSH_HOST}"
  local remote_dir="${DEPLOY_REMOTE_DIR:-/opt/mms-plus}"

  local default_compose="$ROOT_DIR/mms/script/docker/docker-compose.yml"
  [[ -f "$ROOT_DIR/.mms/compose/docker-compose.yml" ]] && default_compose="$ROOT_DIR/.mms/compose/docker-compose.yml"
  local local_compose="${DEPLOY_LOCAL_COMPOSE:-$default_compose}"
  local default_env="$ROOT_DIR/mms/script/docker/.env"
  [[ -f "$ROOT_DIR/.mms/compose/.env" ]] && default_env="$ROOT_DIR/.mms/compose/.env"
  local local_env="${DEPLOY_LOCAL_ENV:-$default_env}"

  [[ -f "$local_compose" ]] || die "未找到 compose 文件：$local_compose"
  if ! $apply; then echo "[INFO] 预演模式（不会真正执行），要执行请加 --apply"; DRY_RUN=true; fi

  run "ssh $ssh_opt \"$remote\" \"mkdir -p '$remote_dir'\""
  run "rsync -av -e \"ssh $ssh_opt\" \"$local_compose\" \"$remote:$remote_dir/docker-compose.yml\""
  [[ -f "$local_env" ]] && run "rsync -av -e \"ssh $ssh_opt\" \"$local_env\" \"$remote:$remote_dir/.env\"" || true

  local remote_cmd="
set -e
cd '$remote_dir'
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose pull || true
  docker compose up -d
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose pull || true
  docker-compose up -d
else
  echo '未找到 docker compose 或 docker-compose'
  exit 1
fi
"
  run "ssh $ssh_opt \"$remote\" \"$remote_cmd\""
  echo "[OK] deploy 完成。"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --yes) YES=true; shift ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

case "${1:-}" in
  doctor) doctor ;;
  deps) deps ;;
  secrets) shift || true; secrets "${1:-}" ;;
  run) shift || true; run_cmd "${1:-}" ;;
  build) shift || true; build "${@}" ;;
  docker:build) docker_build ;;
  docker:push) docker_push ;;
  deploy) shift || true; deploy "${1:-}" ;;
  git:status) git_status ;;
  git:commit) shift || true; git_commit "${1:-}" ;;
  git:push) git_push ;;
  -h|--help|"") usage ;;
  *) die "未知命令: ${1:-}（用 --help 查看）" ;;
esac
EOF
      chmod +x "$cwd/.mms/bin/mms.project.sh"
    else
      echo -e "  ${GREEN}✓${NC} 跳过：.mms/bin/mms.project.sh 已存在。"
    fi

    # 7) .mms/conf 兼容说明、compose 模板
    cat > "$cwd/.mms/conf/README.md" <<'EOF'
# conf/（兼容旧路径）

新项目请优先使用 **`.mms/config/`**。若仍存在本目录下的 **`deploy.conf`** 或 **`ssh-info.yml`**，`.mms/bin/mms.project.sh` 会与 **mms-ssh-connect** 技能描述一致兜底读取。
EOF
    cat > "$cwd/.mms/compose/.env.example" <<'EOF'
MYSQL_ROOT_PASSWORD=change_me
EOF
    cat > "$cwd/.mms/compose/README.md" <<'EOF'
# compose/（项目专用 docker-compose 覆盖）

`deploy` 会优先使用 **`.mms/compose/docker-compose.yml`**（若存在）。**`.env`** 多为机密，已由根 `.gitignore` / `.mms/.gitignore` 忽略。

**无 Ruby 时**：可同时使用 **`.mms/config/deploy.conf`**（VAR=），不必写 **`ssh-info.yml`**。
EOF

    # 8) 更新根目录 .gitignore（只追加缺失规则，与 mms-plus 对齐）
    local gi="$cwd/.gitignore"
    [[ -f "$gi" ]] || touch "$gi"
    grep -qE '^[[:space:]]*\.mms/compose/\.env' "$gi" 2>/dev/null || echo ".mms/compose/.env" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/config/db-info\.yml' "$gi" 2>/dev/null || echo ".mms/config/db-info.yml" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/config/deploy\.conf' "$gi" 2>/dev/null || echo ".mms/config/deploy.conf" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/config/ssh-info\.yml' "$gi" 2>/dev/null || echo ".mms/config/ssh-info.yml" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/config/ssh\.conf' "$gi" 2>/dev/null || echo ".mms/config/ssh.conf" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/conf/deploy\.conf' "$gi" 2>/dev/null || echo ".mms/conf/deploy.conf" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/conf/db-info\.yml' "$gi" 2>/dev/null || echo ".mms/conf/db-info.yml" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/conf/ssh-info\.yml' "$gi" 2>/dev/null || echo ".mms/conf/ssh-info.yml" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/conf/ssh\.conf' "$gi" 2>/dev/null || echo ".mms/conf/ssh.conf" >> "$gi"
    grep -qE '^[[:space:]]*\.mms/deploy\.conf' "$gi" 2>/dev/null || echo ".mms/deploy.conf" >> "$gi"
    grep -qE '^\*\*/config/application-\*-\*secret\.yml' "$gi" 2>/dev/null || echo "**/config/application-*-secret.yml" >> "$gi"
    grep -qE '^\*\*/config/dynamic-datasource-rsa\.keys' "$gi" 2>/dev/null || echo "**/config/dynamic-datasource-rsa.keys" >> "$gi"

    # 9) Cursor 技能与规则（仓库检出优先，内嵌兜底）
    local _have_cursor=""
    [[ -f "$cwd/.cursor/skills/mms-cli/SKILL.md" && -f "$cwd/.cursor/skills/mms-db-connect/SKILL.md" && -f "$cwd/.cursor/skills/mms-ssh-connect/SKILL.md" && -f "$cwd/.cursor/rules/mms-cli.mdc" ]] && _have_cursor="y"
    if ! $MMS_FORCE_CURSOR && [[ -n "$_have_cursor" ]]; then
      echo -e "  ${GREEN}✓${NC} 跳过：.cursor 四件套已由仓库检出（默认不覆盖）。MMS_INIT_FORCE_EMBED_CURSOR=1 可写入内嵌快照。"
    else
    cat > "$cwd/.cursor/skills/mms-cli/SKILL.md" <<'EOF'
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
EOF
    cat > "$cwd/.cursor/rules/mms-cli.mdc" <<'EOF'
---
description: 全局 mms 工具脚本与项目适配约定
alwaysApply: false
---

# mms-cli 约定

当涉及全局 `mms` 命令或项目初始化/部署脚本时，优先遵守 `.mms/` 目录结构：**本地机密**放在 **`.mms/config/`**（如 **`ssh-info.yml`**（YAML，优先）、**`ssh.conf`**（旧名 **`deploy.conf`**，兼容）、**`db-info.yml`**），**勿提交**模板外的真值。

**`db-info.yml`**：内嵌 local/dev/prod 三套 JDBC，用 **`active`** 或 **`MMS_DB_PROFILE`** 选用；**只**给本机/助手拼 mysql，**不**参与 Spring Boot（应用仍用 `application-*.yml` + secret）。模板见 **`db-info.example.yml`**；协作细节见 **mms-db-connect** 技能。

**远端 SSH / `ssh-info.yml` / `ssh.conf` / `mms … deploy`**：见 **mms-ssh-connect** 技能。
EOF

    cat > "$cwd/.cursor/skills/mms-db-connect/SKILL.md" <<'EOF'
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
EOF

    cat > "$cwd/.cursor/skills/mms-ssh-connect/SKILL.md" <<'EOF'
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
EOF
    fi

    echo ""
    echo -e "  ${GREEN}🎉 初始化完成！${NC}"
    echo "  模板就绪；详见 **mms-plus/scripts/mms-global-init-ssot.md**（真源与 MMS_INIT_FORCE_*）"
    echo ""
    read -r -p "按回车返回..."
}

# ====================================================================
#  项目工具包装函数
# ====================================================================

proj_check() {
    local root
    root="$(find_project_root "$(pwd)" 2>/dev/null || true)"
    [[ -z "${root:-}" ]] && { echo -e "${RED}当前目录未初始化（缺少 .mms/）${NC}"; read -r -p "按回车返回..."; return; }
    run_project "$root" doctor || true
}

proj_start() {
    local root
    root="$(find_project_root "$(pwd)" 2>/dev/null || true)"
    [[ -z "${root:-}" ]] && { echo -e "${RED}当前目录未初始化（缺少 .mms/）${NC}"; read -r -p "按回车返回..."; return; }
    echo -e "${BLUE}===== 启动服务 =====${NC}"
    echo ""
    echo "  选择环境:"
    echo "    1) local   2) dev   3) prod   0) 返回"
    read -r -p "  选择 [0-3]: " c
    case "$c" in
      1) run_project "$root" run local ;;
      2) run_project "$root" run dev ;;
      3) run_project "$root" run prod ;;
      0) return ;;
      *) echo "无效选择" ;;
    esac
    echo ""
    read -r -p "按回车返回..."
}

proj_stop() {
    echo -e "${YELLOW}⚠${NC} 当前 .mms 模式暂不维护统一 stop（建议用各服务的 stop/IDE 控制或 Docker 管理）。"
    read -r -p "按回车返回..."
}

proj_build() {
    local root
    root="$(find_project_root "$(pwd)" 2>/dev/null || true)"
    [[ -z "${root:-}" ]] && { echo -e "${RED}当前目录未初始化（缺少 .mms/）${NC}"; read -r -p "按回车返回..."; return; }
    echo -e "${BLUE}===== 打包/构建 =====${NC}"
    echo ""
    echo "  选择环境:"
    echo "    1) dev   2) prod   0) 返回"
    read -r -p "  选择 [0-2]: " c
    case "$c" in
      1) run_project "$root" build dev ;;
      2) run_project "$root" build prod ;;
      0) return ;;
      *) echo "无效选择" ;;
    esac
    echo ""
    read -r -p "按回车返回..."
}

proj_compile() {
    echo -e "${YELLOW}⚠${NC} compile 已合并到 build（mvn clean package 前置会编译）。"
    read -r -p "按回车返回..."
}

proj_git() {
    local root
    root="$(find_project_root "$(pwd)" 2>/dev/null || true)"
    [[ -z "${root:-}" ]] && { echo -e "${RED}当前目录未初始化（缺少 .mms/）${NC}"; read -r -p "按回车返回..."; return; }
    echo -e "${BLUE}===== Git =====${NC}"
    echo ""
    echo "  1) status   2) commit   3) push   0) 返回"
    read -r -p "  选择 [0-3]: " c
    case "$c" in
      1) run_project "$root" git:status ;;
      2) read -r -p "  commit 信息: " msg; [[ -n "$msg" ]] && run_project "$root" git:commit "$msg" ;;
      3) run_project "$root" git:push ;;
      0) return ;;
      *) echo "无效选择" ;;
    esac
}

proj_db() {
    local root
    root="$(find_project_root "$(pwd)" 2>/dev/null || true)"
    [[ -z "${root:-}" ]] && { echo -e "${RED}当前目录未初始化（缺少 .mms/）${NC}"; read -r -p "按回车返回..."; return; }
    echo -e "${BLUE}===== secrets（生成机密） =====${NC}"
    echo ""
    echo "  说明：将调用后端 GeneratePassword 生成 application-*-secret.yml 与 keys（勿入库）"
    echo "  1) 生成/更新 dev   2) 生成/更新 prod   0) 返回"
    read -r -p "  选择 [0-2]: " c
    case "$c" in
      1) run_project "$root" secrets dev ;;
      2) run_project "$root" secrets prod ;;
      0) return ;;
      *) echo "无效选择" ;;
    esac
}

proj_log() {
    echo -e "${YELLOW}⚠${NC} log 功能在 .mms 模式下建议走：Docker logs / IDE 控制台 / 日志目录约定（后续可补一份 log 适配）。"
    read -r -p "按回车返回..."
}


network_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        echo "  ╔══════════════════════════════════════════════════╗"
        echo "  ║               网络工具                          ║"
        echo "  ╚══════════════════════════════════════════════════╝"
        echo -e "${NC}"
        printf "  ${GREEN}%-28s${NC}  ${GREEN}%-28s${NC}\n" "── 诊断" "── 工具"
        printf "    ${GREEN}%-8s${NC} %-18s" "1." "网络检测"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "4." "Ping 指定地址"
        printf "    ${GREEN}%-8s${NC} %-18s" "2." "刷新 DNS 缓存"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "5." "DNS 查询"
        printf "    ${GREEN}%-8s${NC} %-18s" "3." "查看公网 IP"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "6." "路由追踪"
        echo ""
        printf "    ${RED}%-8s %-18s${NC}\n" "0." "返回主菜单"
        echo ""
        read -r -p "  请选择: " choice
        case "$choice" in
            1) network_check ;;
            2) flush_dns_cache ;;
            3) show_public_ip ;;
            4) ping_target ;;
            5) dns_lookup ;;
            6) trace_route ;;
            0) return ;;
            *) echo -e "${RED}无效选项${NC}"; sleep 1 ;;
        esac
    done
}

show_public_ip() {
    echo -e "${BLUE}===== 公网 IP =====${NC}"
    echo ""
    echo -n "  IPv4: "
    ipv4=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "获取失败")
    echo "$ipv4"
    echo -n "  IPv6: "
    ipv6=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "获取失败")
    echo "$ipv6"
    echo ""
    echo -n "  归属地: "
    curl -s --max-time 5 "cip.cc" 2>/dev/null | head -5 || echo "  查询失败"
    echo ""
    read -r -p "按回车返回..."
}

ping_target() {
    echo -e "${BLUE}===== Ping =====${NC}"
    echo ""
    echo "  快捷选项:"
    echo "    1) baidu.com      2) google.com"
    echo "    3) 8.8.8.8        4) 114.114.114.114"
    echo "    5) 自定义"
    echo ""
    read -r -p "  选择 [1-5]: " opt
    case "$opt" in
        1) addr="baidu.com" ;;
        2) addr="google.com" ;;
        3) addr="8.8.8.8" ;;
        4) addr="114.114.114.114" ;;
        5) read -r -p "  输入地址: " addr ;;
        *) echo "无效"; read -r -p "按回车返回..."; return ;;
    esac
    if [[ -z "$addr" ]]; then
        echo "地址不能为空"
        read -r -p "按回车返回..."
        return
    fi
    echo ""
    echo -e "  Ping ${CYAN}$addr${NC} (Ctrl+C 停止)..."
    echo ""
    ping "$addr"
    echo ""
    read -r -p "按回车返回..."
}

dns_lookup() {
    echo -e "${BLUE}===== DNS 查询 =====${NC}"
    echo ""
    read -r -p "  输入域名: " domain
    if [[ -z "$domain" ]]; then
        echo "域名不能为空"
        read -r -p "按回车返回..."
        return
    fi
    echo ""
    if command -v dig &>/dev/null; then
        echo -e "  ${CYAN}[dig 结果]${NC}"
        dig +short "$domain" 2>/dev/null | while read -r line; do
            echo "  - $line"
        done
    elif command -v nslookup &>/dev/null; then
        echo -e "  ${CYAN}[nslookup 结果]${NC}"
        nslookup "$domain" 2>/dev/null | grep -A5 "Name:\|Address:" | while read -r line; do
            [[ -n "$line" ]] && echo "  $line"
        done
    else
        echo -e "  ${RED}✗${NC} dig / nslookup 均未安装"
    fi
    echo ""
    read -r -p "按回车返回..."
}

trace_route() {
    echo -e "${BLUE}===== 路由追踪 =====${NC}"
    echo ""
    echo "  快捷选项:"
    echo "    1) baidu.com      2) google.com"
    echo "    3) 自定义"
    echo ""
    read -r -p "  选择 [1-3]: " opt
    case "$opt" in
        1) addr="baidu.com" ;;
        2) addr="google.com" ;;
        3) read -r -p "  输入地址: " addr ;;
        *) echo "无效"; read -r -p "按回车返回..."; return ;;
    esac
    if [[ -z "$addr" ]]; then
        echo "地址不能为空"
        read -r -p "按回车返回..."
        return
    fi
    echo ""
    if command -v traceroute &>/dev/null; then
        traceroute "$addr" 2>&1
    else
        echo -e "  ${RED}✗${NC} traceroute 未安装"
        echo "  安装: brew install traceroute"
    fi
    echo ""
    read -r -p "按回车返回..."
}


network_check() {
    echo -e "${BLUE}===== 网络检测 =====${NC}"
    echo ""
    echo -e "${CYAN}[网卡状态]${NC}"
    ifconfig -l | tr ' ' '\n' | while read -r iface; do
        ip=$(ifconfig "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}')
        if [[ -n "$ip" ]] && [[ "$ip" != "127.0.0.1" ]]; then
            echo -e "  ${GREEN}●${NC} $iface → $ip"
        fi
    done
    echo ""
    echo -e "${CYAN}[DNS 服务器]${NC}"
    scutil --dns | grep 'nameserver\[' | awk '{print $3}' | sort -u | while read -r dns; do
        echo "  - $dns"
    done
    echo ""
    echo -e "${CYAN}[连通性]${NC}"
    targets=("8.8.8.8:Google DNS" "114.114.114.114:114DNS" "baidu.com:百度")
    for t in "${targets[@]}"; do
        addr="${t%%:*}"
        label="${t##*:}"
        if ping -c 1 -W 2 "$addr" &>/dev/null; then
            latency=$(ping -c 1 -W 2 "$addr" 2>/dev/null | grep 'time=' | sed 's/.*time=\(.*\) .*/\1/')
            echo -e "  ${GREEN}✓${NC} $label ($addr) → ${latency}ms"
        else
            echo -e "  ${RED}✗${NC} $label ($addr) → 超时"
        fi
    done
    echo ""
    read -r -p "按回车返回..."
}

flush_dns_cache() {
    echo -e "${BLUE}===== 刷新 DNS 缓存 =====${NC}"
    echo ""
    echo "  将执行: sudo dscacheutil -flushcache"
    echo "          sudo killall -HUP mDNSResponder"
    echo ""
    read -r -p "  确认刷新? (需 sudo 密码) [y/N] " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder 2>/dev/null
        echo -e "  ${GREEN}✓${NC} DNS 缓存已刷新"
    else
        echo "  已取消"
    fi
    echo ""
    read -r -p "按回车返回..."
}

# ====================================================================
#  分组 3: 端口管理
# ====================================================================
# ====================================================================
#  端口 & 进程 二级菜单
# ====================================================================

port_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        echo "  ╔══════════════════════════════════════════════════╗"
        echo "  ║              端口 & 进程                        ║"
        echo "  ╚══════════════════════════════════════════════════╝"
        echo -e "${NC}"
        printf "  ${GREEN}%-28s${NC}  ${GREEN}%-28s${NC}\n" "── 端口" "── 进程"
        printf "    ${GREEN}%-8s${NC} %-18s" "1." "查看监听端口"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "4." "进程列表"
        printf "    ${GREEN}%-8s${NC} %-18s" "2." "端口详情"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "5." "查找进程"
        printf "    ${GREEN}%-8s${NC} %-18s" "3." "终止端口进程"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "6." "网络连接"
        echo ""
        printf "    ${RED}%-8s %-18s${NC}\n" "0." "返回主菜单"
        echo ""
        read -r -p "  请选择: " choice
        case "$choice" in
            1) list_ports ;;
            2) port_detail ;;
            3) kill_port ;;
            4) proc_list ;;
            5) proc_find ;;
            6) net_connections ;;
            0) return ;;
            *) echo -e "${RED}无效选项${NC}"; sleep 1 ;;
        esac
    done
}

port_detail() {
    echo -e "${BLUE}===== 端口详情 =====${NC}"
    echo ""
    read -r -p "输入端口号: " port
    if [[ -z "$port" ]]; then
        echo "端口号不能为空"
        read -r -p "按回车返回..."
        return
    fi
    echo ""
    echo -e "  ${CYAN}[TCP 监听]${NC}"
    lsof -iTCP:"$port" -sTCP:LISTEN -P -n 2>/dev/null || echo "  (无)"
    echo ""
    echo -e "  ${CYAN}[TCP 连接]${NC}"
    lsof -iTCP:"$port" -P -n 2>/dev/null | grep -v LISTEN || echo "  (无)"
    echo ""
    echo -e "  ${CYAN}[UDP]${NC}"
    lsof -iUDP:"$port" -P -n 2>/dev/null || echo "  (无)"
    echo ""
    read -r -p "按回车返回..."
}

proc_list() {
    echo -e "${BLUE}===== 进程列表 (按 CPU) =====${NC}"
    echo ""
    count="20"
    read -r -p "显示行数 [默认 20]: " n
    count="${n:-20}"
    echo ""
    ps aux --sort=-%cpu 2>/dev/null | head -$((count + 1)) | awk '{
        if (NR==1) printf "  %-10s %-6s %-5s %-5s %s\n", $1, $2, $3, $4, $11
        else printf "  %-10s %-6s %-5s %-5s %s\n", $1, $2, $3, $4, $11
    }'
    echo ""
    read -r -p "按回车返回..."
}

proc_find() {
    echo -e "${BLUE}===== 查找进程 =====${NC}"
    echo ""
    read -r -p "输入进程名/关键字: " keyword
    if [[ -z "$keyword" ]]; then
        echo "关键字不能为空"
        read -r -p "按回车返回..."
        return
    fi
    echo ""
    result=$(ps aux 2>/dev/null | grep -i "$keyword" | grep -v "grep -i $keyword" | grep -v "proc_find")
    if [[ -z "$result" ]]; then
        echo -e "  ${YELLOW}未找到匹配进程${NC}"
    else
        echo "$result" | awk '{printf "  %-10s %-6s %-5s %-5s %-8s %s\n", $1, $2, $3, $4, $8, $11}'
    fi
    echo ""
    read -r -p "按回车返回..."
}

net_connections() {
    echo -e "${BLUE}===== 网络连接状态 =====${NC}"
    echo ""
    echo -e "  ${CYAN}[ESTABLISHED 连接]${NC}"
    netstat -an 2>/dev/null | grep ESTABLISHED | awk '{printf "  %-25s %-25s %s\n", $4, $5, $6}' | head -20 || echo "  (无结果)"
    echo ""
    echo -e "  ${CYAN}[LISTEN 端口]${NC}"
    netstat -an 2>/dev/null | grep LISTEN | awk '{printf "  %-25s %s\n", $4, $6}' | head -20 || echo "  (无结果)"
    echo ""
    read -r -p "按回车返回..."
}


kill_port() {
    echo -e "${BLUE}===== 端口停用 =====${NC}"
    echo ""
    read -r -p "输入端口号: " port
    if [[ -z "$port" ]]; then
        echo "端口号不能为空"
        read -r -p "按回车返回..."
        return
    fi
    info=$(lsof -iTCP:"$port" -sTCP:LISTEN -P -n 2>/dev/null)
    if [[ -z "$info" ]]; then
        echo -e "${YELLOW}端口 $port 没有监听中的进程${NC}"
        read -r -p "按回车返回..."
        return
    fi
    pid=$(echo "$info" | awk 'NR>1{print $2}' | head -1)
    cmd=$(echo "$info" | awk 'NR>1{print $1}' | head -1)
    echo ""
    echo -e "  进程: ${YELLOW}PID=$pid  命令=$cmd${NC}"
    echo "$info" | awk 'NR>1{printf "  %-10s %-8s %s\n", $1, $2, $9}'
    echo ""
    read -r -p "  确认 kill -9? [y/N] " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        kill -9 "$pid" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 进程 $pid 已终止" || echo -e "  ${RED}✗${NC} 终止失败"
    else
        echo "  已取消"
    fi
    echo ""
    read -r -p "按回车返回..."
}

list_ports() {
    echo -e "${BLUE}===== 当前监听端口 =====${NC}"
    echo ""
    lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | awk 'NR==1 || NR>1{printf "  %-10s %-8s %-20s %s\n", $1, $2, $3, $9}' || echo "  (无结果)"
    echo ""
    read -r -p "按回车返回..."
}

# ====================================================================
#  分组 4: 项目管理 (编译 / 打包 / 发布 / 自检)
# ====================================================================

mvn_compile() {
    echo -e "${BLUE}===== Maven 编译 =====${NC}"
    echo ""
    cd "$ROOT_DIR"
    echo "  项目根目录: $ROOT_DIR"
    echo ""
    if [[ ! -f pom.xml ]]; then
        echo -e "  ${RED}✗${NC} 未找到 pom.xml，请确认项目目录正确"
        read -r -p "按回车返回..."
        return
    fi
    echo -e "  执行: ${CYAN}mvn clean compile -DskipTests${NC}"
    echo ""
    read -r -p "  确认编译? [Y/n] " yn
    yn="${yn:-Y}"
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        mvn clean compile -DskipTests
        echo -e "\n  ${GREEN}✓${NC} 编译完成"
    else
        echo "  已取消"
    fi
    echo ""
    read -r -p "按回车返回..."
}

mvn_build() {
    echo -e "${BLUE}===== Maven 打包 =====${NC}"
    echo ""
    cd "$ROOT_DIR"
    echo "  项目根目录: $ROOT_DIR"
    echo ""
    if [[ ! -f pom.xml ]]; then
        echo -e "  ${RED}✗${NC} 未找到 pom.xml"
        read -r -p "按回车返回..."
        return
    fi
    echo -e "  执行: ${CYAN}mvn clean package -DskipTests${NC}"
    echo ""
    read -r -p "  确认打包? [Y/n] " yn
    yn="${yn:-Y}"
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        mvn clean package -DskipTests
        echo -e "\n  ${GREEN}✓${NC} 打包完成"
    else
        echo "  已取消"
    fi
    echo ""
    read -r -p "按回车返回..."
}

mvn_check() {
    echo -e "${BLUE}===== 项目自检 =====${NC}"
    echo ""
    cd "$ROOT_DIR" 2>/dev/null || true
    echo "  项目根目录: $ROOT_DIR"
    echo ""
    # 检查 pom.xml
    if [[ -f pom.xml ]]; then
        echo -e "  ${GREEN}✓${NC} pom.xml 存在"
    else
        echo -e "  ${RED}✗${NC} pom.xml 缺失"
    fi
    # 检查 java
    if command -v java &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} java: $(java -version 2>&1 | head -1)"
    else
        echo -e "  ${RED}✗${NC} java 未安装"
    fi
    # 检查 mvn
    if command -v mvn &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} mvn:  $(mvn --version 2>&1 | head -1)"
    else
        echo -e "  ${RED}✗${NC} mvn 未安装"
    fi
    # 磁盘
    echo ""
    echo -e "  ${CYAN}磁盘使用:${NC}"
    df -h "$ROOT_DIR" 2>/dev/null | tail -1 | awk '{printf "  %s / %s (已用 %s)\n", $3, $2, $5}'
    echo ""
    read -r -p "按回车返回..."
}

# ====================================================================
#  分组 5: Git 操作
# ====================================================================

git_pull() {
    echo -e "${BLUE}===== Git Pull =====${NC}"
    echo ""
    cd "$ROOT_DIR"
    echo "  当前分支: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo ""
    git pull --rebase 2>&1
    echo -e "\n  ${GREEN}✓${NC} Pull 完成"
    echo ""
    read -r -p "按回车返回..."
}

git_push() {
    echo -e "${BLUE}===== Git Push =====${NC}"
    echo ""
    cd "$ROOT_DIR"
    branch=$(git branch --show-current 2>/dev/null || echo 'N/A')
    echo "  当前分支: $branch"
    echo ""
    read -r -p "  确认 push origin $branch? [y/N] " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        git push origin "$branch" 2>&1
        echo -e "\n  ${GREEN}✓${NC} Push 完成"
    else
        echo "  已取消"
    fi
    echo ""
    read -r -p "按回车返回..."
}

git_status() {
    echo -e "${BLUE}===== Git Status =====${NC}"
    echo ""
    cd "$ROOT_DIR"
    git status -s 2>&1
    echo ""
    read -r -p "按回车返回..."
}

git_log() {
    echo -e "${BLUE}===== Git Log =====${NC}"
    echo ""
    cd "$ROOT_DIR"
    git log --oneline -20 2>&1
    echo ""
    read -r -p "按回车返回..."
}

# ====================================================================
#  分组 6: 数据库
# ====================================================================

db_menu() {
    echo -e "${BLUE}===== 数据库操作 =====${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠ 数据库连接信息待配置${NC}"
    echo ""
    echo "  请在下方配置环境变量后使用:"
    echo "    DB_HOST / DB_PORT / DB_USER / DB_PASS / DB_NAME"
    echo ""
    read -r -p "按回车返回..."
}

# ====================================================================
#  分组 7: 服务控制
# ====================================================================

start_service() {
    echo -e "${BLUE}===== 启动服务 =====${NC}"
    echo ""
    echo "  可用模块: admin | api | ui | nuxt | service | all"
    echo ""
    read -r -p "  输入模块名: " module
    if [[ -z "$module" ]]; then
        echo "模块名不能为空"
        read -r -p "按回车返回..."
        return
    fi
    echo ""
    echo -e "  ${YELLOW}⚠ 服务启动逻辑待配置 (模块: $module)${NC}"
    echo "  请在脚本中完善各模块的启动命令。"
    echo ""
    read -r -p "按回车返回..."
}

stop_service() {
    echo -e "${BLUE}===== 停止服务 =====${NC}"
    echo ""
    pid_file="$ROOT_DIR/.mms-pids"
    if [[ -f "$pid_file" ]]; then
        echo "  读取 PID 文件: $pid_file"
        while read -r pid; do
            [[ -n "$pid" ]] && kill "$pid" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 已停止 PID $pid" || true
        done < "$pid_file"
        rm -f "$pid_file"
        echo -e "\n  ${GREEN}✓${NC} 所有 mms 进程已停止"
    else
        echo -e "  ${YELLOW}未找到 .mms-pids 文件${NC}"
    fi
    echo ""
    read -r -p "按回车返回..."
}

# ====================================================================
#  启动 Cursor
# ====================================================================

launch_cursor() {
    echo -e "${BLUE}===== 启动 Cursor =====${NC}"
    echo ""

    # 第一步：启动 Cursor助手
    CURSOR_HELPER=$(mdfind -name "Cursor助手" 2>/dev/null | grep "/Cursor助手.app\$" | head -1)
    if [[ -n "$CURSOR_HELPER" ]]; then
        if ! pgrep -f "Cursor助手.app" &>/dev/null; then
            echo "🔧 正在启动 Cursor助手..."
            open "$CURSOR_HELPER"
            echo -e "  ${GREEN}✓${NC} Cursor助手 已启动"
        else
            echo -e "  ${GREEN}✓${NC} Cursor助手 已在运行"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} 未找到 Cursor助手.app"
    fi

    # 第二步：启动 Cursor（16GB 内存上限）
    echo ""
    echo "📂 正在启动 Cursor..."
    open -a Cursor --args --max-memory=16384
    echo -e "  ${GREEN}✓${NC} Cursor 已启动 (max-memory=16384)"

    echo ""
    echo -e "  ${GREEN}🎉 启动完成！${NC}"
    echo ""
    countdown_exit
}

# ====================================================================
#  菜单界面
# ====================================================================

show_main_menu() {
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║               MMS 统一工具                      ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    # ===== 全局工具 =====
    # 按显示宽度补齐，避免中文在终端里错位
    _pad_text() {
        local txt="$1"
        local width="$2"
        python3 -c "import sys;s=sys.argv[1];w=int(sys.argv[2]);cur=sum(2 if ord(ch)>127 else 1 for ch in s);print(s+' '*max(0,w-cur),end='')" "$txt" "$width" 2>/dev/null || printf "%-${width}s" "$txt"
    }

    _menu_cell() {
        local idx="$1"
        local label="$2"
        local color="$3"
        local w=24
        printf "    ${color}%s${NC} " "$(_pad_text "$idx" 4)"
        printf "%s" "$(_pad_text "$label" "$w")"
    }

    _menu_cell "──" "全局" "$GREEN"
    _menu_cell "──" "全局" "$GREEN"
    echo ""
    _menu_cell "1." "启动 Codex" "$GREEN"
    _menu_cell "3." "网络工具 ▶" "$GREEN"
    echo ""
    _menu_cell "2." "项目初始化" "$GREEN"
    _menu_cell "4." "端口进程 ▶" "$GREEN"
    echo ""
    _menu_cell "d." "MMS初始化" "$GREEN"
    _menu_cell "c." "启动 Cursor" "$GREEN"
    echo ""
    _menu_cell "l." "启动 LLM-Proxy" "$GREEN"
    echo ""
    echo ""

    # ===== 项目工具（仅在已初始化项目目录中显示）=====
    local pr
    pr="$(find_project_root "$(pwd)" 2>/dev/null || true)"
    if [[ -n "${pr:-}" && -d "$pr/.mms" ]]; then
        local pname
        pname="$(basename "$pr")"
        printf "  ${GREEN}%-28s${NC}  ${GREEN}%-28s${NC}\n" "── $pname" "── 项目(.mms)"
        printf "    ${GREEN}%-8s${NC} %-18s" "5." "doctor 自检"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "8." "build 打包"
        printf "    ${GREEN}%-8s${NC} %-18s" "6." "run 启动"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "9." "git"
        printf "    ${GREEN}%-8s${NC} %-18s" "7." "secrets 机密"
        printf "    ${GREEN}%-8s${NC} %-18s\n" "a." "deploy 部署"
        echo ""
    fi
    printf "    ${RED}%-8s %-18s${NC}\n" "0." "退出"
    echo ""
}

main() {
    while true; do
        show_main_menu
        read -r -p "  请选择: " choice
        case "$choice" in
            1) launch_codex ;;
            2) project_init ;;
            3) network_menu ;;
            4) port_menu ;;
            d) init_mms ;;
            c) launch_cursor ;;
            l) launch_llm_proxy ;;
            5) proj_check ;;
            6) proj_start ;;
            7) proj_db ;;
            8) proj_build ;;
            9) proj_git ;;
            a) 
              pr="$(find_project_root "$(pwd)" 2>/dev/null || true)"
              [[ -n "${pr:-}" ]] && run_project "$pr" --dry-run deploy || echo -e "${YELLOW}未初始化项目（缺少 .mms/）${NC}"
              read -r -p "按回车返回..."
              ;;
            0) echo "Bye~"; exit 0 ;;
            *) echo -e "${RED}无效选项${NC}"; sleep 1 ;;
        esac
    done
}

# ====================================================================
#  命令行模式（非交互）
#    - 在已初始化项目目录：自动分发给 .mms/bin/mms.project.sh
#    - 其它目录：仅支持少量全局命令（init / codex / help）
# ====================================================================

cli_help() {
    cat <<EOF
用法:
  mms                 进入交互菜单
  mms init            在当前目录生成/覆盖 .mms/* 与 .cursor(mms-cli)

在「已初始化项目目录（含 .mms/bin/project.yml）」下，还支持：
  mms doctor|deps|secrets|run|build|docker:build|docker:push|deploy|git:status|git:commit|git:push
（会自动分发到 .mms/bin/mms.project.sh；兼容仍存在 .mms/project.yml + bin 的旧布局）
EOF
}

dispatch_cli() {
    # init 在任何目录都允许（按你选择的“强制覆盖”策略）
    case "${1:-}" in
      init) shift || true; project_init; return 0 ;;
    esac

    local pr
    pr="$(find_project_root "$(pwd)" 2>/dev/null || true)"
    if [[ -n "${pr:-}" ]]; then
        # 兼容：mms help => 项目脚本 --help
        if [[ "${1:-}" == "help" ]]; then
            shift || true
            run_project "$pr" --help
            return $?
        fi
        run_project "$pr" "$@"
        return $?
    fi

    # 非项目目录：只允许全局命令
    case "${1:-}" in
      codex) shift || true; launch_codex ;;
      help|-h|--help) cli_help ;;
      "") main ;;
      *) echo -e "${YELLOW}当前目录未初始化项目（缺少 .mms/），仅可用: mms / mms init / mms help${NC}" ;;
    esac
}

if [[ $# -gt 0 ]]; then
    dispatch_cli "$@"
else
    main
fi
