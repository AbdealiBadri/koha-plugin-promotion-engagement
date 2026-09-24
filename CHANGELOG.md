# Changelog

## [0.6.1] - 2026-09-24

### Fixed
- Scheduled/future campaigns no longer distort measured portfolio title-utilization and zero-response KPIs.
- Recommendation decision/audit and native Koha Suggestion submission are concurrency-safe and transactional.
- CSV exports neutralize spreadsheet formulas.
- Campaign/report dates use real calendar validation.
- Open active campaigns overlap report date filters through today, matching Analytics semantics.
- Historical language/audience values remain editable without silent rewriting; forged new values are rejected.
- Analytics and Resource Impact campaign selectors are no longer silently capped at 200 campaigns.
- KPI table highlighting works across all filtered DataTable pages.
- Decimal hold-ratio copy recommendations use mathematical ceiling correctly.
- Comparative report circulation queries reuse request-local evidence.
- Temporary debug logging removed.
- KPZ smoke waits for Plack readiness after upgrade.

### Verified
- **7 files / 213 assertions PASS** on Koha 25.11.02.
- 50 dedicated bug-audit assertions PASS.
- Schema idempotence PASS.
- Exact authenticated v0.6.1 KPZ upgrade PASS with seven plugin tables and observed row counts preserved.
- Nine-page authenticated browser matrix PASS.
- Server render and native Koha Suggestion workflow smoke PASS.
- SHA-256: `da4a68cb125bb22ee9806718561eafb4d368495f40e5063cc2fd3a406a117afc`.

## [0.6.0] - 2026-09-23

### Added
- Searchable campaign and reusable-vocabulary selectors, including multi-campaign comparison where appropriate.
- Shared sortable/filterable/export-capable Koha table behavior.
- KPI drill-downs from issued/borrowed, increased-issue and zero-response cards into supporting tables.
- Resource Impact green/highest-issue and red/zero-response cues with an explanatory legend.
- Campaign Analytics and Comparative Reports chart views with data labels, table toggles and JPEG download.
- Page-specific beginner-friendly **How to Use** guidance across the main workflow and detailed Configuration guidance.
- Dedicated v0.6 usability/visualization regression coverage.

### Changed
- User-facing “Titles Used” is now **Titles Issued / Borrowed**.
- User-facing “Increased-Use Titles” is now **Titles with Increased Issues**.
- Dashboard evidence-cycle explanations are simplified while academic headings remain.
- Collection-development signals receive clearer visual hierarchy without changing acquisition authority.
- Exact-KPZ upgrade smoke now verifies plugin table row counts remain unchanged.

### Verified
- Full suite: **6 files / 163 assertions PASS** on Koha 25.11.02.
- Schema idempotence PASS.
- Exact v0.6.0 KPZ authenticated upload/upgrade PASS with all seven plugin-table row counts preserved.
- Authenticated browser rendering PASS for Dashboard, Promotions, Analytics, Reports, Configuration, Resource Impact, Campaign Detail, Edit Promotion and New Promotion.
- Synthetic approve → native Koha ASKED Suggestion workflow PASS.
- Exact tested KPZ SHA-256: `6ca98215bcce431f7877633e3af45aa0aff8024e87c4411bd55769862c25ed28`.

## [0.5.0] - 2026-09-21

### Added
- Live-to-date analytics for started active campaigns without requiring artificial completion.
- Explicit Pending / To date / Complete states for During and follow-up windows.
- Distinct promoted-title metrics alongside promoted copy/item metrics.
- Titles Used, Title Utilization, Increased-use, Zero-response and Repeat-demand title signals.
- Portfolio promoted-title/item/use/baseline/campaign-checkout de-duplication.
- Engagement-first KPI summaries on Dashboard, Promotions, Campaign Detail, Campaign Analytics and Reports.
- Generalized **Promoted Resource Impact** staff UI with engagement evidence before collection-development workflow counters.
- 30 dedicated v0.5 analytics-intelligence assertions.

### Changed
- Campaign Analytics now leads with title reach/use/utilization and baseline comparison rather than secondary timing indicators.
- Future follow-up periods display Pending rather than misleading zero values.
- Multiple promoted copies of one bibliographic record are combined for title-utilization breadth.
- Comparative Reports now include title use, utilization, baseline/campaign checkouts, change, zero-response and increased-title counts.
- Workflow smoke uses an isolated temporary campaign and preserves retained campaign 40 evidence.

### Verified
- Full suite: 5 files / 113 assertions PASS on Koha 25.11.02.
- Exact v0.5.0 KPZ authenticated upload/upgrade PASS.
- Dashboard, Promotions, Analytics, Reports, Configuration and Promoted Resource Impact authenticated render PASS.
- Native Koha ASKED Suggestion workflow and synthetic cleanup PASS.
- Exact tested KPZ SHA-256: `931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670`.
- Koha 26.05 runtime validation remains blocked by host disk capacity; no PASS claimed.

## [0.4.1] - 2026-09-21

### Changed
- Polished all staff screens with consistent professional Koha-native navigation, buttons, tables, focus states and contrast.
- Added all-campaign Analytics comparison and clearer campaign selectors.
- Added Reports campaign/status/date filters, retained export filters and explicit single-location evidence.
- Added Dashboard display-location intelligence without falsely attributing multi-location campaigns.
- Standardized native Koha Purchase Suggestion reason as `Book Display Impact`.
- Added upgrade-survival audit and repeatable staging/rollback procedure.

### Fixed
- Isolated Book Display Impact tests from pre-existing real recommendations.
- Kept multi-location campaigns out of misleading “best location” calculations.

## [0.4.0] - 2026-09-20

### Added
- Book Display Impact module inside the existing plugin.
- Biblio-level circulation, copy availability, holds and evidence grading.
- Audited approval/rejection with evidence snapshot.
- Transactional handoff to native Koha Purchase Suggestions.
- Beginner installation, user, KohaCon26 video/demo and public-release documentation.
- 17 dedicated assertions plus authenticated browser and end-to-end workflow smokes.


## 0.1.0 - 2026-08-15
- Initial Koha Tool Plugin scaffold.
- Added plugin-owned campaign, item, audit and settings tables.
- Added non-destructive uninstall policy.
- Added dashboard and read-only promotion form mockup.
- Reserved authenticated REST API namespace with health endpoint.
