#!/bin/bash
#===========================================================================
# mms-skills 安装脚本
# 将共享技能库的引导文件安装到目标项目，供 Codex / Cursor / Claude Code 使用
#===========================================================================
set -e

# --- 颜色输出 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

# --- 默认值 ---
SKILLS_HOME="$(cd "$(dirname "$0")" && pwd)"
TARGET="${PWD}"
INSTALL_CODEX=false
INSTALL_CURSOR=false
INSTALL_CLAUDE=false
INSTALL_ALL=true
ADD_SHELL=false
GLOBAL_INSTALL=false

# --- 帮助 ---
usage() {
  echo "mms-skills 安装脚本"
  echo ""
  echo "用法: $0 [选项]"
  echo ""
  echo "选项:"
  echo "  --codex       仅安装 Codex 引导文件"
  echo "  --cursor      仅安装 Cursor 引导文件"
  echo "  --claude      仅安装 Claude Code 引导文件"
  echo "  --all         安装全部三端（默认）"
  echo "  --target DIR  指定目标项目目录（默认当前目录）"
  echo "  --global      全局安装（Cursor → ~/.cursor/rules/，Claude → ~/.claude/）"
  echo "                Codex 不支持全局安装，会跳过"
  echo "  --shell       同时写入 shell 配置 (~/.zshrc)，持久化 MMS_SKILLS_HOME"
  echo "  --help        显示此帮助"
  echo ""
  echo "示例:"
  echo "  # 克隆技能库并安装到当前项目"
  echo "  git clone <repo-url> ~/mms-skills"
  echo "  cd ~/my-project"
  echo "  ~/mms-skills/install.sh"
  echo ""
  echo "  # 仅安装 Codex 到指定目录"
  echo "  ~/mms-skills/install.sh --codex --target ~/my-project"
  echo ""
  echo "  # 安装全部并持久化环境变量"
  echo "  ~/mms-skills/install.sh --all --shell"
  echo ""
  echo "  # 全局安装（所有项目生效）"
  echo "  ~/mms-skills/install.sh --global --all"
  echo ""
  echo "技能库位置: $SKILLS_HOME"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex)  INSTALL_CODEX=true; INSTALL_ALL=false; shift ;;
    --cursor) INSTALL_CURSOR=true; INSTALL_ALL=false; shift ;;
    --claude) INSTALL_CLAUDE=true; INSTALL_ALL=false; shift ;;
    --all)    INSTALL_ALL=true; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    --shell)   ADD_SHELL=true; shift ;;
    --global)  GLOBAL_INSTALL=true; ADD_SHELL=true; shift ;;
    --help)   usage; exit 0 ;;
    -h)       usage; exit 0 ;;
    *)        echo "未知参数: $1"; usage; exit 1 ;;
  esac
done

# --- 全局安装：覆盖目标目录 ---
if [ "$GLOBAL_INSTALL" = true ]; then
  echo "→ 全局安装模式"
  if [ "$INSTALL_CODEX" = true ]; then
    warn "Codex 不支持全局安装，已跳过"
    INSTALL_CODEX=false
  fi
  if [ "$INSTALL_CURSOR" = true ]; then
    TARGET="$HOME/.cursor"
    ok "Cursor 全局规则目录: $TARGET/rules/"
  fi
  if [ "$INSTALL_CLAUDE" = true ]; then
    CLAUDE_TARGET="$HOME/.claude"
    ok "Claude Code 全局规则目录: $CLAUDE_TARGET/"
  fi
  echo ""
fi

# --- 前置检查 ---
if [ ! -d "$SKILLS_HOME/skills-shared" ]; then
  fail "未找到 skills-shared 目录，请确认在 mms-skills 仓库根目录运行此脚本"
  exit 1
fi

if [ "$INSTALL_ALL" = true ]; then
  INSTALL_CODEX=true
  INSTALL_CURSOR=true
  INSTALL_CLAUDE=true
fi

if [ ! -d "$TARGET" ]; then
  fail "目标目录不存在: $TARGET"
  exit 1
fi

# --- 持久化 MMS_SKILLS_HOME ---
if [ "$ADD_SHELL" = true ]; then
  RC_FILE="$HOME/.zshrc"
  if [ -f "$HOME/.bashrc" ] && ! echo "$SHELL" | grep -q zsh; then
    RC_FILE="$HOME/.bashrc"
  fi
  LINE="export MMS_SKILLS_HOME=\"$SKILLS_HOME\""
  if grep -q "MMS_SKILLS_HOME" "$RC_FILE" 2>/dev/null; then
    warn "$RC_FILE 中已有 MMS_SKILLS_HOME，跳过写入"
  else
    echo "" >> "$RC_FILE"
    echo "# mms-skills 技能库路径" >> "$RC_FILE"
    echo "$LINE" >> "$RC_FILE"
    ok "已写入 $RC_FILE"
  fi
fi

# --- 安装函数 ---
install_file() {
  local src="$SKILLS_HOME/$1"
  local dst="$TARGET/$2"
  local label="$3"

  if [ ! -f "$src" ]; then
    fail "$label: 源文件不存在 $src"
    return 1
  fi

  mkdir -p "$(dirname "$dst")"

  # 替换路径占位符（支持多种写法）
  sed \
    -e "s|/Volumes/SXPCWLKJ/MyWork/mms-skills/skills-shared|$SKILLS_HOME/skills-shared|g" \
    -e "s|/Volumes/SXPCWLKJ/MyWork/mms-skills|$SKILLS_HOME|g" \
    "$src" > "$dst"

  ok "$label → $2"
}

# --- 执行安装 ---
echo ""
echo "════════════════════════════════════════"
echo "  mms-skills $(head -1 "$SKILLS_HOME/PROJECT_VERSION" 2>/dev/null || echo '?') 安装"
echo "  来源: $SKILLS_HOME"
echo "  目标: $TARGET"
echo "════════════════════════════════════════"
echo ""

INSTALLED=0

if [ "$INSTALL_CODEX" = true ]; then
  install_file "AGENTS.md" "AGENTS.md" "Codex"
  INSTALLED=$((INSTALLED + 1))
fi

if [ "$INSTALL_CURSOR" = true ]; then
  install_file ".cursor/rules/00-project-bootstrap.mdc" ".cursor/rules/00-project-bootstrap.mdc" "Cursor"
  INSTALLED=$((INSTALLED + 1))
fi

if [ "$INSTALL_CLAUDE" = true ]; then
  if [ "$GLOBAL_INSTALL" = true ]; then
    mkdir -p "$CLAUDE_TARGET"
    install_file "CLAUDE.md" "$CLAUDE_TARGET/CLAUDE.md" "Claude Code（全局）"
  else
    install_file "CLAUDE.md" "CLAUDE.md" "Claude Code"
  fi
  INSTALLED=$((INSTALLED + 1))
fi

echo ""
ok "安装完成 — 已处理 $INSTALLED 个平台"

if [ "$ADD_SHELL" = true ]; then
  echo ""
  warn "请执行以下命令使环境变量生效:"
  echo "  source ~/.zshrc"
fi

echo ""
echo "验证方式:"
[ "$INSTALL_CODEX" = true ]  && echo "  ls -la $TARGET/AGENTS.md"
[ "$INSTALL_CURSOR" = true ] && echo "  ls -la $TARGET/.cursorrules"
if [ "$INSTALL_CLAUDE" = true ]; then
  if [ "$GLOBAL_INSTALL" = true ]; then
    echo "  ls -la ~/.claude/CLAUDE.md"
  else
    echo "  ls -la $TARGET/CLAUDE.md"
  fi
fi
echo ""
