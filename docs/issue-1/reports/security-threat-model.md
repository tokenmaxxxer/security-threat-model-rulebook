# Issue #1 — Phase 2 record: rulebook maturation (plugin reflection)

## What was done

Encoded the approved phase-1 proposal
(`docs/issue-1/proposals/security-threat-model.md`) into this role's
plugin, per its part (d) plan:

1. `security-threat-model/hooks/record-fields.env` —
   `RECORD_FIELDS_REQUIRED` changed from
   `"stride-table,mitigation-list,residual-risk-note"` to
   `"asset-inventory,trust-boundary-map,stride-table,mitigation-list,residual-risk-note,canon-references"`,
   with a comment noting the CVSS-default/DREAD-override risk-rating
   scheme lives inside cell content, not as its own gated field.
2. `security-threat-model/hooks/directive.sh` — `PRODUCES` updated to
   `"asset inventory, trust boundary map (DFD), STRIDE table with
   CVSS-style risk rating per threat, mitigation list per threat
   (accept/mitigate/transfer/avoid), residual risk note with approver
   reference, canon references"`, matching the new gated field set.
3. `docs/handbooks/security-threat-model.md` — added a "Methodology"
   section stating STRIDE as the enumeration framework, CVSS-style
   default risk rating with marked DREAD-style override, and the
   sign-off/canon-reference norms, linking back to the proposal and scout
   brief.
4. `security-threat-model/agents/warrant-hunter.md` — no change, per
   proposal (d).5: its existing role-unique mandate/hand-off text already
   matches the retained trust-boundary framing.
5. No new gate script added — core's existing generalized record-fields
   gate (core issue #66) already fails closed on any of the six
   `RECORD_FIELDS_REQUIRED` entries being absent; whether it can also
   check internal cross-references (e.g. every `stride-table` row citing
   a valid `trust-boundary-map` entry) beyond field presence remains
   unconfirmed (core repo not checked out here) and stays a manual-review
   item at the contract v3 s19 Approve step, not a blocking gap.

This record itself is the first artifact produced under the new field
set, demonstrating the six required fields below.

## Why

Reason: issue #1 requires the approved phase-1 proposal's methodology and
required-field norms to be enforced, not just documented — per the
proposal's own gap-line and rationale (part (c)), STRIDE stays the
enumeration framework, CVSS-style rating is the default with a marked
DREAD-style override, and asset-inventory/trust-boundary-map/
canon-references close gaps the phase-1 survey found in the prior
three-field set. This record demonstrates the new required-field set in
practice, which is itself part of what phase 2 is expected to prove out.

## asset-inventory

| Asset | Classification |
| --- | --- |
| `security-threat-model/hooks/record-fields.env` (gate config) | important — controls what phase-2 records for this role are accepted |
| `security-threat-model/hooks/directive.sh` (SessionStart directive) | important — operator-facing statement of what this role must produce |
| `docs/handbooks/security-threat-model.md` (handbook) | non-critical — documentation only, no enforcement effect |

## trust-boundary-map

- **Proposal → plugin boundary**: content crosses from a phase-1 document
  (`docs/issue-1/proposals/security-threat-model.md`, non-enforcing) into
  enforcing plugin config (`record-fields.env`) only after the contract
  v3 s19 Approve gate — the trust boundary this issue itself is about.
- **Role directive → operator boundary**: `directive.sh`'s `PRODUCES`
  string is trusted, unverified input to whichever human/agent starts a
  session for this role next; it carries no code-execution risk, only an
  expectation-setting one.
- **Gate → record boundary**: core's generalized record-fields gate reads
  `RECORD_FIELDS_REQUIRED` and checks field presence in a future phase-2
  record; a mismatch between the env value and the directive's `PRODUCES`
  text would let the two drift silently, which is why both were updated
  together (item 2 above).

## stride-table

| # | Threat | STRIDE category | Boundary/asset | risk-rating |
| --- | --- | --- | --- | --- |
| 1 | `record-fields.env` and `directive.sh` `PRODUCES` text drift apart after a future edit touches only one file, letting the gate silently diverge from what operators are told to produce | Tampering | Role directive → operator boundary | Low (CVSS-style: low likelihood — both are hand-edited together per this same proposal's plan item 2; low impact — a mismatch is cosmetic, not enforcement-breaking, since the gate reads only `record-fields.env`) |
| 2 | Core's generalized record-fields gate is unreachable/unverified in this repo (no `core/` checkout), so the six-field requirement added here is unverified against the actual gate implementation | Denial of Service (of the gate's intended effect) | Gate → record boundary | Medium (CVSS-style: same unresolved-dependency posture already flagged in issue #2's record; unverified whether presence-only checking is what actually lands) |

## mitigation-list

| # | Control | Type |
| --- | --- | --- |
| 1 | `directive.sh`'s `PRODUCES` and `record-fields.env`'s `RECORD_FIELDS_REQUIRED` were edited in the same phase-2 pass (this record), keeping them in sync at time of writing | Mitigate |
| 2 | Left as an open manual-review item at each future Approve step, per proposal (d).4, rather than blocking phase-2 landing on an unconfirmed core capability | Accept |

## residual-risk-note

Post-mitigation rating: Low for both threat-table rows (item 1 fully
mitigated by the synchronized edit above; item 2 accepted, not
eliminated, since it depends on an external repo this rulebook does not
control). Sign-off: approver `JiwonJung94` (`docs/specs/approvers.md`),
via the issue-level comment `APPROVE issue-1/security-threat-model`
(contract v3 s19 single-account mode), 2026-07-31.

## canon-references

- Core's `warrant/` plugin (core issue #63) — relied on by
  `security-threat-model/agents/warrant-hunter.md` for the rotating-stance
  hunt; referenced by path/description only, no copy in this repo (issue
  #1's own no-copy constraint, unchanged by this issue).
- Core's generalized record-fields gate and `core_role_directive`/
  `role-directive.sh` (core issue #66) — relied on by
  `security-threat-model/hooks/directive.sh` and
  `security-threat-model/hooks/record-fields.env`; referenced by path
  only, no vendored copy in this repo.

## Open Findings

- Whether core's generalized record-fields gate checks only field
  presence or can also verify internal cross-references (e.g. every
  `stride-table` row citing a valid `trust-boundary-map`/`asset-inventory`
  entry) is unconfirmed — no `core/` checkout is reachable from this repo.
  Per proposal (d).4, this stays a manual-review item at each future
  contract v3 s19 Approve step, not a blocking gap for this phase-2
  landing.
- The DREAD-style override marker convention (how an override is denoted
  inline in a `stride-table` row) is described in prose in the handbook
  and proposal but has no enforced syntax — a future record author could
  mark it inconsistently. Not blocking, since no such override was needed
  in this record's own `stride-table` above (all rows are CVSS-style).

## Upstream basis

`docs/issue-1/proposals/security-threat-model.md` (approved), itself
based on `docs/issue-1/reports/security-threat-model/survey.md` and
`docs/issue-1/reports/security-threat-model/scout-brief.md`; approval
given via the issue-level comment `APPROVE issue-1/security-threat-model`.

loop_state: landed
