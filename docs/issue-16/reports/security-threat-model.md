# Issue #16 — Phase-2 Record: A+ certification closeout (stale README preamble)

loop_state: landed

Executes `docs/issue-16/proposals/security-threat-model.md` (approved)
against the single blocking reason confirmed in
`docs/issue-16/reports/security-threat-model/survey.md`. Documentation-only
infrastructure fix to this role's own README — like issue-10/issue-13, not
a fresh threat-modelling exercise — so this record follows
`docs/issue-13/reports/security-threat-model.md`'s shape rather than
carrying a threat table of its own.

## What was done

**Blocking reason resolved — `README.md:3-5`.** The stale present-tense
implication that the repo is still "skeleton scaffolding" is removed. The
issue-170 provenance fact is kept (it is true and worth keeping), and the
sentence is extended to name the three implementation milestones since
(issue-7 six-plugin methodology set, issue-10 gate-lib migration, issue-13
A+ compliance), pointing the reader at the file's own "Plugins"/"Layout"
sections for the current shape rather than duplicating that description in
the preamble.

```diff
 Rulebook for the `security-threat-model` role (contract v3 role-handoff protocol), split off
-per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
-generated as skeleton scaffolding by issue-170.
+per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion. Seeded
+as skeleton scaffolding by issue-170 and since implemented as a six-plugin
+methodology enforcement set (issue-7), migrated onto core's generalized
+gate-lib (issue-10), and brought to gate-house-standard A+ compliance
+(issue-13) — see "Plugins" and "Layout" below for the current shape.
```

Matches the proposal's Section 1 fix verbatim.

**Requirement 2 (core #78, sales-only precondition) — does not apply.**
Confirmed in survey s4 and proposal Section 2: this role is not `sales`, so
no landing-gate precondition blocks this issue. No action taken, none
required.

No `hooks/*.sh`, `hooks.json`, `plugin.json`, `record-fields.env`, or
`tests/*.sh` file was touched — survey s1-s3 found these already correct
and green, and the proposal's Non-goals (Section 2) excluded them from
scope.

## Why

The 2026-08-01 certification audit's only cited defect was the README
preamble's false present-tense "skeleton scaffolding" claim; survey s1-s3
confirmed every gate script already carries issue-13's guarded source line
and the full suite was already green before this edit. Re-deriving or
touching gate code here would be scope creep against a documentation-only
finding — the fix is exactly the sentence the audit named, nothing more.

## Evidence

`bash tests/run-gate-tests.sh`, run after the `README.md` edit (working
tree, post-edit):

```
GNU bash, 버전 5.1.16(1)-release (x86_64-pc-linux-gnu)
ok    directive.sh
ok    methodology-gate.sh
ok    tests/deny-only-check.sh
ok    tests/parse-check.sh
ok    tests/run-gate-lib-tests.sh

parse-check: 5 file(s) under /bin/bash

== security-threat-model-canon-citation: parse-check.sh ==
[... same ok block ...]

== security-threat-model-residual-signoff: parse-check.sh ==
[... same ok block ...]

== security-threat-model-risk-rating: parse-check.sh ==
[... same ok block ...]

== ALL SUITES GREEN ==
```

`git diff -- README.md` confirms the applied change is exactly the
proposal's Section 1 diff, lines 3-5 only, no other file touched.

## What did not work

Nothing required iteration — the README edit is exactly the proposal's
Section 1 text, applied on the first attempt, and the suite was green
before and after (documentation-only change, no code-path affected).

## Open findings

None new. Carried forward for completeness, unchanged from issue-13's
Open findings (not this issue's scope, not re-derived here): the
`deny-only-check.sh` substance-probe boundary and the
`Write|Edit|MultiEdit`-only matcher's Bash-tool-write blind spot — both
documented, asserted-not-silent boundaries.

## Residual risk (residual-risk-note)

Pre-mitigation: the stale "skeleton scaffolding" sentence was a
documentation-accuracy defect, not a security-control defect — no gate,
hook, or test path was affected by the wording being wrong. Pre-mitigation
rating: **Low** (misleading provenance text, no enforcement-path exposure).

Post-mitigation rating: **Low residual, unchanged.** The edit corrects the
false present-tense claim (confirmed by the diff above); no residual
exposure exists because the defect never touched an enforcement path.
Disposition: mitigate (the stale sentence itself, since the audit named it
directly and the fix is complete) / accept (the underlying risk level,
which was Low before and after — no control was ever weakened by the
wording).

Approver reference: `docs/specs/approvers.md` (contract v3 §19 Approve
gate) — this record's phase 2 opened via the single-account `APPROVE
issue-16/security-threat-model` path, posted by `JiwonJung94` (listed in
`docs/specs/approvers.md`), 2026-08-01.

## Canon references

Referenced by path and description only; no canon script content is
reproduced in this repo or in this record.

- `docs/issue-16/proposals/security-threat-model.md` — the approved plan
  this record executes, Section 1 diff applied verbatim.
- `docs/issue-16/reports/security-threat-model/survey.md` — the current-state
  survey confirming the blocking reason is documentation-only (s1-s3) and
  that requirement 2 does not apply to this role (s4).
- `docs/issue-13/reports/security-threat-model.md` — the prior record's
  shape and evidence-citation convention, followed here.
