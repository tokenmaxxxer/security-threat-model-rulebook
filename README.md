# security-threat-model-rulebook

Rulebook for the `security-threat-model` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion. Seeded
as skeleton scaffolding by issue-170 and since implemented as a six-plugin
methodology enforcement set (issue-7), migrated onto core's generalized
gate-lib (issue-10), and brought to gate-house-standard A+ compliance
(issue-13) — see "Plugins" and "Layout" below for the current shape.

- **decides**: 신뢰 경계의 위협 표면
- **use_when**: 스펙에 신뢰 경계·인증·민감데이터가 걸릴 때
- **produces**: STRIDE table, mitigation list per threat, residual risk note
- **write_scope**: []
- **hand-off**: 구현 단계 취약점 점검은 → secure-coding; 법적 노출이면 → legal-compliance

## Install

```
claude plugin marketplace add tokenmaxxxer/security-threat-model-rulebook
claude plugin install security-threat-model
```

The five methodology plugins install the same way, by name:
`security-threat-model-stride`, `security-threat-model-risk-rating`,
`security-threat-model-mitigation`,
`security-threat-model-residual-signoff`,
`security-threat-model-canon-citation`. All six are registered in
`.claude-plugin/marketplace.json`.

## Plugins

| plugin | gate | kill switch |
| --- | --- | --- |
| `security-threat-model` (base: role identity, hand-off, phase-1 sequence precondition) | `hooks/sequence-gate.sh` | `SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF` |
| `security-threat-model-stride` | `hooks/methodology-gate.sh` | `SECURITY_THREAT_MODEL_STRIDE_GATE_OFF` |
| `security-threat-model-risk-rating` | `hooks/methodology-gate.sh` | `SECURITY_THREAT_MODEL_RISK_RATING_GATE_OFF` |
| `security-threat-model-mitigation` | `hooks/methodology-gate.sh` | `SECURITY_THREAT_MODEL_MITIGATION_GATE_OFF` |
| `security-threat-model-residual-signoff` | `hooks/methodology-gate.sh` | `SECURITY_THREAT_MODEL_RESIDUAL_SIGNOFF_GATE_OFF` |
| `security-threat-model-canon-citation` | `hooks/methodology-gate.sh` | `SECURITY_THREAT_MODEL_CANON_CITATION_GATE_OFF` |

A kill switch disables its gate only on a recognized on-spelling
(`1`/`true`/`yes`/`on`, case-insensitive). Every other value — including a
typo — leaves the gate **active**, per core's `gate_kill_switch_active`.

## Layout

Every plugin directory carries the same shape:

- `<plugin>/.claude-plugin/plugin.json` — plugin manifest
- `<plugin>/hooks/hooks.json` — SessionStart + PreToolUse (`Write|Edit|MultiEdit`) wiring
- `<plugin>/hooks/directive.sh` — SessionStart directive
- `<plugin>/hooks/methodology-gate.sh` (base plugin: `hooks/sequence-gate.sh`) — this plugin's PreToolUse gate
- `<plugin>/hooks/tests/run-gate-lib-tests.sh` — the six mandatory gate-house-standard cases against this plugin's gate
- `<plugin>/hooks/tests/parse-check.sh`, `<plugin>/hooks/tests/deny-only-check.sh` — canon-scripts.md named-exception verbatim copies

Base plugin only:

- `security-threat-model/hooks/record-fields.env` — required-field config consumed by core's generalized record-fields gate
- `security-threat-model/agents/warrant-hunter.md` — rotating-stance hunt agent

Repo root:

- `.claude-plugin/marketplace.json` — registers all six plugins
- `tests/run-gate-tests.sh` — the test entrypoint: cross-plugin cases, then each plugin's `run-gate-lib-tests.sh` and `parse-check.sh`
- `docs/handbooks/security-threat-model.md` — this role's handbook
- `docs/specs/approvers.md` — Approve-authority allowlist

## Core dependency

Every gate sources core's `core/hooks/lib/gate-lib.sh` (and, from its Python
judge, `core/hooks/lib/gate-lib.py` via the `GATE_LIB_PY` env var that
sourcing exports) for the fail-closed trap, kill switch, JSON-parse-or-deny,
absolute-path normalization, and Write/Edit/MultiEdit/NotebookEdit content
reconstruction. Core is referenced by path, never vendored into this repo.
Set `CLAUDE_PLUGIN_ROOT_CORE` to an installed core plugin root; the gates
otherwise fall back to a `../../core` sibling of the plugin directory.
