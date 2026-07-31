#!/usr/bin/env bash
# SessionStart directive — residual-risk sign-off facet of the
# security-threat-model role (proposal §2.4). Plain-bash, no core-canon
# helper: this plugin does not call core_role_directive.
set -uo pipefail

cat <<'EOF'
security-threat-model-residual-signoff: residual-risk sign-off discipline

Every `residual-risk-note` in a security-threat-model proposal or record
must carry:

  1. a post-mitigation rating (the residual risk level after mitigations
     are applied — not a restatement of the pre-mitigation rating), and
  2. an explicit approver reference: a citation to `docs/specs/approvers.md`
     (contract v3 §19 Approve gate), or the literal word "Approve"/
     "approver" tied to a named account.

This proposal does not invent a second sign-off mechanism — it makes the
existing `docs/specs/approvers.md` Approve gate mechanically checkable
inside the residual-risk-note itself. A residual-risk-note with a rating
but no approver reference is incomplete and will be refused by
methodology-gate.sh on write.
EOF
