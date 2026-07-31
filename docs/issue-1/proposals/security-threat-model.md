# Issue #1 — Proposal: Security Threat-Model Methodology & Deliverable Norms

Status: **proposal only — phase 1.** No plugin/rulebook file is changed by
this document; it is gated on `docs/specs/approvers.md`'s Approve per
contract v3 s19 before phase 2 (encoding these norms into
`directive.sh`/`record-fields.env`/the handbook) may proceed. This proposal
does not write, and must not write, the phase-2 record file itself
(`docs/issue-1/reports/security-threat-model.md`) — that file is phase-2's
own deliverable, produced by whoever executes an approved phase-2, using
the norms below.

This proposal is grounded in:
- `docs/issue-1/reports/security-threat-model/survey.md` (current-state
  survey of this repo)
- `docs/issue-1/reports/security-threat-model/scout-brief.md` (external
  field-norm scout brief, with sources)

## (a) Phase-1 proposal norms for this domain, going forward

Every future phase-1 proposal for this role (i.e. any issue that revises
this role's methodology, required fields, or directive text) should
contain:

1. **A current-state survey** (`docs/issue-<n>/reports/<topic>/survey.md`)
   enumerating exactly which files/fields are affected today, following
   the file-by-file table format established in
   `docs/issue-2/reports/implementation/survey.md`.
2. **A scout brief** (`docs/issue-1/reports/security-threat-model/
   scout-brief.md`-style, or a similarly named sibling file for future
   issues) whenever the proposal introduces or revises a *methodology* or
   *risk-rating scheme* choice — not required for purely mechanical/
   refactor-only proposals (issue #2 did not need one, since it moved
   already-decided content, not decided new content).
3. **Explicit citation format**: every claim about "how the field does X"
   must carry a URL in a trailing `Sources:` list (as in the scout brief
   above) — no unsourced "industry practice says" assertions. This is the
   evidence bar issue #1 itself asks for ("감이 아니라 도메인 조사에 근거").
4. **A gap line**: one paragraph stating current repo state vs. the
   external norm vs. what's missing, so the proposal's rationale is
   auditable against both ends without re-deriving it from prose.
5. **Rationale tied to sources, not restated preference**: each adopted
   choice must trace to a specific scout-brief citation and to a specific
   gap-line item — see part (c) below for how this proposal itself does
   that.

## (b) Phase-2 deliverable norms (what the phase-2 record must contain)

The phase-2 record (`docs/issue-1/reports/security-threat-model.md`, not
written here) should be required to contain the following sections/fields,
replacing and extending the current `RECORD_FIELDS_REQUIRED=
"stride-table,mitigation-list,residual-risk-note"`:

1. **`asset-inventory`** — a table of assets/data covered by the review,
   each with a classification (critical/important/non-critical or
   equivalent), per the NIST SP 800-154 data-centric principle and the
   generic risk-assessment-template norm (scout brief, "Document
   structure").
2. **`trust-boundary-map`** — a DFD or equivalent diagram/table naming
   trust boundaries in scope (machine, privilege, integrity boundaries or
   role-specific equivalents), consistent with this role's own mandate
   text ("신뢰 경계의 위협 표면") and Microsoft SDL's DFD/trust-boundary
   convention (scout brief, Microsoft SDL section).
3. **`stride-table`** (kept, refined) — one row per identified threat,
   each row tagged with its STRIDE category, the trust boundary/asset it
   applies to (foreign key into the two sections above), and a required
   **`risk-rating`** cell.
4. **`risk-rating` scheme** — CVSS-style qualitative severity
   (Critical/High/Medium/Low, derived from likelihood × impact) as the
   default; a documented DREAD-style qualitative override is permitted
   only for findings that are architectural/trust-boundary-shaped with no
   CVE-like vector, and the override must be noted inline in the row (not
   silently mixed with CVSS-style rows without a marker).
5. **`mitigation-list`** (kept) — one entry per threat row, each stating
   the control and which of accept/mitigate/transfer/avoid it represents,
   per the generic risk-assessment-template norm.
6. **`residual-risk-note`** (kept, refined) — the post-mitigation risk
   rating (same scheme as `risk-rating`) plus an explicit sign-off
   reference: this repo's own contract v3 s19 Approve gate
   (`docs/specs/approvers.md`) already supplies the "formal sign-off
   acknowledging residual risk" the field norm requires, so this field
   should simply record which approver Approved and when, rather than
   inventing a separate sign-off mechanism.
7. **`canon-references`** — any reliance on external canon (e.g. core's
   `warrant/` plugin for the rotating-stance hunt) must be cited by
   path/description only, per issue #1's own no-copy constraint; this
   field makes that citation explicit and auditable in the record itself,
   rather than leaving it implicit in hook wiring.
8. **Attack-tree attachments (optional, not required)** — any `stride-table`
   row whose exploit path is non-obvious may attach an attack-tree
   sketch; this is a "may attach," not a gated required field, since
   requiring it on every row would over-constrain simple findings (scout
   brief, "Adopt optionally").

## (c) Rationale, tied to sources and the gap line

- STRIDE retained as the enumeration framework because it is (i) already
  in this role's `PRODUCES` field, (ii) DFD/trust-boundary native per
  Microsoft's own tooling convention, and (iii) directly matches the
  role's stated mandate of trust-boundary threat surfaces — see scout
  brief's STRIDE and Microsoft SDL entries.
- PASTA explicitly not adopted as primary: its added business-impact/
  attacker-simulation stages fit a `write_scope` beyond this role's `[]`
  and would duplicate work this role's own hand-off already routes
  elsewhere (secure-coding for implementation-level vulns, legal-compliance
  for legal exposure) — see scout brief PASTA entry and this role's
  existing hand-off text in `directive.sh`.
- `asset-inventory` and `trust-boundary-map` added as new required fields
  because the survey's gap-line item 3 found neither exists in
  `RECORD_FIELDS_REQUIRED` today, while every external template/framework
  surveyed treats an asset inventory and a trust-boundary/DFD artifact as
  a precondition to a valid threat table (scout brief "Document structure"
  and NIST SP 800-154 entries) — without them, `stride-table` rows have no
  well-defined subject.
- CVSS-style `risk-rating` chosen over DREAD-only because DREAD's
  assessor-inconsistency problem is explicitly documented in the scout
  brief's methodology comparison, while CVSS is the more standardized
  industry default; DREAD is kept only as a marked override for
  non-vulnerability-shaped architectural findings, closing survey gap-line
  item 2 (no risk-rating scheme existed before this proposal).
- Sign-off routed through the existing `docs/specs/approvers.md` Approve
  gate rather than a new mechanism, because that gate already
  structurally satisfies the "formal sign-off acknowledging residual
  risk" norm found in the scout brief's review/gating-norms section — no
  new gate needed, only a pointer field (`residual-risk-note`'s approver
  reference).
- `canon-references` added because issue #1's own constraint (canon by
  reference, never by copy) is currently only honored implicitly in hook
  comments (survey section 3); making it an explicit record field closes
  that gap and gives phase-2's completeness gate something concrete to
  check.

## (d) Plugin reflection plan (phase-2 encoding, concrete)

This section is the phase-2 execution plan; nothing in it is applied by
this phase-1 PR.

1. **`security-threat-model/hooks/record-fields.env`** —
   change `RECORD_FIELDS_REQUIRED` from
   `"stride-table,mitigation-list,residual-risk-note"` to
   `"asset-inventory,trust-boundary-map,stride-table,mitigation-list,residual-risk-note,canon-references"`.
   Add a comment naming the risk-rating scheme requirement (CVSS-style
   default, DREAD-style marked override) since it lives *inside*
   `stride-table`/`residual-risk-note` cells rather than as its own
   top-level gated field — the gate only checks field presence, not
   per-row rating-scheme conformance, so this comment is documentation for
   whoever authors the phase-2 record, not a mechanically enforced rule.
2. **`security-threat-model/hooks/directive.sh`** — update `PRODUCES` from
   `"STRIDE table, mitigation list per threat, residual risk note"` to
   `"asset inventory, trust boundary map (DFD), STRIDE table with
   CVSS-style risk rating per threat, mitigation list per threat
   (accept/mitigate/transfer/avoid), residual risk note with approver
   reference, canon references"` — keeps the SessionStart directive text
   in sync with the enforced field set so an operator sees the same
   requirement whether they read the directive or the gate config.
3. **`docs/handbooks/security-threat-model.md`** — add a "Methodology"
   subsection (currently absent — the handbook only documents hook
   wiring) stating: STRIDE is the enumeration framework, CVSS-style
   qualitative severity is the default risk-rating scheme with a marked
   DREAD-style override for non-vulnerability-shaped findings, and
   linking to this proposal + the scout brief as the rationale trail, so
   a future reader doesn't need to re-derive the "why" from git history
   alone.
4. **Gate condition for phase-2 completeness** — no new gate script is
   proposed; core's existing generalized record-fields gate (per
   `docs/handbooks/security-threat-model.md`'s description of core issue
   #66's landing) already fails closed on any of the six
   `RECORD_FIELDS_REQUIRED` entries being absent from the phase-2 record.
   Phase 2 execution should confirm (per issue #2's own precedent of
   flagging core-contract unknowns) whether that gate does simple
   substring/field-presence checking only, or can be extended to check
   internal cross-references (e.g. every `stride-table` row citing a valid
   `trust-boundary-map` entry) — if the latter isn't supported, that
   remains a manual-review item at the contract v3 s19 Approve step, not
   a blocking gap for phase-2 to first land the field-presence version.
5. **`security-threat-model/agents/warrant-hunter.md`** — no change
   proposed; its existing role-unique mandate and hand-off text already
   match the trust-boundary framing this proposal retains.
