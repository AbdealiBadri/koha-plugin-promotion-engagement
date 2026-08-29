# Current State

**Last verified:** 2026-08-29  
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`  
**Repository default branch:** `main`  
**Active implementation branch:** `feature/v0.2-campaign-crud`  
**Implementation commit under test:** `3537b8e` — Fix health endpoint to report current plugin version

## Current milestone

**v0.2.x — Campaign data entry, validation, integrity, audit and security checkpoint.**

The environment/API blockers are resolved. The immediate objective is now to complete the remaining dedicated security/permission tests and close **v0.2 Checkpoint 1**.

## Overall status

**Pre-alpha / development only. Not approved for production.**

Core campaign creation is materially working and has passed the manual integrity tests performed so far. The `kohadev` KTD environment is healthy again.

## Working functionality — verified

### Plugin foundation

- `kohadev` rebuilt cleanly and KTD reports `KTD READY`.
- Koha Administration > Plugins shows Promotion & Engagement **0.2.0 Enabled**.
- Four plugin-owned tables are created/maintained by `_ensure_schema`.
- Uninstall remains intentionally non-destructive.

### REST health endpoint

Runtime verification now passes:

- authenticated request returns `status: ok`;
- plugin name is `Promotion & Engagement`;
- version is `0.2.0`;
- InPrivate/unauthenticated request returns `Authentication failure.`

Therefore the stale `0.1.0` health-version defect is closed.

### Campaign creation

Previously verified in `kohadev` before the clean KTD reset:

- campaign can save with zero linked items;
- valid Koha barcode can be linked to a campaign;
- invalid barcode blocks save;
- duplicate barcode input is detected and one link is stored;
- mixed valid + invalid input saves nothing;
- dashboard counters update after successful writes;
- successful campaign creation creates an audit row;
- campaign/item/audit writes are transactional.

The old checkpoint DB test rows were backed up before reset. Their evidence is preserved in the Project Brain; they do not need to be restored merely to prove the already-recorded tests.

### Database evidence from prior checkpoint run

For `Duplicate Barcode Test`, runtime SQL verified:

- `campaign_id = 3`;
- status `draft`;
- actor/creator borrower number recorded;
- one campaign-item row despite duplicate input;
- linked Koha item `itemnumber = 109`;
- real barcode `39999000002034`;
- a `campaign_created` audit row exists.

A prior apparent barcode-validation inconsistency was traced to a manually mistyped barcode with one zero missing; it was not a plugin defect.

## Resolved environment incident

`kohadev-koha-1` had previously exited because only the app container was recreated while a populated `kohadev-db-1` remained. KTD first-time initialization then refused the non-empty database.

Resolution completed:

1. backed up all four `plugin_ajsn_promo_*` tables;
2. performed full KTD `down`;
3. recreated the full `kohadev` environment;
4. confirmed all three containers stay Up;
5. `--wait-ready 180` returned `KTD READY`;
6. plugin loaded as 0.2.0 Enabled;
7. authenticated and unauthenticated health tests passed.

## Partially working / incomplete

### Campaign model

- type/channel are generic but still hard-coded allowed values;
- audience/language/location are simple fields;
- only one free-text display location is currently stored;
- campaign detail/edit/delete/list management is not built;
- soft-delete columns exist but no UI/workflow uses them.

### Dashboard

Current dashboard provides counts and recent campaigns. Conversion rate is a placeholder (`Analytics engine: Phase 3`). Professional analytics and visual design are not yet built.

## Unimplemented approved functionality

- multi-location campaign model;
- configurable universal vocabularies;
- recurring/cadence support;
- e-resource/non-barcode resource model;
- campaign detail/edit/archive/list/filter workflows;
- analytics engine;
- before/during/after and 7/14/30/60-day KPIs;
- conversion and days-to-first-checkout;
- channel/location/subject/language/audience comparisons;
- restricted top user/student and top Darajah/class/group/category analytics;
- professional management dashboard;
- reports and CSV/JSON exports;
- external campaign/analytics APIs;
- OAuth2 integration guide;
- historical spreadsheet importer;
- automated test suite for release gate;
- Koha 26.05 validation;
- AJSN staging deployment;
- production deployment.

## Test state

### PASS

- v0.1 KPZ build/structure/checksum and historical clean install.
- plugin disable/re-enable data persistence.
- v0.2 campaign creation with no barcode.
- v0.2 valid barcode linkage.
- v0.2 invalid barcode blocking.
- v0.2 duplicate barcode de-duplication.
- v0.2 campaign/item/audit database write verification.
- v0.2 mixed valid+invalid rollback.
- clean consistent KTD rebuild and readiness.
- plugin v0.2.0 runtime load.
- authenticated v0.2 health returns `0.2.0`.
- unauthenticated v0.2 health is denied.

### CURRENT CHECKPOINT WORK

- dedicated missing/invalid CSRF rejection test;
- user without plugin tool permission test;
- authenticated API user without `catalogue` permission test.

### NOT RUN

- Koha 26.05 compatibility.
- institutional staging.
- production.
- analytics correctness tests because analytics are not implemented.

## Local environment state

- Development host: Windows with WSL Debian and Docker/KTD.
- KTD repository: `~/git/koha-testing-docker`.
- Plugin repository is mounted through `--single-plugin` for feature development.
- Main dev KTD instance: `kohadev`.
- `kohadev-koha-1`, `kohadev-db-1`, and `kohadev-memcached-1` are Up as last verified.
- KTD readiness: PASS.
- Historical checkpoint plugin tables were backed up before clean reset.

## Production/staging state

- No production deployment verified.
- No AJSN staging deployment verified.
- Production remains explicitly gated behind KTD regression, Koha 26.05, staging, backup/rollback, exact KPZ and checksum validation.

## Immediate next task

Complete the security checkpoint in this order:

1. T-131 — prove a missing/invalid CSRF token cannot create a campaign.
2. T-132 — prove a logged-in user without plugin tool permission cannot use the plugin write workflow.
3. T-133 — prove a logged-in API user without `catalogue` permission cannot call the health endpoint.
4. Re-run a normal authorized campaign smoke test if any security test requires account/configuration changes.
5. If all pass, mark v0.2 Checkpoint 1 closed and move to campaign management/configuration/multi-location work.

See `SESSION_HANDOFF.md` and `TESTING.md`.