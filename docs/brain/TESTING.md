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