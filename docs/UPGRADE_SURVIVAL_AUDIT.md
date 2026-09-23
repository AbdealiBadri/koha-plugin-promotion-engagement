# Koha Upgrade Survival Audit

**Plugin candidate:** 0.5.0
**Audit date:** 2026-09-21
**Primary runtime:** Koha 25.11.02 KTD (promoeng)
**Forward target:** Koha 26.05.x

## Executive result

The plugin is architected to survive a normal Koha upgrade because it uses the Koha Plugins framework, keeps its operational data in seven namespaced plugin tables, reads catalogue/circulation data from Koha rather than duplicating it, and does not patch Koha core.

- Koha 25.11.02: **VERIFIED-RUNTIME / exact v0.5.0 KPZ PASS**.
- Koha 26.05.x: **VERIFIED-CODE / RUNTIME BLOCKED**. A fresh image pull was retried on 2026-09-21 but stopped when Windows C: free space fell from about 16 GB to about 11 GB before completion. No compatibility PASS is claimed.
- Institutional staging: **REQUIRED**.
- Production: **NOT AUTHORIZED by this development gate**.

An upgrade is never zero-risk. Koha APIs, permissions, templates and database schemas can change, so every target Koha line must run the exact candidate package through the matrix below.

## Exact v0.5.0 local evidence

Artifact: PromotionEngagement-v0.5.0.kpz

SHA-256:

931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670

On Koha 25.11.02:

- 113 automated assertions: PASS;
- plugin/Analytics/Resource Impact Perl syntax: PASS;
- schema idempotence: PASS;
- exact authenticated KPZ upload/upgrade: PASS;
- seven plugin tables after install: PASS;
- Dashboard/Promotions/Analytics/Reports/Configuration/Promoted Resource Impact browser render: PASS;
- native Koha ASKED Suggestion workflow: PASS;
- synthetic fixture cleanup: PASS.

## Module-by-module review

| Module | Koha dependency | Survival design | 25.11.02 | 26.05 action |
|---|---|---|---|---|
| Plugin shell | Koha::Plugins::Base | Standard Tool plugin metadata/hooks | PASS | Install/upgrade exact KPZ |
| Plugin schema | DBIx/Koha DB connection | Seven plugin_ajsn_promo_* tables; idempotent schema | PASS | Run upgrade twice; compare tables/counts |
| Campaign CRUD | items, branches, CSRF, plugin permissions | Live validation; transactional plugin-only writes | PASS | CRUD/security regression |
| Configuration | plugin vocabulary/settings tables | No institution-specific Koha core changes | PASS | Verify active/disabled/linked values |
| Multi-location | plugin relation table | Normalized links; soft removal; legacy fallback | PASS | Create/edit/archive regression |
| Analytics 1.1 | issues, old_issues, items, biblio | Shared half-open windows; live active periods; aggregate output | PASS | Schema + fixture totals + active-campaign tests |
| Promoted Resource Impact | items, biblio, holds, suggestions | Koha authoritative; audited librarian handoff | PASS | Verify hold/Suggestion model fields and permissions |
| Reports/exports | shared Analytics service | UI/CSV/JSON use one rule layer | PASS | Filter/export parity |
| REST API | Koha OpenAPI/auth | Authenticated/permission-gated routes | Prior PASS | 200/401/403 matrix |
| Templates/UI | Koha staff TT/includes | Koha-native markup; no core template patch | PASS | Render + accessibility/contrast review |
| Packaging | Koha plugin installer | Exact versioned KPZ; no production bind mount | PASS | Clean exact-package install/upgrade |

## Upgrade-sensitive watch points

1. Koha::Suggestion field names/validation, especially reason, patronreason, STATUS and branch handling.
2. Plugin permission names and plugins => tool authorization behavior.
3. OpenAPI plugin route registration and Plack reload behavior.
4. Template Toolkit includes, Bootstrap/staff-theme classes and contrast.
5. issues and old_issues columns: issue_id, itemnumber, borrowernumber, issuedate.
6. items/biblio relationships used for title-level analytics.
7. reserves/hold model and serviceable-copy interpretation.
8. CSRF token generation and Koha cud- request convention.
9. Koha library/item/biblio ORM changes.
10. Date/time behavior around active campaign as-of calculation.

## Required pre-upgrade capture

Before upgrading Koha:

1. Record Koha version, plugin version and exact KPZ checksum.
2. Back up the full Koha database, including every plugin_ajsn_promo_* table.
3. Capture campaign, linked-item, location-link and recommendation counts.
4. Capture a representative Campaign Analytics result and Comparative Report export.
5. Record a representative active campaign so live-to-date calculations can be compared after upgrade.
6. Clone production data into restricted staging.
7. Confirm rollback owner and maintenance window.

## Required staging matrix

1. Upgrade staging Koha using the institution-supported procedure.
2. Upload/upgrade the exact candidate KPZ.
3. Run plugin schema/install twice; both executions must succeed.
4. Confirm all seven plugin tables and preserved row counts.
5. Run Perl syntax, OpenAPI/JSON checks and the full automated suite.
6. Confirm active campaign without end date measures start→today.
7. Confirm future 7/14/30/60 windows render Pending rather than zero.
8. Confirm Promoted Titles and linked copies/items remain distinct.
9. Open Dashboard, Promotions, Campaign Detail, Analytics, Promoted Resource Impact, Reports and Configuration through a normal staff login.
10. Run authenticated/anonymous/under-permission REST checks.
11. Create/edit/archive one temporary campaign and confirm audit history.
12. Run one temporary Resource Impact approval and verify the native Koha Suggestion; remove only the temporary fixture.
13. Compare Analytics and export totals with the pre-upgrade baseline.
14. Review Koha/Plack logs for template, database, authorization and API errors.

## Rollback principles

- Never drop plugin tables as a routine rollback.
- Keep the previous working KPZ and checksum.
- Restore the database backup if an upgrade changed data incompatibly.
- Do not blindly downgrade plugin schema.
- Record any manual intervention.
- A failed forward-compatibility test must not modify the primary verified promoeng runtime.

## Compatibility policy

The project supports the verified Koha line (N) and treats the forward line (N+1) as unverified until the runtime matrix passes. Metadata must not imply support from code inspection alone.

## 26.05 runtime blocker — latest evidence

A dedicated 26.05 pull was retried on 2026-09-21 after approximately 16 GB Windows C: free space became available.

During koha/koha-testing:26.05 layer expansion:

- free space fell to approximately 12 GB;
- then approximately 11 GB before image completion;
- the pull was terminated deliberately;
- no completed 26.05 image appeared;
- no promoeng2605 container was created;
- primary promoeng remained untouched.

The earlier 12–15 GB safe-space estimate is therefore superseded.

**Do not retry until at least 20–25 GB of safe Windows C: free space is available.**

Do not perform global Docker pruning, delete unrelated volumes or remove unrelated project images merely to force this test through.

## Production decision

Proceed only after the target Koha runtime matrix and institutional staging both pass, the exact package checksum is recorded, the database backup is restorable, and the institution has explicitly authorized the change window and rollback ownership.
