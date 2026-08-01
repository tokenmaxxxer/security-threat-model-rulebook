# security-threat-model — operational handbook

## Methodology

Phase 2 (`docs/issue-7/proposals/security-threat-model.md`) splits this
role's methodology across six sibling plugins — one base (role-identity)
plugin and five methodology plugins, each owning exactly one judgment that
only it can make. Each subsection below covers one plugin. Per
`docs/issue-7/proposals/security-threat-model.md` section 3, a phase-1
proposal is compliant only once all six plugins' framing guidance has been
followed, and a phase-2 record passes only once every plugin in the set
allows — any single plugin's deny blocks the write regardless of what the
other plugins found.

See `docs/issue-1/proposals/security-threat-model.md` for the full
rationale trail, `docs/issue-1/reports/security-threat-model/
scout-brief.md` for the field-norm sources it's grounded in, and
`docs/issue-7/proposals/security-threat-model.md` for the plugin-split
rationale and the exact machinery each plugin below implements.

### `security-threat-model` (base plugin)

Role-identity/hand-off plugin — owns no methodology itself and stays the
anchor the five methodology plugins compose against. Its `SessionStart`
`directive.sh` issues the core role directive and `record-fields.env`
supplies core's generic record-fields gate with this role's six required
fields (unchanged mechanism). It also owns the one role-level phase
**sequence** rule that is not specific to any single methodology:
`hooks/sequence-gate.sh` is a `PreToolUse` gate on
`docs/issue-<n>/proposals/*security-threat-model*.md` writes that denies
unless `docs/issue-<n>/reports/security-threat-model/survey.md` already
exists for the same issue number — a phase-1 proposal must not be written
before its phase-1 survey. Kill switch:
`SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF`.

### `security-threat-model-stride` (STRIDE threat enumeration)

Owns whether `asset-inventory` and `trust-boundary-map` precede
`stride-table`, and whether `stride-table` rows carry a STRIDE category
tag. STRIDE is the enumeration framework for this role's threat tables — it
is DFD/trust-boundary native and matches the role's mandate ("신뢰 경계의
위협 표면"). Every phase-2 record must include an `asset-inventory` and a
`trust-boundary-map` before its `stride-table`, since a threat row has no
well-defined subject without them, and the `stride-table` section must name
at least one of the six STRIDE categories. Kill switch:
`SECURITY_THREAT_MODEL_STRIDE_GATE_OFF`.

### `security-threat-model-risk-rating` (CVSS-default / DREAD-marked-override)

Owns whether DREAD-shaped language carries the `[dread-override]` marker.
Risk is rated on a CVSS-style qualitative severity scale
(Critical/High/Medium/Low) by default; a DREAD-style qualitative override is
permitted only for architectural/trust-boundary findings with no CVE-like
vector, and must be marked inline in the row when used (immediately
following the rating), never silently mixed with CVSS-style rows. Kill
switch: `SECURITY_THREAT_MODEL_RISK_RATING_GATE_OFF`.

### `security-threat-model-mitigation` (risk-disposition vocabulary)

Owns whether every `mitigation-list` entry states a disposition from
accept/mitigate/transfer/avoid (or a stated Korean equivalent, since this
role's directive text is bilingual). Kill switch:
`SECURITY_THREAT_MODEL_MITIGATION_GATE_OFF`.

### `security-threat-model-residual-signoff` (residual-risk sign-off)

Owns whether `residual-risk-note` names an approver reference.
`residual-risk-note` records the post-mitigation rating plus which
`docs/specs/approvers.md` approver Approved and when — this repo's
contract v3 s19 Approve gate is the sign-off, not a separate mechanism; this
plugin makes that existing mechanism mechanically checkable inside the
record rather than inventing a second one. Kill switch:
`SECURITY_THREAT_MODEL_RESIDUAL_SIGNOFF_GATE_OFF`.

### `security-threat-model-canon-citation` (no-copy canon citation)

Owns whether `canon-references` cites by path/description rather than
pasting script content. `canon-references` cites any external canon relied
on (e.g. core's `warrant/` plugin or sibling `methodology-gate.sh` scripts)
by path/description only, per this issue's no-copy constraint; the gate is
a best-effort mechanical backstop (denies on a shebang line or
core-canon-shaped fenced code), not a substitute for review. Kill switch:
`SECURITY_THREAT_MODEL_CANON_CITATION_GATE_OFF`.

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
- `hooks/sequence-gate.sh` (PreToolUse, `Write|Edit|MultiEdit`) — the base
  plugin's own sequence-precondition gate; see the base-plugin subsection
  under Methodology above.
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

## Gate-house standard migration (issue-10)

`hooks/sequence-gate.sh` and every methodology plugin's
`hooks/methodology-gate.sh` now source `core/hooks/lib/gate-lib.sh` (bash)
and load `core/hooks/lib/gate-lib.py` (Python, via `importlib` off the
`GATE_LIB_PY` env var `gate-lib.sh` exports) instead of hand-rolling the
fail-closed trap, kill-switch case statement, path normalization, and
Edit/MultiEdit/NotebookEdit reconstruction — see
`docs/handbooks/gate-house-standard.md` (core canon) for what the library
provides and `docs/issue-10/proposals/security-threat-model.md` /
`docs/issue-10/reports/security-threat-model.md` for this migration's
scope and evidence. Every plugin's kill-switch env var now uses the fixed
`gate_kill_switch_active` semantics: only a recognized on-spelling
(`1`/`true`/`yes`/`on`) disables the gate — empty, a recognized
off-spelling, or any unrecognized value all leave it active.

Each plugin's `hooks/tests/run-gate-lib-tests.sh` is the mandatory
seven-case suite (replace_all-honoring Edit/MultiEdit, malformed JSON,
unrecognized kill-switch value, absolute/`./`-prefixed paths, a
Bash-tool write target, and — issue-13, core #75's shape — a
`missing-core` case asserting the gate denies when
`CLAUDE_PLUGIN_ROOT_CORE` points at a nonexistent path) that
`tests/run-gate-tests.sh` (repo root) now chains alongside each plugin's
existing `directive.sh`/`methodology-gate.sh`/`deny-only-check.sh`/
`parse-check.sh` checks. `core/hooks/tests/compliance-check.sh
<plugin>/hooks` is the mechanical detector for a gate that has drifted
back to hand-rolled kill-switch/reconstruction logic, or back to an
unguarded `gate-lib.sh` source line; run it against a plugin's `hooks/`
directory to verify compliance. Every gate's source line (`sequence-gate.sh:2`,
`methodology-gate.sh:2`) carries a `||` fallback that denies (exit 2)
before `gate_trap_fail_closed` is reached, so a failed source itself
denies rather than silently falling through — see
`docs/issue-13/proposals/security-threat-model.md` s1 and
`docs/issue-13/reports/security-threat-model.md`.
