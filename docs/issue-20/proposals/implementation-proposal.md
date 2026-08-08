---
status: proposed
files:
  - docs/handbooks/security-threat-model.md
  - security-threat-model-stride/hooks/methodology-gate.sh
  - security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh
  - security-threat-model/hooks/record-fields.env
  - docs/issue-20/reports/implementation.md
---

## Request

Marketplace issue #521 landed `roles/specs/security-threat-model.spec.json`
in `tokenmaxxxer/on-the-record` — a closed-enum spec naming this role's
required per-threat fields (`element`, `type`, `title`, `description`,
`severity`, `status`, `mitigation`), a reference-resolution rule
(`element` must resolve to a named element, no orphan refs), a
recomputation rule (residual risk derived per-threat, never asserted as
one free-standing summary), and a 4-state `loop_state` set
(`modeling` / `landed` / `trust-boundary-undetermined` /
`spec-unreadable`). Align this rulebook's methodology docs, handbooks,
and hooks with that landed spec — layering its evidence vocabulary onto
the existing six-plugin structure, not changing role scope, and pointing
at marketplace-side enforcement (`role-spec-reference-guard.sh`) rather
than re-implementing it here. Mirrors the completed
execution-observation-rulebook #63/PR#66 pattern for the sibling role.

## Constraints

- No role scope change: the six-plugin split, each plugin's one owned
  judgment, and `write_scope`
  (`docs/issue-<n>/reports/security-threat-model.md`) all stay as-is.
- No invented enum for `severity`/`status` — the spec states explicitly
  these are free text in the Threat Dragon source schema; inventing a
  closed vocabulary for either would violate the marketplace proposal's
  own no-invented-enum constraint (survey.md, spec fetch).
- Reference marketplace gates, never fork their logic: `role-spec-
  reference-guard.sh` (reference_resolution) and the recomputation
  check (currently `TBD` upstream, per issue-521) are marketplace-owned;
  this rulebook cites them by path/description, the same discipline the
  existing `canon-citation` plugin already enforces for other external
  canon.
- Stay inside the plugin that already owns the affected judgment: STRIDE
  per-row shape belongs to `security-threat-model-stride`, not a new
  plugin or the base plugin.
- `python3 -m pytest -q` has nothing to collect in this repo (survey.md:
  no Python test suite exists) — the phase-2 record states
  `unverifiable: no test suite present` for that acceptance check rather
  than fabricating a run.

## Rationale

**Chosen approach**: extend `security-threat-model-stride`'s existing
per-row STRIDE-tag check (it already walks every `stride-table` row
looking for one of the six STRIDE category names) to also require the
spec's sibling per-row markers — `element`, `title`, `description`,
`status`, `mitigation` — on the same row, and name all seven field words
explicitly in the handbook so the acceptance grep passes. `severity`
already appears in the risk-rating plugin's prose; it gets an explicit
field-name mention alongside the others rather than a new mechanism.

**Alternative considered and rejected**: add the seven spec fields as a
*new*, separate `RECORD_FIELDS_REQUIRED` section-level entry (e.g. a
`per-claim-fields` marker checked once per record) instead of touching
the STRIDE plugin's row-level check. Rejected because the spec's fields
are inherently per-threat-row data (each `stride-table` row already
*is* one threat claim carrying a category, a description, and a
mitigation) — checking them only once per whole record would not catch
a record with five threat rows and only one of them naming a `mitigation`
value, which defeats the acceptance check's intent (every required-field
name present *and meaningfully tied to each claim*, not just present
once anywhere in the file as a decoy). Layering onto the plugin that
already owns row shape also keeps one plugin owning one judgment, per
this role's existing split — a new section-level field would duplicate
the STRIDE plugin's existing walk-every-row logic in a second place.

## What will be done

1. `docs/handbooks/security-threat-model.md`: under the
   `security-threat-model-stride` subsection, name the spec's seven
   required fields explicitly and state how each maps onto the existing
   `stride-table` row shape (`type` = the existing STRIDE category tag;
   `element`, `title`, `description`, `status`, `mitigation` = new
   per-row requirements). Add one paragraph under the base-plugin
   subsection naming the marketplace's 4-state `loop_state` set
   verbatim and stating this role has no current terminal-state
   divergence from it (matching `record-fields.env`'s existing
   comment, now naming the set instead of leaving it implicit). Add a
   sentence pointing at `role-spec-reference-guard.sh` (marketplace-side,
   referenced by path only) for `element` reference-resolution, and
   noting the recomputation rule's `checked_by: TBD` status is a
   marketplace follow-up this rulebook does not need to build.
2. `security-threat-model-stride/hooks/methodology-gate.sh`: extend the
   existing per-row walk (already denies naming the first row missing a
   STRIDE category tag) to also deny naming the first row missing any of
   `element`/`title`/`description`/`status`/`mitigation` as a
   line-start `field:` marker or equivalent inline label — same
   marker-detection discipline the file's docstring already states for
   `stride-table`/`asset-inventory`/`trust-boundary-map` (heading or
   `token:` field marker, never mid-sentence prose). Kill switch stays
   `SECURITY_THREAT_MODEL_STRIDE_GATE_OFF`.
3. `security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh`: add
   cases exercising the new per-row field checks (present/absent) inside
   the existing seven-case suite shape.
4. `security-threat-model/hooks/record-fields.env`: update the comment
   only — name the spec's 4-state `loop_state` set explicitly as the
   set this role currently has no terminal divergence from, replacing
   the current implicit "no terminal-loop_state divergence... yet" note.
   `RECORD_FIELDS_REQUIRED` itself is unchanged (no scope change).
5. `docs/issue-20/reports/implementation.md`: phase-2 record, written
   only after human Approve, per contract v3 s19 — not part of this
   phase-1 commit.

## Out of scope

- Building the recomputation `checked_by` mechanism — issue-521 states
  this is `TBD`, an explicit marketplace-side follow-up once real-usage
  evidence shows which roles need it. Not this rulebook's job to build
  ahead of that.
- Forking or vendoring `role-spec-reference-guard.sh` into this repo —
  referenced by path only, per the canon-citation plugin's existing
  no-copy discipline.
- Any change to `write_scope`, the six-plugin split, or which plugin
  owns which judgment.
- Inventing a closed enum for `severity` or `status`.
- A new Python/pytest test suite — none exists today, and adding one is
  not part of aligning with the spec's field vocabulary.

## How you'll know it worked

- `grep` for each of the seven required-field names (`element`, `type`,
  `title`, `description`, `severity`, `status`, `mitigation`) against
  this rulebook's methodology/handbook docs exits 0 for every field
  (acceptance check 1).
- `grep -o` for the marketplace's 4-state `loop_state` vocabulary
  (`modeling`, `landed`, `trust-boundary-undetermined`, `spec-unreadable`)
  against this rulebook's docs/hooks, with the set-diff against
  `roles/security-threat-model.json`'s `record_fields.loop_state` shown
  as empty in the phase-2 record (acceptance check 2).
- `python3 -m pytest -q` exits 0, or (as expected here, per survey.md) the
  phase-2 record states `unverifiable: no test suite present`
  (acceptance check 3).
- `security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh` and
  `tests/run-gate-tests.sh` (repo root) still pass after the per-row
  field-check extension, with new cases covering the added fields.
