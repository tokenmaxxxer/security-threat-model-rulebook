#!/usr/bin/env bash
# security-threat-model-risk-rating — the seven mandatory gate-house-standard
# test cases (issue-10 proposal s8; 7th group added issue-13, mirroring
# core #75's own bump to seven groups), run against this plugin's own gate
# as a real subprocess.
#
# Harness shape follows tests/run-gate-tests.sh at this repo's root (temp
# git repo per case, JSON PreToolUse payload on stdin, exit-code assertion:
# 0=allow, 2=deny). The six mandatory cases are the ones core's
# docs/handbooks/gate-house-standard.md requires of every migrated gate;
# that handbook and core/hooks/lib/gate-lib.{sh,py} are referenced by path
# here, never copied.
#
# NB: `pipefail` is deliberately NOT set. Every case feeds the gate over a
# pipe, and when the kill switch legitimately disables the gate it exits 0
# without draining stdin — the writing `printf` then takes SIGPIPE (141) and
# `pipefail` would report the pipeline as failed even though the gate under
# test exited 0.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/.."
GATE="$HOOKS/methodology-gate.sh"

# The gate sources core's gate-lib.sh via CLAUDE_PLUGIN_ROOT_CORE; this
# harness resolves it the same way the real runtime does, since this repo
# deliberately keeps no vendored copy of core.
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ]; then
  for cand in "$HOME/tokenmaxxxer/tokenmaxxxer-core/core" \
              "$HOME/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core"; do
    if [ -f "$cand/hooks/lib/gate-lib.sh" ]; then export CLAUDE_PLUGIN_ROOT_CORE="$cand"; break; fi
  done
fi
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] || [ ! -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]; then
  echo "run-gate-lib-tests: cannot locate core gate-lib.sh — set CLAUDE_PLUGIN_ROOT_CORE to the installed core plugin root" >&2
  exit 1
fi

pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-64s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-64s want=%s got=%s\n' "$3" "$1" "$2"; fi; }
jstr() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

TARGET=docs/issue-999/reports/security-threat-model.md

mktd() { _td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$_td"; mkdir -p "$_td/$(dirname "$TARGET")"; printf '%s' "$_td"; }
seed_allow() { :; }

fire() { # td payload  -> sets $got
  printf '%s' "$2" | env CLAUDE_PROJECT_DIR="$1" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
}

write_payload() { # file_path content
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$1" "$(jstr "$2")"
}

write_case() { # want name content [seed]
  td="$(mktd)"
  if [ "${4:-}" = seed ]; then seed_allow "$td"; fi
  fire "$td" "$(write_payload "$TARGET" "$3")"
  rm -rf "$td"; report "$1" "$got" "$2"
}

raw_case() { # want name raw_payload
  td="$(mktd)"; fire "$td" "$3"; rm -rf "$td"; report "$1" "$got" "$2"
}

DENY_CONTENT='rating uses a DREAD-shaped score here'

ALLOW_CONTENT='rating: High (CVSS-style qualitative severity)'

RA_BASE='rating: dread score for the trust-boundary finding [dread-override]
rating: dread score for the second finding [dread-override]'

# ---------------------------------------------------------------- baseline
write_case deny  "baseline: a would-be-refused write denies" "$DENY_CONTENT"
write_case allow "baseline: a conforming write allows"       "$ALLOW_CONTENT" 

# --- mandatory case 1: Edit + replace_all:true against a multiply-occurring
# old_string. Before the issue-10 migration this gate hand-rolled
# `.replace(o, n, 1)` and never read replace_all, so it judged a document
# that was never going to be written. The fixture is built so the verdict
# depends on every occurrence having been replaced.
edit_replace_all_case() {
  td="$(mktd)"; 
  printf '%s\n' "$RA_BASE" > "$td/$TARGET"
  fire "$td" "$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":%s,"new_string":%s,"replace_all":true}}' \
    "$TARGET" "$(jstr '[dread-override]')" "$(jstr '(no marker)')")"
  rm -rf "$td"; report deny "$got" "Edit replace_all:true over a multiply-occurring old_string is judged on ALL occurrences"
}
edit_replace_all_case

# --- mandatory case 2: MultiEdit mixing replace_all true and false in one
# call; each edit's own flag must be honoured independently.
multiedit_case() {
  td="$(mktd)"; 
  printf '%s\n' "$RA_BASE" > "$td/$TARGET"
  fire "$td" "$(printf '{"tool_name":"MultiEdit","tool_input":{"file_path":"%s","edits":%s}}' "$TARGET" '[{"old_string":"[dread-override]","new_string":"(no marker)","replace_all":true},{"old_string":"second finding","new_string":"2nd finding","replace_all":false}]')"
  rm -rf "$td"; report deny "$got" "MultiEdit mixing replace_all true/false honours each edit own flag"
}
multiedit_case

# --- mandatory case 3: malformed JSON must deny, never pass through on a
# best-effort guess.
raw_case deny "malformed JSON: truncated payload denies"    '{"tool_name":"Write","tool_input":{"file_path":'
raw_case deny "malformed JSON: non-object top level denies" '"just a bare string"'
raw_case deny "malformed JSON: empty payload denies"        ''

# --- mandatory case 4: an UNRECOGNIZED kill-switch value must leave the gate
# ACTIVE. The pre-issue-10 `case ... in ""|0|false|no|off) ;; *) exit 0` idiom
# disabled the gate on any value outside its five-item off-list, so a typo
# silently fail-opened it.
kill_switch_case() { # want name value
  td="$(mktd)"
  printf '%s' "$(write_payload "$TARGET" "$DENY_CONTENT")" \
    | env CLAUDE_PROJECT_DIR="$td" SECURITY_THREAT_MODEL_RISK_RATING_GATE_OFF="$3" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}
kill_switch_case deny  "kill switch set to an unrecognized value (typo) stays ACTIVE"        "offf"
kill_switch_case deny  "kill switch set to a recognized OFF-spelling stays ACTIVE"           "off"
kill_switch_case allow "kill switch set to a recognized on-spelling (1) disables the gate"   "1"

# --- mandatory case 5: an absolute file_path, and a ./-prefixed one, must
# resolve into exactly the same scope the relative fixture matches.
path_case() { # want name file_path_template
  td="$(mktd)"; fp="$3"; fp="${fp/__ROOT__/$td}"
  fire "$td" "$(write_payload "$fp" "$DENY_CONTENT")"
  rm -rf "$td"; report "$1" "$got" "$2"
}
path_case deny  "absolute file_path resolves to the same scope as the relative fixture"    "__ROOT__/$TARGET"
path_case deny  "./-prefixed file_path resolves to the same scope as the relative fixture" "./$TARGET"
path_case allow "a path resolving OUTSIDE the project root is not this gate business"      "__ROOT__/../outside-probe/$TARGET"

# --- mandatory case 6: a Bash-tool write reaching the same target. This
# plugin hooks.json matcher is Write|Edit|MultiEdit only, so a Bash command
# writing the same file is NOT inspected today. Asserted here as a
# deliberate, documented no-coverage boundary (gate-house-standard.md sixth
# case), so that widening the matcher to Bash cannot land silently
# unguarded. core gate_bash_write_targets is the function that would extract
# the path tokens once this gate starts matching Bash.
bash_case() {
  td="$(mktd)"
  fire "$td" "$(printf '{"tool_name":"Bash","tool_input":{"command":"echo bad >> %s"}}' "$TARGET")"
  rm -rf "$td"; report allow "$got" "Bash-tool write to the same target: currently a no-op (matcher is Write|Edit|MultiEdit)"
}
bash_case

# --- mandatory case 7: missing-core -> CLAUDE_PLUGIN_ROOT_CORE pointed at a
# nonexistent path must deny (exit 2), not silently allow. Regression test
# for the guard added at methodology-gate.sh:2 (core #75's guard shape,
# issue-13).
missing_core_case() {
  td="$(mktd)"
  printf '%s' "$(write_payload "$TARGET" "$DENY_CONTENT")" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" "missing-core: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere denies (issue-13/core #75 guard fix, not silent-allow)"
}
missing_core_case

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
