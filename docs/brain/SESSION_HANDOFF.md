# Session Handoff

**Last updated:** 2026-09-19
**Active runtime branch:** `feature/v0.2-campaign-read`
**Runtime environment:** isolated KTD `promoeng`
**Current milestone:** Campaign List + Campaign Detail visual acceptance

## Verified completed today

- v0.2 Checkpoint 1 security gate is closed:
  - T-131 invalid CSRF: PASS — HTTP 403, no campaign write.
  - T-132 catalogue-only staff without plugin tool permission: PASS — normal staff session valid, plugin write denied, no campaign write, original flags restored.
  - T-133 authenticated API identity without `catalogue`: PASS — HTTP 403 with required permission detail.
  - T-134 authorized campaign-create smoke: PASS — campaign + audit created, then test data cleaned.
- Switched local mounted plugin to `feature/v0.2-campaign-read`.
- Restarted Plack.
- Created read-view fixtures through the real plugin create workflow.
- CR-01 through CR-07 all PASS in `promoeng`.
- No new Plack/intranet template/database errors observed after the suite.

## Test fixtures retained for visual review

- `READ-ZERO-20260919`
- `READ-LINKED-20260919`
- `READ-REGRESSION-20260919`

## Exact next action

User performs one visual check of the local Promotions list/detail screens. Do not merge Draft PR #1 before that check.

After visual approval:
1. Sync/rebase the read branch with the now-advanced `feature/v0.2-campaign-crud` base and resolve documentation-only divergence safely.
2. Re-run CR-01..CR-07.
3. Merge Draft PR #1.
4. Move to Edit/Update/Archive, then universal configuration + multi-location support.

## Visual URL

`http://promoeng-intra.localhost/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool&action=promotions`

If not already authenticated, log in to the local KTD Koha staff interface first and then open the URL above.
