# Issue #13 — Scout Brief

subject: issue-13
role: security-threat-model
phase: 1 (scout)

## Angle

This is a remediation of this role's own gate machinery against a shape
that core #75 already decided and landed (survey s0, s1, s4). The open
design questions this issue could plausibly raise — what should the guard
look like, what should the compliance detector check, what should the
mandatory missing-core test assert — are not open here: they were already
settled, built, and merged in the sibling core repo
(`tokenmaxxxer-core-issue-75-implementation`, commit `f61d52f`), and this
role's own prior migration (issue-10) already established the convention
of adopting core's gate-house-standard shape by reference rather than
re-deriving it (`docs/issue-10/reports/security-threat-model.md:112-127`).
Internal-canon scouting is therefore the right and sufficient angle:
confirm what core #75 actually built (not what the issue text speculates it
built), and apply the same shape here.

## What was checked

- `tokenmaxxxer-core-issue-75-implementation` (local sibling checkout,
  branch `issue-75/implementation`, 1 commit ahead of `origin/main`):
  read `docs/issue-75/reports/implementation.md` (the landed record) and
  `git show f61d52f` (the actual diff — inspected, not pasted into this
  repo) for `core/hooks/lib/gate-lib.sh`, `core/hooks/directive.sh`, and
  `core/hooks/tests/compliance-check.sh`. Confirmed the guard shape
  (`||`-fallback on the same source statement, gate-name-specific stderr
  message, exit 2), the compliance-check detection regex shape (source
  line ending in `gate-lib\.sh"$` with no `\|\|` on the same line), and the
  `docs/handbooks/gate-house-standard.md` "Transition note (issue-75...)"
  section that explicitly names this repo's situation (an
  already-migrated rulebook that needs to re-pull the guarded line).
- `on-the-record-issue-182-implementation` (local sibling checkout) +
  `gh issue view 182 --repo tokenmaxxxer/on-the-record --comments`:
  confirmed closed, approved, and landed at commit `e50fe08`. Read only the
  issue text and commit log — did not need to open `spawn.py` itself, since
  this repo has nothing to change for #182 (it is infrastructure the
  survey cites as background for why the guard fix is not merely
  defensive).
- This repo's own prior remediation issue, `docs/issue-10/reports/
  security-threat-model.md`, for the existing convention this proposal
  extends (adopt core's library by reference, `compliance-check.sh` as the
  acceptance criterion, six-group `run-gate-lib-tests.sh` shape) — the
  precedent for how a "core moved the standard forward, this rulebook
  re-pulls it" issue should be structured in this repo.
- This repo's own six gate scripts, six `hooks.json`, six
  `hooks/tests/run-gate-lib-tests.sh`, `README.md`, six `plugin.json`, and
  `docs/handbooks/security-threat-model.md` directly, to establish current
  state (recorded in the survey, not repeated here).

## Why no external sweep

Once core #75's actual landed shape was confirmed, every defect in this
issue collapses to "apply the already-decided upstream pattern, unchanged,
to six files" (s1's guard; s4's 7th test group) or "re-confirm an
already-clean state in the phase-2 record" (s2, s3, s5) — there is no
remaining question a web search or a different framework's convention could
usefully inform. The guard's fail-open mechanism (an unguarded `.` failure
leaving downstream `gate_*` calls undefined, misread as "kill switch off"
by a bare `||` fallback) is bash-semantics-specific and already diagnosed
correctly by core #75's own record; re-deriving or second-guessing that
diagnosis externally would only reproduce the divergence issue-72/issue-75
exist to end (the same rationale issue-10's record gives at
`docs/issue-10/reports/security-threat-model.md:124-127` for adopting the
library by reference in the first place). No genuinely novel design
question survives past "read what core #75 built."

## Skip record

Not applicable — this scout brief is written in full because the
internal-canon read was substantive (two sibling repos, a specific commit
inspected, a specific handbook section that names this repo's remediation
population), not because the scouting step itself was skippable. A
SKIP RECORD would misrepresent that work as absent.
