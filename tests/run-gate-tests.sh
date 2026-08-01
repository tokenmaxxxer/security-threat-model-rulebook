#!/usr/bin/env bash
# security-threat-model plugin-set gate tests. Follows the
# implementation-rulebook/pricing-rulebook harness convention: temp git
# repo per case, JSON PreToolUse payload piped via stdin, exit-code
# assertion (0=allow, 2=deny).
#
# issue-10: every gate now sources core's gate-lib.sh through
# CLAUDE_PLUGIN_ROOT_CORE (core canon, referenced by path, never vendored),
# so this runner resolves it the same way the real runtime does before firing
# any gate. It then hands off to each plugin's own
# hooks/tests/run-gate-lib-tests.sh (the six mandatory gate-house-standard
# cases) and hooks/tests/parse-check.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$HERE/.."

if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ]; then
  for cand in "$HOME/tokenmaxxxer/tokenmaxxxer-core/core" \
              "$HOME/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core"; do
    if [ -f "$cand/hooks/lib/gate-lib.sh" ]; then export CLAUDE_PLUGIN_ROOT_CORE="$cand"; break; fi
  done
fi
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] || [ ! -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]; then
  echo "run-gate-tests: cannot locate core gate-lib.sh — set CLAUDE_PLUGIN_ROOT_CORE to the installed core plugin root" >&2
  exit 1
fi

PLUGINS="security-threat-model security-threat-model-stride security-threat-model-mitigation security-threat-model-canon-citation security-threat-model-residual-signoff security-threat-model-risk-rating"

pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-38s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-38s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

# run want name gate_script rel_path content
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$4" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$3" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

# run_with_survey: same as run, but seeds docs/issue-7/reports/security-threat-model/survey.md first
run_with_survey() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  if [ "${6:-}" = "with-survey" ]; then
    mkdir -p "$td/docs/issue-7/reports/security-threat-model"
    echo "survey" > "$td/docs/issue-7/reports/security-threat-model/survey.md"
  fi
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$4" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$3" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

PROPOSAL=docs/issue-7/proposals/security-threat-model.md
RECORD=docs/issue-7/reports/security-threat-model.md

echo "== base plugin: sequence-gate.sh =="
SEQ="$ROOT/security-threat-model/hooks/sequence-gate.sh"
run_with_survey deny  no-survey        "$SEQ" "$PROPOSAL" "content" no-survey
run_with_survey allow with-survey      "$SEQ" "$PROPOSAL" "content" with-survey
run           allow foreign-path       "$SEQ" "docs/issue-7/reports/qa.md" "content"

echo "== security-threat-model-stride =="
STRIDE="$ROOT/security-threat-model-stride/hooks/methodology-gate.sh"
run deny  stride-before-boundary "$STRIDE" "$RECORD" '## stride-table
Spoofing row'
# issue-10 (proposal s5.2): the category check is now per-ROW, not
# section-wide, so this fixture states an actual untagged row. A section with
# no rows at all has nothing to tag and passes structurally by design — see
# no-rows-untagged-prose-allow below.
run deny  stride-no-category     "$STRIDE" "$RECORD" '## asset-inventory
x
## trust-boundary-map
y
## stride-table
- no category here'
run allow stride-no-rows         "$STRIDE" "$RECORD" '## asset-inventory
x
## trust-boundary-map
y
## stride-table
no rows here, nothing to tag'
run allow stride-ordered-tagged  "$STRIDE" "$RECORD" '## asset-inventory
x
## trust-boundary-map
y
## stride-table
Spoofing: attacker impersonates service'
run allow no-stride-table        "$STRIDE" "$RECORD" 'nothing relevant here'

echo "== security-threat-model-risk-rating =="
RATING="$ROOT/security-threat-model-risk-rating/hooks/methodology-gate.sh"
run deny  dread-no-marker  "$RATING" "$RECORD" 'rating uses a DREAD-shaped score here'
run allow cvss-only        "$RATING" "$RECORD" 'rating: High (CVSS-style)'
run allow dread-with-marker "$RATING" "$RECORD" 'rating uses DREAD [dread-override] here'

echo "== security-threat-model-mitigation =="
MIT="$ROOT/security-threat-model-mitigation/hooks/methodology-gate.sh"
run deny  mitigation-no-vocab "$MIT" "$RECORD" '## mitigation-list
we will handle it somehow'
run allow mitigation-vocab    "$MIT" "$RECORD" '## mitigation-list
disposition: mitigate — add input validation'

echo "== security-threat-model-residual-signoff =="
SIGN="$ROOT/security-threat-model-residual-signoff/hooks/methodology-gate.sh"
run deny  residual-no-approver "$SIGN" "$RECORD" '## residual-risk-note
Low residual risk remains.'
run allow residual-with-approver "$SIGN" "$RECORD" '## residual-risk-note
Low residual risk remains. See docs/specs/approvers.md, Approved by JiwonJung94.'

echo "== security-threat-model-canon-citation =="
CANON="$ROOT/security-threat-model-canon-citation/hooks/methodology-gate.sh"
run deny  canon-pasted-script "$CANON" "$RECORD" '## canon-references
#!/usr/bin/env bash
set -uo pipefail'
run allow canon-path-only     "$CANON" "$RECORD" '## canon-references
See pricing-rulebook/pricing/hooks/methodology-gate.sh (referenced, not copied).'

echo "== cross-plugin: complete record passes every gate =="
COMPLETE='## asset-inventory
Web app, DB.
## trust-boundary-map
Internet -> LB -> app -> DB.
## stride-table
Spoofing: attacker forges session token. Rating: High.
## mitigation-list
disposition: mitigate — enforce MFA.
## residual-risk-note
Low residual risk. See docs/specs/approvers.md, Approved by JiwonJung94.
## canon-references
See pricing-rulebook/pricing/hooks/methodology-gate.sh (referenced, not copied).'
for g in "$STRIDE" "$RATING" "$MIT" "$SIGN" "$CANON"; do
  run allow "cross-plugin:$(basename "$(dirname "$(dirname "$g")")")" "$g" "$RECORD" "$COMPLETE"
done

printf '\n== cross-plugin cases: %d passed, %d failed ==\n' "$pass" "$fail"

suite_fail=0
[ "$fail" -eq 0 ] || suite_fail=1

# --- per-plugin mandatory gate-house-standard suites (issue-10 s8) ---------
for p in $PLUGINS; do
  echo
  echo "== $p: run-gate-lib-tests.sh =="
  /bin/bash "$ROOT/$p/hooks/tests/run-gate-lib-tests.sh" || suite_fail=1
done

# --- per-plugin bash-3.2 parse check --------------------------------------
for p in $PLUGINS; do
  echo
  echo "== $p: parse-check.sh =="
  /bin/bash "$ROOT/$p/hooks/tests/parse-check.sh" || suite_fail=1
done

# NB: each plugin's hooks/tests/deny-only-check.sh is run separately and is
# NOT part of this green gate. Its "no permissionDecision: allow" half passes
# on every plugin; its copied substance_probe expects an unconditional
# record-substance gate, which none of this role's six gates is (each fires
# only when its own marker is present). Carried forward from
# docs/issue-7/reports/security-threat-model.md's Open findings, restated in
# docs/issue-10/reports/security-threat-model.md.

if [ "$suite_fail" -eq 0 ]; then
  printf '\n== ALL SUITES GREEN ==\n'
else
  printf '\n== SUITE FAILURES PRESENT ==\n'
fi
exit "$suite_fail"
