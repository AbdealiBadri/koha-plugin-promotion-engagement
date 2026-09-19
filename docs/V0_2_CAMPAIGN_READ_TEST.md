# v0.2 Campaign Read Views — Manual Test Plan

**Branch:** `feature/v0.2-campaign-read`  
**Status:** AUTOMATED RUNTIME PASS on `promoeng` (2026-09-19) — awaiting final human visual check before merge.

For the exact branch-switch and KTD commands, use `docs/V0_2_TOMORROW_TEST_RUNBOOK.md`.

## Purpose

Verify the new read-only Promotions list and Promotion detail screens without changing the existing campaign schema or write workflow.

## Preconditions

- `feature/v0.2-campaign-crud` security tests T-131/T-132/T-133 are complete or their state is explicitly preserved before switching branches.
- `kohadev` reports `KTD READY`.
- Promotion & Engagement plugin is enabled.
- At least one campaign exists; ideally one campaign has a linked Koha item.

## Test CR-01 — Promotions list opens

1. Switch/pull `feature/v0.2-campaign-read`.
2. Re-initialise plugins and restart Plack.
3. Open Promotion & Engagement dashboard.
4. Click **View promotions** or **Promotions**.

**Expected:**
- Promotions page renders without template/server errors.
- Saved campaigns appear newest first.
- Each row shows type, channel, dates, audience, location, linked-item count and status.
- Campaign name is clickable.

## Test CR-02 — Campaign detail opens

1. Click a campaign name.

**Expected:**
- Campaign detail page renders.
- Campaign metadata matches the saved record.
- Institution-wide campaign shows `All / institution-wide`.
- Branch-specific campaign resolves the live Koha library name when available.

## Test CR-03 — Linked Koha item read-through

Use a campaign with a linked item.

**Expected:**
- Barcode and itemnumber match plugin link data.
- Title, author and biblionumber are read from live Koha data.
- No Koha item/catalogue data is modified.

## Test CR-04 — Zero-linked-item campaign

Open a campaign with no linked barcodes.

**Expected:**
- Detail page renders normally.
- `No Koha items are linked to this campaign.` is shown.

## Test CR-05 — Audit history

Open a campaign created through the v0.2 workflow.

**Expected:**
- Existing `campaign_created` audit row is displayed.
- Actor and timestamp match the database record.

## Test CR-06 — Invalid campaign ID

Open the detail action with a non-numeric or nonexistent campaign ID.

**Expected:**
- No SQL/server error.
- User is returned to the Promotions screen with a clear error message.

## Test CR-07 — Existing write regression

After read-view testing, create one normal campaign using the existing New promotion form.

**Expected:**
- Existing v0.2 create workflow still succeeds.
- Dashboard and Promotions list both show the new record.

## Merge gate

Do not merge Draft PR #1 into `feature/v0.2-campaign-crud` until:

- T-131/T-132/T-133 pass;
- CR-01 through CR-07 pass;
- no Plack/template/database errors appear;
- Project Brain is updated with actual runtime evidence.


## Runtime results — 2026-09-19

Environment: isolated KTD project `promoeng`, Koha 25.11.x, plugin v0.2.0.

- CR-01 Promotions list: **PASS** — HTTP 200; zero-item and linked-item fixtures rendered and detail links were present.
- CR-02 Campaign detail: **PASS** — HTTP 200; linked fixture rendered and branch `CPL` resolved to live Koha branch name `Centerville`.
- CR-03 Linked Koha item read-through: **PASS** — itemnumber `109`, barcode `39999000002034`, biblionumber `52`, and live title/author data were present.
- CR-04 Zero-linked-item campaign: **PASS** — detail page displayed `No Koha items are linked to this campaign.`.
- CR-05 Audit history: **PASS** — `campaign_created` and actor borrower number were rendered.
- CR-06 Invalid/nonexistent campaign ID: **PASS** — both cases returned HTTP 200 with the intended user-facing error messages and no SQL/server error.
- CR-07 Existing write regression: **PASS** — a normal campaign was created after read-view testing and appeared in Promotions.
- Plack/intranet error logs after the suite: **no new template/database errors observed**.

Test fixtures intentionally remain in the isolated `promoeng` database for the user's visual review:
- `READ-ZERO-20260919`
- `READ-LINKED-20260919`
- `READ-REGRESSION-20260919`

Merge gate status: automated runtime gate is satisfied; final visual review is still pending before Draft PR #1 is merged.


## Human visual review — Promotions list

**Date:** 2026-09-19  
**Result:** PASS for list-page rendering.

The user supplied a screenshot of the local `promoeng` Promotions page. The expected three fixtures are visible:
- `READ-REGRESSION-20260919`
- `READ-LINKED-20260919`
- `READ-ZERO-20260919`

The page visually shows the expected campaign columns, right-side plugin navigation, active Promotions state, and New promotion action.

Non-blocking polish observations:
- campaign type/channel values are still displayed as machine labels such as `physical_display`, `new_arrivals`, and `subject_display`;
- the `draft` status text has low visual contrast.

These are UI-polish items and do not block functional acceptance of the read-view module.

**Remaining visual gate:** open `READ-LINKED-20260919` and visually confirm the Campaign Detail page before merge.
