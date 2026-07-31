# Issue #7 — Phase 1 Current-State Survey

Role: `security-threat-model`. Scope: what mechanical enforcement exists
today for the methodology adopted in issue #1
(`docs/issue-1/proposals/security-threat-model.md`), vs. what issue #7 asks
for — a hook-machine-level enforcement comparable to implementation-rulebook's
`coding-progress-gate.sh` / pricing-rulebook's `methodology-gate.sh`.

## 1. What exists now in this repo

| Path | Relevant content |
|---|---|
| `security-threat-model/hooks/directive.sh` | Stub calling `core_role_directive`. `PRODUCES` already lists all six adopted elements in order (asset inventory, trust boundary map, STRIDE table with CVSS-style rating, mitigation list, residual risk note with approver reference, canon references) — but as one flat string, no per-phase breakdown of steps/judgment-criteria/prohibitions. |
| `security-threat-model/hooks/record-fields.env` | `RECORD_FIELDS_REQUIRED="asset-inventory,trust-boundary-map,stride-table,mitigation-list,residual-risk-note,canon-references"` — consumed by **core's** generalized record-fields gate. This enforces *field presence* only (core issue #66's generic mechanism); it cannot know that a "stride-table" section actually contains STRIDE-tagged rows, that a "residual-risk-note" actually names an approver, or that `asset-inventory`/`trust-boundary-map` physically precede `stride-table` in the document. |
| `security-threat-model/hooks/hooks.json` | Only a `SessionStart` → `directive.sh` entry. **No `PreToolUse` entry exists** — there is currently zero role-specific mechanical check on this role's own write surfaces (`docs/issue-<n>/proposals/*security-threat-model*.md`, `docs/issue-<n>/reports/security-threat-model.md`). |
| `docs/handbooks/security-threat-model.md` | States the ordering constraint in prose ("Every phase-2 record must include an `asset-inventory` and a `trust-boundary-map` before its `stride-table`") and the CVSS-default/DREAD-override-must-be-marked rule — but **prose is not enforcement**; nothing checks either claim mechanically today. |
| `docs/issue-1/proposals/security-threat-model.md` part (d) | Explicitly left open: "confirm whether [core's] gate does simple substring/field-presence checking only, or can be extended to check internal cross-references... if the latter isn't supported, that remains a manual-review item... not a blocking gap for phase-2 to first land the field-presence version." Issue #7 is the mechanism that closes this. |
| `docs/issue-1/reports/security-threat-model.md` Open Findings | Repeats the same gap and additionally flags: "the DREAD-override marker convention has no enforced syntax" — i.e. even the one deliberate manual-override path in the methodology has no machine-checkable shape yet. |
| Repo root | **No `tests/` directory exists anywhere in this repo.** No hook-gate test harness of any kind exists for this rulebook. |
| `security-threat-model/agents/warrant-hunter.md` | Core-canon stub (issue #2); role-unique mandate/hand-off text only, no repeated-procedure content that issue #7's "agents/체크리스트" item would need to touch beyond what's already there. |

## 2. What core canon does vs. does not cover (per `canon-scripts.md`)

Per the canon-scripts.md convention this repo already follows (issue #2):
`trailer-gate.sh`, `record-fields-gate.sh` (mechanics), and
`handbook-trigger-gate.sh` are role-agnostic and live in core — this repo
must not vendor copies of them. `parse-check.sh` and `deny-only-check.sh` are
the **named exception**: they parse/scan *this repo's own* hook scripts, so
canon-scripts.md expects every rulebook to carry its own copy under a local
`tests/` directory.

A `methodology-gate.sh` that checks **STRIDE-specific ordering and
content** (not generic field presence) has no core equivalent and no
generic-role home — it is this role's own payload, exactly parallel to how
`pricing-rulebook/pricing/hooks/methodology-gate.sh` is pricing's own payload
on top of (never instead of) core's generic gate. This is the gap issue #7
asks this rulebook to fill for itself.

## 3. Established conventions from prior issues (issue #1, #2)

- `docs/issue-<n>/reports/<topic>/survey.md` + `scout-brief.md` (issue #1) —
  this survey and its accompanying scout brief follow that shape.
- `docs/issue-<n>/proposals/<slug>.md` opening with a "proposal only — phase
  1" banner, itemized work items with rationale and explicit "TBD in phase
  2" callouts where core's exact contract (e.g. `core_role_directive`'s CLI
  signature, whether it accepts more than the six fixed arguments already
  used) is unconfirmed from this repo alone (issue #2's own precedent).
- Repo-root `tests/run-gate-tests.sh` + per-plugin `hooks/tests/parse-check.sh`
  + `hooks/tests/deny-only-check.sh`, established as the sibling-rulebook
  convention (`implementation-rulebook/tests/`, mirrored across
  `pricing-rulebook`, `technical-feasibility-rulebook`, etc.) — this repo has
  none of these yet; issue #7 phase 2 is where they'd first land.

## 4. Gaps a scout pass should target

1. **Concrete gate-script shape**: what does a working, fail-closed,
   role-specific methodology gate actually look like line-by-line (kill
   switch, payload parsing, path targeting, resulting-content
   reconstruction, keyword/positional checks, fail-closed wrapper) —
   examine the closest real sibling (`pricing-rulebook`'s
   `methodology-gate.sh`) rather than inventing a shape from scratch.
2. **Ordering/state-tracking mechanism**: how do sibling rulebooks enforce
   a *sequence* constraint (research → evidence → adoption, or section A
   before section B within one file) — examine
   `implementation-rulebook/coding/hooks/coding-progress-gate.sh` (a
   cross-file precondition: a commit is denied unless a referenced
   verification record exists in a required state) as the closest analog
   to issue #7's "조사→근거→채택" state-tracking ask.
3. **Test-harness shape**: how do sibling rulebooks structure
   `run-gate-tests.sh` (temp-repo-per-case, JSON-stdin payload, exit-code
   assertion) so this repo's new tests match the ecosystem convention
   rather than inventing a bespoke format.
4. **What issue #7 must NOT do**: re-implement anything core's generic
   record-fields-gate already covers (field presence), or vendor
   copies of core's role-agnostic gates — the new gate's job is strictly
   the STRIDE-domain-specific layer core cannot know about.

These gaps are addressed in
`docs/issue-7/reports/security-threat-model/scout-brief.md` and the proposal
at `docs/issue-7/proposals/security-threat-model.md`.
