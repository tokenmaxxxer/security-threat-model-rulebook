# Issue #10 — Phase-2 Record: Gate A+ Remediation (plugin set migrated onto core's gate-house standard)

loop_state: landed

Executes `docs/issue-10/proposals/security-threat-model.md` (approved) against
the defect inventory in `docs/issue-10/reports/security-threat-model/survey.md`.
Infrastructure remediation of this role's own enforcement machinery — like
issue-7, not a fresh threat-modelling exercise — so this record follows
`docs/issue-7/reports/security-threat-model.md`'s shape rather than carrying a
threat table of its own.

## What was done

Mapped to survey.md's confirmed defect inventory, 1.1–1.7.

**1.1 kill-switch fail-open (6/6 gates) — fixed.** Every gate's hand-rolled
`case "${..._GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac` — which
disabled the gate on *any* unrecognized value, including a typo — is replaced
by `gate_kill_switch_active "${..._GATE_OFF:-}" || { trap - EXIT; exit 0; }`.
The hand-rolled `__fc`/`trap __fc EXIT` pair is likewise replaced by
`gate_trap_fail_closed`, sourced from core before `set -uo pipefail` so an
abort on the next line is still forced to exit 2. Files:
`security-threat-model/hooks/sequence-gate.sh` and the five
`security-threat-model-{stride,risk-rating,mitigation,residual-signoff,canon-citation}/hooks/methodology-gate.sh`.

**1.2 hand-rolled Edit/MultiEdit reconstruction, `replace_all` ignored (5/5
methodology gates) — fixed.** Each embedded Python judge loads core's Python
helper by path via `importlib` from the `GATE_LIB_PY` env var that sourcing
gate-lib.sh exports, and calls `gate_reconstruct_write(tool, ti, current)` in
place of its own `current.replace(o, n, 1)` chain. Each edit's own
`replace_all` is now honoured, and `NotebookEdit` is covered for the day the
`Write|Edit|MultiEdit` matcher is widened. `sequence-gate.sh` reconstructs no
content (it checks path and survey existence only) and correctly gets no
reconstruction call.

**1.3 STRIDE sequence check incomplete — fixed.**
`security-threat-model-stride/hooks/methodology-gate.sh` enforced only
`asset-inventory -> stride-table` and `trust-boundary-map -> stride-table`.
The third pairwise ordering (`asset_pos > boundary_pos`) now feeds the same
`missing_order` list and the same single deny call, so the three-way order the
gate's own header comment documents is mechanically enforced for the first
time.

**1.4 semantic checks were substring-only — upgraded to structural.** Two
changes in the stride gate:

- Marker location: `find_marker`'s "first bare occurrence of the token
  anywhere" fallback is gone. A marker now counts only as a markdown heading
  (`^#{1,6}[ \t]*.*\btoken\b`) or a line-start field marker
  (`^[ \t]*token[ \t]*:`). A mid-sentence prose mention no longer satisfies
  it, closing survey.md s1.4's false positive.
- Category tagging: the section-wide `has_name`/`has_initial` scan (one word
  anywhere satisfied the entire table) is replaced by per-row checking. The
  section is split into markdown table rows (lines starting with `|`) or, when
  the section has no table, list-item rows (`-`, `*`, `<digit>.`); the table's
  own header and separator rows are exempt; every remaining row must carry a
  STRIDE category name or an isolated initial, and the deny names the first
  untagged row (1-indexed within the section) plus its text. A section with
  zero rows passes structurally — "the field must be non-empty" belongs to
  core's record-fields gate, not this one.

**1.5 `deny-only-check.sh` / `parse-check.sh` defaults targeted the wrong role
(6/6 test dirs) — fixed.** `../coding/hooks` became `..` (each plugin's own
`hooks/` directory, matching how the file's own top-level `dir` argument
already defaults) and `docs/issue-999/reports/coding.md` became
`docs/issue-999/reports/security-threat-model.md`, in all six
`hooks/tests/deny-only-check.sh` and all six `hooks/tests/parse-check.sh`.
Nothing else in those two canon copies was touched. See Open findings for what
this changed about the substance probe's failure mode.

**1.6 absolute-path / `./`-prefix normalization — migrated and now covered.**
Each gate's dual bash `_under()` + inline-Python `resolve()` pair is replaced
by one `gate_normalize_path(root, path)` call inside the Python judge, which is
now the single source of truth for in-root/out-of-root; `None` maps onto each
gate's existing "not this gate's business, exit 0" branch. Per proposal s3 the
bash-side `_plausible()`/root-detection half is unchanged. Absolute,
`./`-prefixed, and outside-root paths are now asserted in every plugin's test
suite (previously unexercised in CI).

**1.7 deny-reason stderr delivery — confirmed, unchanged.** Every gate still
writes its reason to stderr and exits 2; no gate emits a permission grant.
`deny-only-check.sh`'s grep half confirms this on all six plugins after the
migration.

**Test suites (proposal s8).** Each plugin gained
`hooks/tests/run-gate-lib-tests.sh` covering the six mandatory cases against
its own gate: Edit with `replace_all: true` over a multiply-occurring
`old_string` (fixtures built so the verdict flips unless every occurrence is
replaced); MultiEdit mixing `replace_all` true/false in one call; malformed
JSON (truncated, non-object, empty); a kill switch holding an unrecognized
value asserted to stay ACTIVE (plus a recognized off-spelling, plus the
on-spelling that really does disable); an absolute `file_path` and a
`./`-prefixed one resolving into the same scope as the relative fixture, plus
an outside-root path; and a Bash-tool write to the same target asserted to be
a deliberate, documented no-op, since these matchers are `Write|Edit|MultiEdit`
only. The stride plugin additionally carries the three regressions for 1.3 and
1.4: asset-inventory placed after the trust-boundary map, a mid-sentence
marker mention, and one untagged row among tagged ones.

`tests/run-gate-tests.sh` (repo root, the entrypoint) now resolves
`CLAUDE_PLUGIN_ROOT_CORE` the way the runtime does, then runs its own
cross-plugin cases followed by each plugin's `run-gate-lib-tests.sh` and
`parse-check.sh`.

**README sync (proposal s9).** `README.md` documented three hook files that do
not exist in this tree (`record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`) and listed only the base plugin. It now lists all
six plugins with their real gate script and their real kill-switch env var,
the per-plugin directory shape as it actually is, the repo-root files, and the
core dependency. Structure and tone kept; no rewrite.

## Why

The upstream basis is core issue #72, which landed `gate-lib.sh`/`gate-lib.py`
and `docs/handbooks/gate-house-standard.md` after finding that every gate in
core's own canon had independently re-derived the same trap, kill-switch,
path-normalize and reconstruct machinery — in two or three idioms each, with
confirmed live bugs. This plugin set was written before that library existed
and carried the same six independent copies, including the two bug classes the
standard names: a kill switch that fail-opens on any unrecognized value, and a
reconstruction that always replaces the first occurrence regardless of
`replace_all`. Both are silent: the gate keeps running and keeps returning a
verdict, just on a document that was never going to be written, or on no
document at all. Re-deriving fixes locally would have reproduced exactly the
divergence issue #72 exists to end, so the whole set adopts the library by
reference instead, and `compliance-check.sh` — core's own detector — is the
acceptance criterion rather than this role's self-assessment.

The two stride-specific upgrades answer the issue's own requirement that a
methodology judgment must not be satisfiable by a word appearing somewhere.
Position comparison already made ordering structural; the missing third
pairwise check made it incomplete, and marker-as-heading plus per-row tagging
move the remaining two checks from "the token occurs" to "the section exists
and every row in it is tagged".

## Evidence

`compliance-check.sh` from core, run against each plugin's `hooks/` directory
after the migration — verbatim output:

```
### security-threat-model/hooks
compliance-check: ok — .../security-threat-model/hooks/sequence-gate.sh
rc=0
### security-threat-model-stride/hooks
compliance-check: ok — .../security-threat-model-stride/hooks/methodology-gate.sh
rc=0
### security-threat-model-mitigation/hooks
compliance-check: ok — .../security-threat-model-mitigation/hooks/methodology-gate.sh
rc=0
### security-threat-model-canon-citation/hooks
compliance-check: ok — .../security-threat-model-canon-citation/hooks/methodology-gate.sh
rc=0
### security-threat-model-residual-signoff/hooks
compliance-check: ok — .../security-threat-model-residual-signoff/hooks/methodology-gate.sh
rc=0
### security-threat-model-risk-rating/hooks
compliance-check: ok — .../security-threat-model-risk-rating/hooks/methodology-gate.sh
rc=0
```

(Absolute paths abbreviated to `...` for width; the detector prints the full
path of each gate it clears.) Before the migration the same command reported
`FAIL` on all six — the kill-switch finding on 6/6 gates and the
reconstruction finding on the 5/5 methodology gates, exactly the violation
counts proposal s10 step 1 predicted.

Full suite, `tests/run-gate-tests.sh`: green.

```
== cross-plugin cases: 22 passed, 0 failed ==
== security-threat-model: run-gate-lib-tests.sh ==        14 passed, 0 failed
== security-threat-model-stride: run-gate-lib-tests.sh == 21 passed, 0 failed
== security-threat-model-mitigation: ... ==               14 passed, 0 failed
== security-threat-model-canon-citation: ... ==           14 passed, 0 failed
== security-threat-model-residual-signoff: ... ==         14 passed, 0 failed
== security-threat-model-risk-rating: ... ==              14 passed, 0 failed
== ALL SUITES GREEN ==
```

`parse-check.sh` passes on all 5 shell files under each of the six plugins'
`hooks/` directories.

## What did not work

The generated per-plugin suites first ran with `set -uo pipefail`, and every
"kill switch on-spelling disables the gate" case reported `exit-141` instead of
`allow`. The gate was correct: it exits 0 immediately without draining stdin,
so the feeding `printf` takes SIGPIPE, and `pipefail` surfaced 141 as the
pipeline's status. Fixed by dropping `pipefail` in those harnesses, with the
reason stated in each file rather than left as folklore.

One existing repo-root case, `stride-no-category`, asserted deny on a section
whose body was the prose line `no category here`. Under the per-row rule that
section has zero rows and passes by design (proposal s5.2 states this
explicitly). The fixture now states an actual untagged row, and a companion
`stride-no-rows` case pins the zero-row behaviour so it cannot regress
silently in either direction.

## Open findings

`deny-only-check.sh`'s copied `substance_probe` still reports FAIL on all six
plugins, but for a different and now-honest reason. Before this issue it
pointed at a non-existent `../coding/hooks` sibling, found zero gate scripts,
printed "no gate scripts under ..." and returned 0 — a vacuous pass. With the
defaults corrected it now really does invoke each plugin's real gate against
this role's real record path, and those gates allow the probe's
`nothing here` payload because every gate in this set is conditional: each
fires only when its own marker is present in the write. The probe expects an
unconditional record-substance gate, which is core's record-fields gate's job,
not this plugin set's. Carried forward from
`docs/issue-7/reports/security-threat-model.md`'s Open findings; the probe is
deliberately not wired into `tests/run-gate-tests.sh`'s green gate, and the
substantive half of the same file (no permission-granting verdict anywhere)
passes on all six plugins.

The `Write|Edit|MultiEdit` matchers are unchanged, so a Bash-tool write to a
record path is still uninspected by every gate in this set. That boundary is
now asserted in all six suites rather than merely true, so widening a matcher
cannot land silently unguarded; core's `gate_bash_write_targets` is the
function that would extract the path tokens when it is.

No other findings outstanding.

## Canon references

Referenced by path and description only; no canon script content is reproduced
in this repo or in this record.

- `core/hooks/lib/gate-lib.sh` (core issue-72) — the sourced shell library
  supplying `gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`,
  `gate_allow`, `gate_bash_write_targets`, and the `GATE_LIB_PY` export. Every
  gate in this plugin set sources it; none vendors it.
- `core/hooks/lib/gate-lib.py` — the Python helper loaded via `importlib`,
  supplying `gate_parse_json_or_deny`, `gate_normalize_path`, and
  `gate_reconstruct_write`.
- `core/docs/handbooks/gate-house-standard.md` — the migration checklist this
  execution followed and the six mandatory test cases each plugin's
  `run-gate-lib-tests.sh` implements.
- `core/hooks/tests/compliance-check.sh` — the detector run before and after
  the migration; its post-migration output is quoted in Evidence above.
- `core/hooks/tests/run-gate-lib-tests.sh` — reference harness shape for the
  six cases, adapted independently per plugin.
- `docs/issue-10/proposals/security-threat-model.md` — the approved plan this
  record executes, section by section.
