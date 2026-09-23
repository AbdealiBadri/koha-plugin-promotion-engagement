# Project Overview

## Project identity

**Project:** Koha Promotion & Engagement
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`
**Product form:** Koha Tool Plugin / versioned KPZ package
**Institutional origin:** Aljamea-tus-Saifiyah Nairobi library
**Current candidate:** v0.5.0 Analytics Intelligence
**Primary verified Koha runtime:** 25.11.02

## Purpose

Koha Promotion & Engagement records library promotion activity, links promoted resources to live Koha records and measures whether those resources receive measurable circulation response.

Koha remains the authoritative library system. The plugin stores promotion-specific operational/audit data in namespaced tables and derives engagement analytics from Koha circulation history.

The product is designed to answer a management question Koha does not normally answer directly:

**We promoted these resources — were they actually used, did borrowing change compared with before, and what should the library learn or do next?**

## Core management questions

The plugin aims to answer:

1. What did the library promote?
2. How many distinct titles and physical/item copies were involved?
3. How many promoted titles were actually borrowed?
4. What share of promoted titles was used?
5. How many checkout events occurred during the promotion?
6. How did the campaign compare with an immediately preceding equal-duration baseline?
7. Which titles increased, produced no response or generated repeat demand?
8. Which channels/audiences/campaign types/locations perform differently where attribution is defensible?
9. Is current demand/copy pressure strong enough to justify collection-development review?
10. What evidence should be handed to native Koha Suggestions/Acquisitions?

## Evidence principle

The plugin measures observed Koha circulation response.

It may conclude that:

- circulation increased during a promotion;
- more promoted titles were used;
- a campaign generated new borrowing response;
- a title produced increased/repeat demand.

It must not claim:

- that promotion caused every checkout;
- that a physical display was definitely seen by a particular borrower;
- that a multi-location campaign proves which physical location generated the checkout.

## Primary users

- Library managers and administrators.
- Librarians creating/maintaining promotions.
- Staff reviewing engagement and campaign evidence.
- Collection-development/acquisitions staff reviewing approved recommendations.
- Future authorized AJS applications consuming aggregate read-only analytics.

## Current functional scope

### Campaign operations

- create/list/detail/edit/archive;
- audit history;
- plugin-managed campaign type/channel/location/language/audience/cadence vocabulary;
- reusable multi-location campaigns;
- barcode scan/paste and live Koha validation;
- duplicate prevention;
- transactional campaign/item/location/audit writes.

### Analytics Intelligence

- active campaigns measured live through today without forced completion;
- equal-duration pre-campaign Baseline;
- During and After 7/14/30/60 windows;
- Pending / To date / Complete window states;
- checkout union from Koha `issues` + `old_issues`;
- issue-ID de-duplication;
- promoted item/copy count;
- promoted-title count;
- titles used;
- title utilization;
- campaign/baseline checkout totals and daily rates;
- uplift / new response;
- increased-use titles;
- zero-response titles;
- repeat-demand titles;
- title-level before/during/follow-up response;
- portfolio de-duplication and multi-attribution quality signals.

### Management surfaces

- engagement-first Dashboard;
- impact-aware Promotions list;
- Campaign Detail Impact-at-a-glance;
- Campaign Analytics;
- Promoted Resource Impact;
- Comparative Reports;
- CSV/JSON exports;
- authenticated read-only analytics API.

### Promoted Resource Impact / acquisitions handoff

- title-level circulation/copy/hold evidence;
- serviceable/available copies;
- active holds and holds-per-copy;
- priority/evidence grade;
- Koha HoldRatioDefault-aware quantity proposal;
- librarian approval/rejection;
- evidence snapshot/audit;
- native Koha ASKED Suggestion submission;
- duplicate/submission protection.

The plugin does not choose vendor, fund, price, currency, basket or order. Those remain in Koha Acquisitions.

## Data architecture

Koha is authoritative for:

- biblios;
- items/barcodes;
- patrons;
- branches/libraries;
- issues/old_issues;
- holds;
- Suggestions/Acquisitions.

Plugin operational data remains in seven namespaced tables:

- `plugin_ajsn_promo_campaigns`
- `plugin_ajsn_promo_items`
- `plugin_ajsn_promo_audit`
- `plugin_ajsn_promo_settings`
- `plugin_ajsn_promo_vocab_values`
- `plugin_ajsn_promo_campaign_locations`
- `plugin_ajsn_promo_recommendations`

No Koha core table is altered with plugin-specific columns and no Koha core source patch is required.

## Privacy boundary

General management analytics remain aggregate-only.

Patron-identifiable rankings/history are outside the general plugin analytics boundary unless a later restricted privacy/permission design is separately approved.

## Current local verification

On isolated Koha 25.11.02 `promoeng`:

- 5 automated test files / 113 assertions: PASS;
- syntax/diff/schema-idempotence gates: PASS;
- exact v0.5.0 KPZ authenticated upload/upgrade: PASS;
- seven plugin tables: PASS;
- Dashboard/Promotions/Analytics/Reports/Configuration/Resource Impact authenticated browser matrix: PASS;
- native Koha Suggestion synthetic workflow and cleanup: PASS.

Exact locally verified v0.5.0 KPZ SHA-256:

`931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670`

## Current compatibility position

- Koha 25.11.02: local runtime PASS.
- Koha 26.05.x: code/dependency review favorable, runtime BLOCKED by host disk capacity.
- Institutional staging: not yet executed.
- v0.5 formal production deployment: not verified/authorized by this development gate.

A 26.05 image pull retried on 2026-09-21 reduced Windows C: free space from about 16 GB to about 11 GB before completion, so it was stopped safely. Require 20–25 GB safe free C: space before retrying.

## Nairobi pilot context

The user installed v0.4.1 on the live Nairobi Koha and reported normal installation/runtime behavior. Real campaign screenshots then exposed the active-campaign and first-glance analytics deficiencies that v0.5 addresses.

This pilot observation is useful product evidence but is not treated as formal v0.5 release acceptance.

## Technology

- Perl / `Koha::Plugins::Base`
- Template Toolkit Koha staff UI
- MariaDB/MySQL through Koha DB connection
- Koha ORM/models and native Suggestions
- Mojolicious/OpenAPI REST controller
- Koha Testing Docker
- Python KPZ build helper
- Git/GitHub branch-based development

## Branch status

Repository default: `main`

Active implementation branch:

`feature/v0.5-analytics-intelligence`

Base v0.4.1 acceptance/upgrade-survival checkpoint:

`57a38bc`

## Remaining external gates

1. user visual review of final v0.5;
2. Koha 26.05 runtime matrix after adequate host disk headroom;
3. institutional non-production staging;
4. explicit production backup/change-window/rollback ownership and release authorization.

## Authoritative current references

- `CURRENT_STATE.md`
- `SESSION_HANDOFF.md`
- `ANALYTICS_SPEC.md`
- `V0.5_ANALYTICS_INTELLIGENCE.md`
- `TESTING.md`
- `ISSUES.md`
- `DECISIONS.md`
- `docs/UPGRADE_SURVIVAL_AUDIT.md`
