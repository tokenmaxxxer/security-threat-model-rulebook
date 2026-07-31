#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — STRIDE methodology plugin,
# on top of (never instead of) the core canon record-fields-gate.sh's
# generic field-presence check and the base plugin's sequence-gate.sh.
#
# Targets: docs/issue-<n>/proposals/*security-threat-model*.md (phase-1
# proposals) and docs/issue-<n>/reports/security-threat-model.md (phase-2
# record) — this role's own write surfaces.
#
# Checks, only when a `stride-table` heading/marker is present in the
# resulting text:
#   (1) it must appear, positionally, after both an `asset-inventory` and a
#       `trust-boundary-map` heading/marker in the same document — deny
#       naming which is missing/out of order otherwise.
#   (2) the `stride-table` section's text (from that heading to the next
#       heading or end of doc) must contain at least one of the six STRIDE
#       category names or their initials — deny if none found.
# If no `stride-table` marker exists at all, this gate is not this write's
# business (core's generic field-presence gate handles absence) — exit 0.
#
# Kill switch: export SECURITY_THREAT_MODEL_STRIDE_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-security-threat-model-stride}"
deny() { echo "security-threat-model-stride: refused — $1" >&2; exit 2; }

case "${SECURITY_THREAT_MODEL_STRIDE_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

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
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (STRIDE methodology check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("security-threat-model-stride: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge STRIDE ordering/tagging on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on STRIDE methodology.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (STRIDE).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*security-threat-model.*\.md$', re.I)
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/security-threat-model\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not (PROPOSAL_RE.match(rel) or RECORD_RE.match(rel)):
        sys.exit(0)  # not this role's write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on STRIDE methodology." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so STRIDE ordering/tagging can be "
            "checked." % (rel, tool)
        )

    # Locate heading/marker positions. A "heading/marker" is either a markdown
    # heading line whose text contains the token, or a bare occurrence of the
    # token itself (e.g. a field-style marker such as `stride-table:`).
    def find_marker(text, token):
        pat = re.compile(
            r'(?im)^(?:#{1,6}[ \t]*.*\b' + token + r'\b.*|.*\b' + token + r'\b.*:.*)$'
        )
        m = pat.search(text)
        if m:
            return m.start()
        # fallback: first bare occurrence of the token anywhere
        m2 = re.search(r'(?i)\b' + token + r'\b', text)
        return m2.start() if m2 else None

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

    if missing_order:
        deny(
            "a `stride-table` is present but the required precondition order "
            "asset-inventory -> trust-boundary-map -> stride-table is not satisfied: "
            "%s. Per docs/issue-1/proposals/security-threat-model.md (b), the asset "
            "inventory and trust-boundary map must both precede the STRIDE table." % ", ".join(missing_order)
        )

    # 2. stride-table section text must carry at least one STRIDE category
    #    name or isolated initial.
    line_end = new_text.find("\n", stride_pos)
    scan_from = line_end + 1 if line_end != -1 else len(new_text)
    next_heading = re.search(r'(?m)^#{1,6}[ \t]', new_text[scan_from:])
    section_end = scan_from + next_heading.start() if next_heading else len(new_text)
    section_text = new_text[stride_pos:section_end]

    category_names = (
        "spoofing", "tampering", "repudiation",
        "information disclosure", "denial of service", "elevation of privilege",
    )
    has_name = any(cn in section_text.lower() for cn in category_names)
    has_initial = re.search(r'(?<![A-Za-z])[STRIDE](?![A-Za-z])', section_text) is not None

    if not (has_name or has_initial):
        deny(
            "the `stride-table` section carries no STRIDE category tag (Spoofing, "
            "Tampering, Repudiation, Information Disclosure, Denial of Service, "
            "Elevation of Privilege, or an isolated S/T/R/I/D/E initial). Per "
            "docs/issue-1/proposals/security-threat-model.md (b), every stride-table "
            "row must carry a STRIDE category tag."
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
