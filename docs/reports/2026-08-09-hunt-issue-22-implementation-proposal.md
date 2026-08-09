---
proposal: docs/issue-22/proposals/implementation-proposal.md
---

# Hunt record — issue-22-implementation-proposal

## after-proposal — stance 2: assume this guard goes silent when its own input is malformed — make it go silent.

Verdict: FINDING — the planned detection predicate `[ ! -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]` (unchanged by the proposal, only its miss-path message/exit code changes) treats a present-but-empty/unsourceable gate-lib.sh as "core reachable"; the harness then proceeds normally, sources the empty file (which succeeds with no error and defines nothing), and every gate under test silently fails OPEN — 10 of 15 mandatory gate-house-standard deny-cases return `allow` instead of `deny`, with no SKIP message, no exit 75, and no FAIL bubbling to the suite's "cannot locate" path.
Kind: silent-failure
Seed: docs/issue-22/proposals/implementation-proposal.md (plan text, line 81: `[ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] || [ ! -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]` reused verbatim as the sole reachability check, only the miss-path body at line 83 is planned to change to the SKIP/exit-75 contract) plus current code at security-threat-model/hooks/tests/run-gate-lib-tests.sh (same predicate today, one of the 7 scripts named in scope) and security-threat-model/hooks/sequence-gate.sh (`. "$CORE/hooks/lib/gate-lib.sh" || { echo ...; exit 2; }` — sourcing an empty file returns 0, so the `||` never fires either).
cap_seconds: 60
tier: default
diff_stat_lines: 2 files, both new (proposal ~130 lines, survey ~unknown lines) — docs-only commit
started_at: 2026-08-09T09:35:00+09:00
ended_at: 2026-08-09T09:47:00+09:00

### Reproduce
```
mkdir -p "$TMPDIR/fakecore/hooks/lib" && touch "$TMPDIR/fakecore/hooks/lib/gate-lib.sh"
env CLAUDE_PLUGIN_ROOT_CORE="$TMPDIR/fakecore" bash security-threat-model/hooks/tests/run-gate-lib-tests.sh
```

### Observed
```
FAIL   baseline: a would-be-refused write denies                        want=deny got=allow
FAIL   Edit replace_all:true over a multiply-occurring old_string is judged on ALL occurrences want=deny got=allow
FAIL   MultiEdit mixing replace_all true/false honours each edit own flag want=deny got=allow
FAIL   malformed JSON: truncated payload denies                         want=deny got=allow
FAIL   malformed JSON: non-object top level denies                      want=deny got=allow
FAIL   malformed JSON: empty payload denies                             want=deny got=allow
FAIL   kill switch set to an unrecognized value (typo) stays ACTIVE     want=deny got=allow
FAIL   kill switch set to a recognized OFF-spelling stays ACTIVE        want=deny got=allow
FAIL   absolute file_path resolves to the same scope as the relative fixture want=deny got=allow
FAIL   ./-prefixed file_path resolves to the same scope as the relative fixture want=deny got=allow

== 5 passed, 10 failed ==
EXIT:1
```
No "SKIP: core plugin unreachable" message and no exit 75 appear anywhere — the harness believed core was reachable (the `-f` test passed on the empty file) and ran the full suite, which then reports ordinary FAIL lines rather than the loud, unambiguous unreachable-core signal the SKIP contract is meant to guarantee. (Today it at least prints ordinary FAIL lines and exits 1 from the harness's `[ "$fail" -eq 0 ]`; but nothing distinguishes "core is broken" from "the gate under test regressed" — a maintainer or CI dashboard collapsing on exit-code alone, or the top-level `tests/run-gate-tests.sh` propagating this per-plugin subprocess's exit code, sees the same shape as a real gate defect, not the SKIP-worthy "core unreachable" condition the proposal is trying to make loud.) Adopting the proposed SKIP/exit-75 contract does nothing to close this: the reachability check that decides whether to take the SKIP branch at all still only asks `-f`, so a zero-byte or truncated/corrupted gate-lib.sh — the "unreadable" case the dispatcher explicitly asked about — never reaches the SKIP branch and keeps producing this silent-fail-open cascade indistinguishable from real test failures.

### Expected
The proposal's reachability check (both in the top-level runner and in each of the 7 per-plugin `run-gate-lib-tests.sh`) should verify gate-lib.sh is non-empty and actually sourceable (e.g. `bash -n` parse check, or a post-source check that a known function like `gate_trap_fail_closed` is defined) before concluding "core reachable" and skipping the SKIP branch — otherwise a corrupted/zero-byte core install silently downgrades every gate to fail-open with no SKIP marker at all.
