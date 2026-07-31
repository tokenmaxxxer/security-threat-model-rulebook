# Issue #7 — Phase-2 Record: Methodology Enforcement Machinery (Plugin Set)

loop_state: landed

## What was done

Implemented `docs/issue-7/proposals/security-threat-model.md` (approved via
`APPROVE issue-7/security-threat-model`) as a six-plugin set at repo root,
each with `.claude-plugin/plugin.json`, `hooks/hooks.json`,
`hooks/directive.sh`, its own `hooks/tests/parse-check.sh` +
`hooks/tests/deny-only-check.sh` (canon-scripts.md named-exception verbatim
copies):

- `security-threat-model` (base, narrowed): added `hooks/sequence-gate.sh`
  (`PreToolUse`, kill switch `SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF`) —
  denies a `docs/issue-<n>/proposals/*security-threat-model*.md` write
  unless `docs/issue-<n>/reports/security-threat-model/survey.md` already
  exists. Restructured `docs/handbooks/security-threat-model.md`'s
  Methodology section into one subsection per plugin below.
- `security-threat-model-stride`: `hooks/methodology-gate.sh`
  (`SECURITY_THREAT_MODEL_STRIDE_GATE_OFF`) — when a `stride-table` marker
  is present, denies unless `asset-inventory` and `trust-boundary-map`
  precede it, and denies unless the `stride-table` section carries a STRIDE
  category name/initial.
- `security-threat-model-risk-rating`
  (`SECURITY_THREAT_MODEL_RISK_RATING_GATE_OFF`) — denies DREAD-shaped
  language with no `[dread-override]` marker.
- `security-threat-model-mitigation`
  (`SECURITY_THREAT_MODEL_MITIGATION_GATE_OFF`) — denies a
  `mitigation-list` section carrying none of
  accept/mitigate/transfer/avoid (또는 수용/완화/전가/회피).
- `security-threat-model-residual-signoff`
  (`SECURITY_THREAT_MODEL_RESIDUAL_SIGNOFF_GATE_OFF`) — denies a
  `residual-risk-note` with no `approvers.md`/approver reference.
- `security-threat-model-canon-citation`
  (`SECURITY_THREAT_MODEL_CANON_CITATION_GATE_OFF`) — denies a
  `canon-references` section containing a shebang or hook-script-shaped
  fragment (best-effort mechanical backstop, stated as such in the deny
  message).

`.claude-plugin/marketplace.json` now registers all six plugins (mirrors
`tokenmaxxxer-core`'s five-plugin shape). `tests/run-gate-tests.sh` (new,
repo root) exercises all six gates plus a cross-plugin case (21 cases, all
passing): fail-closed skeleton is `pricing-rulebook/pricing/hooks/methodology-gate.sh`'s,
referenced by path/description only — no content copied except the two
named `canon-scripts.md` exceptions.

## Why

Per the approver's correction on PR #8: enforcement machinery must be a
set of independent, self-completed plugins (one per methodology), not one
deepened gate — mirroring `tokenmaxxxer-core`'s `freelunch`-level
completeness bar per plugin. Each of the five methodology plugins owns
exactly the judgment only it can make (STRIDE ordering/tagging, rating
marker, disposition vocabulary, sign-off reference, no-copy citation);
none re-implements the base plugin's generic field-presence gate or the
sequence precondition.

## What did not work

The STRIDE plugin's worker-built section-extraction regex had an off-by-one
bug: it searched for the next markdown heading starting at `stride_pos + 1`,
which — for a `##`-level heading — lands on the second `#` of the current
heading itself and misreads it as the next heading, truncating the section
to a single `#` character and always failing the category-tag check. Fixed
by scanning from the end of the heading's own line
(`security-threat-model-stride/hooks/methodology-gate.sh`) instead of one
character past its start. Caught by `tests/run-gate-tests.sh`'s
`stride-ordered-tagged` and `cross-plugin:security-threat-model-stride`
cases before landing.

## Open findings

None outstanding. `deny-only-check.sh`'s copied `substance_probe` (hardcoded
to a `coding.md`/`*-gate.sh` shape from the rulebook it originated in) FAILs
on every one of this role's plugins by construction — the probe targets a
path/tool shape this role's gates correctly ignore — expected under the
canon-scripts.md verbatim-copy convention, not a defect; its "no
`permissionDecision: allow`" check (the substantive part of the copy) passes
on every plugin. `tests/run-gate-tests.sh` is this role's own substance
proof and passes 21/21.

## Canon references

- `pricing-rulebook/pricing/hooks/methodology-gate.sh` — gate skeleton
  (fail-closed trap, kill switch, JSON stdin, content reconstruction),
  referenced by path, not copied.
- `implementation-rulebook/coding/hooks/coding-progress-gate.sh` — sequence
  precondition pattern, referenced by path, not copied.
- `implementation-rulebook/tests/run-gate-tests.sh` — harness shape
  (temp-repo, JSON-stdin, exit-code assertion), referenced by path, adapted
  independently for this role's six gates.
- `implementation-rulebook/tests/parse-check.sh`,
  `implementation-rulebook/tests/deny-only-check.sh` — copied verbatim per
  `docs/handbooks/canon-scripts.md`'s named exception, once per plugin.
