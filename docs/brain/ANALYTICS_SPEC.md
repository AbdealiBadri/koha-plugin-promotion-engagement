# Analytics Engine Specification

**Specification version:** 1.1.0
**Plugin milestone:** v0.5 Analytics Intelligence
**Status:** Implemented and locally verified on Koha 25.11.02
**Primary service:** `Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics`

## Purpose

Provide one shared, testable calculation layer for Koha staff UI, reports and read-only APIs. Koha remains authoritative for circulation, catalogue, items, patrons and branches. The plugin does not maintain a duplicate circulation ledger.

The management objective is to answer:

**What did we promote → what was actually used → how did use compare with baseline → what should staff investigate next?**

## Authoritative checkout event

A checkout event is a row from the union of Koha `issues` and `old_issues`, keyed by `issue_id` and dated by `issuedate`.

- `issues` supplies current loans.
- `old_issues` supplies returned/historical loans.
- Duplicate `issue_id` values across the two tables are counted once.
- Renewals do not create additional checkout events.
- Rows with null `itemnumber` or `issuedate` are excluded.
- `statistics` is not the canonical source because retention can vary by installation.

## Campaign measurability

A campaign is analytically eligible when:

- it is not archived unless an explicitly authorized historical view is requested; and
- it has a valid `start_date`.

### Effective end-date rule

The resolved During end depends on campaign state.

For a started campaign with `status = active`:

- blank `end_date` → current/as-of date;
- future `end_date` → current/as-of date;
- past `end_date` → configured end date plus a data-quality warning that status is still active.

For a future campaign, the During window is Pending.

For a non-active/completed campaign:

- configured `end_date` is used;
- when a completed campaign has no end date, the start date is used as a one-day fallback and a warning is returned.

An effective end may never precede the start date.

## Campaign item eligibility

The eligible promoted-item cohort is fixed for all comparison windows so Baseline and During compare the same resource set.

It contains each distinct campaign item link whose active interval overlaps the resolved campaign period:

- the link was added before the end of During; and
- it has no `deleted_at`, or was deleted on/after campaign start.

Historical soft-deleted links remain analytically explainable without being treated as currently active.

## Time windows

All boundaries use half-open datetime ranges to prevent boundary double counting.

### During

Campaign start date 00:00 inclusive through the day after resolved effective end 00:00 exclusive.

### Baseline

The immediately preceding period with exactly the same number of calendar days as During.

### After 7 / 14 / 30 / 60

Each begins at the end of During and spans the named number of calendar days.

Events exactly on a boundary belong to the later window only.

## Window availability state

Each window exposes one of:

- `pending`: as-of time has not reached the window start;
- `partial`: window has started but has not ended;
- `complete`: full window has elapsed.

Pending windows return null KPI values. A not-yet-started future period must never be represented as zero activity.

## Item-level KPIs

For each measurable window:

### `checkout_count`

Count of de-duplicated checkout events for eligible promoted items.

### `unique_items_checked_out`

Distinct eligible `itemnumber` values with at least one checkout.

### `eligible_item_count`

Distinct eligible promoted `itemnumber` values.

### `conversion_rate`

`unique_items_checked_out / eligible_item_count × 100`

This is retained as an item/copy-level measure. When the denominator is zero, conversion is null.

### `daily_checkout_rate`

`checkout_count / window_days`

### `days_to_first_checkout`

Elapsed days from campaign start to the first qualifying campaign/follow-up checkout; null when none exists.

## Title-level KPIs

Management impact is additionally calculated at distinct Koha bibliographic-title level.

### Promoted titles

Distinct `biblionumber` values represented by the eligible item cohort.

### Titles used

Distinct promoted `biblionumber` values with one or more checkout events during During.

### Title utilization rate

`titles_used / promoted_titles × 100`

This is the principal breadth-of-engagement KPI. Multiple promoted copies of one title count as one title.

### Increased-use titles

Distinct promoted titles where During checkout count is greater than the same title's Baseline checkout count.

### Zero-response titles

Distinct promoted titles with no During checkout event.

For a Pending campaign this value is null, not equal to all promoted titles.

### Repeat-demand titles

Distinct promoted titles with at least two During checkout events.

## Baseline change

### Absolute daily-rate delta

`during_daily_rate - baseline_daily_rate`

### Uplift percent

`absolute_rate_delta / baseline_daily_rate × 100`

When baseline daily rate is zero:

- uplift percent is null rather than infinity;
- the absolute-rate delta remains available;
- the UI may describe a positive During result as **New response**.

## Title-response table

Campaign Analytics returns one row per distinct promoted `biblionumber`, including:

- title;
- author;
- promoted copy count;
- linked barcodes;
- Baseline checkout count;
- During checkout count;
- After-60 checkout count/state;
- response label: Increased / Lower / Unchanged / No checkout / Pending.

The title table intentionally aggregates copies so the management interpretation is not distorted by duplicate copies.

## Impact interpretation

The service may return findings such as:

- Awaiting campaign activity;
- No promoted items;
- No response;
- New response;
- Positive response;
- Unchanged;
- Below baseline.

A live During period is provisional. A future campaign is scheduled/pending, never failed.

The finding is evidence of Koha borrowing response. It must not be phrased as proof that promotion caused every checkout or as a count of people who physically saw a display.

## Portfolio aggregation

A checkout can qualify for more than one overlapping campaign.

Per-campaign results may multi-attribute the event. Portfolio totals must not sum campaign totals blindly.

Portfolio metrics de-duplicate:

- checkout events by `issue_id`;
- promoted copies/items by `itemnumber`;
- promoted titles by `biblionumber`;
- used titles by `biblionumber`.

Portfolio output includes:

- campaign count;
- promoted item count;
- promoted title count;
- titles used;
- title utilization;
- zero-response titles;
- increased-use titles;
- repeat-demand titles;
- de-duplicated Baseline checkout count;
- de-duplicated During/campaign checkout count;
- de-duplicated campaign-plus-follow-up event count;
- multi-attributed event count;
- aggregate unique borrowers where permitted.

## Comparative dimensions

The shared service supports comparison by:

- channel;
- configured location;
- campaign type;
- language;
- target audience.

Each row can expose:

- campaign count;
- promoted item count;
- promoted title count;
- titles used;
- title utilization;
- Baseline checkout count;
- During checkout count;
- checkout change percent;
- zero-response titles;
- increased-use titles.

### Location attribution safeguard

A multi-location campaign may appear in every linked location's comparison context, but it cannot prove at which physical point a reader discovered the resource.

Therefore:

- multi-location campaign count is explicit;
- “leading location” evidence only considers single-location campaigns;
- `unassigned` is excluded from the leading physical-location statement.

## Privacy and access

Core analytics do not return patron names, card numbers, usernames or individual borrowing histories.

- Staff management pages are aggregate-only.
- Cohorts below five distinct borrowers remain suppressible where borrower/category breakdowns are used.
- Identifiable top-user/student analytics remain outside the general analytics endpoint until a separate restricted permission/privacy design is approved.

## Consistency contract

Dashboard, Campaign Analytics, Resource Impact, Reports and read-only APIs must use the shared Analytics service. KPI formulas must not be reimplemented independently in templates/controllers.

Each result includes, where applicable:

- specification version;
- campaign;
- analysis period;
- resolved windows and states;
- eligible item count;
- promoted-title count;
- KPI values;
- data-quality warnings;
- calculation timestamp.

## Acceptance coverage

Historical AN-01 through AN-16 remain valid.

v0.5 adds explicit coverage for:

- active open-ended campaigns measured through as-of date;
- active future-ended campaigns clamped to as-of date;
- equal-duration live baseline;
- Pending future follow-up windows;
- null rather than zero future metrics;
- promoted item versus promoted-title distinction;
- title-level de-duplication;
- title utilization;
- zero-response semantics;
- portfolio title/item/checkouts;
- Resource Impact title/use/utilization summary;
- prevention of incomplete follow-up being treated as sustained evidence.

Current complete regression result: **5 files / 113 assertions / PASS** on Koha 25.11.02.
