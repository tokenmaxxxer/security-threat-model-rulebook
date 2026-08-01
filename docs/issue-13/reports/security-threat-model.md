# Issue #13 — Phase-2 Record: Gate A+ final closeout (re-audit residual defects)

loop_state: landed

Executes `docs/issue-13/proposals/security-threat-model.md` (approved) against
the defect inventory in `docs/issue-13/reports/security-threat-model/survey.md`.
Infrastructure remediation of this role's own enforcement machinery — like
issue-10, not a fresh threat-modelling exercise — so this record follows
`docs/issue-10/reports/security-threat-model.md`'s shape rather than carrying
a threat table of its own.

## What was done

Mapped to survey.md's confirmed defect inventory (proposal s1–s6).

**s1. Guarded source line, all 6 gates — fixed.** The unguarded
`. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"` on line 2 of
`security-threat-model/hooks/sequence-gate.sh` and each of the five
`security-threat-model-{stride,risk-rating,mitigation,canon-citation,
residual-signoff}/hooks/methodology-gate.sh` now carries a `||` fallback on
the same statement: a gate-specific stderr message plus `exit 2` before
`gate_trap_fail_closed` is ever reached, matching core #75's guard shape.
The header comment immediately below was updated in all six files: it now
states that the `||` guard on the source line is what makes "a failed
source itself denies" true, rather than describing only the post-source
`gate_trap_fail_closed` trap. Closes the false claim the 2026-08-01
re-audit named directly (the header claimed fail-closed-on-failed-source
protection the code did not yet provide).

**s2. `deny-only-check.sh` default path — confirmed, no code change.**
Re-ran `deny-only-check.sh` for all six plugins. The `dir`/`rec_rel`
defaults still resolve to each plugin's own `hooks/` directory and
`docs/issue-999/reports/security-threat-model.md`, unchanged since
issue-10. The `permissionDecision`-grant half passes clean on all six. The
substance-probe's structural mismatch (every gate in this set is
conditional — fires only on its own section marker — so an unconditional
"is this record substantive at all" probe cannot pass against any of them)
is the same accepted, carried-forward boundary issue-10's Open findings
recorded; re-confirmed here, not re-derived, and not wired into
`tests/run-gate-tests.sh`'s green gate.

**s3. `hooks.json` matcher / code coverage parity — confirmed, no code
change.** All six `hooks.json` declare `PreToolUse` matcher
`"Write|Edit|MultiEdit"`; the Python judge in every gate dispatches on
exactly `Write`, `Edit`, `MultiEdit` (`gate_reconstruct_write`'s tool
argument), with `NotebookEdit` support present in the shared reconstruction
helper but not yet matched by any `hooks.json` — a documented, asserted
no-coverage boundary (mandatory case 6 in every plugin's
`run-gate-lib-tests.sh`), not a mismatch.

**s4. `missing-core` mandatory test, 6 plugins — fixed.** Added a 7th case
group to each plugin's `hooks/tests/run-gate-lib-tests.sh`, mirroring core
#75's own 7th group: invoke the plugin's gate with
`CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent `no-such-core` path
under a fresh `mktemp -d`, assert the gate denies (exit 2). This is s1's
regression test: before s1 landed it observed fail-open (allow); after, it
observes the guard's deny. Each file's "N mandatory" framing comment was
bumped from six to seven to match.

**s5. README / manifest ghost role names — confirmed, no code change.**
Re-grepped `README.md`, all six `hooks.json`/plugin manifests, and
`marketplace.json` for stale role names and ghost file references (the
three issue-10 already removed: `record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`). None found. The issue's "옛 이름은 하드 에러"
clause has no applicable target — there is no old name present in this
tree to make a hard error out of.

## Why

Same rationale issue-10 established: this plugin set adopts core's
already-decided canon by reference rather than re-deriving a guard or test
shape locally. Re-deriving would reproduce the exact fragmentation core
#75 exists to end. `compliance-check.sh` — core's own detector — is the
acceptance criterion for s1, not this role's self-assessment; the new
`missing-core` case group is the regression test that the guard is what
actually produces the deny, not incidental exit-code plumbing.

## Evidence

`compliance-check.sh` from core, run against each plugin's `hooks/`
directory, before the s1 fix — verbatim (abbreviated absolute path
prefix):

```
=== security-threat-model (pre-fix) ===
compliance-check: FAIL — .../security-threat-model/hooks/sequence-gate.sh:
  - sources gate-lib.sh with no || guard on the same line — fail-open when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)
rc=1
=== security-threat-model-stride (pre-fix) ===
compliance-check: FAIL — .../security-threat-model-stride/hooks/methodology-gate.sh: (same reason)
rc=1
=== security-threat-model-risk-rating (pre-fix) ===
compliance-check: FAIL — .../security-threat-model-risk-rating/hooks/methodology-gate.sh: (same reason)
rc=1
=== security-threat-model-mitigation (pre-fix) ===
compliance-check: FAIL — .../security-threat-model-mitigation/hooks/methodology-gate.sh: (same reason)
rc=1
=== security-threat-model-canon-citation (pre-fix) ===
compliance-check: FAIL — .../security-threat-model-canon-citation/hooks/methodology-gate.sh: (same reason)
rc=1
=== security-threat-model-residual-signoff (pre-fix) ===
compliance-check: FAIL — .../security-threat-model-residual-signoff/hooks/methodology-gate.sh: (same reason)
rc=1
PRE-FIX OVERALL rc=1 (6/6 FAIL on the unguarded-source rule, matching survey s1 and core #75's detection rule)
```

After the s1 guard fix landed, same command, all six clean:

```
=== security-threat-model ===
compliance-check: ok — security-threat-model/hooks/sequence-gate.sh
rc=0
=== security-threat-model-stride ===
compliance-check: ok — security-threat-model-stride/hooks/methodology-gate.sh
rc=0
=== security-threat-model-risk-rating ===
compliance-check: ok — security-threat-model-risk-rating/hooks/methodology-gate.sh
rc=0
=== security-threat-model-mitigation ===
compliance-check: ok — security-threat-model-mitigation/hooks/methodology-gate.sh
rc=0
=== security-threat-model-canon-citation ===
compliance-check: ok — security-threat-model-canon-citation/hooks/methodology-gate.sh
rc=0
=== security-threat-model-residual-signoff ===
compliance-check: ok — security-threat-model-residual-signoff/hooks/methodology-gate.sh
rc=0
OVERALL rc=0
```

Full suite, `tests/run-gate-tests.sh` (repo-root entrypoint) plus every
plugin's now-seven-group `run-gate-lib-tests.sh`, plus `parse-check.sh` —
green, including the new `missing-core` case in each suite:

```
== cross-plugin cases: 22 passed, 0 failed ==
== security-threat-model: run-gate-lib-tests.sh ==            15 passed, 0 failed
== security-threat-model-stride: run-gate-lib-tests.sh ==     22 passed, 0 failed
== security-threat-model-risk-rating: run-gate-lib-tests.sh == 15 passed, 0 failed
== security-threat-model-mitigation: run-gate-lib-tests.sh ==  15 passed, 0 failed
== security-threat-model-canon-citation: run-gate-lib-tests.sh == 15 passed, 0 failed
== security-threat-model-residual-signoff: run-gate-lib-tests.sh == 15 passed, 0 failed
parse-check: 31 file(s) under /bin/bash — all ok
== ALL SUITES GREEN ==
```

Each plugin's 15 (22 for stride, which also carries its own s4/s5
regressions from issue-10) includes the new `missing-core` case as the
final entry, asserted `deny`.

`deny-only-check.sh`, re-run for all six plugins: `permissionDecision`-grant
half `ok` on all six; substance-probe `FAIL` on all six, same accepted
boundary as s2 above and as issue-10's Open findings — not part of the
green gate.

## What did not work

Nothing required iteration this pass — the guard fix and the
`missing-core` test group both landed clean on the first attempt, verified
against the pre-fix FAIL baseline captured above so the new test is known
to actually exercise the guard rather than pass by exit-code coincidence.

## Open findings

Carried forward unchanged from issue-10's Open findings: the
`deny-only-check.sh` substance-probe boundary (s2 above), and the
`Write|Edit|MultiEdit`-only matcher leaving a Bash-tool write to a record
path uninspected by every gate in this set (s3 above) — both documented,
asserted-not-silent boundaries, not residual defects this issue's wording
asks to be redone.

## Residual risk (residual-risk-note)

Per `docs/issue-13/proposals/security-threat-model.md` s8: the unguarded-source
fail-open (survey s1) was a confirmed, not hypothetical, live-deployment
risk — on-the-record #182 reported a spawned role session with
`CLAUDE_PLUGIN_ROOT_CORE` unset falling through to an unreachable relative
path. Pre-mitigation rating: High (a PreToolUse write gate silently not
gating, on every write, whenever core is unreachable).

Post-mitigation rating: **Low residual.** Confirmed by the before/after
`compliance-check.sh` evidence above (6/6 FAIL → 6/6 clean) and the new
`missing-core` test group, green in all six suites. The guard converts the
failure mode to a denial; residual risk is limited to a gate-script syntax
error downstream of the guard, which `gate_trap_fail_closed` already
covers per its existing, correctly-claimed scope. Disposition: mitigate.

Items s2/s3/s5 carry no residual risk to disposition — confirmed clean
before and after this session's edits, no change made, no new exposure
introduced or left open. Disposition: accept.

Approver reference: `docs/specs/approvers.md` (contract v3 §19 Approve
gate) — this record's phase 2 opened via the single-account `APPROVE
issue-13/security-threat-model` path, posted by `JiwonJung94` (listed in
`docs/specs/approvers.md`), 2026-08-01.

## Canon references

Referenced by path and description only; no canon script content is
reproduced in this repo or in this record.

- `core/hooks/lib/gate-lib.sh` (core #75) — usage comment mandates the
  `||`-guarded source form landed in s1 above.
- `core/hooks/tests/compliance-check.sh` (core #75) — gained the
  unguarded-source detection rule; its before/after output is quoted in
  Evidence above.
- `core/hooks/tests/run-gate-lib-tests.sh` (core #75) — reference shape for
  the new mandatory `missing-core` 7th group, adapted per plugin exactly as
  the original six groups were in issue-10.
- `docs/handbooks/gate-house-standard.md`'s "Transition note (issue-75...)"
  section — the instruction this record executes.
- `docs/issue-10/proposals/security-threat-model.md` and
  `docs/issue-10/reports/security-threat-model.md` — the prior migration's
  shape and evidence-citation convention, followed here.
- `docs/issue-13/proposals/security-threat-model.md` — the approved plan
  this record executes, section by section.
