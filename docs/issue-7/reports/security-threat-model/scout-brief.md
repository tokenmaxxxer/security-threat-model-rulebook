# Issue #7 — Scout Brief: Hook-Machine Enforcement Patterns

Scope: issue #7 asks for enforcement machinery "at implementation-rulebook's
hook-machine level." The relevant field to scout is not external
threat-modeling literature (issue #1 already scouted that) but **how sibling
rulebooks in this same plugin ecosystem mechanically enforce their own
adopted methodologies** — the closest same-segment exemplars. Sources here
are local sibling-repo file paths (real, on-disk sibling rulebook
checkouts), not web search, since the object of study is this ecosystem's
own convention, not general industry practice.

## Exemplar 1 — `pricing-rulebook/pricing/hooks/methodology-gate.sh`

Closest direct analog: a role-specific `PreToolUse` gate layered **on top
of** (never instead of) core's generic record-fields gate.

Must-bes observed:
- Fail-closed trap (`__fc`) wrapping the whole script exit; any non-0/2 rc
  becomes exit 2.
- Named kill switch (`PRICING_METHODOLOGY_GATE_OFF`).
- Regex-targets only this role's own write surfaces
  (`docs/issue-<n>/proposals/*pricing*.md`,
  `docs/issue-<n>/reports/pricing.md`) — exits 0 immediately for anything
  else, so it never becomes a generic gate.
- Reconstructs the *resulting* file content for Write/Edit/MultiEdit
  (denies if it can't — e.g. a non-matching `old_string` — rather than
  guessing).
- All Python judgment logic wrapped in `try/except` → exit 2 on any
  internal exception, never a silent pass.
- Checks are **keyword/phrase presence against the reconstructed text**,
  each keyed to one required element from that role's own phase-1
  methodology-norms doc; deny message names exactly which element(s) are
  missing and cites that doc by path.

Adopt: this entire skeleton (fail-closed trap, kill switch, path targeting,
content reconstruction, `deny()` naming the source doc). Skip: pricing's
own keyword list (conjoint/PSM vocabulary) is domain-specific to pricing,
not reusable — security-threat-model needs its own STRIDE-shaped checks.

## Exemplar 2 — `implementation-rulebook/coding/hooks/coding-progress-gate.sh`

This is the closest analog to issue #7's second ask: "방법론상 순서 제약이
있으면(예: 조사→근거→채택) 상태 추적으로 강제." Its pattern (per
`implementation-rulebook/tests/run-gate-tests.sh`'s `progress()` test case):
a commit-time `Bash` gate reads a **cross-file precondition** — it denies a
commit if a referenced verification record
(`docs/issue-<n>/reports/verify.md`) exists but carries an unresolved
blocking finding, and allows it once that file's state clears. This is
sequence enforcement via **file-existence/content precondition**, not a
separate state-machine file — simpler than a dedicated `state.sh` for a
two-or-three-step sequence.

Adopt: the precondition-check pattern (gate on write X requires document Y
to already exist / be in an allowed state) applied to security-threat-model's
own sequence: (a) within one record, `asset-inventory` and
`trust-boundary-map` must appear before `stride-table` (positional check
inside one reconstructed text — no cross-file state needed for this leg);
(b) across phase-1 documents, a `docs/issue-<n>/proposals/*security-threat-model*.md`
write should require `docs/issue-<n>/reports/security-threat-model/survey.md`
to already exist in the tree (mirrors the scout-directive's own
survey-first-order rule, made mechanical instead of just a convention).
Skip: a dedicated `hunt-state.sh`/`state.sh` file — not needed at this
sequence's size (2-3 steps), and issue #7's own text treats state tracking
as conditional ("필요 시"), not mandatory machinery.

## Exemplar 3 — `implementation-rulebook/tests/run-gate-tests.sh`

Test-harness shape: one script, `report()` helper comparing want/got,
per-case `run()` helper that builds a fresh temp git repo, pipes a
constructed JSON `PreToolUse` payload to the gate script via stdin under
`env CLAUDE_PROJECT_DIR=...`, and asserts exit code (0=allow, 2=deny).
Repo-root `tests/` directory, with `parse-check.sh` (bash syntax-parses
every `*.sh`) and `deny-only-check.sh` (greps for any accidental
`"permissionDecision":"allow"` emission, plus an "empty content must be
refused by at least one gate" substance probe) as the two canon-scripts.md
named exceptions copied per-rulebook.

Adopt: this exact harness shape (temp-repo, JSON-stdin, exit-code
assertion) and the two copied test-helper scripts, so this repo's new tests
read as ecosystem-standard rather than bespoke.

## Gap line (repo state → ecosystem norm)

This repo has: a stub `directive.sh`, a `record-fields.env` config value
consumed by core's generic gate, and prose-only ordering/rating-discipline
rules in the handbook. **Missing** against the ecosystem norm demonstrated
by `pricing-rulebook` and `implementation-rulebook`: (1) any role-specific
`PreToolUse` gate at all, (2) any mechanical ordering/precondition check,
(3) any `tests/` directory, (4) any test case proving deny-on-violation
behavior.

## Stage count / mode

Single-pass, three targeted reads (one per exemplar file/directory already
located during phase-1 current-state survey) — no parallel fan-out was run
since all three candidate exemplars were already identified from the
current-state survey's own gap list and each was resolved by reading one
file; no further drill-down changed any build decision.

## Sources

- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/hooks.json`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/parse-check.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/deny-only-check.sh`
