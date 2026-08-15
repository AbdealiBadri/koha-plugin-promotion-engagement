# Promotion & Engagement

A Koha Tool Plugin for recording library promotion activity and measuring circulation impact while keeping Koha as the source of truth.

## v0.1.0

Foundation release only. The promotion-entry form is deliberately read-only until validation, permissions, CSRF handling and audit logging are implemented and tested.

## Safety rules

- No Koha core file modifications.
- No schema changes to Koha core tables.
- Plugin data is stored only in `plugin_ajsn_promo_*` tables.
- Uninstall does not delete historical plugin data.
- Catalogue/circulation data is read from Koha rather than duplicated.
- REST endpoints live under `/api/v1/contrib/ajsn_promotion`.
