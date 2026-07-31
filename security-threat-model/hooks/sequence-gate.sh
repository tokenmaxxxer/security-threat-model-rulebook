#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — base security-threat-model plugin's
# sequence-precondition gate: a phase-1 proposal write must not happen before
# this issue's phase-1 survey exists. Mirrors
# implementation-rulebook/coding/hooks/coding-progress-gate.sh's precondition
# pattern (referenced, not copied) and pricing-rulebook's
# pricing/hooks/methodology-gate.sh's script skeleton.
#
# Targets: docs/issue-<n>/proposals/*security-threat-model*.md only. For any
# other path, this is not this gate's business.
#
# Requires docs/issue-<n>/reports/security-threat-model/survey.md to already
# exist as a file under the project root; denies naming the missing path and
# citing contract v3 s19 rigor floor / scout-directive survey-first-order
# when it does not.
#
# Kill switch: export SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-security-threat-model}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

case "${SECURITY_THREAT_MODEL_SEQUENCE_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "sequence-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "sequence-gate: empty tool-use payload on stdin; cannot evaluate the sequence gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (sequence check cannot run)."

SG_PAYLOAD="$payload" SG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("security-threat-model: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("SG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge sequence ordering on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on sequence ordering.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (sequence).")

    root = posixpath.normpath(os.environ["SG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*security-threat-model.*\.md$', re.I)

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
    m = PROPOSAL_RE.match(rel)
    if not m:
        sys.exit(0)  # not a phase-1 proposal write surface — not this gate's business

    issue_no = m.group(1)
    survey_rel = "docs/issue-%s/reports/security-threat-model/survey.md" % issue_no
    survey_abs = posixpath.join(root, survey_rel)

    if not os.path.isfile(survey_abs):
        deny(
            "%s is a phase-1 proposal write for issue-%s, but %s does not exist. "
            "Per contract v3 s19 rigor floor / scout-directive survey-first-order, "
            "phase-1 proposals require the survey to exist first." % (rel, issue_no, survey_rel)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("sequence-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "security-threat-model: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
