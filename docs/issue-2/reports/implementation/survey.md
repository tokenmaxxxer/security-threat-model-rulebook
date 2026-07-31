# Issue #2 — Phase 1 Current-State Survey

Role: `security-threat-model`. Scope: the 5 work items in issue #2 (core canon
reference conversion, following core issue #63 warrant plugin landing and
core issue #66 role-agnostic gate landing).

## 1. What exists now (from the issue-170 seed commit `0b94a16`)

The seed commit added a full skeleton rulebook with self-contained copies of
generic infrastructure, not yet converted to reference core canon:

| Path | Role |
|---|---|
| `security-threat-model/agents/warrant-hunter.md` | Full warrant-hunter agent doc, explicitly noted in its own text as "adapted from implementation-rulebook's `agents/warrant-hunter.md`" — a duplicate copy, not a core-canon reference. |
| `security-threat-model/hooks/trailer-gate.sh` | Commit-trailer gate (`Subject: issue-<n>` enforcement). Its own header comment says "Adapted from implementation-rulebook's trailer-gate.sh, role name substituted only (this file's logic is role-agnostic)." — a textbook duplicate-copy candidate for item 2. |
| `security-threat-model/hooks/record-fields-gate.sh` | Required-field gate for this role's record. Header comment states it is role-specific (`security-threat-model`'s own required-field set, from `roles/security-threat-model.json`'s `produces`), **not** copied from another role. This is the role-unique part called out in issue item 4 (must be preserved, e.g. as `RECORD_FIELDS_TERMINAL_STATES`-style config once stubbed). |
| `security-threat-model/hooks/handbook-trigger-gate.sh` | s21 handbook-sync gate. Currently a placeholder (`exit 0 # TODO`), role-agnostic logic once implemented. |
| `security-threat-model/hooks/directive.sh` | SessionStart directive. Currently a full inline heredoc mixing generic boilerplate (kill-switch handling, `CLAUDE_ROLE` check, RECORD line format) with role-unique content (YOU DECIDE / USE_WHEN / PRODUCES / WRITE_SCOPE / HAND-OFF text pulled from this role's `decides`/`use_when`/`produces`/`write_scope`/hand-off fields). This is the target of work item 3 (stub form). |
| `security-threat-model/hooks/hooks.json` | Registers all three gates + directive locally via `${CLAUDE_PLUGIN_ROOT}/hooks/...` command paths. This is the local hook registration that work item 2 says core's registration should replace. |

No other commits exist on this branch besides the seed commit; `git log
--oneline` shows only `0b94a16`.

## 2. Mapping to the issue's 5 work items

1. **Remove warrant-hunter copy → reference core canon.**
   Target: `security-threat-model/agents/warrant-hunter.md`. This file is a
   full duplicate matching implementation-rulebook's file per its own doc
   comment. Removal/replacement candidate.

2. **Remove trailer-gate.sh / record-fields-gate.sh / handbook-trigger-gate.sh
   copies + their hook registrations (core-side registration replaces
   them).**
   Targets: the three `.sh` files under `security-threat-model/hooks/`, plus
   the `PreToolUse` entries in `security-threat-model/hooks/hooks.json` that
   wire them up (`record-fields-gate.sh`, `handbook-trigger-gate.sh`,
   `trailer-gate.sh`). Of the three, `trailer-gate.sh` and
   `handbook-trigger-gate.sh` are role-agnostic by their own comments —
   clean copy-removal candidates. `record-fields-gate.sh` is **not**
   role-agnostic (see item 4) — it cannot simply be deleted; its role-unique
   payload (the `REQUIRED_FIELDS` list) must survive the conversion, per
   item 4's explicit config-based preservation instruction.

3. **Replace `directive.sh` with a stub (shared function `source` + call +
   role-unique part only).**
   Target: `security-threat-model/hooks/directive.sh`. Current file mixes
   generic mechanics (kill-switch env var check, `CLAUDE_ROLE` gate, RECORD
   line convention) with role content (YOU DECIDE/USE_WHEN/PRODUCES/
   WRITE_SCOPE/HAND-OFF/BOUNDARY CASE text). Issue text names the shared
   function as `core_role_directive`, defined in
   `core/hooks/lib/role-directive.sh`. This function does not exist
   anywhere in this repo — this repo has no `core/` directory at all (see
   section 3). The stub must `source` it from wherever core installs it
   (likely `${CLAUDE_PLUGIN_ROOT}` of a core plugin, or a path supplied via
   an env var) and pass this role's unique fields as arguments/env, leaving
   only role-unique text inline.

4. **Preserve role-specific real differences (e.g. terminal loop_state set)
   via `RECORD_FIELDS_TERMINAL_STATES`-style explicit config.**
   Target: `security-threat-model/hooks/record-fields-gate.sh`. Its
   role-unique payload today is the Python list
   `REQUIRED_FIELDS = ["stride-table", "mitigation-list",
   "residual-risk-note"]` (matches this role's `produces` field from
   README/plugin description). No terminal `loop_state` set currently
   appears anywhere in this repo (`rg -i loop_state` finds nothing) — this
   role may not have that particular divergence yet, but the mechanism
   issue item 4 asks for (explicit named config var, not silent
   role-branch logic) applies directly to `REQUIRED_FIELDS` here.

5. **Confirm `core/hooks/tests/stub-check.sh` passes and record it.**
   No such script exists in this repo (`find . -iname 'stub-check.sh'`
   returns nothing) — it lives in the external `core` repo referenced by
   the issue (core issues #63/#66), which is not vendored or linked from
   here. Phase 2 execution will need that script pulled in (as a plugin
   dependency, submodule, or CI step) before it can be run and its result
   recorded in `docs/issue-2/reports/implementation.md` (the phase-2
   record file — out of scope for this phase-1 PR).

## 3. Precedent search — core canon / stub pattern

Searched this repo for any existing `core/`, `canon/` directory, any other
role's rulebook, or any prior "directive stub referencing canon" pattern:

```
find . -iname "*core*" -o -iname "*canon*"   # (excluding .git)
```

Only hits: this survey's own path references and the marketplace/plugin
manifests (which just name `tokenmaxxxer/security-threat-model-rulebook`,
unrelated to a `core` canon repo). There is:

- no `core/` directory in this repo,
- no other role rulebook in this repo to compare against,
- no existing "stub sources shared lib" file anywhere in this repo.

**No precedent found in this repo — the proposal in
`docs/issue-2/proposals/core-canon-reference-conversion.md` establishes the
stub pattern rather than following an established local convention.** The
issue text implies the pattern exists in the external `core` repo
(`core/hooks/lib/role-directive.sh`'s `core_role_directive` function, and
core's own hook registration for the three gates + the `warrant/` plugin),
but that repo's contents are not visible from here, so the exact call
signature of `core_role_directive` and the exact gate-registration
mechanism are assumptions to be confirmed in phase 2, not verified facts.

## 4. Role-unique content inventory (must survive conversion)

- `decides`: 신뢰 경계의 위협 표면
- `use_when`: 스펙에 신뢰 경계·인증·민감데이터가 걸릴 때
- `produces` / required record fields: STRIDE table, mitigation list per
  threat, residual risk note (currently hardcoded as
  `REQUIRED_FIELDS` in `record-fields-gate.sh` and duplicated in prose in
  `directive.sh`'s heredoc and in `README.md`)
- `write_scope`: `[]` (report-only role)
- hand-off targets: 구현 단계 취약점 점검은 → secure-coding; 법적 노출이면 →
  legal-compliance
- warrant-hunter's role-specific mandate line (quotes `decides` verbatim)
  and its scope/out-of-scope note

These currently exist in three duplicated forms (plugin.json description,
README.md, directive.sh heredoc) plus one config form
(`record-fields-gate.sh`'s `REQUIRED_FIELDS`). The conversion should
converge these to a single source of truth passed into the shared
`core_role_directive` call, per the proposal.
