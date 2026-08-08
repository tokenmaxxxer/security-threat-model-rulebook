---
proposal: docs/issue-20/proposals/implementation-proposal.md
---

# Hunt record — implementation-proposal

## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the proposal's step-2 per-row field check reuses the section-marker "line-start `token:`" detection discipline for markdown-table-cell fields, but no stride-table row in this repo (or producible by the table-row shape the gate already parses) is ever a line-start `token:` line — every row is a `|`-prefixed table line, so the proposed marker state can never be satisfied and the extended check would deny every existing/future compliant stride-table row.
Kind: design-error
Seed: docs/issue-20/proposals/implementation-proposal.md (step 2, "extend the existing per-row walk ... to also deny naming the first row missing any of element/title/description/status/mitigation as a line-start `field:` marker or equivalent inline label — same marker-detection discipline the file's docstring already states for stride-table/asset-inventory/trust-boundary-map (heading or `token:` field marker, never mid-sentence prose)")
cap_seconds: 120
tier: default
diff_stat_lines: 262 (2 files, docs-only)
started_at: 2026-08-09T00:00:00+09:00
ended_at: 2026-08-09T00:05:00+09:00

### Reproduce
Applied the existing gate's own `find_marker`-equivalent line-start-token regex (copied verbatim from `security-threat-model-stride/hooks/methodology-gate.sh`) to a stride-table row that legitimately carries all five proposed fields as table cells, exactly the row shape the gate's own test fixtures use (`security-threat-model-stride/hooks/tests/run-gate-lib-tests.sh:199-204`, e.g. `| session forgery | Spoofing | high |`):

    python3 - <<'PY'
    import re
    def find_marker_line(line, token):
        pat = re.compile(r'(?im)^(?:#{1,6}[ \t]*.*\b' + token + r'\b.*|[ \t]*' + token + r'[ \t]*:.*)$')
        return pat.search(line) is not None

    row = "| Attacker spoofs session | Spoofing | element: Login API | title: Session spoofing | description: attacker forges session token | status: open | mitigation: MFA |"
    for token in ["element","title","description","status","mitigation"]:
        print(token, find_marker_line(row, token))
    PY

### Observed
    element False
    title False
    description False
    status False
    mitigation False

Every field evaluates False even though the row plainly carries all five field labels with values, because the row (like every real stride-table row in this repo's own fixtures — a `|`-delimited markdown table cell) never starts the line with a bare `token:` — it starts with `|`, and the "heading or line-start `token:`" marker grammar the proposal says to reuse has no notion of "marker inside a table cell." Implementing step 2 literally as specified would therefore deny every stride-table row, compliant or not, since the state the check depends on (a row that is simultaneously a table row and a line-start marker) does not and cannot exist under the row shape the same gate file already parses and tests.

### Expected
Either the proposal should specify a table-cell-aware field grammar for per-row checks (distinct from the document-level heading/line-start-token marker grammar it explicitly says to reuse), or it should not claim the existing marker-detection discipline is directly reusable at the row level — as written, the rule names a marker format with no state (no document shape) in this repo that would ever produce it.
