<!-- Context: core/compact-contract-schema | Priority: critical | Version: 1.0 | Updated: 2026-04-01 -->

# Contract Compact Schema

**Purpose**: Canonical schema for workflow contract replicas created at stage boundaries.

**Use this for**: planner -> implementer, implementer -> verifier, verifier -> handoff packets.

**Do not use this for**: `/context compact` MVI minimization.

---

## Core Required Fields

These fields are required in every `contract_replica` packet:

- `goal`
- `approved_scope`
- `acceptance_criteria`
- `dont_do`
- `approval_state`
- `open_risks`
- `unresolved_questions`

---

## Conditional Fields

Include these fields only when the stage/work type requires them:

- `non_goals` -> required for `PLAN_APPROVED` and `SUBTASK_SPLIT_DONE`
- `test_requirements` -> required for `IMPLEMENT_DONE_PRE_VERIFY` and `VERIFY_DONE_HANDOFF`
- `rollback_notes` -> required for deployment/infrastructure/risky changes

---

## Locale Policy

- Packet keys, enums, stage triggers, and identifiers stay in English.
- Human-readable value fields should default to Korean (`ko-KR`).
- If source artifacts are English-only, preserve meaning while allowing Korean handoff text in replica fields.

---

## Packet Template

```yaml
contract_replica:
  stage_trigger: PLAN_APPROVED | SUBTASK_SPLIT_DONE | IMPLEMENT_DONE_PRE_VERIFY | VERIFY_DONE_HANDOFF
  workflow_state: normal | debug | rca | recovery | handoff_ready
  mode: warn | block
  output_locale: ko-KR
  source_contract_id: "{id-or-session-path}"
  goal: "{single sentence objective}"
  approved_scope:
    - "{in-scope item}"
  non_goals:
    - "{explicit out-of-scope item}"
  acceptance_criteria:
    - "{binary pass/fail criterion}"
  dont_do:
    - "{forbidden action/constraint}"
  approval_state: approved | conditional_approved | rejected | pending
  changed_files:
    - "{path}"
  open_risks:
    - "{risk + impact}"
  test_requirements:
    - "{test required before handoff}"
  unresolved_questions:
    - "{still unresolved question}"
  rollback_notes:
    - "{rollback strategy or n/a with reason}"

validation:
  presence_check: pass | fail
  non_empty_check: pass | fail
  preservation_check: pass | fail
  inheritance_check: pass | fail
  failures:
    - "{exact failure reason if any}"
  inheritance:
    dropped_fields:
      - "{field removed from parent contract}"
    downgraded_values:
      - "{value changed in unsafe way}"
```

---

## Preservation Rules

Parent -> child packet preservation is mandatory for:

- `dont_do` (must not be removed)
- `approval_state` (must not be upgraded without explicit approval)
- `unresolved_questions` (must not be zeroed without resolution proof)
- `acceptance_criteria` (must not be silently reduced)
- `open_risks` (must not be removed without mitigation evidence)

If preservation fails:

- `mode: block` -> stop handoff and report failure
- `mode: warn` -> continue but include explicit warning marker

If inheritance fails:

- `mode: block` -> stop handoff and include `dropped_fields` and `downgraded_values`
- `mode: warn` -> continue but include explicit warning marker and inheritance details

---

## Related

- `compact-protocol.md` - Stage-gated compact protocol
- `task-delegation-basics.md` - Delegation and session contracts
- `../context-system/guides/compact.md` - MVI compaction (different purpose)
