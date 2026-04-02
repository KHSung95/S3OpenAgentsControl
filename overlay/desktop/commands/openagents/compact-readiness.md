---
description: Evaluate rollout readiness for compact protocol phase transitions (default: phase2)
tags:
  - openagents
  - compact
  - readiness
  - rollout
dependencies:
  - skill:protocol-guard
---

# Compact Readiness

**Arguments**: `$ARGUMENTS`

**Purpose**: Decide GO/HOLD for protocol rollout phase progression.

## Run

1. Load skill: `protocol-guard`
2. Determine target phase:
- If no args: `phase2`
- If args include `phase3`: `phase3`

3. Run:

```powershell
$env:TS_NODE_COMPILER_OPTIONS='{"module":"commonjs"}'
# Default
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" compact-readiness phase2

# Phase 3 check
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" compact-readiness phase3
```

4. Return:
- GO or HOLD verdict
- Blocking reasons
- Minimal next actions to reach GO
