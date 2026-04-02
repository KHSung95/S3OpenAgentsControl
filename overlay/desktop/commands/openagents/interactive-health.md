---
description: Validate question UI readiness and decision-gate enforcement for custom orchestrators
tags:
  - openagents
  - validation
  - interactive
  - question
dependencies:
  - skill:protocol-guard
---

# Interactive Health

**Purpose**: Check whether custom primary agents can render selectable question UI and enforce decision gates.

## Run

1. Load skill: `protocol-guard`
2. Run:

```powershell
$env:TS_NODE_COMPILER_OPTIONS='{"module":"commonjs"}'
npx ts-node "C:/Users/bug95/.config/opencode/skills/protocol-guard/scripts/protocol-cli.ts" interactive-health
```

3. Return:
- Overall PASS/HOLD
- Failed checks by file
- Exact remediation steps
