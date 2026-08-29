# Deployment and Environment Guide

## Release status

**No production deployment is currently verified.** The plugin is pre-alpha/development only.

## Target lifecycle

`source -> static checks -> KTD 25.11 -> KTD 26.05 -> AJSN staging -> exact versioned KPZ + checksum -> production`

Skipping a gate requires an explicit new decision; do not infer approval from a successful local test.

## Local development environment

Verified working model:

- Windows workstation.
- WSL Debian shell.
- Docker.
- `koha-testing-docker` repository under `~/git/koha-testing-docker`.
- plugin repository under `$PLUGINS_DIR/koha-plugin-promotion-engagement`.
- main KTD instance: `kohadev`.
- Koha image selector used: `KOHA_IMAGE=25.11`.
- staff URL observed: `kohadev-intra.localhost`.

Typical feature-development startup:

```bash
cd ~/git/koha-testing-docker
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" up -d
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --wait-ready 180
```

Enter the application container only after readiness:

```bash
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --shell
```

Inside a healthy KTD app container, plugin reinitialization used during development:

```bash
cd /kohadevbox/koha
./misc/devel/install_plugins.pl
sudo koha-plack --restart kohadev
```

Do not treat these development bind-mount commands as a production deployment procedure.

## Current KTD blocker

As of 2026-08-29, `kohadev-koha-1` exits with code 11 because only the app container was recreated while the retained DB was already populated. Log terminal line:

`Database is not empty! at /kohadevbox/misc4dev/do_all_you_can_do.pl line 89.`

Recovery principle:

1. Preserve any test data that matters.
2. Tear down/recreate the KTD environment consistently instead of mixing fresh app initialization with a retained initialized DB.
3. Reach `KTD READY` before re-running plugin tests.

### Backup before destructive local KTD reset

If checkpoint rows must be preserved, dump only the four plugin tables first using the local KTD database credentials from the local environment/configuration. Do **not** write the password into scripts or Project Brain.

Conceptual command pattern:

```bash
docker exec <db-container> mariadb-dump -u <local-kohadev-user> -p'<LOCAL_KTD_PASSWORD>' <kohadev-db> \
  plugin_ajsn_promo_campaigns plugin_ajsn_promo_items \
  plugin_ajsn_promo_audit plugin_ajsn_promo_settings \
  > ~/kohadev_promo_backup.sql
```

`<LOCAL_KTD_PASSWORD>` is a placeholder and must never be committed.

## Clean KPZ package testing

Feature bind-mount testing and package acceptance are separate.

Historical procedure:

1. Build KPZ from repository root:
   ```bash
   python3 scripts/build_kpz.py
   ```
2. Inspect archive and checksum.
3. Start a clean KTD instance **without** `--single-plugin` for this plugin.
4. Confirm no plugin is preinstalled.
5. Upload the exact `.kpz` via **Koha Administration > Plugins > Upload plugin**.
6. Verify plugin enabled/version/actions/screens/tables/API.
7. Verify unauthenticated API denial.
8. Verify disable/re-enable persistence.

Historical `kpztest` fulfilled this for v0.1.0. That does not count as a v0.2 package release test.

## KPZ artifact rules

- Archive root must be `Koha/` namespace tree.
- No `.git`, `.env`, logs, editor files, repository wrapper or unrelated docs in package.
- Record SHA-256 for exact release artifact.
- Production must install the exact artifact that passed staging/acceptance; rebuilding after acceptance creates a different artifact and requires re-validation.

## Staging

**Status:** NOT RUN / not verified.

Before staging:

- v0.2 functional/security checkpoint closed;
- clean KPZ test passed for the intended version;
- schema upgrade behavior tested;
- backup/restore procedure rehearsed;
- Koha 25.11 and forward 26.05 compatibility gates addressed as required;
- least-privilege roles defined.

## Production

**Initial target:** Aljamea-tus-Saifiyah Nairobi.

**Status:** NOT DEPLOYED / NOT APPROVED.

Required before production:

- database backup;
- plugin-table backup;
- current plugin KPZ and checksum retained;
- relevant Koha/plugin configuration backup;
- staging sign-off;
- rollback plan;
- exact artifact install;
- post-install smoke and health checks;
- monitoring/log review.

## Rollback

Current verified safety mechanism: plugin can be disabled and historical tables are not intentionally dropped. A complete production rollback procedure is still `NEEDS VERIFICATION` and must include version-specific schema compatibility, previous KPZ artifact and restore rules.

## Network note

WSL temporarily experienced GitHub HTTPS routing failure while Windows networking was healthy. It was resolved by refreshing WSL networking. Do not modify plugin code in response to host/WSL connectivity failures.

## Secrets

Never commit database passwords, Koha admin credentials, API tokens, OAuth secrets, private keys or session cookies. Use local secure configuration/environment mechanisms.