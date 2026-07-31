# Issue #7 — Proposal: Methodology Enforcement Machinery (Plugin Set)

Status: **proposal only — phase 1**. No plugin file, hook registration,
`marketplace.json` entry, or test is created by this document; everything
below is a design for phase 2, gated on an approvers.md Approve per
contract v3 s19. This revision replaces the prior single-gate/single-directive
design after the approver's requirement correction on PR #8: the machinery
must be a **set of independent plugins**, one per adopted methodology, not
one deepened gate/directive inside the existing `security-threat-model`
plugin.

This proposal is based on `docs/issue-7/reports/security-threat-model/survey.md`
(current state) and `docs/issue-7/reports/security-threat-model/scout-brief.md`
(sibling-rulebook exemplars: `pricing-rulebook/pricing/hooks/methodology-gate.sh`'s
gate skeleton and `implementation-rulebook/coding/hooks/coding-progress-gate.sh`'s
precondition pattern). It references sibling and core canon by path/description
only, per the no-copy constraint (`canon-scripts.md`) — phase 2 must write
each plugin's own scripts from this design, not paste sibling or core content
in, except for the two named `canon-scripts.md` exceptions (`parse-check.sh`,
`deny-only-check.sh`), which are copied per-rulebook by that convention.

The methodology set this machinery enforces is the one already adopted in
`docs/issue-1/proposals/security-threat-model.md` (the adoption-rationale
doc, source of truth for methodology choice) and reflected today in
`docs/handbooks/security-threat-model.md` / `record-fields.env`. This
proposal does not reopen methodology choice; it closes the open item that
proposal's part (d) left pending — field-presence checking exists (core's
generic `record-fields-gate.sh`), content/ordering/cross-reference checking
does not — by decomposing that missing layer into a plugin set instead of
one gate.

## 0. Structural model, calibrated against `tokenmaxxxer-core`

Core's own `.claude-plugin/marketplace.json` registers five independent
plugins from one repo — `core`, `terse`, `freelunch`, `scout`, `warrant` —
each with its own `<plugin>/.claude-plugin/plugin.json`, its own `hooks/`
(directive/gate scripts, `hooks.json`, `hooks/tests/`), and, where relevant,
its own `agents/`. `freelunch` is the completeness bar the approver named:
`freelunch/.claude-plugin/plugin.json`, `freelunch/hooks/freelunch.sh` +
`freelunch/hooks/observe.sh` + `freelunch/hooks/hooks.json` +
`freelunch/hooks/tests/parse-check.sh`, `freelunch/agents/freelunch-worker.md`,
`freelunch/workflows/*.js`, `freelunch/README.md` — a self-contained unit
that does exactly one job end to end (directive/trigger, enforcement,
delegate agent, test, doc) and registers as its own marketplace entry.

This repo's current `.claude-plugin/marketplace.json` registers exactly one
plugin (`security-threat-model`, `source: "./security-threat-model"`). Phase
2 changes this to a **set** of sibling plugin directories at repo root, each
with its own `source` entry in `marketplace.json`, mirroring core's shape —
not one directory with a deepened `hooks/`.

## 1. Methodology → plugin mapping

Reading `docs/issue-1/proposals/security-threat-model.md` part (b) (the
phase-2 deliverable norm this repo already adopted) as the methodology
inventory, five separable methodologies are named, each with its own
judgment logic that only that methodology owns:

| # | Methodology | Adoption-rationale source | What only this methodology can judge |
|---|---|---|---|
| 1 | STRIDE threat enumeration (with its asset-inventory/trust-boundary-map precondition) | issue-1 proposal (b).1–3 | Whether `asset-inventory` and `trust-boundary-map` precede `stride-table`, and whether `stride-table` rows carry a STRIDE category tag |
| 2 | CVSS-default / DREAD-marked-override risk rating | issue-1 proposal (b).4 | Whether DREAD-shaped language carries the `[dread-override]` marker |
| 3 | Risk-disposition vocabulary (accept/mitigate/transfer/avoid) | issue-1 proposal (b).5 | Whether every `mitigation-list` entry states a disposition from that set |
| 4 | Residual-risk sign-off via `docs/specs/approvers.md` | issue-1 proposal (b).6 | Whether `residual-risk-note` names an approver reference |
| 5 | No-copy canon citation | issue-1 proposal (b).7, issue #1/#2's no-copy constraint | Whether `canon-references` cites by path/description rather than pasting script content |

Each becomes its own plugin (below). None of the five re-implements core's
generic field-*presence* check (`record-fields-gate.sh`, driven by
`record-fields.env`) — that stays exactly as-is, owned by the base
`security-threat-model` plugin, and every methodology plugin's gate is
layered strictly on top of it (checks content/ordering/vocabulary only after
a field already exists), exactly as `pricing-rulebook`'s
`methodology-gate.sh` layers on top of its own record-fields gate.

## 2. Plugin list (mandatory per approver correction)

All six plugins below live as sibling directories at this repo's root,
alongside the existing `security-threat-model/` directory (which becomes the
**base plugin** — narrower than today, see 2.0). Each plugin directory has
its own `.claude-plugin/plugin.json`; each registers as its own entry in
`.claude-plugin/marketplace.json` (format in section 4).

### 2.0 `security-threat-model` (base plugin, existing directory, narrowed)

- **Methodology owned**: none — this is the role-identity/hand-off plugin,
  not a methodology plugin. It stays the anchor the other five compose
  against.
- **Components**:
  - `hooks/directive.sh` — `SessionStart` stub calling `core_role_directive`
    (unchanged mechanism); `PRODUCES` stays the single-line six-element
    string it is today. Gains one addition: a trailing comment pointing
    readers to `docs/handbooks/security-threat-model.md`'s Methodology
    section, which phase 2 restructures into per-plugin subsections (one
    per methodology plugin below) instead of one flat "Phase 1/Phase 2
    facet" block, so the handbook's own structure mirrors the plugin set.
  - `hooks/record-fields.env` — unchanged: `RECORD_FIELDS_REQUIRED` stays
    the six-element list; this is core's generic field-*presence* input,
    not this proposal's payload.
  - `hooks/hooks.json` — unchanged `SessionStart` entry, plus one new
    `PreToolUse` entry: the **sequence precondition** gate (survey-must-
    exist-before-proposal, from the prior design's (b) "sequence
    precondition" item). This stays here rather than in any single
    methodology plugin because it is a role-level phase ordering rule
    (phase-1 survey before phase-1 proposal), not specific to STRIDE,
    rating, disposition, sign-off, or citation.
  - `hooks/sequence-gate.sh` (new) — `PreToolUse` (`Write|Edit|MultiEdit`),
    scoped to `docs/issue-[0-9]+/proposals/.*security-threat-model.*\.md`
    only; denies unless `docs/issue-<n>/reports/security-threat-model/survey.md`
    already exists in the working tree for the same `<n>`. Fail-closed
    wrapper, kill switch (`SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF=1`),
    mirrors `implementation-rulebook/coding/hooks/coding-progress-gate.sh`'s
    precondition pattern (referenced, not copied).
  - `agents/warrant-hunter.md` — unchanged; core-canon stub per issue #2,
    role-unique mandate/hand-off text only.
  - `hooks/tests/parse-check.sh`, `hooks/tests/deny-only-check.sh` — copied
    per `canon-scripts.md`'s named exception, scanning this plugin's own
    scripts (`directive.sh`, `sequence-gate.sh`).
- **Combines with**: every methodology plugin below composes on top of this
  plugin's `SessionStart` directive and generic field-presence gate; none of
  them duplicate `record-fields.env` or the sequence gate.

### 2.1 `security-threat-model-stride`

- **Methodology owned**: STRIDE threat enumeration, including its
  asset-inventory/trust-boundary-map precondition.
- **Components**:
  - `.claude-plugin/plugin.json`
  - `hooks/directive.sh` — a small `SessionStart` addition (not a second
    `core_role_directive` stub — that positional call stays solely in the
    base plugin) that prints this methodology's phase-1 framing checklist:
    frame scope (trust boundary/authentication/sensitive-data touchpoints),
    state STRIDE as the default methodology (issue-1 standing default),
    name `asset-inventory` → `trust-boundary-map` → `stride-table` in that
    order, and the `BOUNDARY_CASE`/`HAND_OFF` judgment criterion for specs
    with no trust boundary in view.
  - `hooks/methodology-gate.sh` — `PreToolUse` (`Write|Edit|MultiEdit`),
    scoped to this role's write surfaces
    (`docs/issue-[0-9]+/proposals/.*security-threat-model.*\.md`,
    `docs/issue-[0-9]+/reports/security-threat-model\.md`). Skeleton per
    `pricing-rulebook/pricing/hooks/methodology-gate.sh` (fail-closed trap,
    kill switch `SECURITY_THREAT_MODEL_STRIDE_GATE_OFF`, resulting-content
    reconstruction for Write/Edit/MultiEdit, deny-if-unresolvable). Checks:
    (1) if a `stride-table` heading/marker is present, it must appear after
    both an `asset-inventory` and a `trust-boundary-map` heading/marker in
    the same document — deny naming which is missing/out of order; (2) the
    `stride-table` section's text must contain at least one of the six
    STRIDE category names/initials — deny if absent.
  - `hooks/hooks.json` — `SessionStart` (directive addition) +
    `PreToolUse` (the gate above).
  - `hooks/tests/parse-check.sh`, `hooks/tests/deny-only-check.sh` — copied
    per `canon-scripts.md`'s exception.
  - No agent (STRIDE enumeration is authored directly in the record; no
    delegated hunt is specific to this methodology beyond the base
    plugin's `warrant-hunter.md`).
- **Combines with**: runs after the base plugin's sequence gate (a proposal
  write must already have passed that precondition) and independently of
  the other four methodology plugins' gates — all `PreToolUse` gates on the
  same path fire and must each allow.

### 2.2 `security-threat-model-risk-rating`

- **Methodology owned**: CVSS-style default / DREAD-style marked-override
  risk rating.
- **Components**:
  - `.claude-plugin/plugin.json`
  - `hooks/directive.sh` — `SessionStart` addition stating the rating rule:
    CVSS-style qualitative severity (Critical/High/Medium/Low) is default;
    DREAD is permitted only for architectural/trust-boundary findings with
    no CVE-like vector and must carry the `[dread-override]` marker
    immediately following the rating on that row.
  - `hooks/methodology-gate.sh` — same skeleton/kill-switch/path-targeting
    convention as 2.1's gate (own kill switch
    `SECURITY_THREAT_MODEL_RISK_RATING_GATE_OFF`). Check: if the
    reconstructed text contains DREAD-shaped language ("dread") it must
    also contain the `[dread-override]` marker; deny if DREAD language
    appears without it. (Absence of rating language entirely stays core's
    generic field-presence gate's business, not this check's.)
  - `hooks/hooks.json`, `hooks/tests/parse-check.sh`,
    `hooks/tests/deny-only-check.sh` — as above.
  - No agent.
- **Combines with**: independent of 2.1/2.3/2.4/2.5; all five methodology
  gates are additive deny-only layers on the same write surfaces.

### 2.3 `security-threat-model-mitigation`

- **Methodology owned**: risk-disposition vocabulary
  (accept/mitigate/transfer/avoid).
- **Components**:
  - `.claude-plugin/plugin.json`
  - `hooks/directive.sh` — `SessionStart` addition stating the disposition
    rule: every `mitigation-list` entry uses one of
    accept/mitigate/transfer/avoid (or a stated Korean equivalent, since
    this role's directive text is bilingual).
  - `hooks/methodology-gate.sh` — same skeleton (kill switch
    `SECURITY_THREAT_MODEL_MITIGATION_GATE_OFF`). Check: if a
    `mitigation-list` section exists, deny if none of
    accept/mitigate/transfer/avoid (or their Korean equivalents) appear in
    it.
  - `hooks/hooks.json`, `hooks/tests/parse-check.sh`,
    `hooks/tests/deny-only-check.sh`.
  - No agent.
- **Combines with**: independent of the other four; layered on the same
  write surfaces.

### 2.4 `security-threat-model-residual-signoff`

- **Methodology owned**: residual-risk sign-off via
  `docs/specs/approvers.md` (contract v3 s19 Approve gate) — this proposal
  does not invent a second sign-off mechanism, it makes the existing one
  mechanically checkable inside the record.
- **Components**:
  - `.claude-plugin/plugin.json`
  - `hooks/directive.sh` — `SessionStart` addition stating the rule:
    `residual-risk-note` must carry a post-mitigation rating plus an
    explicit approver reference.
  - `hooks/methodology-gate.sh` — same skeleton (kill switch
    `SECURITY_THREAT_MODEL_RESIDUAL_SIGNOFF_GATE_OFF`). Check: if a
    `residual-risk-note` section exists, deny if it contains no reference
    to `approvers.md` / "Approve" / a named approver account.
  - `hooks/hooks.json`, `hooks/tests/parse-check.sh`,
    `hooks/tests/deny-only-check.sh`.
  - No agent.
- **Combines with**: independent of the other four; also the plugin a
  future governance-facing rulebook change (e.g. a different sign-off gate)
  would touch in isolation, without disturbing STRIDE/rating/mitigation
  logic.

### 2.5 `security-threat-model-canon-citation`

- **Methodology owned**: no-copy canon citation discipline (cite external
  canon, e.g. core's `warrant/` plugin or sibling `methodology-gate.sh`
  scripts, by path/description only — never paste script content).
- **Components**:
  - `.claude-plugin/plugin.json`
  - `hooks/directive.sh` — `SessionStart` addition restating the no-copy
    rule issue #1/#2 already established, now scoped to the
    `canon-references` record field specifically.
  - `hooks/methodology-gate.sh` — same skeleton (kill switch
    `SECURITY_THREAT_MODEL_CANON_CITATION_GATE_OFF`). Check: deny if the
    `canon-references` section's text contains a shebang line (`#!/`) or a
    fenced code block whose contents look like a hook script (heuristic:
    contains `PreToolUse`, `set -uo pipefail`, or similar core-canon-shaped
    tokens) — a best-effort mechanical backstop, not a substitute for
    review; deny message says so explicitly.
  - `hooks/hooks.json`, `hooks/tests/parse-check.sh`,
    `hooks/tests/deny-only-check.sh`.
  - No agent.
- **Combines with**: independent of the other four; this is the one
  methodology plugin whose check applies verbatim to *any* future
  methodology plugin's own `canon-references` prose too, since the
  no-copy rule is role-wide, not STRIDE/rating/mitigation/sign-off-specific
  — kept separate rather than folded into 2.1 for that reason.

## 3. Phase-1 and phase-2 norms as plugin combinations

Per the approver's correction, the norm is not "one gate enforces
everything" — it is which plugins compose to form each norm. Restated
explicitly:

**Phase-1 proposal norm** (`docs/issue-<n>/proposals/*security-threat-model*.md`)
= base plugin's sequence gate (2.0, survey must already exist) **AND** the
five methodology plugins' `SessionStart` directive facets (2.1–2.5, each
contributing its own framing/judgment-criterion text for authoring, not a
`PreToolUse` check at proposal-authoring time beyond what 2.1's STRIDE gate
already covers when the proposal document itself contains STRIDE-table-shaped
content). A phase-1 proposal is compliant only when all six plugins' framing
guidance has been followed; no single plugin's directive is sufficient alone.

**Phase-2 record norm** (`docs/issue-<n>/reports/security-threat-model.md`)
= core's generic `record-fields-gate.sh` (field presence, driven by the base
plugin's `record-fields.env`, unchanged) **AND** all five methodology
plugins' `PreToolUse` gates (2.1 STRIDE ordering/tagging, 2.2 rating-marker
discipline, 2.3 disposition vocabulary, 2.4 sign-off reference, 2.5 no-copy
citation), each independently deny-capable, each scoped to exactly the
element it owns and nothing else. A phase-2 record passes only when every
plugin in the set allows; any single plugin's deny blocks the write
regardless of what the other four found.

This decomposition is the design's body per the approver's correction: the
plugin list in section 2 *is* the enforcement machinery, not a supporting
detail under a single gate.

## 4. `marketplace.json` registration

This repo's `.claude-plugin/marketplace.json` currently registers one
plugin. Phase 2 changes it to register all six plugins from section 2, one
entry per plugin directory, following the exact shape core's own
`marketplace.json` uses for its five plugins (`name`, `source`,
`description` per entry; shared top-level `name`/`owner`):

```json
{
  "name": "tokenmaxxxer-security-threat-model",
  "owner": { "name": "tokenmaxxxer" },
  "plugins": [
    {
      "name": "security-threat-model",
      "source": "./security-threat-model",
      "description": "The security-threat-model role on contract v3 (issue-160 round-3 promotion). Decides: 신뢰 경계의 위협 표면. Base plugin: role identity, hand-off, generic field-presence gate, phase-1 sequence precondition."
    },
    {
      "name": "security-threat-model-stride",
      "source": "./security-threat-model-stride",
      "description": "STRIDE threat-enumeration methodology plugin: asset-inventory/trust-boundary-map precondition ordering and STRIDE-category tagging on stride-table."
    },
    {
      "name": "security-threat-model-risk-rating",
      "source": "./security-threat-model-risk-rating",
      "description": "CVSS-default / DREAD-marked-override risk-rating methodology plugin."
    },
    {
      "name": "security-threat-model-mitigation",
      "source": "./security-threat-model-mitigation",
      "description": "Risk-disposition vocabulary (accept/mitigate/transfer/avoid) methodology plugin."
    },
    {
      "name": "security-threat-model-residual-signoff",
      "source": "./security-threat-model-residual-signoff",
      "description": "Residual-risk sign-off methodology plugin: approvers.md reference discipline on residual-risk-note."
    },
    {
      "name": "security-threat-model-canon-citation",
      "source": "./security-threat-model-canon-citation",
      "description": "No-copy canon-citation discipline methodology plugin on canon-references."
    }
  ]
}
```

Each plugin directory carries its own `.claude-plugin/plugin.json`
(`name`/`description`/`author`, matching the existing base plugin's file
shape) in addition to the shared marketplace registration above — this
mirrors core's per-plugin `plugin.json` + shared `marketplace.json` split
exactly.

## 5. Repo-root `tests/`

This repo has no `tests/` directory today (survey section 1). Phase 2
introduces `tests/run-gate-tests.sh` — the cross-plugin harness, following
the `implementation-rulebook`/`pricing-rulebook` convention (scout-brief
exemplar 3): temp git repo per case, JSON `PreToolUse` payload piped via
stdin, exit-code assertion (0=allow/2=deny), invoked once per plugin's gate
script under test with `CLAUDE_PLUGIN_ROOT` pointed at that plugin's
directory. Minimum case set, one group per plugin:

- **Base plugin (`security-threat-model`) sequence gate**: deny a proposal
  write when no `survey.md` exists yet for that issue number; allow once it
  exists; allow an unrelated path untouched by any of these gates.
- **`security-threat-model-stride`**: deny `stride-table` before
  `trust-boundary-map`; deny `stride-table` with no STRIDE category name;
  allow a correctly ordered, correctly tagged record.
- **`security-threat-model-risk-rating`**: deny DREAD language with no
  `[dread-override]` marker; allow CVSS-only text; allow DREAD text with the
  marker present.
- **`security-threat-model-mitigation`**: deny a `mitigation-list` entry
  using none of accept/mitigate/transfer/avoid; allow one that does.
- **`security-threat-model-residual-signoff`**: deny a `residual-risk-note`
  with a rating but no approver reference; allow one naming
  `docs/specs/approvers.md` or an approver account.
- **`security-threat-model-canon-citation`**: deny a `canon-references`
  section containing a shebang line / hook-script fragment; allow a
  path/description-only citation.
- **Cross-plugin**: allow a complete record that satisfies all five
  methodology plugins plus the base plugin's field-presence and sequence
  checks; allow an `Edit` (not just `Write`) that reconstructs correctly
  and passes the same checks as the complete-record case.

Each plugin also carries its own `hooks/tests/parse-check.sh` and
`hooks/tests/deny-only-check.sh` — copied verbatim per `canon-scripts.md`'s
named exception (each rulebook, and per this revision each plugin within
it, parses/scans its own scripts), sourced from a sibling rulebook's copy by
reference, consistent with the no-copy constraint applying to *behavioral*
canon, not this syntax/scan-helper exception category already established
for `implementation-rulebook`.

## 6. Constraints carried over unchanged

- **Canon scripts remain reference-only.** Nothing in this proposal copies
  `pricing-rulebook/pricing/hooks/methodology-gate.sh`,
  `implementation-rulebook/coding/hooks/coding-progress-gate.sh`, or any
  core canon script; every plugin above cites them by path/description and
  writes its own script from this design, per `docs/handbooks/canon-scripts.md`.
  The only copies are the two named exceptions (`parse-check.sh`,
  `deny-only-check.sh`), copied per-plugin as `canon-scripts.md` already
  permits.
- **Role boundaries and `write_scope` are unchanged.** All six plugins
  operate within the existing `security-threat-model` role's write surfaces
  (`docs/issue-<n>/proposals/*security-threat-model*.md`,
  `docs/issue-<n>/reports/security-threat-model.md`, and this repo's own
  `docs/issue-7/...` phase-1 material); no plugin widens what this role may
  write, and hand-off text (secure-coding, legal-compliance) is untouched.
- **Methodology source of truth stays `docs/issue-1/proposals/security-threat-model.md`.**
  This proposal maps that document's six required fields onto five
  methodology plugins plus one base plugin; it does not reopen or revise
  which methodologies were adopted.
- **Phase separation.** This document proposes what phase 2 builds; it does
  not create any plugin directory, `plugin.json`, gate script, `hooks.json`
  entry, or `marketplace.json` change itself. `docs/issue-7/reports/security-threat-model.md`
  (the phase-2 record) is out of scope for this phase-1 PR, same as before.

## 7. Sequencing within phase 2 (informational)

Suggested order, keeping the role working between commits: (1) narrow the
existing `security-threat-model` plugin to the base-plugin shape from 2.0
(add `sequence-gate.sh`, restructure the handbook's Methodology section into
per-plugin subsections) with no other behavior change → (2) add the five
methodology plugin directories from 2.1–2.5, each with kill switch defaulted
off during initial landing if staged rollout is wanted, then on → (3)
register all six plugins in `marketplace.json` per section 4 → (4) add
`tests/run-gate-tests.sh` plus each plugin's copied test-helper scripts from
section 5, run them, and record pass/fail in
`docs/issue-7/reports/security-threat-model.md` (phase-2 record, out of
scope for this phase-1 PR) → (5) re-flag any core-contract unknown surfaced
during implementation (e.g. whether `core_role_directive` accepts richer
input than the base plugin's one-line `PRODUCES` positional argument) the
same way issue #2 did, rather than guessing. This ordering is a suggestion
for whoever executes phase 2, not something this phase-1 PR performs.
