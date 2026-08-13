---
rule_count_floor: 12
tier: moderate
axes:
  - trust-boundary-scoping
  - asset-sensitivity-classification
  - stride-enumeration-by-element
  - cvss-risk-rating
  - mitigation-disposition
  - residual-risk-signoff
---

# Operational playbook: trust-boundary threat modeling decision rules (issue-1174)

Numbered condition → choice → source rules for the `security-threat-model`
role. Practitioner-depth decision rules, not methodology-name pointers.
Each rule cites the fetched source it is derived from; rules marked
`[REMOVAL]` are subtractive (drop/simplify/de-scope), per amendment 4 —
at least one removal rule is recorded per axis below.

## 1. Trust boundary scoping (axis: trust-boundary-scoping)

**Rule 1.1 — Draw a boundary at every point where privilege or trust
level changes, not just at network edges.**
Condition: a data flow crosses from one privilege/trust zone to
another (internet → DMZ, user tier → admin tier, or a change in
"who can be trusted" assumptions on the same host).
Choice: mark a trust boundary there even if the transition is
in-process (e.g. unprivileged thread → privileged thread), not only at
physical/network edges.
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

**Rule 1.2 — Scope the DFD to one side of a trust boundary per model, with the far side reduced to interactors.**
Condition: a system has both client-side and server-side components
under analysis.
Choice: build the primary DFD for the side under this review's control,
representing everything across the boundary as external interactors
(rectangles) rather than modeling both sides in full detail
simultaneously — "the attacker is under no obligation to use your
tools or respect your protocols."
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

**Rule 1.3 [REMOVAL] — Collapse same-technology, same-trust-boundary elements into one DFD node.**
Condition: two or more processes/data stores are implemented in the
same technology and sit inside the same trust boundary.
Choice: merge them into a single modeled element rather than
enumerating each one separately — separate modeling of elements that
share a trust boundary adds analysis volume without adding threat
coverage.
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

**Rule 1.4 — Never trust a data flow just because it stays inside one trust boundary.**
Condition: a data flow, data store, or process sits entirely within a
single trust boundary (e.g. server-internal only).
Choice: still record tampering/information-disclosure/DoS threats for
it, scaled down in priority relative to boundary-crossing flows, rather
than skipping analysis outright — "anything can fail, and this isn't
any different"; verify first whether the assumed co-location (e.g.
same machine) is actually guaranteed, since if it isn't, the flow's
threat profile matches a boundary-crossing one.
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

## 2. Asset / data sensitivity classification (axis: asset-sensitivity-classification)

**Rule 2.1 — Model the system before scoring any threat.**
Condition: a threat-model session is opened for a spec that has not yet
had its data flows, data stores, processes, and external entities
enumerated.
Choice: complete asset/system modeling (DFD) first; do not begin
threat enumeration or rating until the model exists — "without
understanding a system, one cannot truly understand what threats are
most applicable to it."
Source: https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html (fetched 2026-08-13)

**Rule 2.2 [REMOVAL] — Do not carry an asset into the model that has no reader/writer.**
Condition: a data store in the draft DFD has data flowing in but no
process ever reads it back out (a "data sink"), or data appears with no
process producing it (a "magic source").
Choice: either add the missing reader/writer process to the model
(making the asset's real exposure visible) or remove the asset/data
store from the model if it does not actually exist in the reviewed
system — a magic source/sink is a modeling error, not a real trust
boundary.
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

**Rule 2.3 — Classify an asset by regulatory/contractual exposure, not just by its own label.**
Condition: a data store holds fields that could carry PII, payment
data, or sector-specific regulated data (e.g. health data under HIPAA),
even if the spec labels the store generically (e.g. "analysis
database").
Choice: rate the asset at the sensitivity of its most sensitive
plausible field content, not the store's nominal purpose — different
data types attract different attackers and different legal exposure.
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

## 3. STRIDE enumeration by DFD element type (axis: stride-enumeration-by-element)

**Rule 3.1 — Apply STRIDE by element type, not uniformly to every node.**
Condition: a DFD element is being checked against the six STRIDE
categories.
Choice: apply Tampering, Information Disclosure, and Denial of Service
to data flows and data stores; apply all six categories to processes;
apply Spoofing and Repudiation to external interactors — do not spend
analysis effort on categories the element type is not exposed to (e.g.
Spoofing against a data store).
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

**Rule 3.2 — Ask all six STRIDE questions at every trust boundary crossing, even ones that feel obviously inapplicable.**
Condition: a data flow crosses a marked trust boundary.
Choice: run the full STRIDE checklist against that flow rather than
skipping categories on the assumption they "obviously don't apply" —
threats concentrate at trust boundaries because that is where
who-can-be-trusted assumptions are actually tested.
Source: https://hivesecurity.gitlab.io/blog/stride-threat-modeling-practical-guide/ (fetched 2026-08-13)

**Rule 3.3 [REMOVAL] — Do not chase every downstream consequence of a threat inside the enumeration step.**
Condition: while enumerating one STRIDE threat (e.g. spoofing a
process), the analyst notices it could cascade into others (e.g.
spoofing → DoS → elevation of privilege).
Choice: record the originating threat and move on; do not expand the
enumeration pass into a full consequence tree for every finding — track
follow-on consequences during mitigation planning, not during
enumeration, to keep the enumeration pass finishing in bounded time.
Source: https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach (fetched 2026-08-13)

**Rule 3.4 — Log every finding with an owner and a fix/accept/backlog decision, never as a bare list of worries.**
Condition: a STRIDE pass over a trust boundary produces one or more
findings.
Choice: attach an owner and one of fix/accept/backlog to each finding
at enumeration time, not after the fact — an un-dispositioned finding
list is not a complete STRIDE table for this role's record.
Source: https://hivesecurity.gitlab.io/blog/stride-threat-modeling-practical-guide/ (fetched 2026-08-13)

## 4. CVSS-style risk rating (axis: cvss-risk-rating)

**Rule 4.1 — Rate Attack Vector by what the exploit chain requires, not by where the flaw physically executes.**
Condition: exploitation requires the attacker to reach the vulnerable
component over a network at some point in the chain, even if the
final trigger executes locally (e.g. a local privileged program later
sends data to an attacker-chosen network server).
Choice: score Attack Vector as Network (N), not Local — AV reflects
"how the vulnerability is exploited," including indirect network
dependency in the exploit chain, not merely the final execution
context.
Source: https://www.first.org/cvss/v3.1/user-guide (fetched 2026-08-13)

**Rule 4.2 — Score Local (L) when malicious data crosses components before the vulnerability triggers.**
Condition: malicious data is received over a network by one component,
then handed to a separate vulnerable component (e.g. downloading a
malicious document, then opening it in vulnerable local software).
Choice: rate Attack Vector Local, not Network, for the second
component's vulnerability — the network step belongs to a different
exploit stage than the vulnerability being scored.
Source: https://www.first.org/cvss/v3.1/user-guide (fetched 2026-08-13)

**Rule 4.3 — Assume the attacker knows the system's standard configuration and default defenses when rating Attack Complexity.**
Condition: rating Attack Complexity (AC) for a threat.
Choice: score against the reasonable, undisabled, non-custom
("vulnerable") configuration an attacker would actually encounter with
advanced knowledge of the target's defaults — do not rate AC as High
merely because a deliberately hardened, non-default configuration would
block the attack.
Source: https://www.first.org/cvss/v3.1/user-guide (fetched 2026-08-13)

**Rule 4.4 — Rate Privileges Required by the delta the attacker gains, not by the absolute privilege level reached.**
Condition: an attacker already holds some level of access before
exploiting the flaw.
Choice: compare privileges held before exploitation against privileges
required to exploit — the required-privilege score reflects the
pre-exploit access level needed, independent of how much additional
privilege is gained afterward (which belongs in Impact scoring, not
Privileges Required).
Source: https://www.first.org/cvss/v3.1/user-guide (fetched 2026-08-13)

**Rule 4.5 [REMOVAL] — Do not score Scope Changed unless the vulnerable component and the affected resource sit under different security authorities.**
Condition: a vulnerability's impact reaches beyond the component that
contains the flaw (e.g. a container escape, a sandboxed script
affecting the host).
Choice: only set Scope to Changed when the affected resource is
governed by a different security authority than the vulnerable
component; if impact stays within the same security-authority boundary,
do not inflate the score by marking Scope Changed — drop that marking
and score Scope Unchanged instead.
Source: https://www.first.org/cvss/v3.1/user-guide (fetched 2026-08-13)

## 5. Mitigation disposition selection (axis: mitigation-disposition)

**Rule 5.1 — Rank which threats get mitigation attention by likelihood × impact, not by discovery order.**
Condition: multiple STRIDE findings exist for one trust boundary and
mitigation effort must be sequenced.
Choice: compute a likelihood × impact ranking and address high-rank
items first, even when a lower-ranked item costs less to fix — order
by risk product, not by ease or by the order threats were found.
Disposition: mitigate (선택된 완화 대상에 한함); 나머지는 축적된 우선순위표에서 후순위로 대기.
Source: https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html (fetched 2026-08-13)

**Rule 5.2 [REMOVAL] — Prefer eliminating the vulnerable feature over adding a control around it when the feature is not load-bearing.**
Condition: a threat traces to an optional feature, endpoint, service,
or permission that is not required for the system's stated purpose.
Choice: remove/disable the feature (avoid-by-elimination) rather than
layering a compensating control on top of it — eliminate before
mitigate in the response-strategy ordering when removal is viable
without breaking the required function.
Disposition: avoid (기능 자체를 제거하여 위협을 원천 회피).
Source: https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html (fetched 2026-08-13)

**Rule 5.3 [REMOVAL] — Disable unused services, ports, and accounts found during modeling instead of adding monitoring around them.**
Condition: the DFD/asset survey turns up a running service, open port,
or standing account not required by the current spec (e.g. a leftover
integration, a temporary vendor account).
Choice: cut the unnecessary surface directly — "if a service does not
need to talk to another system, disconnect it; if a temporary vendor
account is no longer needed, remove it" — rather than accepting the
exposure and compensating with detection.
Disposition: avoid (불필요한 표면 자체를 제거).
Source: https://www.ivanti.com/blog/the-8-best-practices-for-reducing-your-organization-s-attack-surface (fetched 2026-08-13)

**Rule 5.4 — Transfer only the risks a contract or insurance instrument can actually cover.**
Condition: a threat's root cause sits outside this system's control
(e.g. a third-party processor's breach exposure) and no direct
technical mitigation is available from this side.
Choice: assign transfer disposition and name the specific
contractual/insurance instrument covering it — a transfer disposition
with no named instrument is incomplete and should default to mitigate
or accept instead.
Disposition: transfer (계약/보험 수단이 실제로 존재할 때만 사용).
Source: https://csrc.nist.gov/glossary/term/risk_response (fetched 2026-08-13)

**Rule 5.5 — Accept a risk only against a stated tolerance threshold, never by default.**
Condition: a rated threat's residual severity, after considering
available mitigations, falls at or below the org's stated risk
tolerance for that asset class.
Choice: record an explicit accept disposition naming the tolerance
threshold compared against — an unrated "we'll live with it" is not an
accept disposition under this rule.
Disposition: accept (명시된 허용 기준과 대비하여 기록).
Source: https://csrc.nist.gov/glossary/term/risk_response (fetched 2026-08-13)

## 6. Residual risk sign-off (axis: residual-risk-signoff)

**Rule 6.1 — Record the residual rating after mitigation, not the pre-mitigation rating restated.**
Condition: a mitigation has been selected and applied (or committed)
for a threat.
Choice: re-rate the threat's severity assuming the mitigation is in
place and record that post-mitigation number as the residual-risk-note
rating — copying the original pre-mitigation rating forward is not a
residual rating.
Source: https://csrc.nist.gov/glossary/term/risk_response (fetched 2026-08-13)

**Rule 6.2 — Escalate sign-off, not just document it, when residual severity still exceeds tolerance.**
Condition: the post-mitigation residual rating remains above the
asset's stated risk tolerance threshold.
Choice: route the residual-risk-note to the approver named in
docs/specs/approvers.md for an explicit accept/avoid decision before
closing the record — do not let a residual-risk-note with an
above-tolerance rating close without a named approver decision attached.
Source: https://csrc.nist.gov/glossary/term/risk_response (fetched 2026-08-13)

**Rule 6.3 [REMOVAL] — Drop a residual-risk-note's mitigation line item once its rating reaches the accepted floor, rather than re-litigating it every review cycle.**
Condition: a threat's residual rating has already been accepted (per
Rule 5.5) at a stated tolerance and no new information (design change,
new attack pattern, new asset exposure) has surfaced since.
Choice: remove that item from the active open-findings list for
subsequent reviews of the same spec revision — carrying an
already-dispositioned, unchanged item forward as if still open dilutes
attention on genuinely new findings; re-open it only if a triggering
change occurs.
Source: https://csrc.nist.gov/glossary/term/risk_response (fetched 2026-08-13)

## Academic layer: why the removal category is required, not optional

Practitioner and standards-body sources above are additive-biased by
construction (STRIDE, CVSS, and NIST risk-response guidance all describe
what to add — a control, a rating, a transfer instrument). Adams,
Converse, Hales & Klotz (*Nature* 594, 2021, "People systematically
overlook subtractive changes") document a general cognitive bias toward
additive solutions even when a subtractive one (removing a feature,
disabling a service, cutting an asset from scope) is equally or more
effective — the mechanism they identify is that people default-search
additive solution space first and stop once a workable additive answer
is found, without a corresponding search of the subtractive space. This
is the reason Rules 1.3, 2.2, 3.3, 5.2, 5.3, and 6.3 above are recorded
as explicit removal rules rather than left implicit inside the additive
rules they sit beside: a threat-model session run only on
practitioner/standards sourcing would reproduce the same additive bias
the academic literature documents, unless removal is forced as its own
checklist item per axis.
Source: Adams, G.S., Converse, B.A., Hales, A.H. et al. "People
systematically overlook subtractive changes." Nature 594, 258–262
(2021). https://doi.org/10.1038/s41586-021-03380-y (cited per amendment
4's named academic pointer; abstract/finding summary confirmed via
https://www.nature.com/articles/s41586-021-03380-y, fetched 2026-08-13)

## Sources

- https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/november/uncover-security-design-flaws-using-the-stride-approach
- https://hivesecurity.gitlab.io/blog/stride-threat-modeling-practical-guide/
- https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
- https://www.first.org/cvss/v3.1/user-guide
- https://csrc.nist.gov/glossary/term/risk_response
- https://www.ivanti.com/blog/the-8-best-practices-for-reducing-your-organization-s-attack-surface
- https://www.nature.com/articles/s41586-021-03380-y
