# KPZ Packaging and Installation Test Plan

This document defines the acceptance test for distributing Promotion & Engagement as a normal Koha Plugin Zip rather than as a development source bind mount.

## Goal

Prove that an exact versioned .kpz file can be uploaded through Koha Administration, installed/upgraded normally, preserve plugin data, and render the major plugin surfaces without Git/manual file copying on the Koha server.

Koha Plugin Zip archives must have the Koha/ namespace at archive root.

## Version-aware build

From the repository root:

    python3 scripts/build_kpz.py

The builder reads the authoritative plugin $VERSION and creates:

    dist/PromotionEngagement-v<VERSION>.kpz
    dist/PromotionEngagement-v<VERSION>.kpz.sha256

Do not hard-code a historical version in this procedure.

The builder packages only Git-tracked files below Koha/. New plugin source/template files must therefore be tracked before the final release build.

## Archive integrity

Run:

    python3 -m zipfile -t dist/PromotionEngagement-v<VERSION>.kpz
    python3 -m zipfile -l dist/PromotionEngagement-v<VERSION>.kpz
    sha256sum dist/PromotionEngagement-v<VERSION>.kpz

Requirements:

- ZIP test returns success;
- paths begin under Koha/Plugin/Com/AJSN/;
- no repository wrapper directory;
- no .git, .env, logs, temporary scripts or credentials;
- main plugin module, templates, OpenAPI file and API/service modules are present;
- checksum is recorded with the release/deployment evidence.

## Test environments

### Development upgrade smoke

An isolated KTD instance may already have an earlier plugin candidate installed. Upload the exact candidate KPZ through Koha and verify normal upgrade behavior.

### Clean-install gate

Before release, the exact artifact should also be tested in a clean Koha instance that is not source-mounted with --single-plugin.

The clean environment must have:

- plugin support enabled;
- plugin upload allowed;
- writable plugin directory;
- authorized staff user.

## Installation/upgrade acceptance

1. Open Koha Administration → Manage plugins.
2. Click Upload plugin.
3. Select the exact versioned KPZ.
4. Upload/confirm installation.
5. Restart Plack if required.
6. Confirm Promotion & Engagement displays the candidate version with no load error.
7. Confirm all expected plugin tables exist.
8. Run schema/install a second time where the test plan permits; historical data/counts must remain stable.

## v0.5 functional smoke

For v0.5.0 the package passes only when these surfaces render through an authenticated normal Koha staff session:

- Dashboard
- Promotions
- Campaign Analytics
- Comparative Reports
- Configuration
- Promoted Resource Impact

The browser response must not contain Template process failure or Internal Server Error.

Also verify:

- active campaign calculates through current date without forced completion;
- future follow-up windows display Pending;
- Promoted Titles differs correctly from linked copies/items where multiple copies share a biblio;
- title utilization is present;
- Resource Impact shows engagement KPIs before collection-development workflow counters.

## Database expectations

Current schema consists of seven namespaced plugin tables:

- plugin_ajsn_promo_campaigns
- plugin_ajsn_promo_campaign_locations
- plugin_ajsn_promo_items
- plugin_ajsn_promo_audit
- plugin_ajsn_promo_settings
- plugin_ajsn_promo_vocab_values
- plugin_ajsn_promo_recommendations

Upgrade/install must not drop retained historical data.

## Native Suggestion workflow smoke

Use only synthetic test data.

1. Create a temporary campaign linked to a known Koha item.
2. Open Promoted Resource Impact.
3. Approve a recommendation.
4. Submit it to native Koha Suggestions.
5. Verify:
   - ASKED/Pending state;
   - quantity;
   - biblionumber;
   - Management reason Book Display Impact;
   - patronreason is not forged/overwritten;
   - evidence staff note;
   - plugin audit record.
6. Delete only the synthetic Koha Suggestion and temporary plugin fixture.
7. Verify no residual temporary campaign/patron/suggestion remains.

Do not assume a retained visual campaign has no recommendation and do not clean up real/retained evidence as part of a smoke test.

## API/authentication gate

Where REST is included in the release matrix:

- authorized authenticated health request returns 200/status ok/current version;
- anonymous request is rejected;
- authenticated under-permission identity is rejected appropriately.

## Disable/re-enable and rollback

- Disable/re-enable must preserve plugin data.
- Uninstall remains intentionally non-destructive in current design.
- Upgrade from the preceding approved package must preserve historical rows.
- Schema routines must be idempotent.
- Keep the previous approved KPZ/checksum and database backup for rollback.
- Do not use blind schema downgrade or manual table deletion.

## Current v0.5.0 execution record — 2026-09-21

Candidate:

    PromotionEngagement-v0.5.0.kpz

SHA-256:

    931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670

Koha 25.11.02 isolated promoeng:

- build: PASS;
- ZIP integrity: PASS;
- 16 packaged Koha files: PASS;
- authenticated exact-KPZ upload/upgrade: PASS;
- version 0.5.0: PASS;
- seven tables: PASS;
- authenticated Dashboard/Promotions/Analytics/Reports/Configuration/Resource Impact browser matrix: PASS;
- native Suggestion synthetic workflow: PASS;
- synthetic cleanup: PASS;
- full automated suite: 5 files / 113 assertions PASS.

A historical clean-install exact-package PASS also exists for v0.4.0, and v0.3.0 had clean-install/upgrade/rollback rehearsal. The v0.5.0 exact package has passed authenticated installation/upgrade on the isolated primary runtime; a separate institutional staging gate remains required.

## Forward Koha gate

Koha 26.05 runtime validation is still blocked by host disk capacity. A 2026-09-21 image pull was stopped when Windows C: free space fell to about 11 GB before completion.

Do not retry until at least 20–25 GB safe C: free space is available. Do not perform global Docker pruning or delete unrelated project resources merely to force the test.

## Production gate

An exact package must not be declared production-ready solely because local KTD passes. Institutional staging, supported target-Koha validation, restorable backup/rollback ownership and explicit change authorization remain required.
