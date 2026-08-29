# Session Handoff

**Last updated:** 2026-08-29  
**Current implementation branch:** `feature/v0.2-campaign-crud`  
**Implementation commit under test:** `3537b8e`  
**Current milestone:** v0.2 Checkpoint 1 — campaign creation integrity/security

## Current objective

Finish the three remaining security/permission tests, then close v0.2 Checkpoint 1 and move to campaign management/configuration/multi-location work.

## Work completed most recently

- Backed up all four plugin-owned checkpoint tables before resetting KTD.
- Performed a full consistent `kohadev` KTD teardown/recreate.
- Confirmed `kohadev-koha-1`, `kohadev-db-1`, and `kohadev-memcached-1` are Up.
- KTD `--wait-ready 180` returned `KTD READY`.
- Koha Administration > Plugins shows Promotion & Engagement version **0.2.0 Enabled**.
- Authenticated `/api/v1/contrib/ajsn_promotion/health` returned `status: ok` and `version: 0.2.0`.
- InPrivate/unauthenticated health request returned `{"error":"Authentication failure."}`.
- BUG-003 stale API version and ISSUE-004 KTD non-empty-DB blocker are now resolved.

## Previously passed v0.2 campaign tests

- campaign with no barcode;
- one valid barcode;
- fake invalid barcode blocked;
- duplicate correct barcode linked once + warning;
- DB campaign/item/audit verification;
- mixed valid + invalid submission rolled back completely;
- dashboard remained unchanged after rollback.

These results are preserved in `TESTING.md`. Old local test rows were backed up before the clean KTD reset and do not need to be restored simply to preserve test evidence.

## Current open checkpoint issue

ISSUE-012 — security matrix is not yet complete.

Still required:

1. T-131 — missing/invalid CSRF token is rejected.
2. T-132 — logged-in user without plugin tool permission cannot use plugin write workflow.
3. T-133 — logged-in API user without `catalogue` permission cannot call `/health`.

## Exact next action

Run **T-131 first** using the current healthy `kohadev` environment.

Goal: attempt the campaign write endpoint without a valid Koha CSRF token and prove that Koha rejects the request and no campaign row is created.

Do not weaken/disable CSRF middleware to perform the test. The test must exercise Koha's normal protection.

After T-131, proceed to lower-permission user tests T-132/T-133. If temporary test users/permissions are created or modified, restore/verify the normal authorized admin workflow afterward.

## What success should look like at checkpoint closure

- normal authorized campaign creation works;
- invalid/missing CSRF is rejected with no DB write;
- user without plugin tool permission is denied;
- health API works for an appropriately authorized user;
- health API is denied to unauthenticated users;
- health API is denied to authenticated users lacking required `catalogue` permission;
- source/UI/API version remains 0.2.0;
- KTD remains healthy.

## Next milestone after checkpoint closure

Campaign management and universal configuration:

- campaign detail/edit/archive/list/filter;
- configurable type/channel/language/audience/cadence;
- reusable multi-location support;
- related audit logging;
- then analytics engine before final UI modernization.