# Proposal — issue-16: A+ certification closeout (blocking reason: stale README preamble)

Phase 1 (design only). Findings this proposal responds to are recorded in
`docs/issue-16/reports/security-threat-model/survey.md`; the scouting skip
record is in the same directory's `scout-brief.md`.

## 0. Approach

The blocking reason is a single stale sentence, not a code or gate defect
(survey s1-s3): all six gate scripts already carry issue-13's guarded
source line and the full test suite is green on a clean checkout. The fix
is a documentation-only edit to `README.md`'s three-line preamble
(lines 3-5) — no `hooks/`, `agents/`, or `tests/` file changes, and no new
canon dependency.

**canon-references**: none introduced. The replacement wording draws only
on facts already recorded in this repo — `README.md`'s own
Plugins/Layout/Core-dependency sections (lines 27-73) and the git history
(issue-7 commits `28b157a`/`40b2e4c`, issue-10 commits
`c984afa`/`b7e1bbe`, issue-13 commits `5667b87`/`108c963`) — so there is no
external script or canon content to cite or copy.

## 1. Fix — `README.md` lines 3-5

**Current:**

```
Rulebook for the `security-threat-model` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.
```

**Proposed:**

```
Rulebook for the `security-threat-model` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion. Seeded
as skeleton scaffolding by issue-170 and since implemented as a six-plugin
methodology enforcement set (issue-7), migrated onto core's generalized
gate-lib (issue-10), and brought to gate-house-standard A+ compliance
(issue-13) — see "Plugins" and "Layout" below for the current shape.
```

Rationale: this keeps the historical fact (issue-170 seeded it as
scaffolding — that is true and worth keeping as provenance) while removing
the false present-tense implication that the repo is *still* scaffolding.
It points the reader at the sections of the same file (Plugins, Layout,
Core dependency) that already describe the real, implemented state,
rather than duplicating that description in the preamble.

## 2. Non-goals

- No change to any `hooks/*.sh`, `hooks.json`, `plugin.json`,
  `record-fields.env`, or `tests/*.sh` file — survey s2 found these already
  correct and green.
- No change to `docs/handbooks/security-threat-model.md` or
  `docs/specs/approvers.md` — out of scope for this issue's stated blocking
  reason.
- Requirement 2 of the issue (core #78 landing gate) does not apply to this
  role (survey s4) — `sales`-only precondition.

## 3. Acceptance criteria (phase 2)

- `README.md:3-5` no longer states or implies the repo is presently
  skeleton scaffolding.
- `bash tests/run-gate-tests.sh` still reports `ALL SUITES GREEN` on a
  clean clone after the edit (documentation-only change, but re-run kept
  as the issue's stated bar: "코드 변경 시 관련 테스트 green 유지").
- Phase-2 record cites the exact diff and the re-run test log, per contract
  v3 s19.
