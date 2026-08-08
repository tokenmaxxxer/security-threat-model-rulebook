#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "methodology-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
# ^ fail-closed: the `||` guard on the source line above is what makes a
#   failed source itself deny (exit 2) instead of silently no-op'ing past a
#   missing gate-lib.sh; gate_trap_fail_closed then covers everything after
#   a successful source (core issue-72, adopted here by issue-10; guard
#   mandated by core #75). Any abnormal termination (set -u abort, unbound
#   var) before the verdict logic runs is forced to exit 2 (DENY), since a
#   PreToolUse hook treats any non-2 exit as NON-BLOCKING (fail-OPEN).
#   Installed as the FIRST executable statement, above `set -uo pipefail`.
#   gate-lib.sh is referenced by path, never vendored; sourcing it also
#   exports GATE_LIB_PY for the Python judge below.
# PreToolUse gate (Write|Edit|MultiEdit) — STRIDE methodology plugin,
# on top of (never instead of) the core canon record-fields-gate.sh's
# generic field-presence check and the base plugin's sequence-gate.sh.
#
# Targets: docs/issue-<n>/proposals/*security-threat-model*.md (phase-1
# proposals) and docs/issue-<n>/reports/security-threat-model.md (phase-2
# record) — this role's own write surfaces.
#
# A `stride-table`/`asset-inventory`/`trust-boundary-map` "marker" is a
# markdown heading carrying the token, or a line-start `token:` field marker
# — never a mid-sentence prose mention (issue-10 proposal s5.1).
#
# Checks, only when a `stride-table` marker is present in the resulting text:
#   (1) all three pairwise orderings of asset-inventory ->
#       trust-boundary-map -> stride-table must hold — deny naming which is
#       missing/out of order otherwise (issue-10 proposal s4).
#   (2) EVERY row of the `stride-table` section (markdown table rows, or
#       list items when the section has no table) other than the table's own
#       header/separator row must carry one of the six STRIDE category names
#       or an isolated initial — deny naming the first untagged row
#       (issue-10 proposal s5.2). A section with no rows has nothing to tag
#       and passes structurally.
#   (3) EVERY checkable row must also carry the marketplace spec's five
#       sibling per-row fields (issue-20; roles/specs/security-threat-model
#       .spec.json) — `element`, `title`, `description`, `status`,
#       `mitigation` (`type` is already covered by check (2)'s STRIDE
#       category tag). A field counts as present on a pipe-table row either
#       via a header column whose name contains the field word (case
#       -insensitive) with a non-empty cell at that column on the row, or
#       via an inline `field:`/`field=` token anywhere in the row text; a
#       list-item row (no header row exists) only has the inline-token
#       route. Deny naming the first row missing any of the five fields.
# If no `stride-table` marker exists at all, this gate is not this write's
# business (core's generic field-presence gate handles absence) — exit 0.
#
# Kill switch: export SECURITY_THREAT_MODEL_STRIDE_GATE_OFF=1 (any other value — including a typo —
# leaves the gate ACTIVE, per gate_kill_switch_active's fixed
# on-spelling set 1/true/yes/on).
set -uo pipefail

role="${CLAUDE_ROLE:-security-threat-model-stride}"
deny() { echo "security-threat-model-stride: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${SECURITY_THREAT_MODEL_STRIDE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "methodology-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "methodology-gate: empty tool-use payload on stdin; cannot evaluate the STRIDE methodology gate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
# `_plausible`/root-detection stays bash-side (issue-10 proposal s3): the
# in-root/out-of-root decision is now made once, by
# gate_lib.gate_normalize_path in the Python judge below, so the old
# bash-side `_under()` pre-check is gone.

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (STRIDE methodology check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("security-threat-model-stride: refused — %s\n" % m); sys.exit(2)

    # core canon gate-lib.py, loaded by path (never vendored) — supplies
    # gate_parse_json_or_deny, gate_normalize_path, gate_reconstruct_write.
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (STRIDE).")

    root = posixpath.normpath(os.path.realpath(os.environ["PG_ROOT"]).replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*security-threat-model.*\.md$', re.I)
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/security-threat-model\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    # Absolute, relative, and `./`-prefixed file_path all normalize the same
    # way here (core canon gate_normalize_path); None = resolves outside the
    # project root, which is not this gate's business.
    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    r = posixpath.join(root, rel) if rel else root
    if not (PROPOSAL_RE.match(rel) or RECORD_RE.match(rel)):
        sys.exit(0)  # not this role's write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on STRIDE methodology." % rel)

    # Post-write content reconstruction is core canon's
    # gate_lib.gate_reconstruct_write (Write/Edit/MultiEdit/NotebookEdit,
    # each edit's own replace_all honoured) — the hand-rolled
    # `.replace(o, n, 1)` this gate used before issue-10 always replaced the
    # first occurrence only and never saw replace_all.
    new_text, _recon_ok = gate_lib.gate_reconstruct_write(tool, ti, current)

    if not _recon_ok or new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so STRIDE ordering/tagging can be "
            "checked." % (rel, tool)
        )

    # Locate heading/marker positions (issue-10 proposal s5.1: structural, not
    # substring). A marker counts ONLY as either
    #   (a) a markdown heading line whose text carries the token, or
    #   (b) a line-start field marker, `token:` at the start of its own line.
    # The pre-issue-10 "first bare occurrence of the token anywhere" fallback
    # is gone: a mid-sentence mention (e.g. "관련 stride-table 논의는 나중에")
    # is prose, not a section, and must no longer satisfy the marker.
    def find_marker(text, token):
        pat = re.compile(
            r'(?im)^(?:#{1,6}[ \t]*.*\b' + token + r'\b.*|[ \t]*' + token + r'[ \t]*:.*)$'
        )
        m = pat.search(text)
        return m.start() if m else None

    stride_pos = find_marker(new_text, "stride-table")
    if stride_pos is None:
        sys.exit(0)  # no stride-table marker at all — not this gate's business

    asset_pos = find_marker(new_text, "asset-inventory")
    boundary_pos = find_marker(new_text, "trust-boundary-map")

    missing_order = []
    if asset_pos is None:
        missing_order.append("asset-inventory")
    elif asset_pos > stride_pos:
        missing_order.append("asset-inventory (present but after stride-table)")

    if boundary_pos is None:
        missing_order.append("trust-boundary-map")
    elif boundary_pos > stride_pos:
        missing_order.append("trust-boundary-map (present but after stride-table)")

    # Third pairwise ordering (issue-10 proposal s4): asset-inventory must also
    # precede trust-boundary-map. Before issue-10 only the two
    # ...-> stride-table orderings were enforced, so an inverted
    # trust-boundary-map -> asset-inventory -> stride-table document passed
    # while violating the gate's own documented three-way order. Feeds the
    # same missing_order list and the same single deny call below.
    if asset_pos is not None and boundary_pos is not None and asset_pos > boundary_pos:
        missing_order.append("asset-inventory (present but after trust-boundary-map)")

    if missing_order:
        deny(
            "a `stride-table` is present but the required precondition order "
            "asset-inventory -> trust-boundary-map -> stride-table is not satisfied: "
            "%s. Per docs/issue-1/proposals/security-threat-model.md (b), the asset "
            "inventory and trust-boundary map must both precede the STRIDE table." % ", ".join(missing_order)
        )

    # 2. EVERY stride-table row must carry a STRIDE category tag (issue-10
    #    proposal s5.2). Before issue-10 this was a section-wide scan: one
    #    "Spoofing" (or one stray isolated letter) anywhere in the section
    #    satisfied the whole table, which is a much weaker bar than the rule
    #    the gate itself cites. Now each row is checked on its own.
    line_end = new_text.find("\n", stride_pos)
    scan_from = line_end + 1 if line_end != -1 else len(new_text)
    next_heading = re.search(r'(?m)^#{1,6}[ \t]', new_text[scan_from:])
    section_end = scan_from + next_heading.start() if next_heading else len(new_text)
    section_body = new_text[scan_from:section_end]

    category_names = (
        "spoofing", "tampering", "repudiation",
        "information disclosure", "denial of service", "elevation of privilege",
    )

    def tagged(row):
        if any(cn in row.lower() for cn in category_names):
            return True
        return re.search(r'(?<![A-Za-z])[STRIDE](?![A-Za-z])', row) is not None

    body_lines = section_body.splitlines()

    # Rows are markdown table rows (lines starting with `|`); if the section
    # contains no `|` row at all, list-item lines (`-`, `*`, or `<digit>.`)
    # are the rows instead. A section with no rows of either shape has
    # nothing to tag and passes structurally — "the field must be non-empty"
    # is core's record-fields gate's job, not this one's.
    pipe_rows = [(i, l) for i, l in enumerate(body_lines) if l.lstrip().startswith("|")]
    header_field_idx = {}
    if pipe_rows:
        rows = pipe_rows
        # The table's own header row and separator row carry column labels,
        # not threats. The separator is the `|---|:--:|` line; the header is
        # the row immediately above it.
        skip = set()
        header_line = None
        for k, (i, l) in enumerate(rows):
            if re.match(r'^\s*\|[\s:|\-]+\|?\s*$', l) and "-" in l:
                skip.add(k)
                if k > 0:
                    skip.add(k - 1)
                    header_line = rows[k - 1][1]
        checkable = [(k, l) for k, (i, l) in enumerate(rows) if k not in skip]
        # issue-20: map each of the five sibling per-row fields onto a
        # header column, if the header names one — a column whose text
        # contains the field word (case-insensitive) counts, e.g. a
        # "Boundary/asset" column matches `element`.
        if header_line is not None:
            header_cells = [c.strip().lower() for c in header_line.strip().strip("|").split("|")]
            for field in ("element", "title", "description", "status", "mitigation"):
                for idx, cell in enumerate(header_cells):
                    if field in cell:
                        header_field_idx[field] = idx
                        break
    else:
        rows = [(i, l) for i, l in enumerate(body_lines)
                if re.match(r'^\s*(?:[-*]|\d+\.)\s+\S', l)]
        checkable = [(k, l) for k, (i, l) in enumerate(rows)]

    def row_field_present(row, field):
        idx = header_field_idx.get(field)
        if idx is not None:
            cells = [c.strip() for c in row.strip().strip("|").split("|")]
            if idx < len(cells) and cells[idx]:
                return True
        return re.search(r'(?i)\b' + field + r'\s*[:=]', row) is not None

    for k, row in checkable:
        if not tagged(row):
            deny(
                "stride-table row #%d in %s carries no STRIDE category tag (Spoofing, "
                "Tampering, Repudiation, Information Disclosure, Denial of Service, "
                "Elevation of Privilege, or an isolated S/T/R/I/D/E initial). Per "
                "docs/issue-1/proposals/security-threat-model.md (b), EVERY stride-table "
                "row must carry a STRIDE category tag — one tagged row elsewhere in the "
                "section does not cover an untagged one. Offending row: %s"
                % (k + 1, rel, row.strip()[:120])
            )
        missing_fields = [f for f in ("element", "title", "description", "status", "mitigation")
                           if not row_field_present(row, f)]
        if missing_fields:
            deny(
                "stride-table row #%d in %s is missing the per-threat field(s) %s required by "
                "roles/specs/security-threat-model.spec.json (marketplace, on-the-record). A "
                "field counts as present via a matching header column with a non-empty cell, "
                "or an inline `field:`/`field=` token in the row. Offending row: %s"
                % (k + 1, rel, ", ".join(missing_fields), row.strip()[:120])
            )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("methodology-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "security-threat-model-stride: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
