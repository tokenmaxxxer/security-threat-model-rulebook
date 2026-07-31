# Issue #1 — Scout Brief: Security Threat-Modeling Field Norms

Scope: broad external sweep of established threat-modeling methodologies,
industry-standard deliverable structure, and review/gating norms, to ground
the phase-1 proposal in domain evidence rather than intuition. WebSearch
was available and used for every claim below; every claim is cited.

## Methodologies (must-bes vs. adopt/skip)

- **STRIDE** (Spoofing, Tampering, Repudiation, Information Disclosure,
  Denial of Service, Elevation of Privilege) — Microsoft-originated,
  remains the most widely taught classification framework for enumerating
  *what kinds* of threats apply to a system, and is DFD/trust-boundary
  native (Microsoft's own Threat Modeling Tool draws trust boundaries as
  the annotation STRIDE threats attach to). **Adopt** — already named in
  this role's `PRODUCES` field, and directly matches the role's stated
  mandate ("신뢰 경계의 위협 표면" / trust-boundary threat surface).
- **PASTA** (Process for Attack Simulation and Threat Analysis) — a
  7-stage, risk-centric methodology that weighs business impact and
  attacker behavior more heavily than STRIDE. **Skip as primary** — PASTA's
  added stages (business objectives, threat intelligence correlation,
  attack simulation) suit an end-to-end product risk program, not a
  narrowly-scoped report-only role whose `write_scope` is `[]` and whose
  hand-off explicitly defers implementation-level and legal-exposure work
  elsewhere.
- **DREAD** — the original STRIDE-adjacent scoring mnemonic (Damage,
  Reproducibility, Exploitability, Affected users, Discoverability),
  documented as having fallen out of favor because assessors disagree by
  several points on the same threat due to unstandardized criteria.
  **Skip as sole scheme**, but acceptable as a documented *qualitative*
  fallback when no CVSS-style vector applies (e.g. a purely architectural
  trust-boundary gap with no CVE-style vector).
- **Attack trees** — one of the oldest techniques, useful for exploring
  *how* a goal is reached via a tree of sub-attacks; commonly used to
  complement STRIDE's enumeration rather than replace it. **Adopt
  optionally** — recommended as a "may attach" artifact for any threat row
  whose exploit path is non-obvious, not a required field for every row.
- **Common complementary pattern**: enumerate with STRIDE, explore
  non-obvious paths with attack trees, prioritize with a rating scheme
  better than DREAD alone. This is the pattern this proposal follows.
- **NIST SP 800-154** (Guide to Data-Centric System Threat Modeling) —
  frames threat modeling as risk assessment of a specific *data* asset's
  confidentiality/integrity/availability, and states its methodology is
  meant to set fundamental principles other methodologies should embed,
  not replace them. **Adopt principle, not process** — reinforces that an
  asset inventory (what data/asset is being protected) is a precondition
  to a valid threat table, independent of which enumeration framework is
  used on top.

## Document structure (industry norm)

Recurring required sections across risk-assessment/threat-model templates:
project/system scope description, **asset inventory** (with
classification, e.g. critical/important/non-critical), **trust
boundaries / DFD** (Microsoft SDL: trust boundaries as an extension of
classical DFDs marking where control/trust level changes — machine,
privilege, and integrity boundaries are named examples), **threat
enumeration** linked to specific assets/boundaries, **risk rating**
(likelihood × impact, qualitative matrix or CVSS-style vector), **proposed
mitigating controls** using the accept/mitigate/transfer/avoid framing,
and **residual risk** re-assessed after controls, closed by **formal
sign-off** acknowledging residual risk and a next-review trigger (typically
major architecture change).

## Risk-rating scheme choice

CVSS (FIRST-maintained) vs. DREAD: CVSS gives a more standardized,
reproducible score (Base + optional Temporal/Environmental vectors) and is
the industry default for vulnerability-shaped findings; DREAD remains
easier to apply to purely architectural/trust-boundary findings that have
no CVE-shaped vector but suffers from assessor inconsistency. **Chosen
approach**: prefer a CVSS-style qualitative severity (Critical/High/
Medium/Low derived from likelihood × impact) as the default per-threat
score, since it is the more defensible/reproducible default per source
comparisons below, with an explicit qualitative override path for
findings that are architectural (trust-boundary/DFD) rather than
vulnerability-shaped.

## Review/gating norms

Mature-org practice requires the sign-off step to be a *named field* (who
approved, with what residual risk explicitly acknowledged), not an
implicit approval — consistent with this repo's own contract v3 s19
Approve-gate mechanism (`docs/specs/approvers.md`), which already
structurally satisfies the "formal sign-off acknowledging residual risk"
norm at the phase-1→phase-2 boundary; this proposal's plugin-reflection
plan (in the accompanying proposal doc) ties the phase-2 record's own
gate to that same mechanism rather than inventing a parallel one.

## Gap line (repo state → field norm)

Current repo (`RECORD_FIELDS_REQUIRED="stride-table,mitigation-list,
residual-risk-note"`) has: threat enumeration (STRIDE) + mitigation +
residual risk. **Missing** against field norm: asset inventory, explicit
trust-boundary/DFD artifact, and a named risk-rating scheme (currently
undefined — "mitigation" and "residual risk" presuppose a score to
mitigate down from, but nothing produces that score today).

## Stage count / mode

Single-pass broad sweep (5 WebSearch queries covering methodology
comparison, SDL/DFD/trust-boundary structure, NIST SP 800-154, generic
risk-assessment templates, and CVSS-vs-DREAD rating), synthesized directly
into this brief — no multi-stage drill-down was needed since the domain
questions (methodology choice, structure, rating scheme, gating norms) were
each answered with converging results from 1-2 queries.

## Sources

- https://www.softwaresecured.com/post/comparison-of-stride-dread-pasta
- https://bluegoatcyber.com/blog/comparing-dread-stride-and-pasta-threat-models-which-is-most-effective
- https://www.practical-devsecops.com/types-of-threat-modeling-methodology/
- https://strobes.co/blog/threat-modeling-explained-stride/
- https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-getting-started
- https://www.microsoft.com/en-us/securityengineering/sdl/threatmodeling
- https://shostack.org/files/papers/modsec08/Shostack-ModSec08-Experiences-Threat-Modeling-At-Microsoft.pdf
- https://csrc.nist.gov/pubs/sp/800/154/ipd
- https://www.securityscientist.net/blog/nist-threat-model-the-complete-guide-for-data-centric-threat-modeling/
- https://threat-modeling.com/cybersecurity-risk-assessment-template/
- https://watchdogsecurity.io/artifacts/project-security-risk-review
- https://www.practical-devsecops.com/owasp-risk-rating-methodology-vs-cvss/
- https://www.simplerisk.com/blog/owasp-risk-rating-methodology-and-simplerisk
