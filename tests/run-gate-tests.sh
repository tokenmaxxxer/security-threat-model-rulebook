#!/usr/bin/env bash
# security-threat-model plugin-set gate tests. Follows the
# implementation-rulebook/pricing-rulebook harness convention: temp git
# repo per case, JSON PreToolUse payload piped via stdin, exit-code
# assertion (0=allow, 2=deny).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$HERE/.."
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
run deny  stride-no-category     "$STRIDE" "$RECORD" '## asset-inventory
x
## trust-boundary-map
y
## stride-table
no category here'
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

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
