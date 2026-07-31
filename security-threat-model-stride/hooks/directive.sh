#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "directive.sh: fail-closed: aborted (rc=$rc)" >&2; exit 0; fi; }
trap __fc EXIT
# SessionStart addition — STRIDE methodology framing checklist. Not a second
# core_role_directive stub (that positional call stays solely in the base
# `security-threat-model` plugin); this only prints phase-1 framing text so it
# shows up in session context. Non-blocking: this is a print, not a gate, so
# it always exits 0 on a normal run.
set -uo pipefail

cat <<'EOF'
[security-threat-model-stride] STRIDE methodology framing checklist:
- Frame scope first: where does this spec touch a trust boundary,
  authentication, or sensitive-data handling? Name those touchpoints before
  enumerating threats.
- STRIDE is the standing default methodology for threat enumeration
  (issue-1 proposal (b).1-3) unless a documented reason routes elsewhere.
- Precondition order for the record: asset-inventory -> trust-boundary-map ->
  stride-table. Each element must exist, in that order, before the next.
- Judgment criterion for specs with no trust boundary in view:
  BOUNDARY_CASE (a boundary exists but is not yet named — keep working the
  spec until it is) vs HAND_OFF (no trust boundary applies to this spec at
  all — hand off rather than force a STRIDE table where none belongs).
EOF
