# Roadmap

## Current milestone — v0.2 Checkpoint 1: campaign creation integrity/security

**Status:** IN PROGRESS / runtime environment healthy  
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
- [x] Health endpoint version source fixed.
- [x] Consistent `kohadev` KTD environment recovered.
- [x] Runtime health endpoint verified at v0.2.0.
- [x] Unauthenticated health denial verified.

### Remaining acceptance work

- [ ] Dedicated invalid/missing CSRF submission test (T-131).
- [ ] Logged-in user without plugin `tool` permission test (T-132).
- [ ] Authenticated API user without `catalogue` permission test (T-133).
- [ ] Authorized smoke test after permission testing.
- [ ] Record checkpoint closure in testing/current-state files.

**Acceptance criteria:** all `docs/V0_2_CHECKPOINT_1_TEST.md` pass criteria plus the security regression checks above.

## Current milestone — v0.2 universal configuration and multi-location

**Priority:** P1  
**Dependency:** checkpoint 1 closure

### Prepared remotely — read-only slice

Branch `feature/v0.2-campaign-read`, Draft PR #1:

- [x] CODE: campaign list view.
- [x] CODE: campaign detail view.
- [x] CODE: linked item title/author/biblionumber live Koha read-through.
- [x] CODE: campaign audit-history view.
- [x] CODE: invalid/nonexistent campaign-ID handling.
- [x] CODE: manual KTD test plan/runbook.
- [x] REMOTE PREPARATION: Project Brain/roadmap/handoff updated for the exact test sequence.
- [ ] RUNTIME: CR-01..CR-07 verification.
- [ ] MERGE: only after T-131/T-132/T-133 and CR-01..CR-07 pass.

### Planned after read-only slice

- [x] campaign edit/update workflow with audit;
- [x] archive/soft-delete and status transitions;
- campaign search/filter refinement;
- [ ] reusable configurable campaign types/channels;
- [ ] plugin-managed location vocabulary;
- [ ] one campaign to multiple locations;
- [ ] configurable languages/audiences/cadence;
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
## v0.3.0 checkpoint update — 2026-09-20

Analytics Engine AN-01..AN-15, professional management UI, comparative Reports, exports, campaign filtering and read-only Analytics API are implemented in the release candidate. The checkpoint is code/runtime complete and awaits Monday human visual acceptance before pull-request merge.

Later roadmap items remain recurrence/templates, non-barcode resources, restricted analytics, historical import, forward compatibility, staging and production deployment.
