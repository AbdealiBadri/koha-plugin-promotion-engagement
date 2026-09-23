# Changelog

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
