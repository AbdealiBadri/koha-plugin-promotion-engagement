# Current State

**Last verified:** 2026-09-24
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`
**Active branch:** `feature/v0.6.1-bugfix-audit`
**Implementation commit:** `1931d25`
**Plugin version:** 0.6.1
**Primary runtime:** isolated KTD `promoeng`, Koha 25.11.02

## Current milestone

**v0.6.1 Reliability Bug-Fix Audit — CLEAN ON VERIFIED KOHA 25.11.02 RUNTIME.**

This release keeps the v0.6 UI/features unchanged and fixes reliability, data-integrity, analytics, validation, concurrency, export-safety and performance defects.

## Fixed defects

- scheduled/future campaigns no longer distort measured portfolio KPIs;
- Recommendation decision + audit are transactional/row-locked;
- native Koha Suggestion submission is protected against duplicate concurrent submission;
- CSV formula injection is neutralized;
- real calendar-date validation replaces regex-only validation;
- active open-ended report filtering now matches live Analytics semantics;
- historical language/audience values are preserved while forged new values are rejected;
- Analytics/Resource Impact campaign selectors are no longer silently capped at 200;
- KPI drill-down highlighting works across all filtered DataTable pages;
- decimal hold-ratio quantity calculation is corrected;
- request-local checkout evidence is reused across comparative report dimensions;
- stray debug logging is removed;
- exact-KPZ smoke waits for Plack readiness.

## Verification

- static diff check: PASS;
- shell syntax: PASS;
- Perl syntax: PASS;
- schema idempotence: PASS;
- **7 files / 213 assertions / PASS**;
- dedicated bug-audit: **50 assertions / PASS**;
- exact authenticated v0.6.1 KPZ upgrade: PASS;
- seven plugin tables retained;
- plugin row counts before/after exact upgrade unchanged;
- authenticated nine-page browser matrix: PASS;
- server-side render smoke: PASS;
- native Koha Suggestion workflow smoke: PASS;
- workflow fixture cleanup: PASS.

**Exact KPZ:** `PromotionEngagement-v0.6.1.kpz`
**SHA-256:** `da4a68cb125bb22ee9806718561eafb4d368495f40e5063cc2fd3a406a117afc`

## Remaining external gate

Koha 26.05 runtime is still unverified because the local Docker host requires additional safe disk headroom. No 26.05 compatibility PASS is claimed.

## Next action

Provide exact v0.6.1 KPZ for user upgrade/testing. Upload as an in-place upgrade; do not uninstall the prior version first.

See `V0.6.1_BUGFIX_AUDIT.md` for the complete defect register and verification evidence.
