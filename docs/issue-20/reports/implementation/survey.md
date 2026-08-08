# issue-20 current-state survey

Scout: skipped. Skip condition — the spec (`roles/specs/security-threat-model.spec.json`,
`on-the-record` main, fetched via `gh api`) is a landed, closed-enum
artifact with no open design choice on what fields exist; the only
decision here is *how* to layer its vocabulary onto this rulebook's
existing structures, which issue-20 and the execution-observation-rulebook
#63/#66 precedent (mirrored explicitly by this issue) already settle.
The one live design point (row-level vs. section-level field placement) is
covered under Rationale in the proposal, not scouted externally.

## Spec fetched (source of truth)

`gh api repos/tokenmaxxxer/on-the-record/contents/roles/specs/security-threat-model.spec.json`
(main branch):

- `required_fields`: `element` (ref), `type` (enum: Spoofing, Tampering,
  Repudiation, Information Disclosure, Denial of Service, Elevation of
  Privilege), `title` (string), `description` (string), `severity`
  (string, free text — no closed vocabulary), `status` (string, free
  text — no closed vocabulary), `mitigation` (string).
- `reference_resolution`: `element` must resolve to an actual
  system/data-flow element named elsewhere in the same record — no orphan
  refs. `severity`/`status` are deliberately free text (Threat Dragon
  schema carries them as present fields with no closed vocabulary; an
  invented enum would violate the marketplace proposal's no-invented-enum
  constraint). Checked by (marketplace-side) `role-spec-reference-guard.sh`.
- `recomputation`: overall risk verdict must be derived per-threat
  (residual risk = post-mitigation severity as stated, per threat), never
  asserted as one standalone summary field independent of the listed
  threats. `checked_by` is `TBD` — issue-521 marks per-role recomputation
  enforcement as an explicit marketplace follow-up, not yet built.
- `write_scope`: `["docs/issue-<n>/reports/security-threat-model.md"]` —
  unchanged from this rulebook's current scope.
- `loop_state`: `progress: [modeling]`, `terminal: [landed]`,
  `refusal: [trust-boundary-undetermined]`, `error: [spec-unreadable]`.
- `use_when.board_condition`: "a spec or design doc landed that
  introduces a new trust boundary, authentication surface, or
  sensitive-data flow AND no security-threat-model record exists yet for
  it" — matches `roles/security-threat-model.json`'s `use_when` verbatim
  (cross-checked via `gh api .../contents/roles/security-threat-model.json`).

## This rulebook's current state

- `docs/handbooks/security-threat-model.md` — describes the six-plugin
  split (base + stride + risk-rating + mitigation + residual-signoff +
  canon-citation) and each plugin's one owned judgment. No mention of
  `element`, `type` (as a per-threat field distinct from the STRIDE
  category tag the stride plugin already checks), `title`, `description`,
  `status`, `severity` (present, but only as "CVSS-style qualitative
  severity scale"), or `mitigation` (present, as `mitigation-list`
  disposition vocabulary) as named per-claim fields. Grep result
  (`grep -no -e element -e '\btype\b' -e '\btitle\b' -e description -e
  severity -e '\bstatus\b' -e mitigation docs/handbooks/security-threat-model.md`):
  only `severity`, `description`, `mitigation` appear — `element`,
  `type`, `title`, `status` appear zero times. This is the acceptance
  check's mismatch: 4 of 7 required-field names are entirely absent from
  the handbook today.
- `security-threat-model/hooks/record-fields.env` — `RECORD_FIELDS_REQUIRED`
  is `asset-inventory,trust-boundary-map,stride-table,mitigation-list,
  residual-risk-note,canon-references` — section-level fields, not the
  spec's per-threat-row fields. `RECORD_FIELDS_TERMINAL_STATES` is unset
  (comment: "No terminal-loop_state divergence exists for this role yet").
- `loop_state` vocabulary (`modeling`/`landed`/`trust-boundary-undetermined`/
  `spec-unreadable`): a repo-wide grep (`grep -rn "loop_state\|modeling\|
  landed\|trust-boundary-undetermined\|spec-unreadable" docs
  security-threat-model*`, excluding prior issues' own historical
  proposal/report text) finds only `landed` — used as a generic
  contract-v3 terminal-state mention in `docs/issue-2/reports/
  implementation.md` and the handbook's "No terminal loop_state
  divergence" note, never as part of a stated 4-state set. `modeling`,
  `trust-boundary-undetermined`, and `spec-unreadable` appear nowhere in
  this rulebook's docs or hooks. This is the second acceptance check's
  mismatch: the marketplace's 4-state set is not named anywhere for this
  role to diverge from or match against explicitly.
- `security-threat-model-stride/hooks/methodology-gate.sh` — already
  checks that every `stride-table` row carries one of the six STRIDE
  category names (or an isolated initial). This is the same closed enum
  as the spec's `type` field, just not named `type` and not paired with
  the sibling per-row fields (`element`, `title`, `description`, `status`,
  `mitigation`) the spec expects alongside it.
- `security-threat-model-canon-citation/hooks/methodology-gate.sh` — the
  existing pattern for "reference marketplace gates rather than forking
  rule logic": `canon-references` cites external canon (core's `warrant/`
  plugin, sibling gates) by path/description, never by pasting script
  content. The spec's `reference_resolution.checked_by:
  role-spec-reference-guard.sh` and `recomputation.checked_by: TBD` are
  marketplace-side scripts this rulebook does not own or fork — the
  existing canon-citation discipline is the template for how to point at
  them.
- Tests: `tests/run-gate-tests.sh` chains each plugin's
  `hooks/tests/run-gate-lib-tests.sh` + `deny-only-check.sh` +
  `parse-check.sh`/`directive.sh` checks — no `pytest`/Python test suite
  exists anywhere in this repo (`find . -name '*.py' -o -name 'pytest.ini'
  -o -name 'conftest.py'` finds nothing). `python3 -m pytest -q` has
  nothing to collect: acceptance check 3's `unverifiable: no test suite
  present` branch applies.

## Write set this issue expects to touch (frozen, for the proposal)

- `docs/handbooks/security-threat-model.md` — name the seven required
  fields explicitly, tie them to the existing stride-table row structure,
  name the 4-state `loop_state` vocabulary, and reference (not fork) the
  marketplace's `role-spec-reference-guard.sh`/recomputation follow-up.
- `security-threat-model-stride/hooks/methodology-gate.sh` — extend the
  existing per-row STRIDE-tag check to also require the sibling per-row
  markers (`element`/`title`/`description`/`status`/`mitigation`), staying
  inside the plugin that already owns stride-table row shape.
- `security-threat-model/hooks/record-fields.env` — no field-name change
  planned (section-level fields stay as-is per no-scope-change); comment
  update only, naming the spec's loop_state set explicitly instead of
  "no terminal loop_state divergence... yet."
- `docs/issue-20/reports/implementation.md` — phase-2 record (written only
  after Approve, per contract v3 s19).

No new dependency, no new env var, no migration. Existing kill-switch
mechanism (`SECURITY_THREAT_MODEL_STRIDE_GATE_OFF` etc.) is unaffected.
