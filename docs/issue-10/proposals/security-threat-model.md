# Proposal — issue-10: gate A+ remediation (security-threat-model plugin set)

Phase 1 (design only). Findings this proposal responds to are recorded in
`docs/issue-10/reports/security-threat-model/survey.md`; scouting record
in the same directory's `scout-brief.md`.

## 0. Approach

Adopt core's gate-house standard by reference, per its own migration
checklist — no reimplementation of `gate_kill_switch_active`,
`gate_reconstruct_write`, `gate_normalize_path`, `gate_deny`,
`gate_trap_fail_closed`, or `gate_bash_write_targets`. Every gate in this
plugin set sources/loads the shared library instead.

**canon-references**: `core/hooks/lib/gate-lib.sh` and
`core/hooks/lib/gate-lib.py` (issue-72) — the shared fail-closed trap,
kill-switch, deny/allow, JSON-parse-or-deny, path-normalize, and
Write/Edit/MultiEdit/NotebookEdit reconstruction functions this
migration sources instead of re-deriving. `docs/handbooks/
gate-house-standard.md` — the migration checklist and the six-case
mandatory test harness this proposal's test plan (s4) follows.
`core/hooks/tests/compliance-check.sh` — the detector phase-2 execution
runs clean before closing this issue.

## 1. Kill-switch fail-open fix (all 6 gates)

Replace, in `sequence-gate.sh` and every `methodology-gate.sh`:
```
case "${..._GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
```
with sourcing `gate-lib.sh` at the top of the script and calling
`gate_kill_switch_active "${..._GATE_OFF:-}" || { trap - EXIT; exit 0; }`
immediately after `gate_trap_fail_closed`. `gate_trap_fail_closed`
replaces the current hand-rolled `__fc`/`trap __fc EXIT` pair in every
gate (identical shape, canon source instead of six independent copies).

## 2. Edit/MultiEdit/replace_all reconstruction (5 methodology gates)

Replace the hand-rolled `current.replace(o, n, 1)` reconstruction in each
methodology gate's embedded Python judge with a call to
`gate_reconstruct_write(tool, tool_input, current_content)`, loaded via
`importlib` from `GATE_LIB_PY` (the env var `gate-lib.sh` exports) exactly
as gate-house-standard.md's usage comment prescribes. This is a like-for-
like swap: `gate_reconstruct_write` already returns `None` on an
unresolvable edit (same "cannot determine resulting content" deny path
each gate already has), and additionally covers `NotebookEdit`, which no
gate in this plugin set currently reconstructs at all — `hooks.json`'s
matcher is `Write|Edit|MultiEdit` only, so `NotebookEdit` coverage is a
latent gap this migration closes without a matcher change being strictly
required (the gate becomes correct if the matcher is later widened, and
does no harm today).

## 3. Path matching — absolute-path normalization (all 6 gates)

Replace each gate's dual bash (`_under`) + inline-python (`resolve`)
path-resolution pair with a single call to `gate_normalize_path(root,
path)` inside the gate's existing Python judge block; drop the bash-side
`_under()` pre-check (redundant once the Python judge is the single
source of truth for in-root/out-of-root and normalization) but keep
`_plausible()`/root-detection in bash as-is (scout-brief.md: no core
precedent or flagged defect for that half — see s2 of the brief).
`gate_normalize_path` returns `None` when a path resolves outside root,
matching each gate's current "not this gate's business, exit 0" branch
for out-of-scope writes.

## 4. STRIDE sequence check — enforce all three pairwise orderings

`security-threat-model-stride/hooks/methodology-gate.sh` currently checks
`asset-inventory < stride-table` and `trust-boundary-map < stride-table`
but never `asset-inventory < trust-boundary-map`. Add the third
comparison:
```python
if asset_pos is not None and boundary_pos is not None and asset_pos > boundary_pos:
    missing_order.append("asset-inventory (present but after trust-boundary-map)")
```
placed alongside the two existing checks, contributing to the same
`missing_order` list and the same single deny call — no new deny path,
just a third condition feeding the existing one. This makes the full
three-way order `asset-inventory -> trust-boundary-map -> stride-table`
mechanically enforced, matching the gate's own header comment for the
first time.

## 5. Semantic check upgrade — section/adjacency/structure, not substring

Two substring-only checks in the stride gate need to become structural.
The general shape (reusable across the other four methodology gates,
which currently do not have per-row semantic checks at all — noted for
phase-2 scope, not invented here beyond stride since only stride's
substring weakness is in the issue's audit findings):

**5.1 Marker location** — drop `find_marker`'s "bare occurrence anywhere"
fallback. A marker only counts as present if it is a markdown heading
(`^#{1,6}[ \t]*.*\btoken\b`) *or* a line-start field marker
(`^[ \t]*token[ \t]*:`) — never a mid-sentence mention. This closes the
"stride-table mentioned in prose" false-positive from survey.md s1.4.

**5.2 Row-level category tagging** — replace the section-wide
`has_name`/`has_initial` scan (satisfied by one word anywhere in the
whole section) with a per-row check: split the `stride-table` section
into table rows (markdown table rows — lines starting with `|`, or, if no
`|` is found in the section, list-item lines starting with `-`/`*`/a
digit followed by `.`), and require **every** row that is not the table's
own header/separator row to carry at least one STRIDE category name or
isolated initial. Deny naming the first row (1-indexed within the
section) that carries none, so the message points at the actual gap
instead of a section-wide pass/fail. A `stride-table` section with zero
rows still passes structurally (nothing to tag) — the existing
core/record-fields-gate.sh-level "field must be non-empty" check is a
different gate's job, not re-derived here.

This directly answers the issue's requirement 2 ("부분문자열에서
섹션/인접성/구조 검사로 상향 — 채택 방법론의 판단이 '단어 언급'으로
통과되지 않게"): marker-as-heading is the "section" half, the three-way
ordering fix (s4) is the "인접성"(adjacency) half already structural via
position comparison, and per-row tagging is the "구조" half.

## 6. `deny-only-check.sh` / `parse-check.sh` default paths (6 plugins)

Fix the copy-pasted defaults in every plugin's
`hooks/tests/deny-only-check.sh`:
```bash
probe_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../coding/hooks" && pwd -P)}"
rec_rel="docs/issue-999/reports/coding.md"
```
to this plugin's own shape:
```bash
probe_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
rec_rel="docs/issue-999/reports/security-threat-model.md"
```
and the matching default in `parse-check.sh`
(`../coding/hooks` -> `..`). Each plugin's `probe_dir` default becomes
its own `hooks/` directory (one level up from `hooks/tests/`), matching
how `deny-only-check.sh`'s *own* top-level `dir` argument already
defaults (`"$(dirname "${BASH_SOURCE[0]}")/.."`) — the substance-probe
default should not diverge from the file's own established default
resolution. Since every gate in this plugin set is a
`Write|Edit|MultiEdit`-matched deny-only gate, the substance probe's
synthetic empty-record payload against `security-threat-model.md` (this
role's real record path) now actually exercises a real gate in every
plugin instead of silently finding zero gate scripts and passing empty.

## 7. Deny-reason stderr delivery — confirm, no change needed

survey.md s1.7: already correct in the current tree (every `deny()`
closure writes to stderr, no gate emits bare `permissionDecision: allow`
or a message-less exit 2). `gate_deny` preserves the same stderr-only
shape, so this item carries through the migration unchanged rather than
being a separate fix.

## 8. Mandatory test cases (per gate-house-standard.md's six-case harness)

Each plugin's `hooks/tests/` gains a `run-gate-lib-tests.sh`-derived suite
covering, against its own gate(s):
1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`.
2. `MultiEdit` mixing `replace_all: true`/`false` edits in one call.
3. Malformed JSON (truncated, non-object, empty payload).
4. Kill-switch set to an unrecognized value (e.g. a typo) — assert the
   gate stays **active** (denies/proceeds as if unset), not disabled.
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write reaching the same target a `Write`-tool call
   would hit (via `gate_bash_write_targets`, for any gate in this set
   that inspects Bash commands — none currently do; this case is
   included as required coverage per the standard even where it
   currently exits 0 trivially, so a future Bash-matcher addition is not
   silently unguarded).

`security-threat-model-stride` additionally gets: the three-way ordering
regression (asset-after-boundary case from s4), the marker-as-heading
false-positive regression (mid-sentence "stride-table" mention from
s5.1), and the per-row tagging regression (one untagged row among tagged
ones from s5.2).

Deliverable: full suite green before phase-2 closes, per the issue's
requirement 3.

## 9. README sync

Phase-2 execution re-reads `README.md` against the real plugin list
(`security-threat-model`, `-stride`, `-mitigation`, `-canon-citation`,
`-residual-signoff`, `-risk-rating`), the real kill-switch env var names
(6, one per plugin, listed in s1/s8 above), and removes any documented
file/path that does not exist in the tree. Not designed further here
since it is a mechanical read-and-sync against phase-2's own completed
migration, not a design decision.

## 10. Execution order (phase 2)

1. Run `compliance-check.sh` against this plugin set's current gates,
   record the violation list (expected: 6/6 kill-switch, 5/5
   reconstruction hits, matching survey.md s1.1/1.2).
2. Migrate `sequence-gate.sh`, then the five `methodology-gate.sh` files
   (s1-s3), then the stride-specific fixes (s4-s5).
3. Fix `deny-only-check.sh`/`parse-check.sh` defaults (s6).
4. Add the six-case-plus-stride-specific test suite (s8); run it and the
   existing suites green.
5. Re-run `compliance-check.sh` clean.
6. Sync README (s9).
7. Write the phase-2 record at `docs/issue-10/reports/
   security-threat-model.md`, citing the clean `compliance-check.sh`
   output as evidence per the migration checklist's step 5.

Phase 1 ends here — no execution work, no APPROVE issued.
