# Koha Promotion & Engagement

API-first Koha Tool Plugin for recording library promotion activity and measuring circulation impact while keeping Koha as the source of truth.

> **Status: pre-alpha / development only. Do not install on a production Koha instance.**

## Target compatibility

- Primary: Koha 25.11.x
- Forward test target: Koha 26.05.x
- Initial production target: Aljamea-tus-Saifiyah Nairobi after KTD and staging validation

## Core architecture

Koha remains authoritative for bibliographic records, items, barcodes, patrons, branches and circulation. The plugin stores only promotion-specific operational data in namespaced plugin tables.

Planned capabilities include:

- Promotion/campaign management
- Bulk barcode scan/paste and Koha item validation
- Before/after circulation impact analysis
- 7/14/30/60-day KPIs
- Target audience, subject, language and branch analytics
- CSV/JSON exports
- Authenticated REST API for external AJS applications
- Audit trail and role-based access
- Historical migration from spreadsheet-based promotion records

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

See `docs/ARCHITECTURE.md`, `docs/SAFETY.md`, and `docs/ROADMAP.md`.
