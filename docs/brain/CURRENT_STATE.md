# Current State

**Last verified:** 2026-08-29  
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`  
**Repository default branch:** `main`  
**Active implementation branch:** `feature/v0.2-campaign-crud`  
**Active implementation commit last verified locally/remotely:** `3537b8e` — Fix health endpoint to report current plugin version  
**Project Brain construction branch:** `docs/project-brain` based on `feature/v0.2-campaign-crud`

## Current milestone

**v0.2.x — Campaign data entry, validation, integrity, audit and security checkpoint.**

The immediate development objective is to finish and close **v0.2 Checkpoint 1** with runtime regression/security verification after restoring the `kohadev` KTD environment.

## Overall status

**Pre-alpha / development only. Not approved for production.**

Core campaign creation is materially working and has passed several manual integrity tests. The current blocker is a **Koha Testing Docker environment lifecycle failure**, not a verified regression in plugin code.

## Working functionality — verified

### Plugin foundation

- Plugin is recognized by Koha when KTD is healthy.
- Version 0.2.0 is defined in current source.
- Plugin metadata targets minimum Koha `25.11.00.000`.
- Plugin has Dashboard / Run Tool and Configure entry points.
- Four plugin-owned tables are created/maintained by `_ensure_schema`.
- Uninstall is intentionally non-destructive.

### Campaign creation

Manual tests in `kohadev` verified:

- campaign can save with zero linked items;
- valid Koha barcode can be linked to a campaign;
- invalid barcode blocks save;
- duplicate barcode input is detected and one link is stored;
- mixed valid + invalid input saves nothing;
- dashboard counters update after successful writes;
- successful campaign creation creates an audit row;
- campaign/item/audit writes are transactional.

Latest verified pre-blocker dashboard state during checkpoint testing:

- Promotions: `3`
- Books linked: `2`
- Recent rows included `Duplicate Barcode Test`, `Valid Barcode Test`, and `Subject wise/ new arrivals display weekly`.

These are test records, not production data.

### Database evidence

For `Duplicate Barcode Test`, runtime SQL verified:

- `campaign_id = 3`;
- status `draft`;
- actor/creator borrower number recorded;
- one campaign-item row despite duplicate input;
- linked Koha item `itemnumber = 109`;
- real barcode `39999000002034`;
- a `campaign_created` audit row exists.

A prior apparent barcode-validation inconsistency was traced to a manually mistyped barcode with one zero missing; it was not a plugin defect.

### v0.1 historical release-path tests

Historically verified in KTD:

- versioned KPZ built successfully;
- archive structure inspected;
- checksum generated;
- clean Koha instance accepted plugin upload;
- plugin loaded/enabled;
- dashboard/configure/new-promotion foundation screens rendered;
- four plugin tables were created;
- authenticated health endpoint returned success;
- unauthenticated/incognito health request failed authentication;
- disable/re-enable preserved plugin-owned setting data.

## Partially working / incomplete

### REST health endpoint

Current source fix is present at commit `3537b8e`: health response now obtains version from the plugin's authoritative `$VERSION` rather than hard-coding `0.1.0`.

**Status:** `IMPLEMENTED-CODE / RUNTIME RE-VERIFICATION BLOCKED`.

Before the fix was downloaded into the local environment, browser output still showed `0.1.0`. GitHub connectivity was restored and the fix was successfully pulled. Runtime confirmation of `0.2.0` has not yet been completed because the `kohadev` application container is now failing during KTD initialization.

### Campaign model

- type/channel are generic but still hard-coded allowed values;
- audience/language/location are simple fields;
- only one free-text display location is currently stored;
- campaign detail/edit/delete/list management is not built;
- soft-delete columns exist but no UI/workflow uses them.

### Dashboard

Current dashboard provides counts and recent campaigns. Conversion rate is a placeholder (`Analytics engine: Phase 3`). Professional analytics and visual design are not yet built.

## Broken / current blocker

### KTD `kohadev-koha-1` exits during initialization

**Current runtime evidence:**

- `kohadev-db-1` remains running;
- `kohadev-memcached-1` remains/runs healthy;
- `kohadev-koha-1` exits;
- Docker inspect result: `ExitCode=11`, `OOMKilled=false`, no Docker state error;
- log reaches Koha setup and ends with:
  - `Database is not empty! at /kohadevbox/misc4dev/do_all_you_can_do.pl line 89.`

**Cause:** during troubleshooting, only the Koha application container was removed/recreated while the already-populated `kohadev` database container was retained. The replacement application container entered a first-time initialization path and refused to initialize over the non-empty database.

**This is not evidence that plugin v0.2 code is crashing Koha.**

## Recent resolved environment issue

WSL/Debian temporarily could resolve `github.com` but could not connect to TCP/443 (`No route to host`). Windows itself could reach GitHub. After restarting WSL networking, Debian `curl -I https://github.com` returned HTTP 200 and `git pull` succeeded. Do not treat this as an active GitHub outage.

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

- v0.1 KPZ build/structure/checksum.
- historical clean KPZ install on Koha 25.11.02.
- plugin disable/re-enable data persistence.
- authenticated vs unauthenticated health behavior for v0.1.
- v0.2 campaign creation with no barcode.
- v0.2 valid barcode linkage.
- v0.2 invalid barcode blocking.
- v0.2 duplicate barcode de-duplication.
- v0.2 campaign/item/audit database write verification.
- v0.2 mixed valid+invalid rollback.

### BLOCKED / NOT YET CLOSED

- v0.2 health endpoint returning `version: 0.2.0` in runtime after commit `3537b8e`.
- final CSRF/security regression verification.
- lower-permission authorization matrix testing.

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
- Historical disposable clean-package instance: `kpztest` (removed after testing).
- Current `kohadev` DB contains checkpoint test data unless subsequently removed.
- Current `kohadev` app container is stopped/exited because of the non-empty-database initialization failure.

## Production/staging state

- No production deployment verified.
- No AJSN staging deployment verified.
- Production remains explicitly gated behind KTD 25.11, KTD 26.05, staging, backup/rollback, exact KPZ and checksum validation.

## Immediate next task

Recover a clean, consistent `kohadev` KTD instance **without losing any test evidence that still matters**:

1. Back up the four plugin test tables if preservation is desired.
2. Perform a proper KTD environment teardown/recreate rather than recreating only `kohadev-koha-1` over a retained populated database.
3. Start `kohadev` with the current `feature/v0.2-campaign-crud` plugin mount.
4. Wait for `KTD READY`.
5. Reinitialize/upgrade plugin if required.
6. Verify plugin displays v0.2.0.
7. Verify `/api/v1/contrib/ajsn_promotion/health` returns `version: 0.2.0` when authenticated and fails authentication when not logged in.
8. Finish the remaining v0.2 security checkpoint tests.

See `SESSION_HANDOFF.md` for exact continuation guidance.