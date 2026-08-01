# Issue #13 — Phase-1 Survey: Gate A+ Final Closeout (Residual Defects from Re-Audit)

subject: issue-13
role: security-threat-model
phase: 1 (survey)

Scope: the 2026-08-01 re-audit (issue #13 body) names one common-defect class
plus a verification item, and this repo carries five audit requirements
against them. This survey documents the actual current state of each,
file:line-cited, before any proposal is written (survey-first order per
contract v3 s19).

## 0. Precondition landings (located, confirmed landed)

The issue names two precondition landings and says "착수 전 랜딩 확인." Both
were located in sibling checkouts on this machine and confirmed landed by
inspecting their git history directly (not guessed):

- **core #75** — `/home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-75-implementation`,
  commit `f61d52feb95dc32b820f79b025bac6dbe94be3a7`
  (`deliver(implementation): gate-lib source guard + gate_bash_write_targets py parity (issue-75)`),
  `loop_state: landed` per `docs/issue-75/reports/implementation.md` in that
  checkout. It fixed, in core's own canon:
  1. `core/hooks/lib/gate-lib.sh`'s usage comment now mandates a source line
     with an `||` fallback (`. "$path" || { echo "<gate-name>.sh: cannot
     source gate-lib.sh" >&2; exit 2; }`) instead of the bare, unguarded
     `. "$path"` the comment showed before — applied to all 7
     `core/hooks/*.sh` gates.
  2. `core/hooks/tests/compliance-check.sh` gained a third structural check:
     a gate that sources `gate-lib.sh` with no `||` guard on the same
     statement now fails compliance.
  3. `core/hooks/tests/run-gate-lib-tests.sh` gained a mandatory 7th group,
     `missing-core`: a gate run with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
     nonexistent path must assert deny (exit 2), not the pre-fix
     silent-allow.
  4. `core/hooks/lib/gate-lib.py` gained `gate_bash_write_targets(command)`
     for sh/py parity.
  5. `docs/handbooks/gate-house-standard.md` (core canon) gained a
     "Transition note (issue-75, for the final 43-rulebook remediation
     batch)" section directing every already-migrated rulebook — this one
     included — to re-pull the guarded source line and re-run
     `compliance-check.sh`.

  This repo's own `docs/handbooks/gate-house-standard.md` is not vendored
  here (referenced by path only, per this role's no-copy convention), so
  it is not itself out of date; what is out of date is this repo's six gate
  scripts and six `run-gate-lib-tests.sh` files, which still reflect the
  pre-issue-75 shape of the standard. See s1 and s4 below.

- **on-the-record #182** — `/home/jwjung/.tokenmaxxxer/work/on-the-record-issue-182-implementation`,
  commit `e50fe08` (`issue-182: phase 2 — inject CLAUDE_PLUGIN_ROOT_CORE into
  role sessions`), issue confirmed `CLOSED` via `gh issue view 182 --repo
  tokenmaxxxer/on-the-record`, approved via issue comments `APPROVE
  issue-182/implementation` and `ACCEPT issue-182/implementation` from
  `JiwonJung94`. It makes `spawn.py` inject `CLAUDE_PLUGIN_ROOT_CORE`
  pointing at the real installed core clone when spawning a role session,
  closing the gap where the unset variable's relative fallback
  (`.../hooks/lib/../../core`) resolved inside the rulebook's own clone in
  real deployment rather than the installed core plugin. This is
  infrastructure outside this repo; nothing in this repo needs to change
  for #182 itself, but it is the reason the guard fix in s1 below is not
  merely defensive — the previously-reported failure mode (gates spawned
  with `CLAUDE_PLUGIN_ROOT_CORE` unset, falling into the unreachable
  relative path, sourcing failing) is a real, now-fixed-upstream trigger,
  not a hypothetical.

No code from either landed change is pasted in this survey or will be
pasted in the proposal — referenced by path/commit/description only, per
this role's canon-citation convention.

## 1. "failed-source 보호 주장 허위" (false failed-source-protection claim)

**Confirmed present, 6/6 gates in this repo.** Every gate in this plugin set
sources `gate-lib.sh` unguarded, then immediately follows with a header
comment claiming failed-source protection that is not true until a guard is
added — the exact defect core #75 fixed in its own canon (s0 above).

Pattern (identical across all six, only the gate filename differs):

```
security-threat-model/hooks/sequence-gate.sh:2   . "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"
security-threat-model/hooks/sequence-gate.sh:3   gate_trap_fail_closed
security-threat-model/hooks/sequence-gate.sh:4-9 # ^ fail-closed trap-at-top ... any abnormal termination
                                                   #   (failed source, set -u abort, unbound var) before the
                                                   #   verdict logic runs is forced to exit 2 (DENY) ...
```

Same shape at:
- `security-threat-model-stride/hooks/methodology-gate.sh:2-9`
- `security-threat-model-risk-rating/hooks/methodology-gate.sh:2-9`
- `security-threat-model-mitigation/hooks/methodology-gate.sh:2-9`
- `security-threat-model-canon-citation/hooks/methodology-gate.sh:2-9`
- `security-threat-model-residual-signoff/hooks/methodology-gate.sh:2-9`

**Why the claim is false today.** Line 2's `. "$path"` has no `||`
fallback. If sourcing fails (the exact scenario the comment claims is
covered — "failed source"), bash does not abort by default (no `set -e` is
in effect yet — `set -uo pipefail` is not reached until line further down,
after the trap-install line). Execution falls through to line 3,
`gate_trap_fail_closed`, which is itself a function *defined inside*
`gate-lib.sh` — so on a failed source it is undefined, the call fails with
"command not found" (exit 127), and — again with no `set -e` — execution
keeps going. Downstream, every gate's `gate_kill_switch_active ... || {
trap - EXIT; exit 0; }` call is likewise undefined and its own failure is
read by the `||` as "the function returned false," i.e. "kill switch is
on," which disables the gate — exit 0, fail-open, on a PreToolUse write
gate. The header's claim ("any abnormal termination... is forced to exit
2") is true only for aborts *after* a successful source; it is false for
the failed-source case it explicitly names, which is precisely the gap
core #75's own fix log describes as "confirmed live" in core's own
already-migrated canon before that issue.

## 2. `deny-only-check` 기본 경로 정리 완료 확인

**Confirmed already clean — no further path-config fix needed.**
`security-threat-model/hooks/tests/deny-only-check.sh` (and its five
identical copies under each methodology plugin's `hooks/tests/`) default
`dir` to `"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"` — the
plugin's own `hooks/` directory — and the substance-probe's `rec_rel` is
`"docs/issue-999/reports/security-threat-model.md"`
(`security-threat-model/hooks/tests/deny-only-check.sh:39`). Both match the
1.5 fix already landed and recorded in
`docs/issue-10/reports/security-threat-model.md` lines 62-69
("`../coding/hooks` became `..`" / "`docs/issue-999/reports/coding.md`
became `docs/issue-999/reports/security-threat-model.md`"). No stale
`coding`-role path remains anywhere in the six copies (verified by
inspecting the base plugin's copy directly; the other five are byte-for-byte
the same canon-scripts.md exception copy per README.md's own documentation
of that convention).

What remains **not** fixed, and does not need to be for this issue, is the
substance-probe's structural mismatch already recorded as an accepted,
carried-forward Open finding in `docs/issue-10/reports/security-threat-model.md`
lines 200-215: the probe expects an unconditional record-substance gate,
and every gate in this six-plugin set is conditional (fires only when its
own section marker is present), so the probe's `nothing here` payload
allows on all six. That is a known, documented design boundary — the probe
is deliberately not wired into `tests/run-gate-tests.sh`'s green gate — not
a residual defect the 2026-08-01 re-audit's wording ("정리 완료 확인",
"confirm the cleanup is complete") is asking to be redone. The proposal
carries this forward rather than re-deriving it.

## 3. hooks.json matcher ↔ code tool-coverage parity

**Confirmed clean, 6/6 plugins.** Every `hooks.json` in this set declares
the identical `PreToolUse` matcher:

- `security-threat-model/hooks/hooks.json:12` — `"Write|Edit|MultiEdit"`
- `security-threat-model-stride/hooks/hooks.json:12` — same
- `security-threat-model-risk-rating/hooks/hooks.json:12` — same
- `security-threat-model-mitigation/hooks/hooks.json:12` — same
- `security-threat-model-canon-citation/hooks/hooks.json:12` — same
- `security-threat-model-residual-signoff/hooks/hooks.json:12` — same

And every gate script's Python judge dispatches on exactly the same three
tool names:

- `security-threat-model/hooks/sequence-gate.sh:96` — `if tool in ("Write", "Edit", "MultiEdit"):`
- `security-threat-model-risk-rating/hooks/methodology-gate.sh:96` — same
- `security-threat-model-residual-signoff/hooks/methodology-gate.sh:96` — same
- `security-threat-model-mitigation/hooks/methodology-gate.sh:100` — same
- `security-threat-model-canon-citation/hooks/methodology-gate.sh:105` — same
- `security-threat-model-stride/hooks/methodology-gate.sh:107` — same

No mismatch in either direction: the matcher does not list a tool the code
ignores, and the code does not special-case a tool the matcher excludes.
`NotebookEdit` is a documented non-mismatch: `gate_lib.gate_reconstruct_write`
(core canon) is capable of reconstructing a `NotebookEdit` payload, per
`docs/issue-10/reports/security-threat-model.md:31-32`, but since no matcher
in this set includes `NotebookEdit`, no gate's tool-dispatch line ever
routes one there — code capability exceeding current matcher scope, not code
failing to handle what the matcher promises. `tests/run-gate-tests.sh`'s
per-plugin `run-gate-lib-tests.sh` mandatory case 6 (`bash_case` /
`bash-tool write to the same target`) already asserts, per plugin, that a
`Bash`-tool write is a documented no-op given the current matcher — this is
the same "asserted boundary, not silent gap" pattern applied to `Bash`.

## 4. missing-core case: guard design + mandatory test

**Guard: not yet applied (see s1).** **Test: missing, 6/6 plugins.**

Core #75's now-current `run-gate-lib-tests.sh` mandatory suite is seven
groups (six pre-existing, plus `missing-core`, per s0 above). This repo's
six `hooks/tests/run-gate-lib-tests.sh` files were written to the six-group
version of the standard (issue-10, before core #75 existed) and have not
been updated:

- `security-threat-model/hooks/tests/run-gate-lib-tests.sh` — six
  `report`/case functions only: baseline (2), `edit_replace_all_case`,
  `multiedit_case`, three `raw_case` malformed-JSON cases, three
  `kill_switch_case`s, three `path_case`s, `bash_case`. No `missing-core`
  group; `CLAUDE_PLUGIN_ROOT_CORE` is resolved once at the top of the file
  (lines 20-27) purely so the harness itself can find core to run the gate
  under test — it is never pointed at a nonexistent path to assert the
  gate's own missing-core behavior.
- The five methodology plugins' `hooks/tests/run-gate-lib-tests.sh` files
  are the same shape (confirmed by their shared six-groups-mandatory
  framing comment, mirroring the base plugin's file).

Because the guard in s1 is also missing, a missing-core test written today
against the current gate scripts would currently observe fail-open (the
bug), not fail-closed — so the guard fix (s1) and the test (s4) must land
together, or the test must land first as a red/failing assertion the guard
fix then turns green. The proposal specifies the guard-first-then-test
order to avoid a period where a merged test asserts a false pass.

## 5. README / manifest — stale role names, ghost files

**Confirmed clean — no stale names, no ghost files found.**

- `README.md` (repo root) — "Layout" section (lines 42-64) lists exactly
  the files that exist on disk: `.claude-plugin/plugin.json`,
  `hooks/hooks.json`, `hooks/directive.sh`, `hooks/methodology-gate.sh` /
  `hooks/sequence-gate.sh` (base), `hooks/tests/run-gate-lib-tests.sh`,
  `hooks/tests/parse-check.sh`, `hooks/tests/deny-only-check.sh`, plus
  base-plugin-only `hooks/record-fields.env` and
  `agents/warrant-hunter.md`. Verified against `find` output for all six
  plugin directories — no extra file on disk is undocumented, and no
  documented file is missing on disk. The three ghost files a prior audit
  (issue-10) found and removed from this README —
  `record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`,
  per `docs/issue-10/reports/security-threat-model.md:105-110` — do not
  reappear anywhere in the current README.
- All six `.claude-plugin/plugin.json` manifests (`security-threat-model`,
  `-stride`, `-risk-rating`, `-mitigation`, `-canon-citation`,
  `-residual-signoff`) — `name`/`description` fields match the plugin's
  actual current role name and current single-owned judgment; no manifest
  references a `coding`/`pricing`/other-role name or a file path.
- `.claude-plugin/marketplace.json` (repo root) — registers exactly the
  six plugins that exist, `source` paths all resolve to real directories,
  no stale entry.
- `docs/handbooks/security-threat-model.md` — grepped for
  `record-fields-gate|trailer-gate|handbook-trigger-gate|coding-gate|
  pricing-rulebook|implementation-rulebook`: zero hits. The file correctly
  describes those three gates as core-canon-only (never vendored here,
  core issues #63/#66), which is accurate, not a ghost reference.

## Summary table

| # | Requirement | State | Fix needed in phase 2 |
| --- | --- | --- | --- |
| 1 | failed-source guard | Confirmed false claim, 6/6 gates | Yes — add `||` guard to all 6 source lines, update header comments |
| 2 | deny-only-check default path | Confirmed already clean | No — carry forward the documented substance-probe boundary as-is |
| 3 | matcher/code parity | Confirmed clean, 6/6 | No — document confirmation in the record |
| 4a | missing-core guard | Same as #1 | Yes (shared fix) |
| 4b | missing-core mandatory test | Missing, 6/6 | Yes — add 7th test group per plugin |
| 5 | README/manifest ghosts | Confirmed clean | No — document confirmation in the record |

Only requirement 1/4 (the guard) and 4b (the test) require a code change;
requirements 2, 3, and 5 require re-confirmation in the phase-2 record, not
a fix, per this survey's findings.
