# security-threat-model — operational handbook

## Methodology

STRIDE is the enumeration framework for this role's threat tables — it is
DFD/trust-boundary native and matches the role's mandate ("신뢰 경계의 위협
표면"). Every phase-2 record must include an `asset-inventory` and a
`trust-boundary-map` before its `stride-table`, since a threat row has no
well-defined subject without them. Risk is rated on a CVSS-style qualitative
severity scale (Critical/High/Medium/Low) by default; a DREAD-style
qualitative override is permitted only for architectural/trust-boundary
findings with no CVE-like vector, and must be marked inline in the row when
used, never silently mixed with CVSS-style rows. `residual-risk-note`
records the post-mitigation rating plus which `docs/specs/approvers.md`
approver Approved and when — this repo's contract v3 s19 Approve gate is the
sign-off, not a separate mechanism. `canon-references` cites any external
canon relied on (e.g. core's `warrant/` plugin) by path/description only,
per this issue's no-copy constraint.

See `docs/issue-1/proposals/security-threat-model.md` for the full
rationale trail and `docs/issue-1/reports/security-threat-model/
scout-brief.md` for the field-norm sources it's grounded in.

## Hooks

- `hooks/directive.sh` (SessionStart) — stub form. Sources
  `core/hooks/lib/role-directive.sh` and calls `core_role_directive` with
  this role's unique fields. The kill-switch, `CLAUDE_ROLE` guard, and
  record-fields/trailer/handbook-trigger gates that used to be vendored
  copies in this rulebook are now core canon (core issues #63/#66):
  core's own hook registration fires them, not this rulebook's
  `hooks.json`.
- `hooks/record-fields.env` — this role's required record fields
  (`RECORD_FIELDS_REQUIRED`) for core's generalized record-fields gate to
  consume. No terminal `loop_state` divergence exists for this role today
  (`RECORD_FIELDS_TERMINAL_STATES` unset).
- `agents/warrant-hunter.md` — no longer a standalone hunt implementation;
  this role now relies on core's `warrant/` plugin (core issue #63) and
  this file supplies only the role-unique mandate/hand-off text it needs.

## Operator notes

If core's shared libs (`core/hooks/lib/role-directive.sh`, the
`warrant/` plugin, core's generalized record-fields gate) are not
reachable at hook-execution time, this role's directive/gate/hunt
behavior will fail closed rather than silently no-op — see
`docs/issue-2/reports/implementation.md` for the open items on how this
repo is meant to obtain a `core` checkout.
