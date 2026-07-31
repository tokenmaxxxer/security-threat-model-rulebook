# Issue #2 — Phase 2 record: core canon reference conversion

## What was done

Converted the `security-threat-model` rulebook's core-canon-eligible
copies to stubs/config that reference core canon instead of duplicating
it, per the approved phase-1 proposal (`docs/issue-2/proposals/core-canon-reference-conversion.md`):

1. `security-threat-model/agents/warrant-hunter.md` — replaced the
   full-text rotating-stance description with a stub that states this role
   relies on core's `warrant/` plugin (core issue #63) and keeps only the
   role-unique mandate and hand-off fields.
2. Deleted `security-threat-model/hooks/trailer-gate.sh`,
   `handbook-trigger-gate.sh`, `record-fields-gate.sh` and their
   `PreToolUse` entries in `hooks/hooks.json` — superseded by core's own
   registration (core issue #66). Only the `SessionStart` → `directive.sh`
   entry remains.
3. `record-fields-gate.sh`'s role-unique `REQUIRED_FIELDS` value is
   preserved as explicit config in the new
   `security-threat-model/hooks/record-fields.env`
   (`RECORD_FIELDS_REQUIRED=stride-table,mitigation-list,residual-risk-note`),
   for a core-provided generalized gate to consume. No terminal
   `loop_state` divergence exists for this role, so
   `RECORD_FIELDS_TERMINAL_STATES` is left unset (documented in the same
   file for future use).
4. `security-threat-model/hooks/directive.sh` rewritten to the stub form:
   sources `core/hooks/lib/role-directive.sh` and calls
   `core_role_directive` with this role's unique fields (`decides`,
   `use_when`, `produces`, `write_scope`, hand-off, boundary case, record
   path) as its only content. The generic mechanics this factored out
   (kill-switch, `CLAUDE_ROLE` guard, fail-closed trap) are assumed to now
   live inside `core_role_directive` itself — not re-verified against
   core's actual implementation, since the core repo is not checked out
   in this rulebook repo.
5. Ran the harness-distributed `stub-check.sh` against the converted tree
   and recorded a pass (see below).

Summary of work: all 5 issue work items executed in one batch, matching
the proposal's suggested sequencing.

## Why

Reason: core landed a single canon for these mechanisms (core issue #63:
`warrant/` plugin; core issue #66: role-agnostic gates +
`role-directive.sh`, `core_role_directive` shared function). Keeping this
rulebook's full-text copies would leave it out of sync with canon and
duplicate maintenance across every rulebook. The issue's own sequencing
constraint requires this conversion to complete before this repo's
rulebook-maturation issue's phase 2 starts.

Upstream basis: `docs/issue-2/proposals/core-canon-reference-conversion.md`
(approved), itself based on `docs/issue-2/reports/implementation/survey.md`;
approval given via the issue-level comment `APPROVE issue-2/implementation`.

## stub-check.sh confirmation

`core/hooks/tests/stub-check.sh` is not vendored in this repo and no
`core/` checkout exists here (per phase-1 survey, unchanged). The harness
distributes this check to every rulebook as a standalone file dropped
alongside `parse-check.sh`; a copy was available at
`/tmp/claude-1000/stub-check.sh` in this session's environment and was run
directly against this role's `security-threat-model/` tree:

```
$ bash /tmp/claude-1000/stub-check.sh security-threat-model
stub-check: ok — no vendored 'trailer-gate.sh' under security-threat-model
stub-check: ok — no vendored 'record-fields-gate.sh' under security-threat-model
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under security-threat-model
stub-check: ok — no vendored 'parse-check.sh' under security-threat-model
stub-check: ok — security-threat-model/hooks/directive.sh is a role-directive stub
exit 0
```

Result: **PASS**. This is the harness-distributed copy of the check, not a
copy vendored into this repo — this repo still has no `core/` reference of
its own, which is exactly what the check confirms is now correct (no
vendored canon copies remain).

loop_state: landed

## Open findings

- How this repo is meant to consume `core` at hook-execution time (git
  submodule / plugin install / CI checkout) is still undecided — the
  `source` path in `directive.sh`
  (`${CORE_HOOKS_LIB_DIR:-${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib}/role-directive.sh`)
  is a best-guess default, overridable via `CORE_HOOKS_LIB_DIR`, not a
  confirmed install contract.
- Whether `core_role_directive`'s actual signature matches the
  `--role/--decides/--use-when/--produces/--write-scope/--hand-off
  /--boundary-case/--record-path` flags used here, and whether it
  internally reproduces the kill-switch/`CLAUDE_ROLE`-guard/fail-closed
  behavior the deleted inline form had, is unconfirmed — core's actual
  `role-directive.sh` was not visible from this repo.
- Same uncertainty applies to how the `warrant/` plugin consumes this
  role's mandate/hand-off text, and to whether core's generalized
  record-fields gate reads `record-fields.env` under this exact name/shape.

These are flagged, not silently assumed correct, per the proposal's own
phase-2 sanity-check note. `loop_state: landed` reflects that this issue's
own batch is complete; it does not assert these upstream contracts are
confirmed.
