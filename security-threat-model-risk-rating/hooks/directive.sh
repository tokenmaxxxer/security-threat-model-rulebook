#!/usr/bin/env bash
# SessionStart addition — security-threat-model-risk-rating.
#
# States the rating rule per docs/issue-7/proposals/security-threat-model.md
# section 2.2: CVSS-style qualitative severity is the default; DREAD is a
# marked override only, never a silent substitute.
set -uo pipefail

cat <<'EOF'
security-threat-model-risk-rating: risk-rating methodology

Default: CVSS-style qualitative severity (Critical/High/Medium/Low) rates
every finding.

Override: DREAD is permitted ONLY for architectural/trust-boundary findings
that have no CVE-like vector. When DREAD is used, the row's rating must be
immediately followed by the literal marker [dread-override] — no other
placement satisfies the check.

A row using DREAD-shaped language without the [dread-override] marker on the
same row is refused by hooks/methodology-gate.sh.
EOF
