# Codex 侧引入与使用

## 一键引入（让 Agent 直接执行）

```bash
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/AGENTS.md" "AGENTS.md"
```

## 验证

```bash
ls -la AGENTS.md
```

## 使用顺序
1. 按任务类型定位技能目录
2. 先读取 `skills-shared/<skill>/SKILL.md`
3. 按技能约束产出结果