# Issue and Bug Register

## BUG-001 — Historical plugin discovery/load failure in KTD

- **Status:** RESOLVED
- **Severity:** High during foundation
- **Module:** KTD / Koha plugin loader
- **Description:** Koha Plugins page initially showed `ERRORS` and the plugin module could not be located in `@INC`.
- **Expected:** plugin loads and appears enabled.
- **Evidence:** historical terminal/browser testing.
- **Resolution:** plugin support/path configuration was corrected, plugin directory was visible in `koha-conf.xml`, plugins were re-initialized and Plack restarted; `Koha::Plugins->GetPlugins` later returned one good plugin and zero bad plugins.
- **Do not repeat:** do not assume browser cache is the cause when Koha's plugin loader reports module discovery errors. Inspect `pluginsdir`, `enable_plugins`, Perl include path/plugin initialization and Koha logs first.

## BUG-002 — Historical Template Toolkit dashboard render failure

- **Status:** RESOLVED
- **Severity:** High
- **Module:** staff UI templates
- **Description:** Run Tool produced `Template process failed: undef error - filter not found` from `C4/Templates.pm` with plugin dashboard stack trace.
- **Result:** later template revisions rendered the dashboard correctly.
- **Do not repeat:** if this exact error returns, inspect template filters/syntax in the plugin template before debugging database/API layers.

## BUG-003 — Health endpoint reported stale `0.1.0`

- **Status:** RESOLVED
- **Severity:** Medium
- **Module:** REST API
- **Expected:** health endpoint version equals plugin `$VERSION` (`0.2.0` on active branch).
- **Actual before fix:** endpoint returned `0.1.0`.
- **Cause:** version string duplicated/hard-coded in `API/Health.pm`.
- **Fix:** commit `3537b8e` makes controller read authoritative plugin `$VERSION`.
- **Runtime verification:** after KTD recovery, authenticated health returned `status: ok`, plugin name and `version: 0.2.0`; InPrivate/unauthenticated request returned `Authentication failure.`

## ISSUE-004 — `kohadev-koha-1` exits with non-empty database

- **Status:** RESOLVED
- **Severity:** High for local development; no production impact
- **Module:** KTD environment lifecycle
- **Historical symptom:** app container exited while DB/memcached remained; Docker inspect showed ExitCode 11 and logs ended `Database is not empty! at /kohadevbox/misc4dev/do_all_you_can_do.pl line 89.`
- **Cause:** only `kohadev-koha-1` was removed/recreated while populated `kohadev-db-1` was retained; replacement app container followed first-time initialization logic.
- **Resolution:** backed up all four plugin tables, performed full consistent KTD `down`, recreated the full environment, then `--wait-ready 180` returned `KTD READY`. All three containers remained Up.
- **Do not repeat:** do not `docker rm -f kohadev-koha-1` as a generic fix while retaining a populated KTD DB unless the KTD lifecycle explicitly supports that state.

## ISSUE-005 — WSL could not reach GitHub TCP/443

- **Status:** RESOLVED
- **Severity:** Medium
- **Module:** local network/WSL
- **Actual:** DNS resolved `github.com`, but `curl`/Git failed with `No route to host` on port 443 while Windows PowerShell connectivity succeeded.
- **Resolution:** WSL networking restart/recreation; Debian later returned HTTP 200 and `git pull` succeeded.
- **Do not repeat:** do not diagnose this as a GitHub outage or plugin failure when Windows can reach GitHub. Compare host vs WSL connectivity.

## ISSUE-006 — KPZ test plan text is v0.1-specific

- **Status:** OPEN DOCUMENTATION DEBT
- **Severity:** Low
- **Module:** release documentation
- **Description:** `docs/KPZ_TEST_PLAN.md` examples and expected health version use `v0.1.0` while active development is `v0.2.0`.
- **Expected:** release procedure should be version-aware or updated for the next artifact.
- **Next action:** update when v0.2 packaging/release checkpoint begins; do not falsely claim v0.2 clean KPZ acceptance has already run.

## TECHDEBT-007 — Generic vocabularies are still hard-coded

- **Status:** OPEN
- **Severity:** Medium
- **Module:** campaign configuration
- **Description:** allowed campaign types/channels are hard-coded in Perl; audience/language/location are free text.
- **Requirement:** configurable universal vocabularies without Nairobi-specific code.
- **Next action:** design configuration source and migrations after v0.2 checkpoint closure.

## TECHDEBT-008 — Single free-text location cannot model real campaigns

- **Status:** OPEN
- **Severity:** Medium
- **Module:** campaign/location data model
- **Actual:** one `display_location VARCHAR(255)`.
- **Expected future:** one campaign can link multiple reusable locations; analytics can compare locations.
- **Open design:** Koha authorized values vs plugin values vs hybrid.

## ISSUE-009 — No campaign detail/edit/archive lifecycle

- **Status:** OPEN / PLANNED
- **Severity:** Medium
- **Module:** campaign management
- **Current:** create + recent list only.
- **Needed:** detail, linked-resource view, edit, controlled status transitions, archive/soft-delete, filters/search and audit of changes.

## ISSUE-010 — Analytics engine not implemented

- **Status:** OPEN / PLANNED
- **Severity:** Product-critical but not current blocker
- **Module:** analytics/dashboard
- **Current:** counts only; conversion tile says later phase.
- **Needed:** before/during/after, 7/14/30/60 windows, unique conversion, days-to-first-checkout, channel/location/subject/audience comparisons, restricted user/class benefit analytics.
- **Dependency:** stable campaign/resource/configuration model.

## ISSUE-011 — Non-barcode resource model not implemented

- **Status:** OPEN / PLANNED
- **Severity:** Medium
- **Module:** promoted resources
- **Need:** e-resources, author/theme and external resources without physical item barcodes.
- **Current safe behaviour:** campaign can save with zero barcodes.

## ISSUE-012 — Security matrix not fully manually tested

- **Status:** OPEN / CURRENT CHECKPOINT WORK
- **Severity:** High before release
- **Module:** authorization/CSRF
- **Code evidence:** Koha-native CSRF convention and tool permission integration are present; health OpenAPI requires `catalogue`.
- **Completed evidence:** authenticated health succeeds; unauthenticated health is denied.
- **Missing evidence:** dedicated forged/missing-CSRF POST test, user without plugin tool permission, and authenticated API user without `catalogue` permission.
- **Next action:** run T-131, T-132 and T-133.

## ISSUE-013 — Compatibility/staging gates outstanding

- **Status:** OPEN
- **Severity:** Release blocker
- **Module:** deployment
- **Missing:** Koha 26.05.x validation, AJSN staging, final backup/restore/rollback rehearsal, exact v0.2+ KPZ acceptance.
- **Production:** must remain blocked until these pass.