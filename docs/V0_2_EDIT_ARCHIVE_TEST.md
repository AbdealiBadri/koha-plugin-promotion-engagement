# v0.2 Edit / Update / Archive — Runtime Test Record

**Branch:** `feature/v0.2-campaign-edit-archive`
**Environment:** isolated KTD `promoeng`, Koha 25.11.x
**Date:** 2026-09-19
**Automated runtime status:** PASS
**Human visual status:** PASS

## Implemented scope

- Edit existing campaign through a pre-filled Koha staff form.
- Validate updates using the same current type/channel/date/branch/status/barcode rules as campaign creation.
- Reconcile linked Koha items transactionally.
- Soft-remove linked items by setting `deleted_at`.
- Reactivate a previously soft-removed campaign-item link without creating a duplicate row.
- Record `campaign_updated`, `campaign_status_changed`, and `campaign_archived` audit actions.
- Archive campaign and active campaign-item links with soft-delete, preserving physical rows and audit history.
- Exclude archived campaigns/links from active list/detail/dashboard counts.
- Protect edit/archive POSTs with Koha-native CSRF middleware.

## Runtime results

| ID | Test | Status | Evidence |
|---|---|---|---|
| EA-01 | Edit page pre-fills campaign and linked barcode | PASS | HTTP 200; campaign name, barcode and update form rendered. |
| EA-02 | Valid update is transactional and audited | PASS | Metadata/items updated; update + status audit rows observed. |
| EA-03 | Invalid barcode blocks entire update | PASS | Campaign and item state unchanged. |
| EA-04 | Removing a campaign item soft-deletes link | PASS | Row preserved with non-null deleted_at. |
| EA-05 | Re-adding removed item reactivates unique row | PASS | Same campaign/item row reactivated; no duplicate. |
| EA-06 | Unconfirmed archive is denied | PASS | Campaign remained active. |
| EA-07 | Confirmed archive soft-deletes campaign and preserves history | PASS | Campaign archived; rows preserved; archive audit inserted. |
| EA-08 | Archived campaign hidden from active read views | PASS | List excludes it; detail reports unavailable. |
| EA-09 | Forged CSRF cannot update | PASS | HTTP 403; no state change. |
| EA-10 | Status whitelist enforced | PASS | Invalid status rejected. |
| EA-11 | Forged CSRF cannot archive | PASS | HTTP 403; campaign remains active. |
| EA-12 | Archive soft-deletes active linked items | PASS | Active link count becomes 0; physical row remains. |
| EA-13 | Dashboard count excludes archived links | PASS | Active linked-item count moved 1 -> 2 -> 1 and matched rendered dashboard. |
| CR-01..CR-07 | Existing create/list/detail regression | PASS | Full campaign-read suite remains green. |
| Static | Perl syntax / whitespace | PASS | perl -c OK; git diff --check clean. |
| Logs | Runtime errors | PASS | No new Plack/intranet application errors observed. |

## Visual acceptance fixture

Retained in promoeng:
- Campaign: EDIT-VISUAL-20260919
- Campaign ID: 13
- Status: active
- One linked Koha item
- Audit history includes create, update and status-change rows

After normal staff login, open:

http://promoeng-intra.localhost/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool&action=promotion_detail&campaign_id=13

Visual gate:
1. Detail page shows Edit promotion and Archive.
2. Open Edit promotion and confirm current fields/barcode are pre-filled.
3. Return without changing data if desired.
4. Do not archive the fixture until visual review is complete.

## Human visual acceptance — PASS

The user supplied screenshots of campaign detail and Edit Promotion on 2026-09-19.

Verified visually:
- Edit promotion and Archive actions are visible on campaign detail.
- linked Koha item data and audit history render.
- Edit Promotion opens with campaign metadata, status, branch, audience, language, location, notes and barcode pre-filled.
- Update/Cancel controls render correctly.
- No session-loss issue occurred when entering through normal Koha staff login.

Non-blocking UI polish remains: machine-value labels such as physical_display/recommendation can later be rendered as friendlier display labels, and the status badge contrast can be improved.

## Final merge gate

PASS. After visual acceptance, EA-01..EA-13, EA security tests, dashboard archive count, and CR-01..CR-07 were rerun and all passed. The branch is ready to merge into feature/v0.2-campaign-crud.
