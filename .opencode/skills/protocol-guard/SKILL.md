---
name: protocol-guard
description: Validate interactive decision-gate enforcement and compact protocol rollout readiness
version: 1.0.0
author: opencode
type: skill
category: quality
tags:
  - protocol
  - compact
  - interactive
  - readiness
  - validation
---

# Protocol Guard Skill

Use this skill to run automated health checks for:

- Interactive decision UI wiring (`question` tool + decision gates)
- Compact protocol integrity (schema + inheritance + locale policy)
- Rollout readiness (`phase2`/`phase3`)

## Commands

```powershell
$env:TS_NODE_COMPILER_OPTIONS='{"module":"commonjs"}'

# Interactive decision-gate health
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" interactive-health

# Compact protocol health
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" compact-health

# Rollout readiness (defaults to phase2)
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" compact-readiness phase2
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" compact-readiness phase3

# Run all checks
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" all
```
