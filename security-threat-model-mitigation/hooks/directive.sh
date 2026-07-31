#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "directive.sh: fail-closed: aborted (rc=$rc)" >&2; exit 0; fi; }
trap __fc EXIT
# SessionStart addition — risk-disposition vocabulary framing. Not a second
# core_role_directive stub (that positional call stays solely in the base
# `security-threat-model` plugin); this only prints phase-1 framing text so it
# shows up in session context. Non-blocking: this is a print, not a gate, so
# it always exits 0 on a normal run.
set -uo pipefail

cat <<'EOF'
[security-threat-model-mitigation] Risk-disposition vocabulary rule:
- Every `mitigation-list` entry must carry a disposition using one of the
  four standing risk-disposition terms: accept / mitigate / transfer /
  avoid.
- 이 역할의 지침문은 이중 언어로 작성됩니다: 위 네 가지 용어에 대응하는
  한국어 표현(수용 / 완화 / 전가 / 회피) 중 하나를 대신 사용해도 됩니다.
- A mitigation-list entry with no disposition term (English or Korean) is
  incomplete — name the disposition before moving to the next threat.
EOF
