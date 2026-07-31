# Issue #2 — Proposal: Core Canon Reference Conversion

Status: **proposal only** — phase 1. No conversion is executed by this
document; it is gated on approvers.md Approve per contract v3 s19 before
phase 2 implements it.

This proposal is based on the current-state survey at
`docs/issue-2/reports/implementation/survey.md`. Since no local precedent
exists for the "stub referencing core canon" pattern (see survey section
3), this proposal establishes that pattern for this rulebook; it should be
sanity-checked against `core/hooks/lib/role-directive.sh` and core's actual
hook-registration mechanism at the start of phase 2, since that repo's
contents were not visible during this survey.

## Work item 1 — warrant-hunter copy → core canon reference

**Remove**: `security-threat-model/agents/warrant-hunter.md` in its current
full-text form.

**Replace with**: a short stub agent doc that:
- states this role installs/relies on core's `warrant/` plugin (core issue
  #63) for the rotating-stance hunt mechanism, instead of re-describing it,
- keeps only the role-unique mandate line (`신뢰 경계의 위협 표면`) and the
  hand-off note (구현 단계 취약점 점검은 → secure-coding; 법적 노출이면 →
  legal-compliance), since those are not duplicated content — they are this
  role's own `decides`/hand-off fields,
- points to wherever core's warrant plugin format expects role-specific
  stance/mandate input (env var, front-matter field, or config file — to be
  confirmed against core's actual plugin contract in phase 2; not knowable
  from this repo alone).

**Migration note**: if core's `warrant/` plugin requires this role to
register a mandate string via a specific mechanism (e.g. a manifest field
in `plugin.json`, or a small config file consumed by the core plugin),
phase 2 must add that registration in the same change that deletes the
full-text duplicate, so the role isn't left without hunt coverage between
commits.

## Work item 2 — remove trailer-gate.sh / record-fields-gate.sh /
handbook-trigger-gate.sh copies + hook registrations

**`trailer-gate.sh`** — delete outright. Its own header already documents
it as role-agnostic logic with only the role name substituted; core issue
#66 landed this exact gate in `core/hooks/` with `CLAUDE_ROLE` injection,
so this role's copy is pure duplication with no unique payload to
preserve.

**`handbook-trigger-gate.sh`** — delete outright. Currently a placeholder
(`exit 0 # TODO`) with no implemented logic at all in this repo, so there
is nothing role-specific to lose; core's registered version supersedes it
cleanly. (Its own comment even questions whether a report-only role with
`write_scope: []` needs this gate at all — worth flagging to core owners,
but not blocking on it since deleting the local stub is safe either way.)

**`record-fields-gate.sh`** — **not** a delete-outright case. Its
`REQUIRED_FIELDS = ["stride-table", "mitigation-list",
"residual-risk-note"]` list is this role's actual unique payload (mirrors
`produces` from this role's spec). Proposal: remove the gate *logic*
(python field-check machinery, payload parsing, etc. — role-agnostic
mechanics that core issue #66 should also cover for record-fields gates in
general) and replace with either:
  (a) an explicit config value consumed by a core-provided record-fields
      gate, analogous to work item 4's `RECORD_FIELDS_TERMINAL_STATES`
      pattern — e.g. a `RECORD_FIELDS_REQUIRED` list this role sets and
      core's gate reads, or
  (b) if core's #66 rollout does not yet generalize record-fields-gate
      (only trailer/handbook-trigger are named as the "역할 무관 게이트
      3종" in the issue body alongside record-fields — re-read: issue body
      *does* list record-fields-gate among the three role-agnostic gates),
      then per the issue's own framing all three, including
      record-fields-gate's *mechanics*, move to core, and only the
      `REQUIRED_FIELDS` value stays here as config.

  Given the issue body explicitly names "trailer/record-fields/
  handbook-trigger" as the three gates covered by core issue #66, the
  correct read is: all three gate *scripts* get removed and superseded by
  core's registration; `record-fields-gate.sh`'s role-unique
  `REQUIRED_FIELDS` value must be preserved as an explicit config artifact
  (env var or small JSON/shell config file) that core's generalized gate
  consumes, exactly parallel to work item 4's terminal-states example.

**Hook registration**: remove the corresponding `PreToolUse` entries from
`security-threat-model/hooks/hooks.json` (the `record-fields-gate.sh`,
`handbook-trigger-gate.sh`, and `trailer-gate.sh` command entries), since
core's own hook registration (per core issue #66) replaces them. Keep the
`SessionStart` → `directive.sh` entry (directive.sh survives as a stub,
per work item 3).

## Work item 3 — directive.sh → stub form

**Replace** the current fully-inline heredoc in
`security-threat-model/hooks/directive.sh` with:
- `source` (or equivalent load) of the shared
  `core/hooks/lib/role-directive.sh`'s `core_role_directive` function,
- a call to `core_role_directive` passing this role's unique fields as
  arguments/env — `decides`, `use_when`, `produces` (record fields),
  `write_scope`, hand-off text — sourced from a single place (proposal:
  keep these as the existing plugin.json description / README front-matter
  fields, or extract to a small `role.json`/`role.env` if
  `core_role_directive`'s calling convention expects that; exact shape
  TBD against core's actual function signature in phase 2),
- retained generic mechanics only as needed if `core_role_directive`
  doesn't already handle them: the kill-switch env var
  (`SECURITY_THREAT_MODEL_CYCLE_OFF`) and `CLAUDE_ROLE` gate should ideally
  move into the shared function too, since they are identical boilerplate
  duplicated across the trailer/record-fields/handbook-trigger gates as
  well (`__fc` trap, `case ... CYCLE_OFF` pattern) — worth confirming in
  phase 2 whether core's shared lib already covers this so this repo isn't
  left duplicating it a second time.

**Preserve inline** (role-unique, cannot move to core): the specific text
values for YOU DECIDE / USE_WHEN / PRODUCES / WRITE_SCOPE / HAND-OFF /
BOUNDARY CASE, since these differ per role by definition.

## Work item 4 — explicit config for real role differences

No terminal `loop_state` divergence exists yet in this role (survey
section 2, item 4) — nothing to encode there today. The applicable
instance in this role is `record-fields-gate.sh`'s `REQUIRED_FIELDS` list
(see work item 2 above): convert it to an explicit named config value
(e.g. `RECORD_FIELDS_REQUIRED=stride-table,mitigation-list,residual-risk-note`
or a small JSON file) that a core-provided generalized gate reads, rather
than this role keeping its own copy of the gate's checking logic. Any
future role-specific gate divergence for this role (e.g. if a terminal
`loop_state` set is later needed) should follow the same
explicit-named-config pattern rather than a role-specific branch inside a
shared script.

## Work item 5 — stub-check.sh confirmation

`core/hooks/tests/stub-check.sh` does not exist in this repo and was not
locatable — it belongs to the external `core` repo. Proposal for phase 2:
1. Establish how this repo consumes `core` (git submodule, plugin
   dependency install, or CI checkout of the core repo) — not yet decided,
   since this repo currently has zero references to a `core` source at
   all. This is a prerequisite decision phase 2 must make before any of
   work items 1-4 can literally run, since `core_role_directive` and the
   core-side gate registrations must be reachable at hook-execution time,
   not just at test time.
2. Once reachable, run `core/hooks/tests/stub-check.sh` against this
   role's converted directive.sh/hooks.json.
3. Record pass/fail plus the invocation used in
   `docs/issue-2/reports/implementation.md` (the phase-2 record file —
   out of scope for this phase-1 PR; noted here only so phase 2 knows
   where it goes).

## Sequencing within phase 2 (informational)

Suggested order to keep the role always in a working state between
commits: (1) land config extraction for `REQUIRED_FIELDS` /
role-unique-fields in isolation with no behavior change → (2) swap
`directive.sh` to the stub form calling `core_role_directive` → (3) remove
the three gate scripts and their `hooks.json` entries once core's
equivalent registration is confirmed active → (4) remove
`warrant-hunter.md` full text once core's `warrant/` plugin install path
is confirmed for this role → (5) run and record `stub-check.sh`. This
ordering is a suggestion for whoever executes phase 2, not something this
phase-1 PR performs.
