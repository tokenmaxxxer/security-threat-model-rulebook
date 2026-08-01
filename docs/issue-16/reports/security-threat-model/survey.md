# Issue #16 — Phase-1 Survey: A+ Certification Closeout (Blocking Reason)

subject: issue-16
role: security-threat-model
phase: 1 (survey)

Scope: the 2026-08-01 certification audit (issue #16 body) names exactly one
blocking reason: `README.md` line 5 still reads "generated as skeleton
scaffolding by issue-170," a leftover from the initial seed commit
(`0b94a16`, "Seed rulebook skeleton for role security-threat-model
(on-the-record issue-170)"). The issue asks that this wording be removed and
replaced with an accurate description of the role's actual, shipped
implementation. Requirement 2 (core #78 stub-check landing gate) is scoped
to the `sales` role only and does not apply here.

## 1. The literal defect — `README.md:3-5`

Current text:

```
Rulebook for the `security-threat-model` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.
```

This is stale. Since the issue-170 seed commit, three implementation rounds
have landed in this repo:

- issue-7 (`28b157a`, `40b2e4c`): the six-plugin methodology enforcement set
  itself — `security-threat-model` (base, `hooks/sequence-gate.sh`) plus
  `security-threat-model-stride`, `-risk-rating`, `-mitigation`,
  `-residual-signoff`, `-canon-citation` (each with `hooks/methodology-gate.sh`).
- issue-10 (`c984afa`, `b7e1bbe`): gate-lib migration to core's generalized
  `gate-lib.sh`/`gate-lib.py`, semantic upgrade of the gates, and mandatory
  gate-house-standard test suites.
- issue-13 (`5667b87`, `108c963`): gate A+ final closeout — guarded
  `gate-lib.sh` source line (`|| { echo ...; exit 2; }`) in all six gate
  scripts, missing-core test group, record entry.

None of this is "skeleton scaffolding" — it is a fully implemented,
tested rulebook. `README.md` lines 27-73 (the "Plugins," "Layout," and
"Core dependency" sections) already correctly describe the real, current
shape (six plugins, kill switches, gate-lib dependency, test entrypoint).
Only the three-line preamble (lines 3-5) still carries the seed-era
"skeleton scaffolding" self-description, which is the one line the audit
flags.

## 2. Verification that the underlying implementation is genuinely non-skeleton

Checked directly, not assumed:

- `grep -n "gate-lib.sh" security-threat-model*/hooks/*.sh` — all six gate
  scripts (`security-threat-model/hooks/sequence-gate.sh` and the five
  `security-threat-model-*/hooks/methodology-gate.sh`) already source
  `gate-lib.sh` with the issue-13 guarded form
  (`. "..." || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`).
  No regression from issue-13's closeout.
- `bash tests/run-gate-tests.sh` — ran clean: `ALL SUITES GREEN` across all
  six plugins' `directive.sh`, `methodology-gate.sh`,
  `tests/deny-only-check.sh`, `tests/parse-check.sh`,
  `tests/run-gate-lib-tests.sh`, on a clean checkout of the current branch
  tip. This is the "배송 상태·clean clone 기준" test-green bar the issue
  requires be kept.
- `grep -rn "issue-170\|skeleton"` across `*.md`/`*.sh`/`*.json` in the repo
  finds exactly two hits: `README.md:5` (the defect) and
  `docs/issue-2/reports/implementation/survey.md:7`, which is a historical
  citation of the seed commit inside an already-closed issue's report, not
  live stale wording — no other file needs a change.

## 3. Gap between claim and reality

The gap is narrow and purely descriptive: `README.md`'s opening
self-description undersells the plugin set's actual, audited, tested
state as one-time generated scaffolding, when every other section of the
same file (Plugins/Layout/Core-dependency tables) and the git history
(issue-7/10/13) show a maintained, gate-house-standard-compliant
implementation. No hook, gate, or test file requires a code change; only
the README's descriptive preamble does.

## 4. Requirement 2 (core #78) applicability

Issue #16 requirement 2 ("sales만 해당: core #78 랜딩 후 착수") scopes a
precondition-landing check to the `sales` role only. This repo's role is
`security-threat-model`, so requirement 2 does not gate this work.
