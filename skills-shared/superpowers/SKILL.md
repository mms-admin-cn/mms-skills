---
name: using-superpowers
description: Use when starting any conversation — establishes task tiering, then loads skills ONLY when the task complexity warrants it. Phatic messages and Level 0/1 tasks skip all skills. Note: AGENTS.md takes priority if it says "skip skills."
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<PHATIC-EXEMPTION>
If the user's message is PURELY phatic — a greeting, status check, or simple acknowledgment with ZERO substantive content — respond directly and naturally. Do NOT invoke skills. Do NOT check for skills. Do NOT read any SKILL.md.

Phatic (skip all skills, respond immediately):
- "在吗", "Hi", "Hello", "你好", "Good morning"
- "Are you there?", "Can I ask something?"
- "OK", "Thanks", "Got it", "👍", "好的"
- Simple questions with no task content: "现在几点", "What time is it"

Substantive (skills MAY apply, continue checking):
- Any message containing a task, question, instruction, or request for action
- "Fix this bug", "Add a login page", "帮我看下这个报错"

If unsure whether a message is purely phatic, default to treating it as substantive — but do NOT load skills yet. Proceed to TASK-TIERING.
</PHATIC-EXEMPTION>

<TASK-TIERING>
Match workflow depth to task complexity. The full pipeline is the MAXIMUM, not the default.

### Level 0 — Trivial (typo, color, config value, comment, one-line fix)
**Workflow:** Direct edit. No analysis. No version doc. No skills at all.
**Examples:** "改按钮颜色为红色", "修复拼写错误", "更新版本号", "加一行注释"
**DO NOT load ANY SKILL.md for these tasks.**

### Level 1 — Simple (single bug fix with clear cause, add one field/component, small isolated change)
**Workflow:** Quick analysis → direct implementation. Use TDD for code changes.
**Examples:** "加一个邮箱字段", "修复空指针异常", "给表格加排序功能"
**If needed:** Read only systematic-debugging (bugs) or test-driven-development. Skip all process skills.

### Level 2 — Moderate (new feature, new page, multi-file change, cross-module work)
**Workflow:** mms-dev-workflow: analysis → version doc → develop → sync → review.
**Examples:** "添加用户登录功能", "新建订单列表页", "对接支付接口"
**Read:** mms-dev-workflow/SKILL.md. Optionally test-driven-development, verification-before-completion.

### Level 3 — Complex (new subsystem, architecture change, greenfield project, multi-service)
**Workflow:** brainstorming → writing-plans → subagent-driven-development.
**Examples:** "构建支付系统", "重构认证模块为微服务", "从零搭建管理后台"
**Read:** brainstorming/SKILL.md first, then follow its guidance.

**Default rule:** When unsure, go ONE level DOWN (not up). It's better to start simple.
**User override:** If user says "快速改"/"just do it"/"不用走流程", skip to Level 0/1 immediately.
</TASK-TIERING>

<EXTREMELY-IMPORTANT>
**Most tasks do NOT need skills.** Skills are specialized workflows for structured development — not an everyday requirement.

LOAD A SKILL ONLY WHEN:
- The task is clearly Level 2 or 3 according to TASK-TIERING above
- The user explicitly names a skill
- You need a specific domain workflow (uni-app, MMS plugin, etc.)

DO NOT LOAD SKILLS WHEN:
- The task is Level 0 or 1 — just do it directly
- You can handle it with your native capabilities
- You're unsure — when unsure, SKIP skills. Over-analysis hurts more than it helps.
- You think "maybe a skill would help" — if it's not obvious, it's not needed.

**Default posture: act first, load skills only when clearly necessary.**
**AGENTS.md always takes priority over this guidance.**
</EXTREMELY-IMPORTANT>

## Instruction Priority

User instructions always take precedence over skills.

1. **User's explicit instructions** (AGENTS.md, direct requests) — highest priority
2. **Superpowers skills** — guide execution where they apply
3. **Default system prompt** — lowest priority

If AGENTS.md says "just do it" and a skill says "follow the full pipeline," follow AGENTS.md.

## How to Access Skills

**In Codex (AGENTS.md context):** Codex does NOT have a native `Skill` tool. When a skill is needed (Level 2+ only), use the `Read` tool to read `skills-shared/<skill-name>/SKILL.md`. Read only ONE skill at a time. Do NOT attempt to call a `Skill` tool that doesn't exist.

**In Claude Code:** Use the `Skill` tool.

**In other environments:** Check your platform's documentation.

# Using Skills

## The Rule

**First:** Check if the message is phatic (skip everything) or Level 0/1 (act directly).
**Then:** Only if the task is Level 2+, read the appropriate skill. Read ONE skill, follow it, then decide if more are needed.
**Never:** Pre-load skills "just in case" or read multiple skills speculatively.

## Red Flags — STOP, you're over-analyzing

| Thought | Reality |
|---------|---------|
| "Maybe a skill applies" | If it's not obvious which skill, none apply. Act directly. |
| "Let me check for skills first" | Only check for Level 2+ tasks. Most things are Level 0/1. |
| "I should read it just to be safe" | Reading unnecessary skills wastes time and degrades quality. |
| "There might be a relevant skill" | There are 83 skills. If nothing obviously matches, skip all. |
| "This is a simple question" | Simple questions don't need skills. Answer directly. |
| "Let me explore the codebase first" | You can explore without loading skills. Only load a skill when you know which one you need. |

## Skill Priority (Level 2+ only)

When multiple skills could apply, use this order:
1. **Process skills** (mms-dev-workflow, brainstorming) — determine HOW to approach
2. **Domain skills** (uniapp-vue3-workflow, mms-plugin) — guide execution

**Skill selection by task type:**
- "Fix this bug" → systematic-debugging (only if complex). Simple bugs: just fix.
- "Build X" (greenfield) → brainstorming → writing-plans
- "Build X" (existing project feature) → mms-dev-workflow
- "改个颜色/加个字段" → no skills at all

## Skill Types

**Rigid** (TDD, debugging): Follow exactly when loaded.
**Flexible** (patterns): Adapt principles to context.

## User Instructions

User instructions say WHAT and HOW — the user is in control.

**User workflow override signals (honor immediately, no debate):**
- "快速改" / "just do it" / "直接改" → skip to Level 0/1
- "不用走流程" / "skip the process" → skip process skills entirely
- "按规范来" / "按流程走" → follow the appropriate pipeline for the task tier
