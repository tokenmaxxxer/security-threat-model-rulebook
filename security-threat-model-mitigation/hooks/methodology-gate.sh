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
# PreToolUse gate (Write|Edit|MultiEdit) — security-threat-model-mitigation
# role-specific, on top of (never instead of) the core canon
# record-fields-gate.sh's generic §20 fields.
#
# Targets: docs/issue-<n>/proposals/*security-threat-model*.md (phase-1
# proposals) and docs/issue-<n>/reports/security-threat-model.md (phase-2
# record) — this role's own write surfaces per
# docs/issue-1/proposals/methodology-norms.md (a)/(b).
#
# Requires that, when a `mitigation-list` heading/marker is present, the
# text of that section (from the heading to the next heading or end of
# document) contains at least one of the four risk-disposition terms
# (accept/mitigate/transfer/avoid) or their stated Korean equivalents
# (수용/완화/전가/회피). Fails closed when the section is present but the
# disposition vocabulary is absent, mirroring record-fields-gate.sh's
# fail-closed pattern. If no `mitigation-list` marker exists at all, this
# gate has nothing to check and exits 0.
#
# Kill switch: export SECURITY_THREAT_MODEL_MITIGATION_GATE_OFF=1 (any other value — including a typo —
# leaves the gate ACTIVE, per gate_kill_switch_active's fixed
# on-spelling set 1/true/yes/on).
set -uo pipefail

role="${CLAUDE_ROLE:-security-threat-model-mitigation}"
deny() { echo "security-threat-model-mitigation: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${SECURITY_THREAT_MODEL_MITIGATION_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "methodology-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "methodology-gate: empty tool-use payload on stdin; cannot evaluate the methodology gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (methodology check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("security-threat-model-mitigation: refused — %s\n" % m); sys.exit(2)

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
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (methodology).")

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
        sys.exit(0)  # not a security-threat-model methodology write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on methodology." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the mitigation-list disposition "
            "vocabulary can be checked." % (rel, tool)
        )

    # Locate a `mitigation-list` heading/marker. Markdown heading (any
    # level) or an inline marker token both count.
    heading_re = re.compile(r'^(#{1,6})[ \t]*.*mitigation-list.*$', re.I | re.M)
    marker_re = re.compile(r'mitigation-list', re.I)

    m = heading_re.search(new_text)
    if m is None:
        if marker_re.search(new_text) is None:
            # No mitigation-list marker anywhere in the document — not this
            # gate's business.
            sys.exit(0)
        # A bare `mitigation-list` token exists with no heading form; scope
        # the check to the rest of the document from that token onward.
        mk = marker_re.search(new_text)
        section = new_text[mk.start():]
    else:
        # Section runs from this heading to the next heading of equal-or-
        # higher rank, or to the end of the document.
        level = len(m.group(1))
        start = m.end()
        next_heading_re = re.compile(r'^#{1,%d}[ \t]+\S' % level, re.M)
        nm = next_heading_re.search(new_text, start)
        section = new_text[start:nm.start()] if nm else new_text[start:]

    disposition_terms_en = ("accept", "mitigate", "transfer", "avoid")
    disposition_terms_ko = ("수용", "완화", "전가", "회피")

    low = section.lower()
    has_en = any(t in low for t in disposition_terms_en)
    has_ko = any(t in section for t in disposition_terms_ko)

    if not (has_en or has_ko):
        deny(
            "the `mitigation-list` section in %s contains none of the required "
            "risk-disposition terms (accept/mitigate/transfer/avoid, or their "
            "Korean equivalents 수용/완화/전가/회피). Per docs/issue-7/proposals/"
            "security-threat-model.md section 2.3, every mitigation-list entry "
            "must carry a disposition using one of these four terms." % rel
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("methodology-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "security-threat-model-mitigation: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
