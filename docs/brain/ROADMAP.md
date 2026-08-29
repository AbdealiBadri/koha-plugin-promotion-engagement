# Roadmap

## Current milestone — v0.2 Checkpoint 1: campaign creation integrity/security

**Status:** IN PROGRESS / runtime environment blocked  
**Priority:** P0

### Completed in current checkpoint

- [x] Writable campaign creation form.
- [x] Promotion type/channel and basic fields.
- [x] Koha branch dropdown/validation.
- [x] Barcode scan/paste parsing.
- [x] Live Koha item validation.
- [x] Invalid barcode blocking.
- [x] Duplicate input warning/de-duplication.
- [x] Transactional campaign/item/audit writes.
- [x] Dashboard counts and recent campaigns.
- [x] Database audit verification.
- [x] Mixed valid/invalid rollback verification.
- [x] Code fix for health endpoint version source.

### Remaining acceptance work

- [ ] Recover consistent `kohadev` KTD environment. **BLOCKER**
- [ ] Runtime verify health endpoint reports v0.2.0.
- [ ] Re-verify unauthenticated health denial on v0.2.
- [ ] Dedicated invalid/missing CSRF submission test.
- [ ] Lower-permission plugin/API authorization tests.
- [ ] Record checkpoint closure in tests/current state.

**Acceptance criteria:** all `docs/V0_2_CHECKPOINT_1_TEST.md` pass criteria plus the security regression checks above.

## Next milestone — v0.2 campaign management and universal configuration

**Priority:** P1  
**Dependency:** checkpoint 1 closure

Planned:

- campaign detail page with linked item title/author/barcode;
- edit/update workflow with audit;
- archive/soft-delete and status transitions;
- campaign list/search/filter;
- reusable configurable campaign types/channels;
- location vocabulary design;
- one campaign to multiple locations;
- configurable languages/audiences/cadence;
- recurring campaign/template strategy decision.

Acceptance highlights:

- Nairobi workflows can be represented without source-code changes;
- one campaign can select all applicable display locations once;
- changes are auditable;
- no core Koha schema change.

## v0.3 — Analytics engine

**Priority:** P1

Planned:

- shared analytics/service layer;
- before/during/after circulation windows;
- 7/14/30/60-day KPIs;
- unique promoted-resource conversion;
- days to first checkout;
- baseline/turnover comparison methodology;
- campaign/channel/location/subject/language/audience analytics;
- promoted items with no response;
- repeated-title campaign analysis;
- restricted top user/student and Darajah/class/group/category analytics;
- privacy/access rules and test fixtures.

Acceptance criteria must define formulas before UI implementation.

## v0.4 — Reporting and external API

**Priority:** P2  
**Dependency:** stable analytics rules

- campaign/detail reports;
- CSV/JSON exports;
- read-only analytics endpoints;
- OAuth2 integration guide;
- ensure API and staff dashboard share identical calculations.

## Resource model expansion

**Priority:** P1/P2 depending on operational need

- support e-resources/external resources without physical barcodes;
- author/theme/collection promotion entities;
- preserve Koha item-linked analytics where items exist.

## v1.0 production readiness

**Priority:** release gate

- controlled historical spreadsheet importer;
- automated regression tests;
- Koha 25.11.x full validation;
- Koha 26.05.x compatibility validation;
- exact KPZ clean-install/upgrade testing;
- backup/restore/rollback documentation and rehearsal;
- least-privilege permissions matrix;
- AJSN staging acceptance;
- production release package/checksum;
- staff training/support documentation.

## UI/UX modernization

**Status:** PLANNED / deliberately deferred

Modern professional dashboard, visual hierarchy and responsive refinement should occur after data model/workflows/analytics stabilize. Avoid double work by not finalizing visual KPI components before formulas and dimensions are approved.

## Backlog / optional ideas

- campaign evidence/asset attachment if a real need is confirmed;
- templates for recurring activities;
- safe aggregate external dashboard views;
- direct integrations with email/signage systems only if explicitly approved later;
- richer charts/trends once analytic definitions are stable.

Items in this backlog are not approved implementation scope until promoted through a decision/PRD update.