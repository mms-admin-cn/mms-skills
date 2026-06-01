# Claude Code 侧引入与使用

## 一键引入（让 Agent 直接执行）

```bash
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/CLAUDE.md" "CLAUDE.md"
```

## 验证

```bash
ls -la CLAUDE.md
```

## 使用顺序
1. 根据任务匹配技能
2. 先读取 `skills-shared/<skill>/SKILL.md`
3. 多技能场景按“主技能 + 辅技能”执行