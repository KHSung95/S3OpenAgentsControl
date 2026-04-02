<!-- Context: core/compact-protocol | Priority: critical | Version: 2.0 | Updated: 2026-04-01 -->

# Compact Protocol (Contract Replica)

**Purpose**: Make compact deterministic, auditable, and safe by treating compact output as a contract replica, not free-form summary.

---

## Scope Boundaries

- Applies to orchestration and handoff workflows.
- Does **not** replace source artifacts (plans, task JSON, validation logs).
- Does **not** replace `/context compact` (MVI content minimization).

---

## Allowed Triggers (Stage-Gated Only)

Compact is allowed only at these boundaries:

1. `PLAN_APPROVED`
2. `SUBTASK_SPLIT_DONE`
3. `IMPLEMENT_DONE_PRE_VERIFY`
4. `VERIFY_DONE_HANDOFF`

Any other timing is a protocol violation.

---

## State Machine

Valid workflow states:

- `normal`
- `debug`
- `rca`
- `recovery`
- `handoff_ready`

Compaction policy by state:

- `normal` -> allowed only on stage triggers
- `debug` -> forbidden
- `rca` -> forbidden
- `recovery` -> allowed only with preservation checks passing
- `handoff_ready` -> allowed

---

## Role Boundaries

- `OpenAgent` / `OpenCoder`: orchestrate stage-gated compact calls
- `TaskManager`: may transform contracts while preserving required fields
- `BatchExecutor`: transport-only, preserve contracts exactly (no re-authoring), run validation gates only
- Worker subagents: emit completion packets, do not redefine upstream approvals

---

## Locale Contract

- Protocol keys, enums, triggers, and identifiers remain English for parser stability.
- Human-readable handoff values default to Korean (`output_locale: ko-KR`).
- If upstream artifacts are English, preserve semantics and allow Korean-friendly replica text for user-facing fields.

---

## Validation Gates

Every compact packet must pass in order:

1. Presence check (required fields exist)
2. Non-empty check (core fields contain meaningful values)
3. Preservation check (parent constraints are retained)
4. Inheritance check (parent -> child deltas are explicit and safe)

Preservation is mandatory for:

- `dont_do`
- `approval_state`
- `acceptance_criteria`
- `open_risks`
- `unresolved_questions`

Inheritance check must emit:

- `dropped_fields`: any fields present in parent but absent in child
- `downgraded_values`: any unsafe reductions (for example reduced acceptance criteria)

If either list is non-empty, the packet fails inheritance validation unless explicit approval evidence is attached.

---

## Rollout Policy (Phased Enforcement)

### Phase 1

- `block`: OpenAgent, OpenCoder, TaskManager
- `warn`: CoderAgent, TestEngineer, CodeReviewer, BuildAgent, OpenFrontendSpecialist, OpenDevopsSpecialist, DocWriter

### Phase 2

- `block`: add CoderAgent, TestEngineer, CodeReviewer

### Phase 3

- `block`: global for remaining worker agents

---

## Failure Handling

When checks fail:

- `warn` mode: emit warning marker and continue
- `block` mode: stop handoff, report exact failed checks, request correction

Fallback policy:

- Never discard source artifacts
- Keep source contract as canonical reference
- Regenerate replica from source after fixes

---

## Canonical Schema

Use: `compact-contract-schema.md`
