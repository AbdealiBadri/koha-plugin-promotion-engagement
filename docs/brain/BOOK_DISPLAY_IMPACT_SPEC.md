# Book Display Impact / Promoted Resource Impact Specification

**Status:** implemented and expanded in v0.5.0
**Module:** part of Koha Promotion & Engagement; not a separate plugin
**Specification version:** 1.1.0

## Naming

The v0.4 acquisition-support workflow was approved as **Book Display Impact**.

v0.5 generalizes the staff-facing analytical page to **Promoted Resource Impact** because the same Koha title evidence can apply to:

- physical displays;
- email campaigns;
- recommendations;
- digital promotion;
- other item-linked promotion types.

For backward compatibility and audit continuity:

- internal action/route remains `book_display_impact`;
- native Koha Suggestion management reason remains `Book Display Impact`.

## Purpose

The module now answers two separate questions in the correct order.

### Engagement

Did users actually borrow the promoted titles?

Primary evidence:

- Promoted titles;
- Titles borrowed;
- Title utilization;
- Campaign checkouts;
- Baseline checkouts;
- Increased-use titles;
- Zero-response titles.

### Collection development

Does current demand/access pressure justify professional additional-copy review?

Secondary evidence:

- serviceable/currently available copies;
- active holds;
- holds per serviceable copy;
- priority/evidence grade;
- suggested quantity aligned to Koha HoldRatioDefault;
- librarian approval/rejection;
- native Koha Suggestion submission.

The module never creates an acquisition order.

## Ownership and boundaries

Koha remains authoritative for:

- biblios;
- items;
- issues/old_issues;
- holds;
- patrons;
- branches;
- Suggestions.

The plugin owns recommendation/decision and audit records in namespaced plugin tables. No Koha core source/schema is modified.

## Analytics source

Promoted Resource Impact reuses the shared Analytics 1.1 service rather than implementing separate circulation formulas.

Title rows aggregate linked item barcodes by distinct `biblionumber`.

The campaign-period semantics are therefore identical to Campaign Analytics:

- active started campaign can measure through today;
- Baseline has equal duration;
- future follow-up windows are Pending;
- incomplete 60-day follow-up cannot be treated as final sustained evidence.

## Summary KPIs

The first row must show engagement before acquisitions workflow:

1. Promoted titles;
2. Titles borrowed;
3. Title utilization;
4. Campaign checkouts, with baseline context;
5. Increased-use titles;
6. Zero-response titles.

High Priority / Active Holds / Approved / Sent to Koha appear in a secondary Collection-development signals section.

## Title evidence row

Each title row may include:

- bibliographic identity;
- promoted barcodes/copies;
- baseline checkout count;
- during-promotion checkout count;
- 60-day follow-up count/state;
- total/serviceable/available copies;
- active holds;
- holds per serviceable copy;
- priority/evidence grade;
- recommendation reason;
- suggested additional-copy quantity;
- current librarian decision.

## Workflow

Candidate → librarian review → approved/rejected → explicit submission → native Koha ASKED suggestion → normal Koha acquisitions review/order workflow.

Submission requires the applicable Koha Suggestions permission.

Vendor, budget/fund, price, currency, basket and final order remain native Koha decisions.

## Koha Suggestion field policy

The plugin creates:

- STATUS = ASKED;
- biblionumber/title/author/quantity/branch;
- management `reason = Book Display Impact`;
- evidence context in staff note.

It does **not** fabricate or overwrite Koha's patron-facing `patronreason` authorised-value field.

## Persistence and safety

`plugin_ajsn_promo_recommendations` keeps one decision row per campaign/biblionumber.

It stores:

- decision status;
- recommended quantity;
- reviewer note;
- evidence snapshot;
- reviewer;
- timestamps;
- native Koha suggestion ID.

Submitted rows cannot be overwritten through the normal workflow.

Suggestion creation, plugin state update and audit write remain transactional.

## Test-safety rule

Workflow smoke tests must never assume a retained development campaign is empty.

The v0.5 runtime smoke creates a synthetic campaign, runs approval → Suggestion → audit verification, then deletes only the synthetic:

- suggestion;
- recommendation;
- audit;
- item link;
- campaign;
- temporary test patron.

Retained campaign 40 evidence remains untouched.

## Responsible interpretation

Checkout/hold evidence indicates borrowing response and access pressure.

The plugin may say circulation increased during a promotion. It must not say the promotion definitely caused every loan or that a physical display was seen by a particular borrower.

## Current verified tests

On Koha 25.11.02:

- BDI-01..BDI-19: PASS;
- v0.5 Resource Impact title/use/utilization tests: PASS;
- full suite: 5 files / 113 assertions PASS;
- authenticated Resource Impact render: PASS;
- exact v0.5.0 KPZ install/upgrade: PASS;
- synthetic approve → native ASKED Suggestion → audit → cleanup: PASS.
