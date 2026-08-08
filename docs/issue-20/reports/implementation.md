---
code_under_review:
  - docs/handbooks/security-threat-model.md
  - security-threat-model-stride/hooks/methodology-gate.sh
  - security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh
  - security-threat-model/hooks/record-fields.env
loop_state: landed
---

# issue-20 phase-2 implementation record

## What was done

Layered `roles/specs/security-threat-model.spec.json`'s (marketplace,
`tokenmaxxxer/on-the-record`, issue #521) per-claim evidence vocabulary
onto this rulebook's existing methodology docs/handbooks/hooks, per the
approved `docs/issue-20/proposals/implementation-proposal.md`:

1. `docs/handbooks/security-threat-model.md` — added a "Per-threat fields
   (issue-20)" paragraph under the `security-threat-model-stride`
   subsection naming all seven spec fields (`element`, `type`, `title`,
   `description`, `severity`, `status`, `mitigation`) explicitly and
   mapping each onto the existing `stride-table` row shape; pointed at
   the marketplace-side `role-spec-reference-guard.sh` (by
   path/description only, per the canon-citation no-copy discipline) for
   `element` reference-resolution, and noted `recomputation`'s
   `checked_by: TBD` status as an out-of-scope marketplace follow-up.
   Named the marketplace's 4-state `loop_state` set
   (`modeling`/`landed`/`trust-boundary-undetermined`/`spec-unreadable`)
   verbatim under the `hooks/record-fields.env` bullet, replacing the
   prior implicit "no terminal-loop_state divergence... yet" note.
2. `security-threat-model-stride/hooks/methodology-gate.sh` — extended
   the existing per-row STRIDE-tag check (`type`) to also deny the first
   `stride-table` row missing any of `element`/`title`/`description`/
   `status`/`mitigation`. A field counts as present via a header column
   whose name contains the field word (case-insensitive) with a
   non-empty cell on that row, or via an inline `field:`/`field=` token
   anywhere in the row text; list-item rows (no header row exists) use
   the inline-token route only. This is a distinct cell/inline grammar
   from the section-marker (heading / line-start `token:`) grammar the
   gate already uses for `stride-table`/`asset-inventory`/
   `trust-boundary-map` — reusing the section-marker grammar unmodified
   at the row level would deny every table row unconditionally, per the
   phase-1 hunt finding recorded in
   `docs/reports/2026-08-09-hunt-implementation-proposal.md`
   (`after-proposal` section) and already resolved in commit `16cc872`.
3. `security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh` —
   updated `ALLOW_CONTENT`/`S4_GOOD` (list-item rows) to carry all five
   inline field tokens, updated `S52_GOOD` (table row) to carry a header
   naming all five fields with non-empty cells, and added two new cases:
   a table row with an empty `mitigation` cell denies, and a list-item
   row with all five inline `field:` tokens allows.
4. `security-threat-model/hooks/record-fields.env` — comment-only change;
   names the marketplace's 4-state `loop_state` set explicitly as the set
   this role has no terminal divergence from. `RECORD_FIELDS_REQUIRED`
   unchanged (no role-scope change, per the proposal's constraint).

## Why

Reason: issue #20 requires this rulebook's methodology docs/handbooks/
hooks to align with the landed marketplace spec's per-claim evidence
vocabulary (required fields, `loop_state` set), without changing this
role's scope — mirroring the completed execution-observation-rulebook
#63/PR#66 pattern for the sibling role, per the approved proposal's
Rationale: the spec's seven fields are inherently per-threat-row data,
so checking them once per whole record (the rejected alternative) would
not catch a record with several threat rows and only one naming a
`mitigation` value, defeating the acceptance check's intent.

## Doctrine ladder / completed items

- [x] `docs/handbooks/security-threat-model.md` updated same turn as the
  hook change it documents (per-row field mapping + `loop_state` set).
- [x] No new dependency, env var, migration, or setup step introduced —
  nothing else on the doctrine ladder applies.

## Acceptance checks

1. **Every required-field name appears in methodology/handbook docs**:
   `grep -woE 'element|type|title|description|severity|status|mitigation'
   docs/handbooks/security-threat-model.md | sort -u` → all seven names
   present (`description`, `element`, `mitigation`, `severity`, `status`,
   `title`, `type`). PASS.
2. **`loop_state` vocabulary set-diff**: marketplace set (per
   `docs/issue-20/reports/implementation/survey.md`'s spec fetch) =
   `{modeling, landed, trust-boundary-undetermined, spec-unreadable}`.
   `grep -noE 'modeling|landed|trust-boundary-undetermined|
   spec-unreadable' docs/handbooks/security-threat-model.md
   security-threat-model/hooks/record-fields.env` → all four states
   present in both files. Set-diff (rulebook docs/hooks vs. marketplace
   `roles/security-threat-model.json`'s `record_fields.loop_state`):
   **empty** — no field in either set is missing from the other. PASS.
3. **`python3 -m pytest -q`**: `unverifiable: no test suite present` —
   `find . -name '*.py' -o -name 'pytest.ini' -o -name 'conftest.py'`
   finds nothing in this repo; this matches survey.md's pre-existing
   finding, not a regression introduced by this change.
4. **Gate test suites still pass**:
   `security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh` run
   directly (with `CLAUDE_PLUGIN_ROOT_CORE` resolved to
   `~/tokenmaxxxer/tokenmaxxxer-core/core`) → `24 passed, 0 failed`
   (includes the two new issue-20 per-row-field cases). `tests/
   run-gate-tests.sh` (repo root) run directly → all `run-gate-lib-tests.sh`
   and `deny-only-check.sh`/`directive.sh` groups pass; the six
   `parse-check.sh` invocations fail with "no such file or directory" —
   this is the pre-existing state left by commit `4576ebf` ("canon
   rollout: remove vendored parse-check.sh, reshape directive.sh stubs"),
   confirmed via `git show 4576ebf --stat`, predates this issue's branch
   point, and is unrelated to and untouched by this change's write set.

## What did not work

None.

## Hunt record

Two dispatches, per `docs/reports/2026-08-09-hunt-implementation-proposal.md`:
- **after-proposal** (phase 1, stance 3 — "assume the rule as written
  cannot hold — find the state nothing maintains"): FINDING — the
  proposal's proposed reuse of the section-marker (heading/line-start
  `token:`) grammar for per-row field checks cannot hold, since no real
  `stride-table` row in this repo's own fixtures is simultaneously a
  table row and a line-start marker. Resolved in this commit by giving
  the per-row check its own cell/inline grammar (header-column match, or
  an inline `field:`/`field=` token anywhere in the row) distinct from
  the section-marker grammar, exactly as the proposal's step 2
  anticipated as the needed resolution.
- **before-landing** (phase 2, stance 1 — "assume this change and
  another plugin's rule cancel each other — find the pair"): NO FINDING.
  Checked the new per-row field check against
  `security-threat-model-risk-rating`'s `[dread-override]` marker check
  and `security-threat-model-mitigation`'s `mitigation-list`
  disposition-vocabulary check on a synthetic record — no cancellation
  or swallowing between gates; each evaluated independently and
  correctly.

## Upstream basis

`docs/issue-20/proposals/implementation-proposal.md` (approved), based on
`docs/issue-20/reports/implementation/survey.md` (scout skipped —
closed-enum landed spec, skip condition stated in survey.md). Approval
given via the issue-level comment `APPROVE issue-20/implementation`
(single-account mode, exact string match, from `docs/specs/approvers.md`
account `JiwonJung94`).

## Open findings

None open. Both hunt dispatches resolved — see Hunt record above.

closed_checks:
- name: acceptance-check-1-required-field-grep
  code_sha: pending-this-commit
- name: acceptance-check-2-loop-state-set-diff
  code_sha: pending-this-commit
- name: acceptance-check-4-gate-test-suites
  code_sha: pending-this-commit
- name: warrant-hunt-before-landing-stance-1
  code_sha: pending-this-commit
