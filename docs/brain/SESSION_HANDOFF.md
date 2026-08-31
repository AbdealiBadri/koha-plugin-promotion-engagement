# Session Handoff

**Last updated:** 2026-08-31  
**Base implementation branch:** `feature/v0.2-campaign-crud`  
**Remote follow-on branch:** `feature/v0.2-campaign-read`  
**Draft PR:** #1 — read-only promotions list and campaign detail views  
**Current milestone:** finish v0.2 Checkpoint 1 security tests, then verify the read-only campaign-management slice.

## Current objective

1. Complete the three remaining security/permission tests on `feature/v0.2-campaign-crud`.
2. Re-run one authorized smoke test.
3. Switch to `feature/v0.2-campaign-read` and execute CR-01 through CR-07.
4. Merge Draft PR #1 only after all runtime tests pass.

## Verified runtime state before remote follow-on work

- `kohadev` KTD was rebuilt cleanly and returned `KTD READY`.
- Koha Administration > Plugins showed Promotion & Engagement **0.2.0 Enabled**.
- Authenticated `/api/v1/contrib/ajsn_promotion/health` returned `status: ok` and `version: 0.2.0`.
- InPrivate/unauthenticated health request returned `{"error":"Authentication failure."}`.
- Campaign integrity tests previously passed: zero item, valid barcode, invalid barcode rejection, duplicate de-duplication, transactional DB/audit writes and mixed valid+invalid rollback.

## Security checkpoint still open

ISSUE-012 remains open until these are actually executed:

1. **T-131** — invalid/missing CSRF is rejected with no campaign write.
2. **T-132** — logged-in user without plugin `tool` permission cannot use the write workflow.
3. **T-133** — authenticated API user without `catalogue` permission cannot call `/health`.

Important T-131 note: a prior manual attempt changed the wrong `csrf_token` belonging to a Koha header/search form. That attempt is invalid evidence, not a failed security control. The correct token is inside the plugin form posting to `/cgi-bin/koha/plugins/run.pl`, beside `action=new_promotion` and `op=cud-create_promotion`.

## Remote work prepared on `feature/v0.2-campaign-read`

**CODE-PREPARED / NOT RUNTIME-VERIFIED**

Draft PR #1 adds a deliberately low-risk read-only campaign-management slice:

- Promotions list page using existing plugin tables.
- Dashboard campaign names link to details.
- Campaign detail page.
- Linked-item barcode/itemnumber from plugin data.
- Live Koha title/author/biblionumber read-through.
- Campaign audit-history display.
- Defensive invalid/nonexistent campaign-ID handling.
- No schema change.
- No edit/archive/delete write actions.
- No Koha core changes.

The branch is mergeable into `feature/v0.2-campaign-crud`, but must remain a Draft PR until KTD testing is complete.

## Exact test runbook

Use `docs/V0_2_TOMORROW_TEST_RUNBOOK.md` for the complete branch-switch, KTD re-initialisation and manual test sequence.

Read-view acceptance tests are in `docs/V0_2_CAMPAIGN_READ_TEST.md`:

- CR-01 Promotions list.
- CR-02 Campaign detail.
- CR-03 Live Koha item read-through.
- CR-04 Zero-linked-item campaign.
- CR-05 Audit history.
- CR-06 Invalid campaign ID.
- CR-07 Existing create-workflow regression.

## Merge gate

Do not merge PR #1 until:

- T-131/T-132/T-133 pass;
- CR-01..CR-07 pass;
- no Plack/template/database errors appear;
- normal authorized campaign creation still works;
- Project Brain and testing records are updated with observed results.

## After PR #1

Next implementation slice should be campaign edit/update + archive/status transitions with audit logging, followed by universal configuration and multi-location modelling. Analytics comes after the campaign data model and management workflow stabilise.