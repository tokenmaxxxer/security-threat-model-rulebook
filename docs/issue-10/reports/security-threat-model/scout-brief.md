# scout-brief — issue-10 gate A+ remediation

Mode: this deliverable is an internal-canon compliance migration (core
issue #72's gate-house-standard, already landed and prescriptive — see
survey.md s2), not a product-shaped build with an external market. Per
scout-directive, a non-product role scouts "the best of its own
deliverable's kind" — here that is: how core's own gates, and any sibling
rulebook, already did this exact migration. Stages used: 1 (single
precedent check, no parallel fan-out needed — only one comparable-system
category exists: gates already migrated to gate-lib.sh). Batched-sequential
(single session, sequential greps/reads), stated explicitly per the
fallback-disclosure rule.

## What was checked
`core/hooks/board-gate.sh` (cached checkout), one of core's own seven
gates migrated as part of issue-72 itself — the highest-signal precedent
available, since it's the canon's own author applying gate-lib.sh to a
gate with comparable shape (path/root resolution, fail-closed trap,
ownership rules) to this plugin's gates.

## Must-bes (from the precedent + gate-house-standard.md)
- Fail-closed trap installed as the very first statement, before
  `set -uo pipefail` (gate_trap_fail_closed's own doc: catches a syntax
  error on the next line too).
- Kill switch checked via `gate_kill_switch_active`, never a hand-rolled
  case statement (this is the exact bug class this issue's gates carry).
- Deny-only, stderr-only messages, `role: refused — reason` shape —
  already true in this plugin's gates (survey.md s1.7); precedent
  confirms the same shape, so no change needed there beyond keeping it
  through the migration.

## Performance axes observed
- **Path resolution** delegated entirely to `gate_normalize_path`
  (Python) rather than hand-rolled bash+python duplication — this
  plugin's gates currently hand-roll `_under()`/`resolve()` twice (bash
  wrapper + python judge) doing overlapping work; the precedent
  centralizes it once.
- **Content reconstruction** (this plugin's gates need this, core's
  board-gate.sh does not — board-gate only inspects paths, not resulting
  text) is exactly what `gate_reconstruct_write` exists for; no
  comparable precedent inside core's own gates to adopt from, since none
  of core's seven gates inspect resulting document content the way this
  plugin's methodology gates do. This axis is unique to this plugin
  among available comparables — flagged as a **gap**, not copied from a
  precedent.

## Adopt / skip
- **Adopt**: sourcing `gate-lib.sh` once at the top of each gate script
  and using `gate_trap_fail_closed`/`gate_kill_switch_active`/`gate_deny`
  in place of the current hand-rolled equivalents (direct precedent from
  board-gate.sh).
- **Skip**: rewriting the bash-side `_target` extraction or `_plausible`
  root-detection heuristic — board-gate.sh's own root-detection is
  materially the same shape already in use here; the issue's audit did
  not flag it as broken, and gate-lib.sh does not supply a bash-side
  root-finder to replace it with, so leave it as-is rather than
  inventing an unreviewed replacement.

## Segment fit
This plugin's gates are one class ahead of core's simplest gates
(board-gate.sh) in complexity: they must reconstruct write content, which
board-gate.sh never needs. The precedent covers the shared floor
(trap/kill-switch/deny) fully; the content-reconstruction and
semantic-check work (survey.md s1.2-1.4) has no sibling-rulebook
precedent to snowball from within reach of this scout's budget — proposal
treats those as first-party design per gate-house-standard's documented
`gate_reconstruct_write` contract, not as copied from an exemplar.

## Gap line
Already meets: fail-closed trap shape, deny-only/stderr messaging,
Write/Edit/MultiEdit tool-name coverage. Missing against the standard:
`gate_kill_switch_active` usage (6/6 gates), `gate_reconstruct_write`
usage (5/5 methodology gates), `gate_normalize_path` usage (6/6 gates,
currently hand-rolled), the mandatory six-case test harness (0/6
plugins currently have it), and `compliance-check.sh` clean run (not yet
attempted — compliance-check.sh itself is not available in this sandbox's
network-restricted core checkout to run directly; proposal treats "run it
in phase 2, in an environment with core plugin access" as an open
execution step, not a phase-1 blocker).

Sources:
- `/tmp/claude-1000/core-check/docs/handbooks/gate-house-standard.md` (cached core canon doc, read this session)
- `/tmp/claude-1000/core-ref/gate-lib.sh`, `/tmp/claude-1000/core-ref/gate-lib.py` (cached core canon library, read this session)
- `core/hooks/board-gate.sh` from a cached core checkout under a sibling session's scratchpad (`/tmp/claude-1000/.../localization-rulebook-issue-10-localization/.../scratchpad/core-repo/core/hooks/board-gate.sh`), read this session
