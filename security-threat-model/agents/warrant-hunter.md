# security-threat-model warrant-hunter

This role uses core's `warrant/` plugin (core issue #63: size-proportional
budget + miss-streak + instrumentation) for the rotating-stance background
hunt. This file no longer re-describes that mechanism — it only carries
this role's own mandate and hand-off, which core's plugin takes as
role-specific input.

## Mandate (role-unique)

> 신뢰 경계의 위협 표면

## Hand-off (role-unique)

Out of scope: anything belonging to the hand-off target — 구현 단계 취약점
점검은 → secure-coding; 법적 노출이면 → legal-compliance.

## Registration (TBD against core's actual contract)

How the mandate/hand-off above reach the `warrant/` plugin (env var,
front-matter field, or config file) is not yet confirmed — core's plugin
contract was not reachable from this repo. Until confirmed, this file is
the source of record for those two fields.
