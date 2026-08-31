# Current State

**Last verified runtime:** 2026-08-29  
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`  
**Repository default branch:** `main`  
**Base implementation branch:** `feature/v0.2-campaign-crud`  
**Remote follow-on branch:** `feature/v0.2-campaign-read`  
**Draft PR:** #1

## Current milestone

**v0.2.x — close campaign-creation security checkpoint, then verify the first read-only campaign-management slice.**

The KTD/API blockers are resolved. The immediate runtime objective remains the dedicated security/permission matrix. In parallel, a separate read-only feature branch has been prepared so development can advance without modifying the unclosed write/security checkpoint.

## Overall status

**Pre-alpha / development only. Not approved for production.**

## Working functionality — VERIFIED-RUNTIME

### Plugin foundation

- `kohadev` rebuilt cleanly and KTD reported `KTD READY`.
- Koha Administration > Plugins showed Promotion & Engagement **0.2.0 Enabled**.
- Four plugin-owned tables are created/maintained by `_ensure_schema`.
- Uninstall remains intentionally non-destructive.

### REST health endpoint

- Authenticated request returns `status: ok`.
- Plugin name is `Promotion & Engagement`.
- Version is `0.2.0`.
- InPrivate/unauthenticated request returns `Authentication failure.`

### Campaign creation

Previously verified in `kohadev`:

- campaign can save with zero linked items;
- valid Koha barcode can be linked;
- invalid barcode blocks save;
- duplicate barcode input stores one link and reports the duplicate;
- mixed valid + invalid input saves nothing;
- dashboard counters update after successful writes;
- successful campaign creation creates an audit row;
- campaign/item/audit writes are transactional.

The old checkpoint DB rows were backed up before the clean KTD reset. Their evidence is preserved and does not need to be restored merely to prove prior tests.

## Security checkpoint — NEEDS-VERIFICATION

Still required on `feature/v0.2-campaign-crud`:

1. T-131 — invalid/missing CSRF token is rejected with no campaign write.
2. T-132 — logged-in user without plugin `tool` permission cannot use the write workflow.
3. T-133 — authenticated API user without `catalogue` permission cannot call `/health`.

A prior T-131 attempt altered the wrong Koha page token and is not valid evidence either way.

## Remote follow-on development — VERIFIED-CODE / NOT RUNTIME-VERIFIED

Branch `feature/v0.2-campaign-read` and Draft PR #1 add:

- read-only Promotions list;
- dashboard links to campaign detail;
- read-only campaign detail view;
- live Koha library-name resolution;
- linked Koha item title/author/biblionumber read-through;
- audit-history display;
- defensive invalid/nonexistent campaign-ID handling;
- dedicated KTD manual test plan and combined test runbook.

Safety properties of this slice:

- no schema change;
- no Koha core modification;
- no edit/archive/delete write path;
- current campaign creation code is retained;
- PR remains draft until runtime testing passes.

## Campaign model — incomplete

- type/channel are generic but still hard-coded allowed values;
- audience/language/location are simple fields;
- only one free-text display location is currently stored;
- edit/update/archive workflows are not built;
- soft-delete columns exist but no UI/workflow uses them;
- multi-location model is not built.

## Dashboard

Current verified dashboard provides counts and recent campaigns. Conversion rate remains a placeholder (`Analytics engine: Phase 3`). Professional analytics and visual design are deliberately deferred until data model/workflows/formulas stabilise.

## Major approved functionality still unimplemented

- campaign edit/update/archive/status-transition workflow;
- multi-location campaign model;
- configurable universal vocabularies;
- recurring/cadence support;
- e-resource/non-barcode resource model;
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
- automated release-gate test suite;
- Koha 26.05 validation;
- AJSN staging and production deployment.

## Test state

### PASS — VERIFIED-RUNTIME

- v0.1 KPZ build/structure/checksum and historical clean install.
- plugin disable/re-enable data persistence.
- v0.2 campaign creation with no barcode.
- v0.2 valid barcode linkage.
- v0.2 invalid barcode blocking.
- v0.2 duplicate barcode de-duplication.
- v0.2 campaign/item/audit DB verification.
- v0.2 mixed valid+invalid rollback.
- clean KTD rebuild/readiness.
- plugin v0.2.0 runtime load.
- authenticated v0.2 health returns `0.2.0`.
- unauthenticated v0.2 health is denied.

### NEXT RUNTIME TESTS

- T-131, T-132, T-133 on `feature/v0.2-campaign-crud`.
- Authorized smoke test.
- CR-01..CR-07 on `feature/v0.2-campaign-read`.

### NOT RUN

- read-only PR #1 runtime verification;
- Koha 26.05 compatibility;
- institutional staging;
- production;
- analytics correctness tests because analytics are not implemented.

## Local environment state

- Development host: Windows with WSL Debian and Docker/KTD.
- KTD repository: `~/git/koha-testing-docker`.
- Plugin repository is mounted through `--single-plugin`.
- Main dev instance: `kohadev`.
- Last verified: Koha, DB and memcached containers Up; KTD readiness PASS.

## Immediate next task

Follow `docs/V0_2_TOMORROW_TEST_RUNBOOK.md`:

1. finish T-131/T-132/T-133;
2. authorized smoke test;
3. switch to `feature/v0.2-campaign-read`;
4. run CR-01..CR-07;
5. if all pass, update evidence and merge Draft PR #1;
6. then begin edit/update/archive + universal configuration/multi-location work.