# Promotion & Engagement

A Koha Tool Plugin for recording library promotion activity and measuring circulation impact while keeping Koha as the source of truth.

## v0.3.0 release candidate

The plugin now provides audited campaign creation and editing, configurable promotion metadata and multi-location selection, Koha-linked item validation, circulation-impact analytics, portfolio comparison reports, CSV/JSON exports, and authenticated REST analytics. Staff pages use a consistent professional academic visual system.

The release candidate is runtime-tested in the dedicated KTD environment. Production deployment remains gated by Monday visual acceptance, clean KPZ installation, Koha 26.05 compatibility, staging, backup, and rollback checks.

## Safety rules

- No Koha core file modifications.
- No schema changes to Koha core tables.
- Plugin data is stored only in `plugin_ajsn_promo_*` tables.
- Uninstall does not delete historical plugin data.
- Catalogue/circulation data is read from Koha rather than duplicated.
- REST endpoints live under `/api/v1/contrib/ajsn_promotion`.
