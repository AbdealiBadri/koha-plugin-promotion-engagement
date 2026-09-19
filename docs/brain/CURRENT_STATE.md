# Current State

**Last verified:** 2026-09-19
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`
**Repository default branch:** `main`
**Active implementation branch:** `feature/v0.3-analytics-engine`
**Base branch:** `feature/v0.2-campaign-crud`

## Current milestone

**v0.3 Analytics Engine — ACTIVE.**

Checkpoint 1, Campaign List/Detail, Edit/Update/Archive, Universal Configuration and Multi-location are complete. PR #3 merged into `feature/v0.2-campaign-crud` as `17915cd`. The active v0.3 branch now defines and implements one shared Analytics Engine using Koha circulation history without duplicating Koha operational data.

## Overall status

**Pre-alpha / development only. Not approved for production.**

Core campaign creation is materially working and has passed the manual integrity tests performed so far. The `kohadev` KTD environment is healthy again.

## Working functionality — verified

### Plugin foundation

- Dedicated `promoeng` KTD runtime is Up and isolated from unrelated projects; intranet returns HTTP 200.
- Koha Administration > Plugins shows Promotion & Engagement **0.2.0 Enabled**.
- Six plugin-owned tables are created/maintained by `_ensure_schema`, including universal vocabulary and campaign-location relation tables.
- Uninstall remains intentionally non-destructive.

### REST health endpoint

Runtime verification now passes:

- plugin route is registered in `promoeng` after Plack restart;
- authenticated authorized requests previously returned `status: ok`, plugin name and version `0.2.0`;
- unauthenticated request returns `Authentication failure.`;
- authenticated user without `catalogue` permission now returns HTTP 403 with the required-permission detail.

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

- campaign type and channel use plugin-managed universal configuration;
- reusable location values support normalized one-campaign-to-many-location links;
- Create and Edit persist/reconcile location links transactionally;
- disabled linked locations remain visible during Edit;
- legacy `display_location` remains as a backward-compatible fallback;
- list/detail/edit/update/archive are runtime-verified and visually accepted;
- campaign, item-link and campaign-location archive uses `deleted_at` and preserves history;
- only PR #3 merge/branch transition remains before Analytics Engine work.

### Dashboard

Current dashboard provides counts and recent campaigns. Conversion rate is a placeholder (`Analytics engine: Phase 3`). Professional analytics and visual design are not yet built.

## Unimplemented approved functionality

- recurring/cadence behavior beyond configuration values;
- e-resource/non-barcode resource model;
- list filtering/search workflows;
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

### SECURITY CHECKPOINT

- T-131 invalid/missing CSRF rejection: PASS.
- T-132 user without plugin tool permission: PASS.
- T-133 authenticated API user without `catalogue`: PASS.
- T-134 authorized campaign-create smoke after security tests: PASS.

Checkpoint 1 is closed.

### CAMPAIGN READ MODULE

- CR-01 Promotions list: PASS.
- CR-02 Campaign detail: PASS.
- CR-03 Linked Koha item read-through: PASS.
- CR-04 Zero-item campaign: PASS.
- CR-05 Audit history: PASS.
- CR-06 Invalid/nonexistent campaign ID handling: PASS.
- CR-07 create-workflow regression: PASS.
- Human visual review: PASS using normal Koha staff login path.

### NOT RUN

- Koha 26.05 compatibility.
- institutional staging.
- production.
- analytics correctness tests because analytics are not implemented.

## Local environment state

- Development host: Windows with WSL Debian and Docker/KTD.
- KTD repository: `~/git/koha-testing-docker`.
- Plugin repository is mounted through `--single-plugin` for feature development.
- Main plugin KTD instance: `promoeng`.
- `promoeng-koha-1`, `promoeng-db-1`, and `promoeng-memcached-1` are Up as last verified.
- `kohadev` is retained only as a legacy/shared instance and is not used for new plugin verification.
- KTD readiness: PASS.
- Historical checkpoint plugin tables were backed up before clean reset.

## Production/staging state

- No production deployment verified.
- No AJSN staging deployment verified.
- Production remains explicitly gated behind KTD regression, Koha 26.05, staging, backup/rollback, exact KPZ and checksum validation.

## Immediate next task

1. Implement the shared Analytics Engine service defined in `ANALYTICS_SPEC.md`.
2. Add transaction-scoped synthetic fixtures because isolated `promoeng` has no circulation history.
3. Execute AN-01..AN-15 before wiring dashboard charts.
4. Preserve aggregate-only privacy behavior and a minimum cohort of five distinct borrowers.
5. Keep staff UI, reports and future APIs on the same service methods.

Architecture decisions DEC-019 and DEC-020 govern the active work.
