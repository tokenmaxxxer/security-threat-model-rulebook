# Current-state survey — issue #22

## Canonical convention (on-the-record #551)

`docs/specs/test-env-resolution.md` in `tokenmaxxxer/on-the-record`
defines the resolution order: (1) `$CLAUDE_PLUGIN_ROOT_CORE` if it
contains a non-empty `hooks/lib/gate-lib.sh`; (2) the first
caller-supplied sibling-checkout candidate containing the same file;
(3) otherwise **SKIP** — print
`SKIP: core plugin unreachable — unverifiable outside spawn env` to
stderr, exit `75` (`EX_TEMPFAIL`), distinct from a gate's own
`0`/`1`/`2`. Reference implementation ships as
`gates/test_env_resolve.py` (`resolve_core()` + CLI:
`python3 -m gates.test_env_resolve <candidates...>`). Bash test runners
are told to invoke it as a subprocess and branch on exit code 0 vs 75.
One enumerated exception: a test suite that never resolves core at all
is out of scope for the convention.

## Write set surveyed

Scripts in this repo that resolve `CLAUDE_PLUGIN_ROOT_CORE` today, all
via a hand-rolled, near-identical block (env var check -> two hardcoded
sibling-candidate paths -> `echo ... >&2; exit 1` on miss — a plain
failure, not a SKIP):

- `tests/run-gate-tests.sh:17-26` — repo-root runner; resolves core once
  before dispatching to per-plugin suites.
- `security-threat-model/hooks/tests/run-gate-lib-tests.sh:27-36`
- `security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh` (same
  block, same line range)
- `security-threat-model-mitigation/hooks/tests/run-gate-lib-tests.sh`
- `security-threat-model-canon-citation/hooks/tests/run-gate-lib-tests.sh`
- `security-threat-model-residual-signoff/hooks/tests/run-gate-lib-tests.sh`
- `security-threat-model-risk-rating/hooks/tests/run-gate-lib-tests.sh`

All seven scripts currently print an error to stderr and `exit 1` when
core is unreachable — indistinguishable from a real assertion failure
(the runner's own `report()`/`[ "$fail" -eq 0 ]` path also exits
non-zero on a genuine regression). This is exactly the issue's
complaint: outside spawn env, `exit 1` reads as "gate under test
regressed" when it actually means "core plugin not on this checkout."

## Scripts NOT in scope (verified, not just assumed)

- `hooks/tests/deny-only-check.sh` (one copy per plugin, byte-identical
  per its own comment "every rulebook copies this file verbatim"):
  greps for `permissionDecision` and fires each `*-gate.sh` directly
  against a temp git repo. Never sources `CLAUDE_PLUGIN_ROOT_CORE` or
  core's `gate-lib.sh` — matches the convention's enumerated exception
  (a suite that never resolves core is out of scope). No change needed
  here; noted, not silently dropped.
- `hooks/tests/parse-check.sh` — referenced by
  `tests/run-gate-tests.sh:155` (`/bin/bash "$ROOT/$p/hooks/tests/parse-check.sh"`)
  but does not exist anywhere in the repo (`find . -iname
  parse-check.sh` returns nothing). This is a pre-existing broken
  reference unrelated to test-env resolution — out of scope for this
  issue; flagging as a real defect per the issue's own empty-state
  instruction ("if a script's failure is a REAL defect, record it as a
  finding — do not mask it with SKIP"), not something this proposal's
  write set will fix.

## Consumer shape

Every in-scope script is a **bash test runner** invoking gate scripts as
subprocesses (never a pytest suite) — this repo has no Python test
suite (`python3 -m pytest -q` collects nothing, confirmed by
issue-20's prior survey). The convention's "Bash test runner" adoption
path applies: invoke the reference module as a CLI and branch on exit
code, `0` -> proceed using the printed path, `75` -> treat the whole
script's run as SKIPPED (print the convention's message, exit 75 in
turn) rather than as a pass or fail.

## Constraint: no vendored core, no network fetch

This repo already avoids vendoring core (`hooks/*.sh` source
`gate-lib.sh` via `CLAUDE_PLUGIN_ROOT_CORE` "referenced by path, never
vendored" per issue-10). The convention's reference resolver
(`gates/test_env_resolve.py`) lives in the on-the-record repo, not
here, and the spec explicitly forbids a network-fetch fallback as part
of the canonical SKIP contract. So this repo cannot literally
`python3 -m gates.test_env_resolve` (that module is not on disk here)
— it must inline the same resolution ORDER and SKIP CONTRACT (the
env var, hardcoded/caller-supplied sibling candidates already present
in each script, then print-and-exit-75) directly in bash, matching the
convention's behavior without importing a foreign Python package this
repo has no dependency path to.

## Alternative considered

Add a real dependency on the on-the-record repo's `gates` Python
package (via a path or git-checkout wrapper) and shell out to
`python3 -m gates.test_env_resolve` from each script, as the "Bash test
runner" adoption path literally describes. Rejected: it would require
either vendoring on-the-record's `gates/` package into this repo (this
repo's own stated practice is never to vendor another repo's
canon — see the core `gate-lib.sh` precedent above) or adding a
cross-repo filesystem dependency on `on-the-record` being checked out
at a guessable sibling path, which is exactly the kind of environment
assumption issue #22 is about removing. Inlining the resolution order
and SKIP contract in bash — the same order, same message text, same
exit code 75 — achieves the convention's behavior without a new
dependency edge this repo cannot make reliable.
