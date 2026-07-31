# Issue #7 — Proposal: Methodology Enforcement Machinery

Status: **proposal only — phase 1**. No script, hook registration, or test
is executed by this document; everything below is a design for phase 2,
gated on an approvers.md Approve per contract v3 s19. This proposal is
based on `docs/issue-7/reports/security-threat-model/survey.md` (current
state) and `docs/issue-7/reports/security-threat-model/scout-brief.md`
(sibling-rulebook exemplars). It references sibling canon (pricing's
`methodology-gate.sh`, implementation-rulebook's `coding-progress-gate.sh`
and test harness) by path/description only, per the no-copy constraint —
phase 2 must write this role's own script from this design, not paste
sibling content in.

The norm this machinery enforces is the one already adopted in
`docs/issue-1/proposals/security-threat-model.md` and reflected in
`docs/handbooks/security-threat-model.md` / `record-fields.env`. This
proposal does not reopen methodology choice; it closes the open item that
proposal's part (d) left pending: field-presence checking exists (core's
generic gate), cross-reference/ordering/content checking does not.

## (a) Directive intensification — facet-level, not a one-line PRODUCES

`directive.sh`'s `PRODUCES` string must stay a single line — it is a fixed
positional argument to `core_role_directive` (core issue #66's stub
contract, per issue #2's precedent) and core's exact CLI signature for
richer input is unconfirmed from this repo alone (flagged TBD below,
consistent with issue #2's own handling of the same unknown). The
"실행 가능한 수준" depth issue #7 asks for therefore belongs in
`docs/handbooks/security-threat-model.md`, which is this role's own file
(not core canon) and is already the place `directive.sh`'s trailing comment
and the handbook's own "Methodology" section point readers to. Proposal:
expand the handbook's "Methodology" section into two explicit subsections:

**Phase 1 facet** (what a `docs/issue-<n>/proposals/*security-threat-model*.md`
must do, step by step):
1. Frame scope: which system/spec surface is in view, and which trust
   boundaries/authentication/sensitive-data touchpoints triggered
   `USE_WHEN`.
2. State the methodology for *this* spec explicitly (STRIDE is the
   standing default per issue #1; only deviate with a stated reason).
3. Name every `PRODUCES` element this record will carry and in what order
   they'll appear (asset-inventory → trust-boundary-map → stride-table →
   mitigation-list → residual-risk-note → canon-references) — matching
   `RECORD_FIELDS_REQUIRED`'s literal order.
4. Judgment criterion for scope-fit: if the spec has no trust boundary,
   authentication surface, or sensitive data in view, this is a boundary
   case (`BOUNDARY_CASE`) — say so and hand off per `HAND_OFF`, don't force
   a STRIDE table onto a spec that doesn't need one.
5. Prohibition: do not skip straight to phase-2 fields without this
   framing — a proposal that only restates `PRODUCES` verbatim with no
   scope statement is not a phase-1 proposal, it's a copy.

**Phase 2 facet** (what `docs/issue-<n>/reports/security-threat-model.md`
must do, step by step, with judgment criteria and prohibitions per
element):
1. `asset-inventory` before `trust-boundary-map` before `stride-table` —
   ordering is load-bearing (a threat row has no well-defined subject
   without an asset and a boundary already named). **Prohibition**:
   writing a `stride-table` section that appears before either of the
   other two.
2. Each `stride-table` row names at least one STRIDE category
   (Spoofing/Tampering/Repudiation/Information Disclosure/Denial of
   Service/Elevation of Privilege) and references an asset or trust
   boundary from the earlier sections. **Judgment criterion**: a row that
   names no STRIDE category is a generic risk note, not a threat-model
   row — it belongs elsewhere or needs re-categorizing.
3. Risk rating: CVSS-style qualitative severity (Critical/High/Medium/Low)
   is the default. DREAD is permitted only for architectural/trust-boundary
   findings with no CVE-like vector, and **must carry an explicit inline
   marker** — proposal fixes the marker syntax as `[dread-override]`
   immediately following the rating on that row, so "marked inline" (handbook's
   existing prose) becomes a checkable string, not a judgment call.
   **Prohibition**: a row using DREAD language with no
   `[dread-override]` marker, or mixing both schemes on the same row.
4. `mitigation-list`: every entry uses one of accept/mitigate/transfer/avoid.
   **Prohibition**: a mitigation entry with no disposition word from that
   set (e.g. a vague "will fix later" with no accept/mitigate/transfer/avoid
   framing).
5. `residual-risk-note`: post-mitigation rating plus an explicit approver
   reference (contract v3 s19's Approve gate via `docs/specs/approvers.md`
   — this proposal does not invent a second sign-off mechanism).
   **Prohibition**: a residual-risk-note with a rating but no named
   approver reference.
6. `canon-references`: cite external canon (e.g. core's `warrant/` plugin)
   by path/description only. **Prohibition**: pasting canon script content
   (a shebang line, a fenced code block copied from a `.sh` file) into this
   section — that is exactly the no-copy violation issue #1/#2 already
   established as a constraint; this proposal makes it mechanically
   checkable (see (b) below).

`directive.sh` itself gains one addition: a trailing comment line pointing
`PRODUCES`'s reader at the handbook's new Phase 1/Phase 2 subsections by
anchor, mirroring the existing "See ... for the full rationale trail"
pattern already in the handbook. **TBD phase 2**: confirm whether
`core_role_directive` accepts an optional richer/multi-line field before
assuming the one-line-only constraint is permanent — not knowable from this
repo alone, same caveat issue #2 raised for this same function.

## (b) Methodology gate — `security-threat-model/hooks/methodology-gate.sh`

New `PreToolUse` (`Write|Edit|MultiEdit`) gate, layered on top of (never
instead of) core's generic record-fields-gate — this gate does not
re-check field *presence* (core's job); it checks STRIDE-domain content and
ordering that only this role can judge. Design mirrors
`pricing-rulebook/pricing/hooks/methodology-gate.sh`'s skeleton
(referenced, not copied):

- **Kill switch**: `SECURITY_THREAT_MODEL_METHODOLOGY_GATE_OFF=1`.
- **Fail-closed wrapper**: same `__fc` trap pattern; any internal error
  (unparseable JSON, unreadable file, unresolved edit) denies (exit 2)
  rather than passing silently.
- **Path targeting**: `docs/issue-[0-9]+/proposals/.*security-threat-model.*\.md`
  and `docs/issue-[0-9]+/reports/security-threat-model\.md` only; every
  other path exits 0 immediately (not this gate's business).
- **Resulting-content reconstruction**: for `Write`, use `content`; for
  `Edit`/`MultiEdit`, apply `old_string`/`new_string` (and each entry in
  `edits`) against the current on-disk text; deny if the resulting content
  can't be determined (matches pricing's rule — never guess).
- **Checks against the reconstructed text** (this role's unique payload,
  per (a) above):
  1. **Ordering**: if a `stride-table` heading/marker is present, its text
     position must be after both an `asset-inventory` and a
     `trust-boundary-map` heading/marker in the same document. Deny naming
     which of the two is missing or out of order.
  2. **STRIDE tagging**: the `stride-table` section's text must contain at
     least one of the six STRIDE category names/initials. Deny if a
     `stride-table` section exists with none.
  3. **Rating discipline**: if the text contains DREAD-shaped language
     ("dread") it must also contain the `[dread-override]` marker; deny if
     DREAD language appears without the marker. (Absence of any rating
     language at all is core's generic field-presence gate's business, not
     this check's.)
  4. **Mitigation vocabulary**: if a `mitigation-list` section exists, deny
     if none of accept/mitigate/transfer/avoid (or their Korean
     equivalents, since this role's directive text is bilingual) appear in
     it.
  5. **Approver reference**: if a `residual-risk-note` section exists, deny
     if it contains no reference to `approvers.md` / "Approve" / an
     approver account name.
  6. **No-copy check on `canon-references`**: deny if that section's text
     contains a shebang line (`#!/`) or a fenced code block whose contents
     look like a hook script (heuristic: contains `PreToolUse`,
     `set -uo pipefail`, or similar core-canon-shaped tokens) — this is a
     best-effort mechanical backstop for the no-copy constraint, not a
     substitute for review; the deny message says so explicitly rather than
     overclaiming completeness.
- **Sequence precondition (the "상태 추적" ask)**: before allowing a write
  to `docs/issue-<n>/proposals/*security-threat-model*.md`, check that
  `docs/issue-<n>/reports/security-threat-model/survey.md` already exists
  in the working tree for the same `<n>`. If not, deny citing the
  scout-directive's survey-first-order rule and this repo's own issue-1/
  issue-7 precedent of writing the survey before the proposal. This is a
  file-existence precondition (implementation-rulebook's
  `coding-progress-gate.sh` pattern), not a dedicated state-machine file —
  proportionate to a two-step phase-1 sequence.
- Deny messages cite this proposal's doc path and the specific missing/
  misordered element(s), matching pricing's and core's existing
  deny-message convention (name the source-of-truth doc, not just "invalid").

`hooks.json` gains one new `PreToolUse` entry (`Write|Edit|MultiEdit` →
`hooks/methodology-gate.sh`), alongside the existing `SessionStart` entry.

## (c) Gate tests — repo-root `tests/`

This repo has no `tests/` directory today (survey section 1). Phase 2
introduces, following the `implementation-rulebook`/`pricing-rulebook`
convention (scout-brief exemplar 3):

- `tests/run-gate-tests.sh` — the harness (temp git repo per case, JSON
  `PreToolUse` payload piped via stdin, exit-code assertion 0=allow/2=deny).
  Minimum case set:
  1. Allow: a complete record — asset-inventory, trust-boundary-map,
     stride-table (STRIDE-tagged, CVSS-rated) in order, mitigation entries
     using accept/mitigate/transfer/avoid, residual-risk-note naming an
     approver, canon-references with no script content → allow.
  2. Deny: `stride-table` appearing before `trust-boundary-map`.
  3. Deny: `stride-table` present with no STRIDE category name anywhere in
     it.
  4. Deny: DREAD language present with no `[dread-override]` marker.
  5. Deny: mitigation-list entry with none of accept/mitigate/transfer/avoid.
  6. Deny: residual-risk-note with a rating but no approver reference.
  7. Deny: canon-references section containing a shebang line / hook-script
     fragment.
  8. Deny: a proposal write when no `survey.md` exists yet for that issue
     number (sequence precondition).
  9. Allow: an unrelated path (e.g. `docs/issue-<n>/reports/qa.md`) with
     none of the above content — proves the gate stays scoped to its own
     write surfaces.
  10. Allow: an `Edit` (not just `Write`) reconstructs correctly and passes
      the same checks as case 1's content.
- `security-threat-model/hooks/tests/parse-check.sh` and
  `security-threat-model/hooks/tests/deny-only-check.sh` — copied verbatim
  per `canon-scripts.md`'s named exception (each rulebook parses/scans its
  own scripts), not written from scratch; phase 2 sources their exact
  content from a sibling rulebook's copy by reference, consistent with the
  no-copy constraint applying to *behavioral* canon, not this
  syntax/scan-helper exception category already established for
  `implementation-rulebook`.

## (d) Agents / checklist

No new agent is proposed. `warrant-hunter.md` already carries this role's
full repeated-hunt delegation to core's `warrant/` plugin (issue #2); the
repeated procedure issue #7 actually names — the ordered phase-1 and
phase-2 steps — is exactly what (a)'s handbook checklist and (b)'s gate
already cover mechanically. Adding a separate agent file would duplicate
(a)'s checklist without adding new enforcement, which the survey's gap list
does not call for.

## Sequencing within phase 2 (informational)

Suggested order, keeping the role working between commits: (1) expand the
handbook's Methodology section into the Phase 1/Phase 2 facets from (a),
no behavior change → (2) add `hooks/methodology-gate.sh` from (b) with its
kill switch defaulted off during initial landing if needed for staged
rollout, then on → (3) add the `PreToolUse` entry to `hooks.json` → (4) add
`tests/run-gate-tests.sh` plus the two copied test-helper scripts from (c),
run them, and record pass/fail in `docs/issue-7/reports/security-threat-model.md`
(phase-2 record, out of scope for this phase-1 PR) → (5) re-flag any
core-contract unknown surfaced during implementation (e.g. (a)'s
`core_role_directive` TBD) the same way issue #2 did, rather than guessing.
This ordering is a suggestion for whoever executes phase 2, not something
this phase-1 PR performs.
