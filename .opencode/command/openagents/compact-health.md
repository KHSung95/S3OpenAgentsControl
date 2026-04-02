---
description: Validate compact protocol integrity, inheritance checks, and locale policy configuration
tags:
  - openagents
  - compact
  - validation
  - protocol
dependencies:
  - skill:protocol-guard
---

# Compact Health

**Purpose**: Audit compact protocol configuration (schema, compactor, orchestration wiring, and warn/block posture).

## Run

1. Load skill: `protocol-guard`
2. Run:

```powershell
$env:TS_NODE_COMPILER_OPTIONS='{"module":"commonjs"}'
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" compact-health
```

3. Return:
- Overall PASS/HOLD
- Missing protocol items
- Worker warn-mode inventory
