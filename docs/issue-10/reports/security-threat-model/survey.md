# issue-10 phase-1 survey — gate A+ remediation

Scope: audit-confirmed defects in this plugin set's PreToolUse gates
(`security-threat-model/hooks/sequence-gate.sh` and the five methodology
gates under `security-threat-model-{stride,mitigation,canon-citation,
residual-signoff,risk-rating}/hooks/methodology-gate.sh`) plus the shared
test harnesses under each plugin's `hooks/tests/`.

## 1. Confirmed defect inventory (read against current tree)

### 1.1 Kill-switch fail-open (all 6 gates)
Every gate uses the pre-issue-72 idiom:
```
case "${..._GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
```
Any unrecognized value — not just the intended on-spellings
(`1|true|yes|on`) — falls into `*) exit 0`, silently disabling the gate.
Present verbatim in `sequence-gate.sh` and all five `methodology-gate.sh`
files (grep-confirmed, 6/6 hits).

### 1.2 Edit/MultiEdit reconstruction hand-rolled, `replace_all` ignored (5/5 methodology gates)
Each methodology gate reconstructs the post-write text itself:
```python
elif tool == "Edit":
    o, n = ti.get("old_string"), ti.get("new_string")
    if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
        new_text = current.replace(o, n, 1)
elif tool == "MultiEdit":
    ...
        text = text.replace(o, n, 1)
```
Always replaces the first occurrence only, regardless of the real call's
`replace_all` field, and does not handle `NotebookEdit` at all. Matches
gate-house-standard.md's bug class 2 exactly. `sequence-gate.sh` does not
reconstruct content (it only checks path/existence), so this defect is
scoped to the 5 methodology gates, not the sequence gate.

### 1.3 Sequence check incomplete (`security-threat-model-stride/hooks/methodology-gate.sh`)
The order check only enforces `asset-inventory -> stride-table` and
`trust-boundary-map -> stride-table` independently:
```python
if asset_pos is None: missing_order.append(...)
elif asset_pos > stride_pos: missing_order.append(...)
if boundary_pos is None: missing_order.append(...)
elif boundary_pos > stride_pos: missing_order.append(...)
```
`asset_pos > boundary_pos` (asset inventory appearing after the trust
boundary map) is never checked — matches the issue's "asset->boundary
미강제" finding precisely. The three-way order `asset-inventory ->
trust-boundary-map -> stride-table` is documented in the gate's own
header comment but only two of the three required pairwise orderings are
enforced in code.

### 1.4 Semantic check is substring-only (`security-threat-model-stride/hooks/methodology-gate.sh`)
`find_marker` locates headings via regex but falls back to "first bare
occurrence of the token anywhere" — a `stride-table` mentioned in prose
(e.g. "관련 stride-table 논의는 나중에") satisfies the marker. The STRIDE
category check (`has_name`/`has_initial`) scans the whole section text
for any of six words or a bare S/T/R/I/D/E letter — a stray letter (e.g.
inside "Design", "State", "Elevation" used off-topic) or a single mention
of "Spoofing" anywhere in an otherwise-empty section satisfies "at least
one category tag," which is a much weaker bar than "every stride-table
row must carry a STRIDE category tag" (the gate's own cited rule). This
is the issue's "'단어 언급'으로 통과" finding: presence of a word, not
structural/row-level presence.

### 1.5 `deny-only-check.sh` substance probe targets the wrong role (6/6 test dirs)
Every plugin's `hooks/tests/deny-only-check.sh` carries:
```bash
probe_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../coding/hooks" && pwd -P)}"
rec_rel="docs/issue-999/reports/coding.md"
```
`../coding/hooks` and `reports/coding.md` are the `implementation`/coding
rulebook's paths, not this plugin's. In this tree there is no
`coding/hooks` sibling directory, so `substance_probe`'s `find "$probe_dir"
-name '*-gate.sh'` finds nothing, prints "no gate scripts under
$probe_dir", and `return 0` — the probe silently passes without ever
exercising a real gate. `parse-check.sh` has the same copy-pasted default
(`../coding/hooks`), though it is less consequential there since the
directory argument is normally passed explicitly by the test runner.
Matches the issue's "deny-only-check 기본 경로가 implementation 복붙"
finding.

### 1.6 Path matching not exercised for absolute paths / `./`-prefix (all 6 gates)
`_under()`/`resolve()` in each gate do call `posixpath.normpath` and
`os.path.realpath`, and code-reading suggests absolute and `./`-prefixed
paths already resolve correctly relative to `root`. No test in
`hooks/tests/` currently exercises this path, so it is unverified in CI —
the issue explicitly asks for "경로 매칭(절대경로 정규화)" as an item to
fix, and for absolute-path/`./`-prefix as mandatory test cases per
gate-house-standard's harness. Treated here as "add coverage," not "known
broken," since no live absolute-path bug was found in the current
`resolve()`/`_under()` bodies — but this needs verification once
`gate_normalize_path` replaces the hand-rolled version, since behavior
must not regress.

### 1.7 Deny reason delivery
All 6 gates already write deny reasons to stderr only, in a
`role: refused — reason` shape (`deny()` closures), and never emit
`permissionDecision: "allow"`. `deny-only-check.sh`'s grep-based check
already guards the "no allow" half. Cross-checked: no gate currently
prints a bare exit 2 without a message. This item in the issue ("deny
사유 stderr 전달") reads as already-satisfied in the current tree; the
proposal below folds it into the mandatory-case migration rather than
inventing new work, and confirms it stays true post-migration since
`gate_deny` (core canon) also writes to stderr only.

## 2. Prerequisite check — core issue #72

`core/hooks/lib/gate-lib.sh` and `gate-lib.py` are landed (per issue
body's precondition and confirmed against a cached core checkout):
`gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`,
`gate_allow`, `gate_bash_write_targets` (bash); `gate_parse_json_or_deny`,
`gate_normalize_path`, `gate_reconstruct_write` (python, loaded via
`importlib` using `GATE_LIB_PY`). `docs/handbooks/gate-house-standard.md`
documents the migration checklist (compliance-check.sh -> migrate ->
re-run tests -> re-run compliance-check.sh -> file the A+ issue) and the
six mandatory test-harness cases. This repo's own migration (this issue)
follows that checklist; canon is referenced by path in the proposal, per
[[security-threat-model-canon-citation]] discipline — never pasted.

## 3. Write-surface map for phase 2 (informational, not yet executed)

- `security-threat-model/hooks/sequence-gate.sh` — kill switch (1.1),
  path/root resolution (1.6) only; no content reconstruction needed
  (doesn't inspect resulting text).
- `security-threat-model-{stride,mitigation,canon-citation,
  residual-signoff,risk-rating}/hooks/methodology-gate.sh` — kill switch
  (1.1), reconstruction (1.2), path/root resolution (1.6); stride gate
  additionally needs 1.3 and 1.4.
- All 6 `hooks/tests/deny-only-check.sh` and `hooks/tests/parse-check.sh`
  — fix probe_dir/rec_rel defaults (1.5); each plugin also needs a copy of
  the six-case `run-gate-lib-tests.sh` suite adapted to its own gate(s),
  per gate-house-standard's harness requirement.
- `README.md` (repo root) — issue asks for ghost-file removal and
  actual-plugin/path/kill-switch documentation; not yet read against the
  6 real kill-switch env vars for drift (deferred to phase-2 execution,
  named here so proposal scope includes it).

## Scout record

Ran a scoped scout (this is infra migration against a fixed internal
canon, not a product-shaped deliverable — see scout-brief.md for the one
precedent check performed and why a full 4-angle sweep was not
warranted).
