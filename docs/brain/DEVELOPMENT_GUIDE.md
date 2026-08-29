# Development Guide

## Prerequisites

- Git.
- Windows + WSL Debian (current verified setup) or equivalent Linux environment.
- Docker.
- Koha Testing Docker (KTD).
- Python 3 for KPZ build helper.
- Access to the private GitHub repository.

## Repositories

Plugin:

```text
AbdealiBadri/koha-plugin-promotion-engagement
```

KTD local path used:

```text
~/git/koha-testing-docker
```

Plugin local path convention:

```text
$PLUGINS_DIR/koha-plugin-promotion-engagement
```

## Branch strategy — current evidence

Repository branches include:

- `main` — default branch;
- `develop` — foundation/package work;
- `feature/v0.2-campaign-crud` — current v0.2 feature branch.

Before work:

```bash
cd "$PLUGINS_DIR/koha-plugin-promotion-engagement"
git status
git branch --show-current
git log -5 --oneline
```

As last verified, v0.2 branch tip before Project Brain work is `3537b8e`.

## First read

Before changing code, follow root `AGENTS.md` and read Project Brain current state/handoff/issues/testing.

## Update local branch

```bash
git fetch origin
git switch feature/v0.2-campaign-crud
git pull --ff-only origin feature/v0.2-campaign-crud
```

If GitHub fails, test network separately from code:

```bash
getent hosts github.com
curl -I https://github.com
```

If Windows reaches GitHub but WSL does not, repair WSL networking before altering repository/plugin configuration.

## Start KTD for feature development

```bash
cd ~/git/koha-testing-docker
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" up -d
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --wait-ready 180
```

Use `ktd --list` to inspect instances.

Only after `KTD READY`:

```bash
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --shell
```

Inside app container when plugin changes need reinitialization:

```bash
cd /kohadevbox/koha
./misc/devel/install_plugins.pl
sudo koha-plack --restart kohadev
```

## Current KTD warning

Do not solve ordinary startup problems by removing only `kohadev-koha-1` while retaining an initialized `kohadev-db-1`. This produced the current `Database is not empty!` initialization failure. See `ISSUES.md` ISSUE-004.

When a clean reset is genuinely required, back up any plugin test tables that matter, then use a consistent KTD lifecycle.

## Verify plugin version

Source:

```bash
grep -n "our \$VERSION" "$PLUGINS_DIR/koha-plugin-promotion-engagement/Koha/Plugin/Com/AJSN/PromotionEngagement.pm"
```

UI: Koha Administration > Plugins should show the same version.

API after runtime is healthy:

```text
/api/v1/contrib/ajsn_promotion/health
```

The version in source, UI and health endpoint must agree.

## Database inspection

Use the KTD database container and credentials from local KTD configuration. Never commit the password.

Useful SQL:

```sql
SHOW TABLES LIKE 'plugin_ajsn_promo_%';
SHOW COLUMNS FROM plugin_ajsn_promo_campaigns LIKE 'channel';

SELECT campaign_id, campaign_type, channel, name, status, created_by, created_at
FROM plugin_ajsn_promo_campaigns
ORDER BY campaign_id DESC
LIMIT 10;

SELECT campaign_item_id, campaign_id, itemnumber, barcode, added_by, added_at
FROM plugin_ajsn_promo_items
ORDER BY campaign_item_id DESC
LIMIT 20;

SELECT audit_id, campaign_id, actor_borrowernumber, action_type, entity_type, entity_id, created_at
FROM plugin_ajsn_promo_audit
ORDER BY audit_id DESC
LIMIT 20;
```

## v0.2 manual campaign regression

Use a known-good live Koha barcode obtained directly from Koha/DB, not transcribed from memory.

1. Save a campaign with zero barcodes.
2. Save with one valid barcode.
3. Submit fake barcode; confirm campaign not saved.
4. Submit valid barcode twice; confirm one link + duplicate warning.
5. Submit one valid + one invalid; confirm complete rollback.
6. Verify DB campaign/item/audit rows.
7. Verify dashboard counts.
8. Verify authenticated/unauthenticated health endpoint.
9. Perform dedicated CSRF and lower-permission tests before checkpoint closure.

## Build KPZ

From plugin root:

```bash
python3 scripts/build_kpz.py
ls -lh dist/
python3 -m zipfile -l dist/PromotionEngagement-vX.Y.Z.kpz
```

Do not assume the historical v0.1 KPZ test proves a new version. Every release artifact needs its own clean-install test/checksum.

## Source structure

```text
Koha/Plugin/Com/AJSN/PromotionEngagement.pm          core plugin/business flow/schema
Koha/Plugin/Com/AJSN/PromotionEngagement/*.tt        staff UI templates
Koha/Plugin/Com/AJSN/PromotionEngagement/openapi.json REST route definition
Koha/Plugin/Com/AJSN/PromotionEngagement/API/         API controllers
scripts/build_kpz.py                                  release packaging helper
docs/                                                 original project docs/test plans
docs/brain/                                           persistent engineering memory
.project-memory/                                      machine-readable memory
```

## Coding constraints

- No Koha core modifications.
- Idempotent/versioned schema evolution.
- Prefer Koha APIs/ORM for Koha-owned entities.
- Keep campaign/item/audit writes transactional.
- Do not hard-code institution-specific vocabulary.
- Keep external API/UI analytics rules shared.
- Escape staff UI output and preserve Koha CSRF/permission patterns.
- No secrets in code/tests/docs.

## Troubleshooting order

1. Check current branch/status/version.
2. Check KTD containers (`docker ps -a`).
3. Read container/Koha Plack logs.
4. Check plugin discovery/config only if loader reports plugin errors.
5. Check database schema/data when persistence is in question.
6. Check host vs WSL networking when Git/web access fails.
7. Do not blame browser cache for server-side module/template/database errors.

## End-of-session procedure

Run relevant tests and update Project Brain per `AGENTS.md`, especially `CURRENT_STATE.md`, `SESSION_HANDOFF.md`, `ISSUES.md`, `TESTING.md` and YAML state.