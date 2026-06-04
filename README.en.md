# mms-skills

Current version: `v1.10.0`

`mms-skills` is a shared skill library for MMS development workflows across Cursor, Codex, and Claude Code. The single source of truth is `skills-shared/`; entry files only tell each Agent where to load skills and which workflow rules to follow.

For the full Chinese guide, see [README.md](README.md).

## Quick Facts

| Item | Value |
|------|-------|
| Version file | `PROJECT_VERSION` |
| Machine-readable manifest | `mms-skills.json` |
| Skills root | `skills-shared/` |
| Default workflow skill | `skills-shared/mms-dev-workflow/SKILL.md` |
| Version docs | `version/` |
| Skill count | `84` |

## Install

Set the repository location first:

```bash
export MMS_SKILLS_HOME="/absolute/path/to/mms-skills"
```

### Codex

```bash
cp -f "$MMS_SKILLS_HOME/AGENTS.md" "AGENTS.md"
```

### Cursor

```bash
mkdir -p .cursor/rules
cp -f "$MMS_SKILLS_HOME/.cursor/rules/00-project-bootstrap.mdc" ".cursor/rules/00-project-bootstrap.mdc"
cp -f "$MMS_SKILLS_HOME/.cursorrules" ".cursorrules"
```

### Claude Code

```bash
cp -f "$MMS_SKILLS_HOME/CLAUDE.md" "CLAUDE.md"
```

## Usage Rules

1. Match the task to a skill under `skills-shared/<skill>/SKILL.md`.
2. Read the main skill first, then related skills when needed.
3. Analyze requirements before new feature work.
4. Create `version/vX.Y.Z-feature.md` before implementation.
5. Implement, verify, report progress, then capture reusable lessons back into `skills-shared/`.

## Verify

```bash
test "$(cat PROJECT_VERSION)" = "v1.10.0"
node -e 'const m=require("./mms-skills.json"); if (m.version !== "v1.10.0") process.exit(1); console.log(m.name, m.version)'
find skills-shared -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l
```
