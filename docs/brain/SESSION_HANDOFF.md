# Session Handoff

**Last updated:** 2026-08-29  
**Current implementation branch:** `feature/v0.2-campaign-crud`  
**Last verified implementation commit:** `3537b8e`  
**Current milestone:** v0.2 Checkpoint 1 — campaign creation integrity/security

## Current objective

Restore the `kohadev` KTD environment, verify the health endpoint now reports plugin version 0.2.0, then finish the remaining security/permission checks and close checkpoint 1.

## Work completed most recently

- v0.2 campaign creation workflow manually tested successfully.
- Valid barcode linking, invalid-barcode blocking, duplicate de-duplication, audit write and mixed valid/invalid rollback all passed.
- Dashboard remained 3 promotions / 2 linked items after rollback test.
- API stale-version cause identified and fixed in GitHub commit `3537b8e`.
- WSL GitHub connectivity recovered and commit `3537b8e` successfully pulled locally.
- KTD app-container failure diagnosed from full logs.
- Project Brain created from repository evidence and project history.

## Files/components changed most recently

Implementation:

- `Koha/Plugin/Com/AJSN/PromotionEngagement/API/Health.pm` — now reads plugin `$VERSION`.

Project memory:

- root `AGENTS.md`
- `docs/brain/*`
- `.project-memory/*`

## Tests actually performed

Passed:

- campaign with no barcode;
- one valid barcode;
- fake invalid barcode blocked;
- duplicate correct barcode linked once + warning;
- DB campaign/item/audit verification;
- mixed valid + invalid submission rolled back completely;
- WSL GitHub HTTPS recovered after network restart.

Diagnostic:

- `docker inspect kohadev-koha-1` -> ExitCode 11, OOMKilled false.
- `docker logs --tail 250 kohadev-koha-1` -> final fatal condition `Database is not empty! ... do_all_you_can_do.pl line 89`.

## What passed

The v0.2 campaign write/integrity behaviour tested so far is sound. The barcode issue encountered during duplicate testing was a manual typo (`3999900002034` vs live `39999000002034`), not plugin validation failure.

## What failed

`kohadev-koha-1` cannot currently reach ready state after it was recreated while the existing populated DB container remained.

## Known issues

- ISSUE-004: KTD non-empty DB initialization blocker — current blocker.
- BUG-003: health version code fixed but runtime 0.2.0 response not yet re-verified.
- ISSUE-012: dedicated CSRF and lower-permission tests still pending.
- Configuration/multi-location/analytics are intentionally not complete.

## Important decisions that must not be reversed

- Koha remains source of truth.
- No Koha core patch/schema extension for plugin features.
- Invalid barcode means whole campaign submission is rejected.
- Duplicate campaign-item links are prohibited.
- Uninstall is non-destructive by default.
- Nairobi workflows are acceptance examples, not hard-coded defaults.
- UI modernization waits until core workflows/analytics stabilize.
- Patron-identifiable analytics require restricted access/privacy design.

## Current blocker

Fresh/recreated KTD app container is attempting first-time setup against retained initialized `kohadev-db-1`; initialization aborts because the DB is not empty.

## Exact next action

1. Decide whether the existing local checkpoint DB rows need to be retained. The important test evidence is already recorded in `TESTING.md` and `CURRENT_STATE.md`.
2. If retaining them, dump the four `plugin_ajsn_promo_*` tables using the local KTD DB credential **without committing the credential**.
3. Perform a consistent full `kohadev` KTD teardown/recreate rather than deleting only the app container.
4. Start with the v0.2 single-plugin mount and wait for readiness.

Commands after any desired backup:

```bash
cd ~/git/koha-testing-docker
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" down
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" up -d
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --wait-ready 180
```

Do not proceed to plugin tests until the last command reports readiness.

Once ready:

```bash
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --shell
```

Inside:

```bash
cd /kohadevbox/koha
./misc/devel/install_plugins.pl
sudo koha-plack --restart kohadev
exit
```

Then verify source/UI/API versions agree.

## What success should look like

- `kohadev` remains up and KTD reports ready.
- Koha Administration > Plugins shows Promotion & Engagement v0.2.0 enabled.
- authenticated `/api/v1/contrib/ajsn_promotion/health` returns status `ok`, plugin name and version `0.2.0`.
- unauthenticated request returns authentication/authorization failure.
- campaign checkpoint smoke tests still pass after clean environment recovery.

## If it fails, investigate

1. `docker ps -a --filter name=kohadev`
2. `docker inspect kohadev-koha-1 --format 'ExitCode={{.State.ExitCode}} OOMKilled={{.State.OOMKilled}} Error={{.State.Error}}'`
3. `docker logs --tail 250 kohadev-koha-1`
4. If plugin loader error: inspect `enable_plugins`, `pluginsdir`, plugin mount and Koha plugin logs.
5. If template error: inspect the named `.tt` file/filter before touching DB.
6. If Git/network error: compare Windows vs WSL HTTPS connectivity.
7. Do not repeat app-container-only recreation over a retained populated KTD DB as a generic fix.