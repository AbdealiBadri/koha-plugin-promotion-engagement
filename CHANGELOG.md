# Changelog

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
