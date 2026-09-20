# KPZ Packaging and Clean-Install Test Plan

This document defines the acceptance test for distributing Promotion & Engagement as a normal Koha plugin package rather than as a development bind mount.

## Goal

Prove that a user can obtain a versioned `.kpz` file, upload it through Koha Administration, and use the plugin without Git, Docker bind mounts, or manual source copying on the Koha server.

Koha calls these archives **Koha Plugin Zip (KPZ)** packages. The archive root must contain the `Koha/` namespace tree used by the plugin.

## Build

From the repository root on the release-candidate branch:

```bash
python3 scripts/build_kpz.py
```

Expected outputs:

```text
dist/PromotionEngagement-v0.3.0.kpz
dist/PromotionEngagement-v0.3.0.kpz.sha256
```

The builder packages only Git-tracked files under `Koha/` and verifies the required plugin module, templates, OpenAPI definition, and API controller are present.

Inspect the archive before testing:

```bash
python3 -m zipfile -l dist/PromotionEngagement-v0.3.0.kpz
cat dist/PromotionEngagement-v0.3.0.kpz.sha256
```

The listing must begin with paths under `Koha/Plugin/Com/AJSN/...`; there must be no repository wrapper directory, `.git`, `.env`, logs, editor files, or documentation-only source files.

## Clean-install environment

The acceptance test must use a clean Koha test instance that is **not** started with `--single-plugin` for this repository. The purpose is to exercise Koha's normal plugin upload and installation path.

Before uploading, confirm the Koha instance has:

- plugin support enabled;
- staff-interface plugin upload allowed for the test instance;
- a writable plugin directory;
- a staff user with permission to administer plugins.

## Installation acceptance test

1. Open **Koha Administration > Plugins**.
2. Click **Upload plugin**.
3. Select the versioned `.kpz` file.
4. Upload/install it.
5. Restart/refresh Plack if required by the test environment.
6. Confirm **Promotion & Engagement** is listed as version `0.3.0`, enabled, and exposes Run tool / Configure / Disable / Uninstall actions.

## Functional smoke test after KPZ install

The clean KPZ installation passes only when all of these succeed:

- Plugin loads without an ERRORS badge.
- Dashboard renders.
- Configure page renders.
- New Promotion foundation screen renders.
- Six plugin tables are created:
  - `plugin_ajsn_promo_campaigns`
  - `plugin_ajsn_promo_campaign_locations`
  - `plugin_ajsn_promo_items`
  - `plugin_ajsn_promo_audit`
  - `plugin_ajsn_promo_settings`
  - `plugin_ajsn_promo_vocab_values`
- Authenticated `GET /api/v1/contrib/ajsn_promotion/health` returns status `ok`, plugin name, and version `0.3.0`.
- The same endpoint fails authentication when requested without a valid Koha login/API authentication.
- Disable and re-enable preserve plugin data.

## Upgrade and uninstall safety

Uninstall remains intentionally non-destructive to plugin-owned historical tables. Upgrade testing must cover migration from the preceding approved version and run migrations repeatedly to confirm idempotence. An explicit data-purge path remains separately gated if one is introduced.

## Production gate

A KPZ must not be promoted to an AJSN production Koha instance until the exact built artifact has passed this clean-install test and its SHA-256 checksum has been recorded with the release.
## v0.3.0 execution record — 2026-09-20

- Clean Koha 25.11 project without `--single-plugin`: PASS.
- Authenticated Koha KPZ upload: PASS.
- Version 0.3.0 listing without ERRORS badge: PASS.
- Six plugin tables: PASS.
- Dashboard, Promotions, Analytics, Reports, Configuration and New Promotion rendering: PASS.
- Authenticated health HTTP 200 / anonymous health HTTP 401: PASS.
- Disable/re-enable data preservation: PASS.
- v0.2.0 to v0.3.0 upgrade preservation: PASS.
- Repeated migration idempotence: PASS.
- Koha database dump/delete/restore rollback: PASS.

Full evidence and remaining external gates are recorded in `docs/brain/V0.3_RELEASE_GATE_REPORT.md`.
