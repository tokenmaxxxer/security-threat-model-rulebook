# Proposal — issue-13: gate A+ final closeout (re-audit grade A, residual defects)

Phase 1 (design only). Findings this proposal responds to are recorded in
`docs/issue-13/reports/security-threat-model/survey.md`; scouting record in
the same directory's `scout-brief.md`.

## 0. Approach

Same convention issue-10 established
(`docs/issue-10/proposals/security-threat-model.md` s0): adopt core's
canon by reference, no reimplementation. Concretely here, that means
re-pulling core #75's already-decided, already-landed guard shape and test
shape into this plugin set's six gate scripts and six
`run-gate-lib-tests.sh` files — not designing a new guard or a new test
shape from scratch. Requirements 2/3/5 (survey s2/s3/s5) are re-confirmed
clean and need a record entry, not a code change.

**canon-references**: `core/hooks/lib/gate-lib.sh` (core #75) — usage
comment now mandates the `||`-guarded source form; every gate in this
plugin set adopts that exact form. `core/hooks/tests/compliance-check.sh`
(core #75) — gained the unguarded-source detection rule; phase-2 execution
runs this clean as its acceptance criterion, same pattern issue-10's record
used. `core/hooks/tests/run-gate-lib-tests.sh` (core #75) — reference shape
for the new mandatory `missing-core` 7th group, adapted per plugin exactly
as the original six groups were in issue-10. `docs/handbooks/
gate-house-standard.md`'s "Transition note (issue-75...)" section — the
explicit instruction this proposal is executing. `docs/issue-10/proposals/
security-threat-model.md` and `docs/issue-10/reports/security-threat-model.md`
— the prior migration's shape and evidence-citation convention, followed
here rather than re-invented.

No canon script content is reproduced in this proposal or will be
reproduced in the phase-2 record — every reference above is by path and
description only, per this role's canon-citation convention
(`security-threat-model-canon-citation`).

## 1. Guarded source line — all 6 gates (issue requirement 1, common item)

**Current false state** (survey s1): `sequence-gate.sh:2` and each of the
five `methodology-gate.sh:2` source `gate-lib.sh` unguarded, while the
adjacent header comment (lines 4-9 in every file) claims failed-source
protection that the unguarded line does not provide — the exact defect
core #75 confirmed and fixed in its own canon.

**Fix**: change, in each of the six files, the one source line from

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
```

to the guarded form core #75's usage comment now prescribes — a `||`
fallback on the same statement that prints a gate-specific stderr message
and exits 2 before `gate_trap_fail_closed` is ever reached, so a failed
source itself is the first thing that can deny, not the first thing that
silently no-ops:

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
```

with `<gate-name>.sh` substituted per file (`sequence-gate.sh`,
`methodology-gate.sh` — five copies, one per methodology plugin, message
text otherwise identical in shape to core's own per-gate messages in
`core/hooks/directive.sh` etc.). Update the header comment immediately
below (currently lines 4-9) to state that the guard is now what makes the
"failed source is forced to exit 2" claim true, instead of leaving the old
wording that described only the post-source trap. This closes the false
claim itself, not just the mechanism it described.

**Files touched**: `security-threat-model/hooks/sequence-gate.sh`,
`security-threat-model-stride/hooks/methodology-gate.sh`,
`security-threat-model-risk-rating/hooks/methodology-gate.sh`,
`security-threat-model-mitigation/hooks/methodology-gate.sh`,
`security-threat-model-canon-citation/hooks/methodology-gate.sh`,
`security-threat-model-residual-signoff/hooks/methodology-gate.sh` — one
line changed each (the source line), plus the adjacent header comment.

**Satisfies issue requirement 1** (공통 항목을 core #75의 확정 가드로 수정)
directly: this is the confirmed guard, applied unchanged, to all six
call sites in this repo.

## 2. `deny-only-check` default path — confirm, record, no code change

**Current state** (survey s2): already clean. Phase-2 execution re-runs
`deny-only-check.sh` per plugin, confirms the `dir`/`rec_rel` defaults
still resolve correctly (no regression since issue-10), and records that
confirmation plus the carried-forward substance-probe boundary explicitly
in the phase-2 record's own words — not by silently omitting the item,
since the issue names it explicitly ("deny-only-check 기본 경로 정리 완료
확인"). No file changes proposed for this item.

**Satisfies issue requirement 1** for this sub-item (재감사 잔여 결함
verification) by producing an explicit, current confirmation rather than
relying on the issue-10 record being read by inference.

## 3. hooks.json matcher / code parity — confirm, record, no code change

**Current state** (survey s3): clean across all six plugins, matcher and
dispatch both `Write|Edit|MultiEdit`, file:line-cited in the survey. No fix
proposed. Phase-2 record states the audit result plugin-by-plugin
(mirroring survey s3's table) as the deliverable for issue requirement 2
("hooks.json matcher와 코드의 도구 커버리지 완전 정합") — this requirement is
already satisfied; the phase-2 record is what makes the satisfaction
checkable rather than assumed.

## 4. `missing-core` mandatory test — 6 plugins (issue requirements 1, 3)

**Current state** (survey s4): the guard (s1) is the fix; the mandatory
7th test group is missing from every plugin's `hooks/tests/
run-gate-lib-tests.sh`.

**Fix**: add a `missing-core` case group to each of the six
`run-gate-lib-tests.sh` files, mirroring core's own 7th group
(`core/hooks/tests/run-gate-lib-tests.sh`, core #75): invoke this plugin's
gate script with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a path that does not
exist (e.g. a `mktemp -d` directory with no `hooks/lib/gate-lib.sh` under
it, or a fixed nonexistent literal path — matching whichever core's own
group uses, adapted to this harness's existing `fire()`/`report()`
helpers), assert the gate denies (exit 2). This is the regression test for
s1's fix: before s1 lands, this case fails (observes fail-open); after s1
lands, it passes. The proposal's execution order (s7 below) sequences the
guard fix before the test addition specifically so no interval exists where
a merged missing-core test is green against an unguarded gate by
coincidence of exit-code plumbing rather than by the guard actually firing.

Each plugin's six-groups-mandatory framing comment at the top of
`run-gate-lib-tests.sh` (currently describing the pre-#75 shape) is updated
to seven, mirroring core's own bump
(`docs/issue-75/reports/implementation.md`, core #75, item covering
`run-gate-lib-tests.sh`).

**Files touched**: all six `hooks/tests/run-gate-lib-tests.sh` (one new
case-group function plus its call, plus the seven-groups comment bump,
each).

**Satisfies issue requirement 1** (missing-core 의무 테스트, named
explicitly in the issue's "공통 선행 조건" list as core #75's scope, and
required by this issue's own requirement wording "missing-core 케이스 포함
전 스위트") and contributes to requirement 3 (green suite including the
missing-core case).

## 5. README / manifest ghost names — confirm, record, no code change

**Current state** (survey s5): clean — no stale role name, no ghost file,
across `README.md`, all six `plugin.json`, `marketplace.json`, and
`docs/handbooks/security-threat-model.md`. No fix proposed. Phase-2 record
states this confirmation explicitly, satisfying issue requirement 4
(README·manifest 옛 역할명·유령 파일 잔재 0) by evidence rather than silence.
The issue's clause "옛 이름은 하드 에러" (an old name should hard-error) has
no applicable target here — there is no old name present to make a hard
error out of; if the re-audit intends a *mechanism* (e.g. a
`compliance-check.sh`-style detector for stale role-name strings, not just
a one-time grep), that is a distinct, larger design question outside this
survey's confirmed-clean finding and is called out here as a decision the
approver may want to weigh in on before phase 2, rather than silently
scoped in or out.

## 6. Full-suite green + `compliance-check.sh` record (issue requirement 3)

Phase-2 execution:

1. Runs `compliance-check.sh` (core canon) against each of the six
   plugins' `hooks/` directories before any fix, records the FAIL list
   (expected: 6/6 on the new unguarded-source rule, per survey s1 and core
   #75's detection rule).
2. Lands s1 (guard) across all six gates.
3. Re-runs `compliance-check.sh`, records the clean pass, same
   before/after evidence shape `docs/issue-10/reports/
   security-threat-model.md`'s Evidence section used.
4. Lands s4 (missing-core test group) across all six
   `run-gate-lib-tests.sh`.
5. Runs `tests/run-gate-tests.sh` (repo root entrypoint) — cross-plugin
   cases, then every plugin's now-seven-group `run-gate-lib-tests.sh`,
   then `parse-check.sh` — records the full green output, matching
   issue-10's Evidence-section convention.
6. Records s2/s3/s5's confirmations (no code change, evidence-only) in the
   same phase-2 record.

## 7. Execution order (phase 2)

1. Run `compliance-check.sh`, record pre-fix FAIL state (s6.1).
2. Land the guard fix, all six gates (s1).
3. Re-run `compliance-check.sh`, record clean pass (s6.3).
4. Add the `missing-core` mandatory test group, all six plugins (s4);
   confirm it is red before s2's guard and green after (s6.2-s6.3 order),
   documented in the record's "What did not work" section if the harness
   needs any iteration, mirroring issue-10's own honesty about its
   `pipefail`/SIGPIPE correction.
5. Run the full suite (`tests/run-gate-tests.sh`), record green (s6.5).
6. Confirm and record s2 (deny-only-check default path), s3 (matcher
   parity), s5 (README/manifest) as already-clean, with the file:line
   citations this survey already established.
7. Write the phase-2 record at `docs/issue-13/reports/
   security-threat-model.md`, citing the compliance-check before/after and
   the full green suite output as evidence, per issue requirement 3's
   explicit wording ("전 스위트 배송 상태 green + compliance-check 통과
   record 기록").

Phase 1 ends here — no execution work, no approval issued in this
document or by this session.

## 8. Risk disposition of not fixing (for record completeness)

Per this role's own mitigation-list convention
(`security-threat-model-mitigation`, disposition vocabulary
accept/mitigate/transfer/avoid — 수용/완화/전가/회피), the residual risk if
s1/s4 are not applied is carried here for the phase-2 record's
`residual-risk-note` to close out with a rating and an approver reference
once landed, per `docs/specs/approvers.md`'s single-account `APPROVE
issue-13/security-threat-model` path (the same path core #75 and
on-the-record #182 both used, per survey s0):

- **Disposition: mitigate.** The unguarded-source fail-open (survey s1) is
  a confirmed, not hypothetical, live-deployment risk given on-the-record
  #182's own bug report (a spawned role session with
  `CLAUDE_PLUGIN_ROOT_CORE` unset previously fell through to an
  unreachable relative path) — mitigated by s1's guard, which turns that
  exact failure into a deny instead of a silent allow. Pre-mitigation
  rating: High (a PreToolUse write gate silently not gating, on every
  write, whenever core is unreachable). Post-mitigation rating, to be
  confirmed by phase-2's `compliance-check.sh` clean pass and the new
  `missing-core` test: Low residual (guard converts the failure mode to a
  denial; residual risk is limited to a gate-script syntax error
  downstream of the guard, which `gate_trap_fail_closed` already covers
  per its existing, correctly-claimed scope).
- **Disposition: accept.** Items s2/s3/s5 (deny-only-check path,
  matcher/code parity, README/manifest) carry no residual risk to
  disposition — confirmed clean, no change, no new exposure introduced or
  left open.

Final post-mitigation rating and approver sign-off belong in the phase-2
record's own `residual-risk-note`, once s1/s4 have actually landed and
been evidenced per s6 above — not asserted here in a document that must
not itself claim or request approval.
