# Koha Upgrade Survival Audit

**Plugin candidate:** 0.4.1  
**Audit date:** 2026-09-21  
**Primary runtime:** Koha 25.11.02 KTD (`promoeng`)  
**Forward target:** Koha 26.05.x

## Executive result

The plugin is designed to survive a normal Koha upgrade because it uses the
Koha Plugins framework, keeps its own data in seven namespaced tables, reads
catalogue/circulation data through Koha-supported models or stable tables, and
does not patch Koha core.

- Koha 25.11.02: **VERIFIED-RUNTIME**.
- Koha 26.05.x: **VERIFIED-CODE / RUNTIME BLOCKED**. The image pull was stopped
  when Windows C: free space fell below 1 GB. No compatibility PASS is claimed.
- Institutional staging: **REQUIRED** before production.
- Production: **NOT AUTHORIZED**.

An upgrade is not zero-risk. Koha APIs, permissions, templates and database
schemas can change, so the exact KPZ must be re-tested on every target Koha
release.

## Module-by-module review

| Module | Koha dependency | Survival design | 25.11 | 26.05 action |
|---|---|---|---|---|
| Plugin shell | `Koha::Plugins::Base` | Standard Tool plugin metadata and hooks | Runtime PASS | Install/upgrade exact KPZ |
| Plugin schema | DBIx connection | Seven `plugin_ajsn_promo_*` tables; idempotent `_ensure_schema` | Runtime PASS | Run upgrade twice and compare |
| Campaign CRUD | Items, libraries, CSRF | Live validation; transactional plugin writes | Runtime PASS | Full CRUD/security regression |
| Configuration | Plugin tables | No institution-specific core changes | Runtime PASS | Verify disabled/linked values |
| Multi-location | Plugin relation table | Normalized links and legacy fallback | Runtime PASS | Create/edit/archive regression |
| Analytics | `issues`, `old_issues` | Shared half-open windows; aggregate output | Runtime PASS | Compare schema and fixture totals |
| Book Display Impact | Items, holds, suggestions | Koha remains authoritative; audited handoff | Runtime PASS | Verify Suggestion fields/permissions |
| Reports/exports | Shared Analytics service | UI, CSV and JSON use one calculation layer | Runtime PASS | Filter/export parity regression |
| REST API | Koha OpenAPI/auth | Authenticated, permission-gated routes | Runtime PASS | 200/401/403 matrix |
| Templates/UI | Koha staff TT/includes | Koha-native markup; no core template patches | Runtime PASS | Render/visual accessibility check |
| Packaging | Koha plugin installer | Versioned KPZ; no production-side source mount | Runtime PASS | Clean exact-KPZ installation |

## Upgrade-sensitive watch points

1. `Koha::Suggestion` field names and validation, especially `reason`,
   `patronreason`, status and branch handling.
2. Plugin permission names and the `plugins => tool` authorization path.
3. Koha plugin OpenAPI route registration and Plack reload behavior.
4. Template Toolkit includes, Bootstrap classes and staff-theme contrast.
5. `issues` and `old_issues` checkout-date/item columns used by Analytics.
6. CSRF token generation and Koha's `cud-` request convention.
7. Koha item, biblio, hold and library ORM relationships.
## Required upgrade procedure

### Before upgrading Koha

1. Record Koha version, plugin version and KPZ checksum.
2. Back up the complete Koha database, including all
   `plugin_ajsn_promo_*` tables.
3. Export a campaign/report baseline: campaign count, linked-item count,
   location-link count, recommendation count and a sample Analytics JSON.
4. Clone production data into a restricted staging environment.
5. Confirm rollback ownership and the maintenance window.

### In staging

1. Upgrade Koha using the institution's supported Koha procedure.
2. Install or upgrade the exact candidate KPZ.
3. Run the plugin installation/upgrade routine twice; both runs must succeed.
4. Confirm all seven plugin tables exist and row counts match the baseline.
5. Run Perl syntax, YAML/OpenAPI checks and the complete automated suite.
6. Test Dashboard, Promotions, Configuration, Analytics, Book Display Impact
   and Reports through a normal staff login.
7. Run authenticated/anonymous/under-permission REST checks.
8. Create, edit and archive a temporary campaign; confirm audit rows.
9. Create a temporary approved Book Display Impact recommendation and confirm
   the native Koha Purchase Suggestion; remove only the temporary fixture.
10. Compare Analytics and export totals with the pre-upgrade baseline.
11. Review logs for template, database, authorization and Plack errors.

### Production decision

Proceed only if staging passes, backups are restorable, the exact KPZ checksum
is recorded, and a rollback owner approves the window. Otherwise restore the
previous Koha/plugin combination in staging, diagnose, and do not promote.

## Rollback principles

- Never drop plugin tables as a routine rollback.
- Restore the database backup if an upgrade changed data incompatibly.
- Keep the previous KPZ and checksum available.
- Do not downgrade schema blindly; use a tested restoration procedure.
- Record every manual adjustment in the deployment log.

## Compatibility policy

The project supports the current verified Koha line (N) and treats the next
target line (N+1) as unsupported until its runtime matrix passes. Do not add a
maximum Koha version merely to imply testing. Update metadata only from actual
evidence.

## Current blocker and safe resolution

The 26.05 image pull expanded the WSL virtual disk and reduced Windows C: free
space to about 0.6 GB. The pull was cancelled and WSL was safely terminated;
free space recovered to about 4.9 GB. Unsafe sparse-VHD forcing and global
Docker pruning were deliberately rejected.

To complete 26.05 validation, first provide at least 12–15 GB of safe free
space, then create a dedicated disposable KTD project without modifying
`promoeng`. Run the matrix above, record exact results, and remove only that
project's containers/volumes after evidence is preserved.
