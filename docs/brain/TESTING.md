# Testing Register

Only executed tests may be marked `PASS`. Suggestions/plans remain `NOT RUN` or `BLOCKED`.

## Environment labels

- `promoeng`: primary isolated KTD feature-development instance for this plugin, Koha 25.11.x/25.11.02 observed.
- `kohadev`: legacy/shared KTD instance; not the primary runtime for new plugin verification.
- `kpztest`: historical disposable KTD instance used for clean KPZ installation testing; later removed.
- `AJSN staging`: planned, not yet verified.
- `production`: not tested/deployed.

## Historical v0.1 foundation and packaging

| ID | Test | Environment | Status | Evidence/result |
|---|---|---|---|---|
| T-001 | Plugin loads without ERRORS badge | KTD | PASS | Koha Plugins page later showed Promotion & Engagement enabled. |
| T-002 | Dashboard renders | KTD | PASS | Run Tool rendered dashboard. |
| T-003 | Configure renders | KTD | PASS | Foundation configuration page rendered. |
| T-004 | New Promotion foundation screen renders | KTD | PASS | Read-only foundation screen rendered before v0.2. |
| T-005 | Four plugin tables created | KTD DB | PASS | campaigns/items/audit/settings tables queried. |
| T-006 | Health endpoint authenticated success | KTD browser | PASS | Returned status ok/plugin/version 0.1.0 in foundation phase. |
| T-007 | Health endpoint without login | InPrivate/incognito | PASS | Authentication/session failure returned rather than successful health payload. |
| T-008 | Disable/re-enable preserves plugin data | KTD DB/UI | PASS | `lifecycle_test=before_disable` setting remained after disable/re-enable. |
| T-009 | KPZ builder produces artifact/checksum | Debian | PASS | `PromotionEngagement-v0.1.0.kpz` and `.sha256` built. |
| T-010 | KPZ archive root/content inspection | Debian | PASS | Archive contained `Koha/Plugin/Com/AJSN/...` files without repository wrapper. |
| T-011 | Clean KPZ upload/install | `kpztest` | PASS | Clean Koha initially showed no plugins; uploaded package then showed v0.1.0 enabled. |
| T-012 | Clean-install schema/health smoke | `kpztest` | PASS | plugin tables and health response verified during historical clean-install sequence. |

Historical v0.1 SHA-256 observed for the built artifact: `c270f375b46d7cda5c06baa0b0a2e87b9b0fcb42c657b3b2be318570d4968c31`. Treat this only as the historical v0.1 test artifact checksum, not a current release checksum.

## v0.2 Checkpoint 1 — campaign creation

| ID | Test | Status | Result |
|---|---|---|---|
| T-101 | Schema upgrade adds `channel` | PASS | DB `SHOW COLUMNS ... LIKE 'channel'` returned `varchar(80)`. |
| T-102 | Save campaign with no barcodes | PASS | `Subject wise/ new arrivals display weekly` saved with zero linked items. |
| T-103 | Save with one valid Koha barcode | PASS | `Valid Barcode Test` saved and linked one item. |
| T-104 | Verify linked item against Koha | PASS | campaign linked itemnumber 109; title/author join succeeded. |
| T-105 | Invalid barcode blocks save | PASS | fake `TEST-NOT-EXIST-99999` identified and campaign not saved. |
| T-106 | Duplicate barcode input de-duplicated | PASS | `Duplicate Barcode Test` saved with one linked item and one duplicate warning. |
| T-107 | Dashboard counters after duplicate test | PASS | Promotions 3, Books linked 2. |
| T-108 | DB campaign/item/audit verification | PASS | campaign 3, one item link, `campaign_created` audit row. |
| T-109 | Mixed valid+invalid transactional rollback | PASS | UI reported one valid + one invalid; campaign not saved. |
| T-110 | Dashboard unchanged after rollback | PASS | remained Promotions 3 / Books linked 2; mixed rollback campaign absent. |

### Barcode typo investigation

A temporary apparent failure using `3999900002034` was **not a plugin bug**. DB inspection proved live item 109 uses `39999000002034` (14 chars). Re-running duplicate test with the correct barcode passed.

## REST regression

| ID | Test | Status | Notes |
|---|---|---|---|
| T-120 | v0.2 health returns status ok | PASS | Authenticated browser returned `status: ok`. |
| T-121 | v0.2 health returns version `0.2.0` | PASS | Runtime response returned `version: 0.2.0`; stale-version bug is closed. |
| T-122 | v0.2 unauthenticated health denied | PASS | InPrivate/incognito returned `{"error":"Authentication failure."}`. |

## Security

| ID | Test | Status | Notes |
|---|---|---|---|
| T-130 | Normal POST with generated CSRF token | PASS indirectly | Successful v0.2 campaign POSTs traversed normal Koha middleware. |
| T-131 | Missing/invalid CSRF token rejected | PASS | Authenticated staff session submitted exact campaign-create POST with `csrf_token=INVALID-CSRF-TEST`; Koha returned HTTP 403 `Wrong CSRF token`; DB count for unique test campaign stayed 0 before/after. |
| T-132 | User without plugin tool permission denied | PASS | Existing KTD test patron `term1` was temporarily set to catalogue-only (`flags=4`), a valid staff session/CSRF token was created, main staff page access passed, plugin write POST was denied to login/authorization flow, and DB count stayed 0. Original flags restored by trap. |
| T-133 | Health API without required `catalogue` permission denied | PASS | `term1` authenticated successfully via HTTP Basic but lacks `catalogue`; endpoint returned HTTP 403 with `Authorization failure. Missing required permission(s).` and required permission `{catalogue: 1}`. Test account state was left/restored at its original flags. |
| T-134 | Authorized campaign-create smoke after security tests | PASS | Synthetic valid staff session for superlibrarian submitted normal campaign create; HTTP 200, one campaign row and one `campaign_created` audit row observed; test data cleaned up afterward. |

## v0.2 Campaign management — Edit / Update / Archive

| ID | Test | Status | Result |
|---|---|---|---|
| EA-01 | Edit form prefill | PASS | Existing fields and linked barcode rendered. |
| EA-02 | Valid transactional update + audit | PASS | Metadata/items updated; campaign_updated and status audit rows created. |
| EA-03 | Invalid barcode blocks entire update | PASS | No campaign/item state changed. |
| EA-04 | Linked-item removal is soft-delete | PASS | Item-link deleted_at set; row preserved. |
| EA-05 | Soft-deleted link can be reactivated | PASS | Existing unique row reactivated. |
| EA-06 | Unconfirmed archive denied | PASS | Campaign remained active. |
| EA-07 | Campaign archive soft-delete + audit | PASS | Campaign archived; rows preserved; archive audit inserted. |
| EA-08 | Archived campaign hidden from active views | PASS | List excludes it; detail returns unavailable. |
| EA-09 | Update with forged CSRF rejected | PASS | HTTP 403; state unchanged. |
| EA-10 | Invalid status rejected | PASS | Status whitelist enforced. |
| EA-11 | Archive with forged CSRF rejected | PASS | HTTP 403; campaign remained active. |
| EA-12 | Archive soft-deletes linked items | PASS | Active links became 0; physical rows preserved. |
| EA-13 | Dashboard active linked-item count after archive | PASS | UI/DB count returned to baseline. |
| EA-14 | Existing CR-01..CR-07 regression | PASS | Create/list/detail behavior remained green. |

Human visual acceptance is pending. See `docs/V0_2_EDIT_ARCHIVE_TEST.md`.

## KTD/runtime recovery

| ID | Test | Status | Result |
|---|---|---|---|
| T-140 | WSL GitHub HTTPS connectivity after restart | PASS | Debian `curl -I https://github.com` returned HTTP 200 and feature-branch pull succeeded. |
| T-141 | `kohadev` restart after app-container-only recreation | FAIL | Historical failed attempt; `kohadev-koha-1` exited because retained DB was non-empty. |
| T-142 | Diagnose app container exit | PASS diagnostic | Docker: OOM false; log ended `Database is not empty! ... do_all_you_can_do.pl line 89`. |
| T-143 | Clean consistent KTD teardown/recreate | PASS | Plugin tables were backed up; full KTD down/up completed; all three containers stayed Up and `--wait-ready 180` returned `KTD READY`. |
| T-144 | Plugin reload after clean KTD recovery | PASS | Koha Administration > Plugins showed Promotion & Engagement `0.2.0` Enabled. |
| T-145 | Dedicated `promoeng` isolated KTD runtime | PASS | `promoeng-koha-1`, `promoeng-db-1`, `promoeng-memcached-1` Up; intranet HTTP 200; plugin 0.2.0 installed; Plack restart restored plugin API route registration. |

## Release/compatibility tests

| ID | Test | Status |
|---|---|---|
| T-200 | Koha 25.11 full v0.2 regression | PARTIAL |
| T-201 | Koha 26.05 compatibility | NOT RUN |
| T-202 | v0.2+ clean KPZ install exact artifact | NOT RUN |
| T-203 | Upgrade from prior KPZ preserving data | NOT RUN |
| T-204 | Backup/restore/rollback rehearsal | PARTIAL | Local plugin-table backup completed before KTD reset; full release rollback rehearsal remains. |
| T-205 | AJSN staging acceptance | NOT RUN |
| T-206 | Production verification | NOT RUN |

## Analytics tests

All analytics correctness/performance/privacy tests are `NOT RUN` because the analytics engine is not yet implemented.

Future analytics test fixtures must cover:

- no-checkout campaigns;
- checkout before/during/after campaign;
- repeated promoted items across campaigns;
- multiple locations/channels;
- configurable windows;
- transfer/changed patron attributes where relevant;
- identifiable vs aggregated outputs;
- baseline/turnover comparison correctness.

## Useful commands

### Confirm current source version

```bash
grep -n "our \$VERSION" "$PLUGINS_DIR/koha-plugin-promotion-engagement/Koha/Plugin/Com/AJSN/PromotionEngagement.pm"
```

### KTD readiness

```bash
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --wait-ready 180
```

### Container diagnostic

```bash
docker inspect kohadev-koha-1 --format 'ExitCode={{.State.ExitCode}} OOMKilled={{.State.OOMKilled}} Error={{.State.Error}}'
docker logs --tail 250 kohadev-koha-1
```

### Build KPZ

```bash
python3 scripts/build_kpz.py
python3 -m zipfile -l dist/PromotionEngagement-vX.Y.Z.kpz
```

Never put DB passwords or other secrets in this file; use local environment/configuration when executing DB commands.
## v0.2 Universal configuration foundation — 2026-09-19

- CFG-01 Configure page renders: PASS.
- CFG-02 vocabulary and campaign-location schema + generic seeds: PASS.
- CFG-03 save reusable location value: PASS.
- CFG-04 disable value: PASS.
- CFG-05 update/re-enable same dimension+code: PASS.
- CFG-06 forged CSRF rejected with HTTP 403 and no write: PASS.
- CFG-07 invalid stable code rejected with no write: PASS.
- Existing CR-01..CR-07 and EA lifecycle/security/archive-count regressions after the configuration change: PASS.

Next test block: campaign form adoption and multi-location persistence/rendering.

## v0.2 Multi-location campaign integration — 2026-09-19

- ML-01 reusable configured locations created through plugin configuration: PASS.
- ML-02 create campaign with two configured locations: PASS.
- ML-03 Promotions list renders friendly configured type/channel labels and combined location labels: PASS.
- ML-04 Campaign detail renders multiple configured location labels: PASS.
- ML-05 Edit form pre-selects current campaign locations: PASS.
- ML-06 Edit reconciles add/remove location links transactionally and records location audit arrays: PASS.
- ML-07 disabled location already linked to a campaign remains visible/selected for safe editing: PASS.
- ML-08 forged CSRF on multi-location update returns HTTP 403 with no state change: PASS.
- Full CFG, CR and EA regression suites after integration: PASS.

Human visual review is complete; the milestone is cleared for merge.

### Multi-location visual acceptance progress
- Campaign Detail visual review for campaign 40: PASS.
- Friendly Type/Channel and three configured locations visible: PASS.
- Low-contrast status/location badge presentation corrected; ML-01..ML-08 and CR-01..CR-07 rerun PASS.
- Campaign 40 Detail human visual acceptance: PASS.
- Campaign 40 Edit human visual acceptance: PASS; Main Entrance, First Floor and Digital Screen are visibly pre-selected.
- Closure runtime sanity: plugin Perl syntax OK; `promoeng` intranet HTTP 200; database shows campaign 40 active with exactly three active normalized location links.
- Edit-form multi-select visual review: PASS.

## v0.3 Analytics Engine

- AN-01 current and historical checkout union with issue-ID de-duplication: PASS.
- AN-02 inclusive campaign dates and half-open boundary handling: PASS.
- AN-03 equal-duration baseline: PASS.
- AN-04 7/14/30/60 window resolution and boundary behavior: PASS for 7/14/60 checks; 30 resolved by shared window function.
- AN-05 renewals do not create extra conversion events: PASS.
- AN-06 fixed promoted-item cohort across all comparison windows: PASS.
- AN-07 distinct-item conversion formula: PASS.
- AN-08 zero/non-zero baseline uplift and absolute delta behavior: PASS.
- AN-09 zero eligible-item conversion returns null: PASS.
- AN-10 days-to-first checkout and no-response null behavior: PASS.
- Synthetic suite result: 23 assertions PASS; transaction rollback verified with zero residual synthetic issues, old_issues or campaigns.
- Campaign 40 no-circulation smoke: PASS.
- Main plugin and Analytics module Perl syntax: PASS.
- AN-11..AN-15: NOT RUN / next implementation checkpoint.
- Analytics page human visual review: PENDING.

### Analytics navigation regression — 2026-09-19
- Direct campaign 40 Analytics rendering: visual PASS.
- Blank requested campaign defaults to newest active campaign: PASS.
- Explicit campaign selection remains unchanged: PASS.
- Empty/missing campaign list remains safely blank: PASS.
- t/analytics_navigation.t: 5 assertions PASS.
- Combined t/analytics_engine.t + t/analytics_navigation.t: 28 assertions PASS.
- Plugin syntax and Plack restart/status: PASS.
- Dashboard > Analytics post-fix human visual recheck: PENDING.

## v0.3.0 release-candidate verification — 2026-09-20

- AN-01..AN-10 core engine: 23 assertions PASS.
- Analytics navigation/default selection: 5 assertions PASS.
- AN-11 overlap and portfolio issue-ID de-duplication: PASS.
- AN-12 stable-code/friendly-label comparisons and multi-location marking: PASS.
- AN-13 minimum-five privacy suppression: PASS.
- AN-14 archived-campaign historical authorization: PASS.
- AN-15 staff UI/API shared-service KPI parity: PASS.
- Advanced suite: 27 assertions PASS.
- Combined Analytics suite: 55 assertions PASS.
- Dashboard, Analytics, Reports and filtered Promotions render through Koha plugin loader without template failures: PASS.
- Analytics and comparative Reports service smoke against campaign fixtures: PASS.
- Main plugin, Analytics service and Analytics API syntax: PASS.
- OpenAPI JSON parse: PASS.
- Synthetic issues/old_issues/campaign residue: 0/0/0 PASS.
- Plack restart/status: PASS.
- v0.3.0 KPZ build, SHA-256 verification, exact archive extraction and extracted-module syntax: PASS.
- Human professional-UI visual acceptance: PENDING for Monday.
- Koha 26.05, institutional staging and production gates: NOT RUN; remain explicitly blocked.

## v0.3.0 clean installation, upgrade and rollback — 2026-09-20

- Exact artifact: `PromotionEngagement-v0.3.0.kpz`.
- SHA-256: `f8158110e09c954e4e65849a040f980c2769e25429cffd82028f5505d48b164d`.
- Clean Koha 25.11 instance without plugin bind mount: PASS.
- Authenticated Koha upload and version 0.3.0 discovery: PASS.
- Six-table schema creation: PASS.
- Dashboard, Promotions, Analytics, Reports, Configuration and New Promotion: PASS.
- REST health authentication: anonymous 401; authenticated 200 with version 0.3.0.
- Disable/re-enable sentinel preservation: PASS.
- v0.2.0 (`a3e2fe4`) to v0.3.0 upgrade and data preservation: PASS.
- Migration run twice without loss: PASS.
- `koha-dump`, deliberate deletion and SQL restore: PASS.
- Koha 26.05: NOT RUN; image unavailable locally and host C: free space was 6.6 GB.
- Institutional staging and human visual acceptance: PENDING.

See `docs/brain/V0.3_RELEASE_GATE_REPORT.md` for complete evidence and boundaries.

## AN-16 display-impact evidence — 2026-09-20

- Analytics service and main plugin syntax: PASS.
- Full Analytics suite: 55 assertions PASS.
- Display-impact finding and provisional state: PASS.
- Title/barcode before/during/after response: PASS.
- Future campaign shown as awaiting activity: PASS.
- Campaign 40 runtime smoke exposes title `E Street shuffle`, barcode `3999900000001` and honest provisional no-response finding: PASS.
- Dashboard/Analytics/Reports server-side render smoke: PASS.
- Plack status after restart: running.
- Human visual acceptance: PENDING.

## BDI-01 through BDI-17 — Book Display Impact

PASS on Koha 25.11 KTD:

- displayed item to biblio aggregation;
- live active-hold and serviceable-copy evidence;
- holds-per-copy, priority, evidence grade and quantity;
- approval decision and reviewed quantity persistence;
- native Koha Suggestion creation with ASKED status, quantity and biblionumber;
- rollback leaves no synthetic test records.

Full suite: 4 files, 72 assertions, PASS.
Authenticated browser render: PASS.
End-to-end approve → submit → Koha row/audit verification → cleanup: PASS.
KPZ checksum, ZIP integrity and inclusion of both new module files: PASS.

## Exact v0.4 KPZ clean-install gate

PASS in disposable `promoengpkg` Koha 25.11: authenticated KPZ upload,
version 0.4.0, seven tables and Book Display Impact render. The exact installed
artifact checksum is `f71eeb9a1d12df8d0e051ee13b1fb4c342b74a7a912ea30f42ce0b838eb70dbf`.
Disposable runtime removed after verification.
