# Session Handoff

**Last updated:** 2026-09-19  
**Current implementation branch:** `feature/v0.2-campaign-crud`  
**Current milestone:** v0.2 Checkpoint 1 — campaign creation integrity/security

## Current objective

Finish the two remaining security tests (T-131/T-132) in the dedicated isolated KTD environment; T-133 now passes. Then run an authorized smoke test, close v0.2 Checkpoint 1, and move module-by-module through campaign management, configuration/multi-location, analytics, reporting/API, compatibility, KPZ, and public release.

## Current environment

Dedicated project KTD instance: **`promoeng`**.

Verified on C0158:
- Desktop Commander is online and connected.
- WSL Debian is available.
- Docker Engine is running.
- `promoeng-koha-1`, `promoeng-db-1`, and `promoeng-memcached-1` are Up.
- `promoeng-intra.localhost` returned HTTP 200.
- Container startup log reports: `koha-testing-docker has started up and is ready to be enjoyed!`
- Single-plugin startup found and installed Promotion & Engagement version 0.2.0.
- Legacy `kohadev` remains exited and must not be used as this project's primary test environment.
- Unrelated repositories/containers must not be touched; no global Docker cleanup commands.

## Work completed previously

- Campaign creation with Koha-native CSRF mechanism wired.
- Valid Koha barcode linking.
- Invalid barcode blocks entire save.
- Duplicate barcode input is ignored/reported and links only once.
- Campaign/item/audit writes are transactional.
- Mixed valid+invalid rollback passed.
- Health endpoint reports plugin version 0.2.0.
- Unauthenticated health request is denied.
- Plugin-owned checkpoint data was backed up before the earlier KTD reset.
- Project Brain, YAML state, session continuity protocol, and chronological session log are in the repository.

## Current open checkpoint issue

ISSUE-012 — complete the dedicated security matrix:

1. T-131 — invalid/missing CSRF token is rejected and creates no campaign.
2. T-132 — logged-in user without plugin tool permission cannot use plugin write workflow.
3. T-133 — PASS: authenticated API identity without `catalogue` returned HTTP 403 and explicit required-permission detail.

## Exact next action

Run T-131 and the full end-to-end T-132 against **`promoeng`**, recording actual runtime evidence. Then re-run one normal authorized campaign smoke test. Do not use `kohadev` for new verification.

If clean, close checkpoint 1 and runtime-test the prepared draft PR #1 for campaign list/detail before merge; then proceed to edit/archive and multi-location/configuration.

## Release direction

Target: a stable public plugin before KohaCon 2026.

Required release gates remain:
- current feature regression suite;
- permissions/security closure;
- clean KPZ install/upgrade test;
- Koha compatibility test, including 26.05 target;
- staging validation;
- backup/rollback validation;
- release documentation and public repository hygiene.
