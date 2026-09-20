# Book Display Impact Specification

**Status:** implemented on `feature/v0.4-book-display-impact`  
**Module:** part of Koha Promotion & Engagement; not a separate plugin  
**Specification version:** 1.0.0

## Decision

The user-approved product name is **Book Display Impact**. The module derives
title-level evidence from existing campaign links, Koha checkout history, current
hold queues and serviceable copy counts. It never creates an acquisition order.

## Ownership and boundaries

Koha remains authoritative for biblios, items, issues, holds, patrons, branches
and Suggestions. The plugin owns one recommendation/decision table and its audit
records. No Koha core schema or source file is modified.

## Workflow

Candidate → librarian review → approved/rejected → explicit submission →
native Koha ASKED suggestion → normal Koha acquisitions review and basket order.

Submission requires Koha `suggestions_create` or `suggestions_manage`.
Vendor, budget, fund, price, currency and final order remain native Koha decisions.
## Evidence model

Rows aggregate displayed item barcodes by biblionumber. Each row includes:

- baseline, during-display and 60-day follow-up checkouts;
- displayed barcodes and bibliographic identity;
- total, serviceable and currently available copies;
- current active holds and holds per serviceable copy;
- priority and evidence grade;
- a quantity proposal aligned to Koha `HoldRatioDefault`.

The interface states that this evidence supports judgment but does not prove
physical views or sole causation.

## Persistence and safety

`plugin_ajsn_promo_recommendations` has one row per campaign/biblionumber.
It stores decision, quantity, note, evidence snapshot, reviewer, timestamps and
the native Koha suggestion identifier. Submitted rows cannot be overwritten
through the normal workflow. Suggestion creation, plugin state update and audit
write are transactional.

## Verified tests

- BDI-01..BDI-17: calculation, aggregation, holds, copies, priority,
  decision persistence and native Koha Suggestion integration.
- Complete Perl suite: 72 assertions PASS.
- Authenticated browser render smoke: PASS.
- End-to-end approve → submit → Koha ASKED suggestion → audit → cleanup: PASS.
- Existing analytics regressions remain green.
