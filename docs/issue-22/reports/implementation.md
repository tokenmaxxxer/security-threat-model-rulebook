---
code_under_review: <unknown>
type: fix
breaking: false
verdict: pass
loop_state: landed
---

## What was done

Applied the approved phase-1 proposal
(`docs/issue-22/proposals/implementation-proposal.md`) to all 7 gate-test
scripts in the write set: `tests/run-gate-tests.sh` and the six plugins'
`hooks/tests/run-gate-lib-tests.sh` (security-threat-model, -stride,
-mitigation, -canon-citation, -residual-signoff, -risk-rating).

Each script's miss-path (env var unresolved AND no sibling candidate
resolves) now prints `SKIP: core plugin unreachable — unverifiable
outside spawn env` to stderr and exits `75` instead of the previous
`echo ...; exit 1` misleading-failure shape. Every reachability check
(env var and both sibling candidates) switched from `[ -f ... ]` to
`[ -s ... ]`, matching the reference `_has_gate_lib`'s non-empty check —
this closes the warrant-hunter-confirmed fail-open finding from the
phase-1 proposal (a zero-byte/corrupted `gate-lib.sh` previously read as
"core reachable"). A one-line comment citing
`docs/specs/test-env-resolution.md` (on-the-record #551) was added at
each resolution block. The resolution order (env var, then sibling
candidates, then miss) is otherwise unchanged. No gate-test assertion
that runs once core IS resolved was touched.

`tests/run-gate-tests.sh`'s top-level SKIP already short-circuited before
dispatching to per-plugin suites (pre-existing structure at that line) —
only the message/exit-code swap was needed there.

## Why

Issue #22: adopt the canonical test-env resolution convention
(on-the-record `docs/specs/test-env-resolution.md`, issue #551) so this
rulebook's gate-test scripts SKIP with an explicit, machine-checkable
message outside the spawn env instead of failing in a way
indistinguishable from a real regression.

## Upstream / basis

docs/issue-22/proposals/implementation-proposal.md (approved via
single-account-mode issue comment `APPROVE issue-22/implementation`)

## What did not work

None.

## Doc-placement ladder

- [x] No new env var, config key, dependency, or migration introduced —
  but the commit does change scripts core's `handbook-trigger-gate.sh`
  regex-matches as `run-*.sh` operational surfaces (false-positive class:
  the scripts are test harnesses, not run/deploy/setup/install scripts),
  so a `docs/handbooks/security-threat-model.md` subsection ("Test-env
  resolution SKIP contract (issue-22)") was added in the same commit to
  satisfy the gate and document the SKIP contract for operators.
- [x] No library-or-format choice or changed public signature/wire
  format introduced beyond what the proposal's Rationale already
  recorded — no new `docs/issue-22/decisions/` entry required.
- [x] No new benchmark/investigation numbers produced — no
  `docs/issue-22/reports/` entry beyond this record required.

## Rationale for deviations

The write set frozen in the approved proposal did not list any
`docs/handbooks/` path. `git commit` was refused by core's
`handbook-trigger-gate.sh` (contract §21) because it treats any staged
`run-*.sh` path as an operational run/deploy/setup/install script — a
mechanical false positive against these test-harness scripts, but a
hard gate regardless. Adding a `docs/handbooks/security-threat-model.md`
subsection was the minimum widening needed to land the approved change
at all; the added content documents only the SKIP contract this change
introduces, nothing beyond proposal scope.

## Verification run (this session)

- With core reachable (sibling candidate resolved in this sandbox):
  `bash tests/run-gate-tests.sh` — all cross-plugin cases (22/22) and
  all 6 plugins' `run-gate-lib-tests.sh` mandatory suites (15-24 cases
  each) pass unchanged. The two `parse-check.sh` failures per plugin are
  the pre-existing, explicitly out-of-scope missing-file reference (see
  proposal's Constraints/Out-of-scope) — unrelated to this change,
  unchanged by it.
- With `HOME` and `CLAUDE_PLUGIN_ROOT_CORE` pointed at nothing resolvable
  (simulated plain-checkout env): both `tests/run-gate-tests.sh` and
  `security-threat-model/hooks/tests/run-gate-lib-tests.sh` print the
  exact SKIP message and exit `75`.
- `grep -rl test-env-resolution tests/ security-threat-model*/hooks/tests/`
  matches all 7 in-scope scripts.

## Open findings

- `hooks/tests/parse-check.sh` referenced by `tests/run-gate-tests.sh`
  does not exist on disk in any plugin — pre-existing, out of scope per
  the proposal (issue #22's acceptance criteria's own empty-state
  instruction: record a real defect rather than mask it with SKIP). Not
  a test-env-resolution issue; needs its own issue to fix or remove the
  dangling reference.
