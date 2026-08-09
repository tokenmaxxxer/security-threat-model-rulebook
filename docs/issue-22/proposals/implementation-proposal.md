---
status: proposed
files:
  - tests/run-gate-tests.sh
  - security-threat-model/hooks/tests/run-gate-lib-tests.sh
  - security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh
  - security-threat-model-mitigation/hooks/tests/run-gate-lib-tests.sh
  - security-threat-model-canon-citation/hooks/tests/run-gate-lib-tests.sh
  - security-threat-model-residual-signoff/hooks/tests/run-gate-lib-tests.sh
  - security-threat-model-risk-rating/hooks/tests/run-gate-lib-tests.sh
  - docs/issue-22/reports/implementation.md
---

## Request

Issue #22: adopt the canonical test-env resolution convention landed at
on-the-record `docs/specs/test-env-resolution.md` (issue #551) across
this rulebook's gate-test scripts. Outside the spawn env (no
`CLAUDE_PLUGIN_ROOT_CORE`, core plugin unreachable), every such script
must SKIP with an explicit message and a distinct exit code instead of
failing in a way indistinguishable from a real regression. Assertions
that run when core IS reachable must not weaken.

## Constraints

- Every script must exit `75` (`EX_TEMPFAIL`) and print
  `SKIP: core plugin unreachable — unverifiable outside spawn env` to
  stderr when core cannot be resolved — the exact message and exit code
  the convention specifies, so the contract is machine-checkable the
  same way in every consumer.
- Resolution order must match the convention exactly: env var first,
  then caller-supplied sibling candidates, then SKIP. No network fetch
  fallback (the convention explicitly excludes this from the canonical
  contract).
- No vendoring the on-the-record `gates` Python package into this repo
  (survey.md's rejected-alternative reasoning) — the order and SKIP
  contract are inlined in bash, matching behavior without a new
  cross-repo dependency.
- `tests/run-gate-tests.sh` dispatches to each plugin's
  `run-gate-lib-tests.sh` as a subprocess (`tests/run-gate-tests.sh:148`);
  when the top-level runner itself SKIPs it must not also attempt to
  invoke those subprocesses (they would independently SKIP and
  double-print), so the SKIP path short-circuits before dispatch.
- Do not touch `hooks/tests/deny-only-check.sh` (verified: never
  resolves core — the convention's own enumerated exception) or
  `hooks/tests/parse-check.sh` (verified: does not exist on disk; a
  pre-existing broken reference in `tests/run-gate-tests.sh`, unrelated
  to test-env resolution) — both out of scope per the acceptance
  criteria's own empty-state instruction to record a real defect rather
  than mask it with SKIP.
- Every touched script's SKIP path and every other in-scope script must
  reference the convention doc, satisfying the acceptance check "scripts
  reference the convention doc (grep for test-env-resolution)".

## Rationale

**Chosen approach**: replace each script's existing
`echo ... >&2; exit 1` miss-path with the convention's SKIP contract
(same resolution order already coded, new terminal behavior), inlined
in bash rather than shelling out to the on-the-record Python module.

**Alternative considered and rejected** (recorded in survey.md's
"Alternative considered" section): shell out to
`python3 -m gates.test_env_resolve <candidates...>` from each script,
as the convention's "Bash test runner" adoption path literally
describes, and branch on its exit code. Rejected because that module
lives in the on-the-record repo, not this one — using it here would
require either vendoring on-the-record's `gates/` package (this repo's
established practice is never to vendor another repo's canon; see the
`CLAUDE_PLUGIN_ROOT_CORE`/`gate-lib.sh` precedent) or hardcoding a
guessable sibling checkout path for on-the-record itself, which
reproduces the exact "assumes a checkout it can't rely on" problem
issue #22 exists to remove. Inlining the same order, message, and exit
code in bash gets the convention's actual guarantee (SKIP, not a
misleading failure) without a new fragile cross-repo dependency edge.

## What will be done

- In each of the 7 listed scripts, replace the current
  `if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] || [ ! -f
  "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]; then echo ... >&2;
  exit 1; fi` miss-path with:
  `echo "SKIP: core plugin unreachable — unverifiable outside spawn env" >&2; exit 75`
  — leaving the existing env-var-then-sibling-candidates resolution
  order above it unchanged (it already matches the convention's order 1
  and 2).
- Add a one-line comment at each resolution block citing
  `docs/specs/test-env-resolution.md` (on-the-record #551) as the
  convention being followed, satisfying the grep-based acceptance
  check.
- In `tests/run-gate-tests.sh`, propagate the top-level SKIP: when core
  resolution misses at the top, exit 75 immediately (current behavior
  already stops before dispatching to per-plugin suites — the change is
  only the message/exit-code swap plus the same short-circuit already
  in place at that line).
- Leave every assertion that runs once core IS resolved completely
  unchanged — no gate-test case, fixture, or expected verdict is
  touched.
- Write the phase-2 implementation record at
  `docs/issue-22/reports/implementation.md` once work lands.

## Out of scope

- `hooks/tests/deny-only-check.sh` and `hooks/tests/parse-check.sh`
  (see Constraints).
- Any change to gate logic itself (`*-gate.sh`, `gate-lib.sh` usage at
  runtime) — this issue is test-harness-only.
- Fixing `parse-check.sh`'s missing-file reference — recorded as a
  finding in the phase-2 record's open findings, not fixed here.
- Adding a real dependency on the on-the-record `gates` Python package
  (see Rationale's rejected alternative).

## How you'll know it worked

- On a plain checkout with `CLAUDE_PLUGIN_ROOT_CORE` unset and no
  sibling core candidate present, running each of the 7 scripts prints
  the exact SKIP message to stderr and exits 75.
- With `CLAUDE_PLUGIN_ROOT_CORE` pointed at a real core checkout (spawn
  env), all 7 scripts run their existing assertions unchanged and exit
  0/1 exactly as before this change.
- `grep -rl test-env-resolution tests/ security-threat-model*/hooks/tests/`
  matches all 7 in-scope scripts.
