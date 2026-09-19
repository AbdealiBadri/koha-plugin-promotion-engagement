# Analytics Engine Specification

**Milestone:** v0.3 Analytics Engine  
**Status:** Approved engineering baseline for implementation  
**Environment:** isolated KTD `promoeng` before staging validation

## Purpose

Provide one shared, testable calculation layer for Koha staff UI, reports and future read-only APIs. Koha remains authoritative for circulation, items, patrons and branches. The plugin stores no duplicate operational circulation ledger.

## Authoritative circulation event

A checkout event is a row from the union of Koha `issues` and `old_issues`, keyed by `issue_id` and dated by `issuedate`.

- `issues` supplies current loans.
- `old_issues` supplies returned/historical loans.
- Renewals do not create additional checkout conversions in v0.3.
- `statistics` is not the canonical event source because installations may purge it and the local KTD currently contains no rows.
- Rows with null `itemnumber` or `issuedate` are excluded.
- On-site checkout rows remain included but can be separated later if required.

## Campaign and resource eligibility

A campaign is measurable when it is not archived and has a valid `start_date`. The effective campaign end is `end_date`, or `start_date` when end date is blank.

The eligible promoted-item cohort is fixed for all windows so baseline and campaign periods compare the same resources. It contains each distinct campaign-item link whose active interval overlaps the campaign period:
- the link was added before the end of During; and
- it has no `deleted_at`, or was deleted on or after campaign start.

That same cohort is used for Baseline, During and After calculations. Links added only after the campaign ended, or removed before it began, are excluded. Historical soft-deleted links remain analytically explainable without being treated as currently active.

## Time windows

All boundaries use the Koha database timezone and half-open datetime ranges to avoid double counting.

- During: campaign start date 00:00 inclusive through the day after effective end 00:00 exclusive.
- Baseline: the immediately preceding period with the same number of calendar days as During.
- After 7/14/30/60: begins at the end of During and spans the named number of calendar days.
- Events exactly on a boundary belong to the later window only.

The service must return resolved start/end datetimes and window-day counts with every result.

## Core KPIs

For each campaign and window:

1. `checkout_count`: checkout events for eligible promoted items.
2. `unique_items_checked_out`: distinct promoted `itemnumber` values with at least one checkout.
3. `eligible_item_count`: distinct promoted items eligible in that window.
4. `conversion_rate`: unique_items_checked_out / eligible_item_count × 100.
5. `days_to_first_checkout`: whole/decimal elapsed days from campaign start to the first During-or-After checkout; null when none.
6. `daily_checkout_rate`: checkout_count / window_days.
7. `absolute_rate_delta`: during daily rate − baseline daily rate.
8. `uplift_percent`: absolute_rate_delta / baseline daily rate × 100.

When baseline daily rate is zero, `uplift_percent` is null—not infinity—while `absolute_rate_delta` remains available. When eligible_item_count is zero, conversion_rate is null.

## Attribution and aggregation

A checkout can qualify for more than one overlapping campaign. Per-campaign analytics attribute it to every qualifying campaign and expose a `multi_attributed` flag/count. Portfolio totals must de-duplicate by `issue_id`; they must never sum campaign totals blindly.

Comparisons by channel, location, language, audience or campaign type use configured stable codes internally and current human labels for display. A multi-location campaign contributes to each linked location and is explicitly marked multi-location.
## Privacy and access

The v0.3 core service does not return patron names, card numbers, usernames or individual borrowing histories.

- Category/class/group comparisons are aggregate-only.
- Borrower/category breakdowns require a minimum cohort of 5 distinct borrowers.
- Smaller cohorts are suppressed, not shown as zero.
- Identifiable top-user/student analytics remain outside the core endpoint until a separate restricted permission and approved privacy design exist.
- External/general dashboards receive only non-identifiable aggregates.

## Consistency contract

The staff dashboard, reports and future REST endpoints must call the same analytics service methods. KPI SQL or formulas must not be copied independently into templates or controllers.

Each response includes:
- formula/spec version;
- campaign identifier;
- resolved windows;
- eligible item count;
- KPI values;
- data-quality warnings;
- calculation timestamp.

## Initial acceptance tests

- AN-01: current and historical checkout rows are combined without duplicate issue IDs.
- AN-02: campaign end date is inclusive and half-open ranges prevent boundary duplication.
- AN-03: baseline duration exactly matches During duration.
- AN-04: 7/14/30/60 After windows resolve correctly.
- AN-05: renewals do not create extra checkout conversions.
- AN-06: eligible soft-deleted links are included only when their active interval overlaps the window.
- AN-07: conversion uses distinct items, not checkout count.
- AN-08: zero baseline returns null uplift plus absolute delta.
- AN-09: zero eligible items returns null conversion.
- AN-10: days to first checkout returns null when no qualifying event exists.
- AN-11: overlapping campaigns expose multi-attribution; portfolio total de-duplicates by issue ID.
- AN-12: location/type/channel comparisons use stable codes and friendly labels.
- AN-13: cohorts below five distinct borrowers are suppressed.
- AN-14: archived campaigns remain historically queryable only through explicitly authorized historical views.
- AN-15: staff UI and future API fixtures produce identical KPI values.

## Current environment limitation

The isolated `promoeng` database currently contains zero rows in `statistics`, `issues` and `old_issues`. Runtime correctness will therefore use transaction-scoped synthetic checkout fixtures that are rolled back or removed after every test. No production patron or circulation data is required.
