#!/usr/bin/env bash
set -uo pipefail
# SessionStart: security-threat-model-canon-citation's directive — plain
# bash, not core_role_directive (this plugin does not own a role, it owns a
# single cross-cutting discipline: how the `canon-references` record field
# may be filled in).
#
# Restates the no-copy rule issue #1/#2 already established, scoped here to
# the `canon-references` record field specifically.
cat <<'EOF'
security-threat-model-canon-citation: no-copy canon citation discipline

The `canon-references` field in this role's phase-2 record (and any
reference to external canon inside a phase-1 proposal) must cite external
canon by path/description only — never by pasting its content.

"External canon" here means: core's `warrant/` plugin, any sibling
methodology plugin's `hooks/methodology-gate.sh` (or other hook script),
and any other canon document or script that lives outside the file you are
currently writing.

Cite it as: a relative path (e.g. `core/warrant/hooks/...`), plus a short
description of what it establishes and why it is relevant here. Do not
paste the script's content, its shebang line, or excerpts long enough to
functionally reconstruct it — a reader who wants the actual text follows
the path and reads it there, where it can change without this record
going stale.

This applies to the `canon-references` field specifically. It does not
relax or replace any other field's own discipline (STRIDE ordering,
rating markers, disposition vocabulary, sign-off references) — those are
owned by the other methodology plugins in this set.

A mechanical backstop (hooks/methodology-gate.sh) checks this on write,
but it is a best-effort heuristic, not a substitute for review.
EOF
