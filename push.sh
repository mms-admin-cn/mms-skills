#!/bin/bash
# MMS Skills 一键推送脚本
# 用法: ./push.sh [commit message]

set -e

REMOTE="origin"
BRANCH="master"

if [ -z "$1" ]; then
  MSG="update: $(date '+%Y-%m-%d %H:%M')"
else
  MSG="$1"
fi

echo "→ 暂存所有变更..."
git add -A

echo "→ 提交: $MSG"
git commit -m "$MSG" || echo "（无新变更，跳过 commit）"

echo "→ 推送到 $REMOTE/$BRANCH ..."
git push "$REMOTE" "$BRANCH"

echo "✓ 推送完成 → https://github.com/mms-admin-cn/mms-skills"
