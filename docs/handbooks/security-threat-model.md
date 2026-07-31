# security-threat-model — operational handbook

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
