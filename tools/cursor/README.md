# Cursor 侧引入与使用

## 一键引入（让 Agent 直接执行）

```bash
mkdir -p .cursor/rules
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/.cursor/rules/00-project-bootstrap.mdc" ".cursor/rules/00-project-bootstrap.mdc"
cp -f "/Volumes/SXPCWLKJ/MyWork/mms-skills/.cursorrules" ".cursorrules"
```

## 验证

```bash
ls -la .cursor/rules .cursorrules
```

## 使用顺序
1. 任务识别 -> 选技能
2. 先读 `skills-shared/<skill>/SKILL.md`
3. 再执行任务
4. 多技能保持主线（主技能 -> 辅技能）