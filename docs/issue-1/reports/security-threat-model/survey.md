# Issue #1 — Phase 1 Current-State Survey

Role: `security-threat-model`. Scope: what this rulebook currently asks for
(record fields, hand-off, directive text) vs. what a domain-grounded
methodology/document-structure norm should require, per issue #1's mandate
to found phase-1 proposal norms and phase-2 record norms on actual
domain research rather than intuition.

## 1. What exists now in this repo

| Path | Relevant content |
|---|---|
| `security-threat-model/hooks/directive.sh` | `PRODUCES="STRIDE table, mitigation list per threat, residual risk note"`. This already names STRIDE and a residual-risk concept, but does not specify a risk-rating scheme (how "risk" on a threat is scored), does not mention assets/trust-boundaries/DFD as required inputs, and does not define what "mitigation list" must contain per threat (control description? owner? residual status?). |
| `security-threat-model/hooks/record-fields.env` | `RECORD_FIELDS_REQUIRED="stride-table,mitigation-list,residual-risk-note"` — the enforced field set for the phase-2 record, mechanically gated by core's record-fields gate. Same three fields as directive.sh; no asset-inventory or trust-boundary field is enforced today. |
| `security-threat-model/agents/warrant-hunter.md` | References core's `warrant/` plugin (core issue #63) for the rotating-stance background hunt; role-unique mandate is "신뢰 경계의 위협 표면" (trust-boundary threat surface) and hand-off to secure-coding (implementation-stage vuln checks) / legal-compliance (legal exposure). Confirms trust boundaries are this role's stated focus, but the plugin doesn't yet define what evidence a trust-boundary claim needs (e.g. a DFD). |
| `docs/handbooks/security-threat-model.md` | Operational handbook; documents hook wiring but has no methodology content — describes *how* gates fire, not *what* a valid record must analytically contain. |
| `security-threat-model/.claude-plugin/plugin.json` | Role description mirrors directive.sh's decides/use_when/hand-off text; no methodology reference. |
| `docs/specs/approvers.md` | Confirms `JiwonJung94` as the single-account approver who can Approve phase 2 per contract v3 s19 — relevant to this proposal's plugin-reflection plan's gate-condition design, not to methodology itself. |

No `docs/issue-1/` tree existed before this survey; this is the first work
on issue #1.

## 2. Established convention from prior issue (issue #2)

`docs/issue-2/reports/implementation/survey.md` +
`docs/issue-2/proposals/core-canon-reference-conversion.md` set the format
this repo uses for phase-1 work:
- `docs/issue-<n>/reports/<topic>/survey.md` — current-state findings,
  file-by-file, with an explicit "no local precedent found" callout where
  applicable.
- `docs/issue-2/proposals/<slug>.md` — a proposal doc that opens with a
  "Status: proposal only — phase 1 ... gated on approvers.md Approve per
  contract v3 s19" banner, organized into itemized work items, each with a
  rationale and a "TBD in phase 2" callout where information isn't
  reachable from this repo alone.
This survey and the accompanying proposal at
`docs/issue-1/proposals/security-threat-model.md` follow the same shape,
plus adding a scout-brief step (issue #1 explicitly asks for a broader
external-methodology sweep than issue #2 needed, since issue #2 was an
internal refactor and issue #1 is a domain-research mandate).

## 3. "Canon" reference search

Searched the repo for any vendored canon/core threat-modeling content:
`grep -ril canon` and `find -iname '*canon*'` surface only
`docs/issue-2/proposals/core-canon-reference-conversion.md` (issue #2's own
title) and the `security-threat-model/hooks/directive.sh` comment
referencing "core canon reference conversion" — no actual canon script
content (e.g. `core/hooks/lib/role-directive.sh`) is vendored into this
repo; that lives in the external `core` repo referenced by core issues
#63/#66, not reachable from here. Per issue #1's constraint, this survey
and the proposal reference that external canon only by path/description
(e.g. "core's `warrant/` plugin", "`core/hooks/lib/role-directive.sh`") and
do not copy its content.

## 4. Gaps a scout pass should target

1. **Methodology selection**: is STRIDE (already named in `PRODUCES`) the
   right default for a trust-boundary-focused role, or should it be paired
   with attack trees / a DFD-first approach (PASTA-style) given the
   mandate explicitly names trust boundaries rather than a specific
   application's business risk?
2. **Risk-rating scheme**: neither DREAD nor CVSS nor any qualitative
   likelihood/impact matrix is currently specified for scoring rows in the
   "STRIDE table" — this is a genuine gap since "mitigation list" and
   "residual risk note" both presuppose some risk score to mitigate down
   from.
3. **Required document structure**: industry practice for a threat-model
   deliverable typically requires an asset inventory and a
   trust-boundary/DFD section as prerequisites to a threat table — this
   repo's `RECORD_FIELDS_REQUIRED` has neither field today.
4. **Phase-1 proposal norms for this domain**: what counts as sufficient
   "logical reason the methodology fits the role's intended value" per the
   issue's own phrasing — needs grounding in how mature orgs justify
   methodology choice and how they gate phase-1 proposals (required
   sections, citation format) before committing to phase-2 required
   fields.
5. **Canon-reference mechanics**: exactly how phase-2's plugin encoding of
   these norms should point at core canon (e.g. whether `record-fields.env`
   is the right layer to add new required fields, or whether directive.sh's
   `PRODUCES` string and the handbook also need parallel updates) is not
   fully knowable without confirming core's generalized record-fields gate
   contract — flagged as a phase-2 TBD, consistent with issue #2's own
   precedent of flagging core-contract unknowns rather than guessing.

These five gaps are what the scout brief
(`docs/issue-1/reports/security-threat-model/scout-brief.md`) and the
proposal (`docs/issue-1/proposals/security-threat-model.md`) address.
