#!/usr/bin/env bash
# SessionStart: security-threat-model's role directive — stub form (core
# canon reference conversion, issue #2). All boilerplate (kill-switch,
# CLAUDE_ROLE guard, fail-closed trap) now lives in core_role_directive
# (core issue #66); this file supplies only the role-unique values.
source "${CORE_HOOKS_LIB_DIR:-${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib}/role-directive.sh"
ROLE="security-threat-model"
DECIDES="신뢰 경계의 위협 표면"
USE_WHEN="스펙에 신뢰 경계·인증·민감데이터가 걸릴 때"
PRODUCES="STRIDE table, mitigation list per threat, residual risk note"
WRITE_SCOPE=""
HAND_OFF="구현 단계 취약점 점검은 → secure-coding; 법적 노출이면 → legal-compliance"
BOUNDARY_CASE="if the work in front of you drifts outside decides above, stop and hand off per the arrow — do not silently absorb another role's scope. Record the hand-off point in this role's record before opening the next role's session."
RECORD_PATH="docs/issue-<n>/reports/security-threat-model.md"
core_role_directive --role "$ROLE" --decides "$DECIDES" --use-when "$USE_WHEN" --produces "$PRODUCES" --write-scope "$WRITE_SCOPE" --hand-off "$HAND_OFF" --boundary-case "$BOUNDARY_CASE" --record-path "$RECORD_PATH"
