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

- **Status:** RESOLVED
- **Severity:** Medium
- **Module:** campaign configuration
- **Resolution:** plugin-managed universal vocabularies now provide configured campaign type, channel, location, language, audience and cadence values without Nairobi-specific source logic.
- **Evidence:** CFG-01..CFG-07 PASS; Create/Edit render configured Type and Channel labels.

## TECHDEBT-008 — Single free-text location cannot model real campaigns

- **Status:** RESOLVED
- **Severity:** Medium
- **Module:** campaign/location data model
- **Resolution:** normalized `plugin_ajsn_promo_campaign_locations` links one campaign to multiple reusable configured locations with soft-remove/reactivation semantics and legacy fallback.
- **Evidence:** ML-01..ML-08 PASS; campaign 40 Detail/Edit visual PASS with Main Entrance, First Floor and Digital Screen.

## ISSUE-009 — Campaign management lifecycle incomplete

- **Status:** RESOLVED FOR v0.3
- **Severity:** Medium
- **Module:** campaign management
- **Completed:** list/detail, linked-resource read-through, edit/update, whitelisted statuses, campaign/item soft-delete archive, audit operations, name/notes search and status filtering.
- **Runtime evidence:** CR-01..CR-07, EA-01..EA-13 and filtered Promotions render smoke pass in isolated promoeng.
- **Later scale polish:** pagination remains optional for a future large-dataset milestone.

## ISSUE-010 — Analytics engine not implemented

- **Status:** RESOLVED FOR v0.3.0 RELEASE CANDIDATE
- **Severity:** Product-critical
- **Module:** analytics/dashboard/reports
- **Completed:** AN-01..AN-16, display-impact findings, title-level response, before/during/after windows, conversion, uplift, days-to-first, portfolio de-duplication, multi-attribution, privacy suppression, configured comparisons, professional UI, exports and shared read-only API.
- **Evidence:** 55 assertions plus service/render/OpenAPI/KPZ gates PASS on 2026-09-20.
- **Remaining gate:** human professional-UI visual acceptance. Restricted identifiable analytics remain a separate future privacy milestone.

## ISSUE-011 — Non-barcode resource model not implemented

- **Status:** OPEN / PLANNED
- **Severity:** Medium
- **Module:** promoted resources
- **Need:** e-resources, author/theme and external resources without physical item barcodes.
- **Current safe behaviour:** campaign can save with zero barcodes.

## ISSUE-012 — Security matrix not fully manually tested

- **Status:** RESOLVED
- **Severity:** High before release
- **Module:** authorization/CSRF
- **Code evidence:** Koha-native CSRF convention and tool permission integration are present; health OpenAPI requires `catalogue`.
- **Completed evidence:** authenticated health succeeds; unauthenticated health is denied.
- **Completed evidence:** authenticated health succeeds; unauthenticated health is denied; T-131 forged CSRF POST returned HTTP 403 with no DB write; T-132 catalogue-only staff session was denied plugin write access with no DB write and original flags restored; T-133 authenticated API user without `catalogue` returned HTTP 403 with required-permission detail; T-134 authorized campaign-create smoke passed and test rows were cleaned up.
- **Resolution date:** 2026-09-19.
- **Next action:** move to runtime validation of Draft PR #1 (Campaign List + Campaign Detail).

## ISSUE-013 — Compatibility/staging gates outstanding

- **Status:** OPEN — external gates only
- **Severity:** Release blocker
- **Module:** deployment
- **Completed:** exact v0.3.0 KPZ build/checksum/extraction, authenticated clean Koha 25.11 upload/install, v0.2-to-v0.3 upgrade preservation, repeated migration idempotence and local database backup/restore rehearsal.
- **Missing:** human visual acceptance, Koha 26.05.x validation, institutional staging and confirmation of production backup ownership/maintenance window.
- **Constraint:** only Koha 25.11 is local; Windows C: had 6.6 GB free, so pulling another approximately 7.5 GB image was intentionally avoided.
- **Production:** must remain blocked until the missing external gates pass.