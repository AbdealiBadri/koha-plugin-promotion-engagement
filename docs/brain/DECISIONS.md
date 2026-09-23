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
## DEC-019 — Plugin-managed universal vocabularies with optional Koha sourcing

- **Date:** 2026-09-19
- **Status:** Accepted for v0.2 configuration/multi-location milestone
- **Context:** Campaign types, channels, languages, audiences, cadence and display locations must be reusable and configurable without hard-coding Nairobi values. Koha Authorized Values are useful for some libraries, but campaign locations can also be signage points, virtual placements or other promotion-specific concepts that are not Koha item locations.
- **Decision:** Use plugin-managed, namespaced vocabulary records as the canonical promotion-configuration layer. Values use dimension + stable code + human label, can be activated/deactivated and sorted, and remain independent of Koha core schema.
- **Integration direction:** Koha Authorized Values may later be imported/synchronized or referenced as an optional source, but the plugin must not require Koha core configuration changes for every promotion dimension.
- **Multi-location model:** one campaign links to many reusable configured location values through a namespaced junction table. Location links are soft-removable and auditable; the plugin validates that linked values belong to the location dimension.
- **Backward compatibility:** existing campaign fields remain during migration so existing v0.2 records continue to render. New configuration-backed workflows must not destructively rewrite historical rows.
- **Rejected alternative:** free text as the long-term source of truth for analytics dimensions.
- **Rejected alternative:** institution-specific locations or values hard-coded in source.

## DEC-020 — Analytics uses Koha issue history through one shared service

- **Date:** 2026-09-19
- **Status:** Accepted for v0.3 implementation
- **Context:** Campaign impact must remain reproducible across staff UI, reports and future APIs even when Koha `statistics` retention differs by installation.
- **Decision:** Use the union of Koha `issues` and `old_issues`, keyed by `issue_id` and dated by `issuedate`, as the canonical checkout-event source for v0.3. Renewals do not create additional conversion events.
- **Windows:** During uses inclusive campaign dates implemented as half-open datetimes; baseline is the immediately preceding equal-duration period; After windows are 7/14/30/60 calendar days.
- **Attribution:** per-campaign results may multi-attribute overlapping campaigns, while portfolio totals de-duplicate by `issue_id`.
- **Privacy:** core analytics are aggregate-only; cohorts below five distinct borrowers are suppressed; identifiable patron analytics require a later restricted design.
- **Consistency:** staff UI, reports and future APIs must call one shared analytics service.
- **Specification:** `docs/brain/ANALYTICS_SPEC.md`.

## DEC-021 — v0.3.0 management UI and report boundary

**Status:** Accepted
**Date:** 2026-09-20

The v0.3.0 release candidate uses a restrained academic visual system—navy, teal, warm gold, serif display headings and Koha-native responsive panels. Dashboard, Analytics and Reports remain server-rendered and accessible without an external frontend framework.

Comparative reports use the shared Analytics service and provide CSV/JSON exports. General staff views remain aggregate-only. Production deployment, identifiable patron ranking, recurrence, non-barcode resources and historical import are not silently absorbed into v0.3.0; they retain separate design and deployment gates.

## DEC-022 — Circulation evidence is not a direct visibility count

**Status:** Accepted
**Date:** 2026-09-20

Book-display effectiveness is presented through comparable Koha checkout behaviour and title-level response. Increased circulation supports a conclusion of improved discovery and borrowing engagement, but the plugin must not claim to count physical views without a separate approved observation mechanism such as anonymous QR interactions or manual footfall data.

The professional academic dashboard may interpret results in plain language, but every finding must remain traceable to baseline, during and follow-up checkout counts from the shared Analytics service. Future-dated and in-progress campaigns must be labelled awaiting or provisional rather than failed or final.

## DEC-023 — Book Display Impact uses native Koha Suggestions, not direct orders

**Status:** Accepted — 2026-09-20

Book Display Impact is part of the existing plugin. It may calculate and preserve
explainable recommendation evidence, but it must not create acquisition orders or
choose vendors/funds. After explicit librarian approval, an authorized user may
create a native Koha ASKED suggestion transactionally. Acquisitions staff retain
acceptance, vendor, fund, price, currency, basket and order authority.


## DEC-024 — Active campaigns are measured live-to-date

**Status:** Accepted — 2026-09-21

A started campaign with `status = active` must not require artificial completion merely to produce analytics.

- If `end_date` is blank, effective During end = current/as-of date.
- If configured end is in the future, effective During end = current/as-of date.
- If configured end is already in the past, the configured end remains authoritative and the service returns a warning that the campaign is still marked active.
- If the campaign has not started, During is Pending.
- Baseline duration always matches the resolved During duration.
- Future follow-up windows return Pending/null metrics, never zero.

This decision supersedes the v0.3 fallback that treated a missing `end_date` as the `start_date`.

## DEC-025 — Management analytics are title-engagement first

**Status:** Accepted — 2026-09-21

The primary management question is not merely how many resources staff promoted; it is whether the promoted collection was actually used and whether use changed relative to a comparable baseline.

Therefore the headline KPI hierarchy is:

1. Promoted Titles;
2. Titles Used;
3. Title Utilization;
4. Campaign Checkouts;
5. Baseline / circulation-rate change;
6. Increased-use / Zero-response / Repeat-demand signals;
7. collection-development workflow signals such as holds, approval and Sent to Koha.

Title metrics use distinct Koha `biblionumber` values. Copy/item metrics continue to use `itemnumber`. Multiple promoted copies must not inflate title-utilization breadth.

The staff-facing Book Display Impact page is generalized to **Promoted Resource Impact** so physical, email, recommendation and digital campaigns can use the same engagement evidence. The existing `book_display_impact` internal route and native Koha Suggestion reason `Book Display Impact` remain stable for backward compatibility and audit continuity.

This decision does not weaken DEC-022: circulation response is evidence of engagement, not proof that a promotion caused every checkout.
