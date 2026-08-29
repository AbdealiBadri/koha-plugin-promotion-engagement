# Engineering Decision Log

This log preserves both current decisions and important superseded/rejected approaches. Do not delete old records when direction changes; add a superseding record.

## DEC-001 — Koha remains the library source of truth

- **Period:** project foundation, August 2026
- **Status:** Accepted
- **Context:** Promotion analytics needs catalogue, item, patron, branch and circulation data.
- **Decision:** Read these domains from Koha. Store only promotion-specific operational data in plugin-owned structures.
- **Rationale:** Prevent data divergence and preserve Koha's authority.
- **Alternatives:** Copy Koha records/transactions into a separate plugin data warehouse as operational truth.
- **Consequences:** Analytics must join/read Koha data; external apps should use shared plugin business rules rather than independent calculations.
- **Affected:** all modules.

## DEC-002 — No Koha core patches or plugin columns in core tables

- **Period:** foundation
- **Status:** Accepted
- **Decision:** Implement as a normal Koha plugin using namespaced tables and plugin hooks/routes only.
- **Rationale:** Upgrade safety, portability, maintainability and clean removal.
- **Rejected alternative:** patch Koha source or extend core tables for campaign fields.

## DEC-003 — Non-destructive uninstall

- **Period:** v0.1
- **Status:** Accepted
- **Decision:** Uninstall must not silently drop historical campaign tables. Any future purge must be explicit and separately confirmed.
- **Consequence:** Current `uninstall` returns success without dropping plugin tables.

## DEC-004 — Universal configuration, Nairobi workflows as acceptance examples

- **Period:** August 2026 real-world workflow review
- **Status:** Accepted
- **Context:** Nairobi runs specific displays, emails, signage and featured-resource activities.
- **Decision:** These workflows define expressive requirements but must not ship as institution-specific hard-coded defaults.
- **Rationale:** The plugin should work for other campuses/libraries.
- **Rejected alternative:** hard-code seven Nairobi locations, current campaign names, languages or staff.

## DEC-005 — Campaign save is all-or-nothing

- **Period:** v0.2 checkpoint 1
- **Status:** Accepted
- **Decision:** Validate all unique barcodes first. Any invalid barcode blocks the entire save. Campaign, item links and audit row are written in a single transaction.
- **Rationale:** Prevent misleading partial campaigns and orphaned records.
- **Consequence:** Mixed valid+invalid submissions intentionally save nothing.

## DEC-006 — Duplicate item links are prohibited within one campaign

- **Period:** v0.2
- **Status:** Accepted
- **Decision:** De-duplicate submitted barcodes and enforce unique `(campaign_id,itemnumber)` at DB level.
- **Rationale:** Accurate campaign/item counts and analytics.

## DEC-007 — Use Koha-native CSRF and permission mechanisms

- **Period:** v0.2
- **Status:** Accepted
- **Decision:** Staff writes follow Koha `cud-` operation + generated CSRF token convention; plugin tool access stays under Koha plugin permissions.
- **Rationale:** Avoid inventing a parallel security framework.

## DEC-008 — Distribution through versioned KPZ artifacts

- **Period:** v0.1 packaging
- **Status:** Accepted
- **Decision:** Production/staging installations should use an exact versioned Koha Plugin Zip with recorded checksum, not a development Git bind mount.
- **Rationale:** Reproducible release artifact and normal Koha administration workflow.
- **Consequence:** `--single-plugin` is for local feature development; clean KPZ acceptance uses a separate clean instance.

## DEC-009 — Use `kohadev` for normal feature checkpoint testing; disposable instance for KPZ test

- **Period:** v0.2 checkpoint plan
- **Status:** Accepted
- **Decision:** Continue feature development/test on existing `kohadev`; use a clean instance such as historical `kpztest` only to prove normal KPZ upload/install.
- **Rejected for checkpoint:** performing all feature work in disposable KPZ environment.

## DEC-010 — Defer modern UI redesign until core workflow is stable

- **Period:** after first working dashboard
- **Status:** Accepted
- **Context:** Current Koha-native screen is visually basic.
- **Decision:** Prioritize correctness, data model, validation, permissions and tests; modern/professional dashboard comes later.
- **Consequence:** Do not treat current styling as final design, but do not derail core milestone for cosmetic refactoring.

## DEC-011 — One campaign must eventually support multiple reusable locations

- **Period:** real-world workflow discussion
- **Status:** Accepted requirement; implementation pending
- **Context:** A subject/new-arrival campaign can be displayed at multiple physical points simultaneously.
- **Decision:** Future model must support one campaign to many locations and location-level analytics.
- **Current gap:** v0.2 stores one free-text `display_location`.
- **Open alternative:** Koha authorized values vs plugin-managed location vocabulary vs hybrid/free-text fallback.

## DEC-012 — Analytics compares campaign periods with circulation baselines

- **Period:** analytics requirements discussion
- **Status:** Accepted direction
- **Decision:** Derive circulation before/during/after campaign and configurable 7/14/30/60-day windows using Koha history.
- **Rationale:** Measure uplift rather than raw campaign counts.
- **Open question:** exact baseline/normalization methodology.

## DEC-013 — Patron/class benefit analytics are restricted staff analytics

- **Period:** analytics requirements discussion
- **Status:** Accepted with privacy constraint
- **Decision:** Top user/student and top Darajah/class/group/category analytics may be useful, but identifiable patron data must not be exposed to general/external dashboards without approved privacy controls.

## DEC-014 — Future external API must reuse the same business rules

- **Period:** architecture foundation
- **Status:** Accepted
- **Decision:** Staff UI, reports and external AJS applications should consume one shared analytics/service rule set.
- **Rationale:** Prevent KPI disagreement across interfaces.

## DEC-015 — Resource model must grow beyond physical barcodes

- **Period:** real-world use cases
- **Status:** Accepted requirement
- **Context:** E-resource of the month, author features and other campaigns may have no physical item barcode.
- **Decision:** Do not require barcodes for every campaign. Introduce an extensible promoted-resource model later.
- **Current support:** zero-barcode campaign can already save; dedicated non-item resource linking is not built.

## DEC-016 — Health endpoint version has one authoritative source

- **Date:** 2026-08-18
- **Status:** Accepted, code implemented; runtime re-verification pending
- **Context:** API returned hard-coded `0.1.0` while plugin UI/source had moved to `0.2.0`.
- **Decision:** `API/Health.pm` reads `PromotionEngagement::$VERSION`.
- **Supersedes:** duplicated hard-coded health version.
- **Commit:** `3537b8e`.

## DEC-017 — Production compatibility gate

- **Period:** foundation/release planning
- **Status:** Accepted
- **Decision:** Production requires successful validation on current supported Koha 25.11.x, forward target 26.05.x, AJSN staging, backups/rollback, and the exact versioned KPZ artifact.
- **Current state:** only 25.11 development/partial release testing has occurred.

## DEC-018 — Current source overrides old planned `events` table

- **Date:** Project Brain reconciliation, 2026-08-29
- **Status:** Accepted reconciliation
- **Context:** an early architecture artifact referenced an events table; current source creates campaigns/items/audit/settings.
- **Decision:** Treat four current source-defined tables as the present schema. Any future event/occurrence table requires an explicit new decision and migration.