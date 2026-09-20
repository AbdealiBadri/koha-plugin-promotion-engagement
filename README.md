# Koha Promotion & Engagement

API-first Koha Tool Plugin for recording library promotion activity and measuring circulation impact while keeping Koha as the source of truth.

> **Status: pre-alpha / development only. Do not install on a production Koha instance.**

## Target compatibility

- Primary: Koha 25.11.x
- Forward test target: Koha 26.05.x
- Initial production target: Aljamea-tus-Saifiyah Nairobi after KTD and staging validation

## Core architecture

Koha remains authoritative for bibliographic records, items, barcodes, patrons, branches and circulation. The plugin stores only promotion-specific operational data in namespaced plugin tables.

The v0.3.0 release candidate includes:

- Campaign create/list/detail/edit/archive with audit history
- Universal campaign types, channels and reusable multi-location configuration
- Bulk barcode scan/paste with live Koha validation
- Baseline, During and After 7/14/30/60-day circulation analytics
- Conversion, uplift, days-to-first-checkout and portfolio de-duplication
- Privacy-aware channel, location, type, language and audience comparisons
- Professional Koha-native dashboard and reports
- CSV/JSON exports
- Authenticated health and read-only campaign Analytics API

Later milestones include recurring campaigns, non-barcode resources, historical import, Koha 26.05 validation and institutional staging.

## Safety rules

1. Never patch Koha core for plugin functionality.
2. Never add columns to Koha core database tables.
3. Use namespaced plugin-owned tables only.
4. Treat Koha as the source of truth for catalogue and circulation data.
5. Do not silently destroy historical promotion data on uninstall.
6. Test releases in Koha Testing Docker (KTD) and staging before production.
7. Use least-privilege staff and API accounts.
8. Do not expose patron-identifiable analytics to general external dashboards.

## Development lifecycle

`source -> static checks -> KTD 25.11 -> KTD 26.05 -> AJSN staging -> versioned KPZ -> production`

See `docs/ARCHITECTURE.md`, `docs/SAFETY.md`, `docs/ROADMAP.md`, and `docs/REAL_WORLD_USE_CASES.md`.
