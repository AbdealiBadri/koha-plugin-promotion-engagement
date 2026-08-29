# Project Overview

## Project identity

**Project:** Koha Promotion & Engagement  
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`  
**Product form:** Koha Tool Plugin / KPZ package  
**Institutional origin:** Aljamea-tus-Saifiyah Nairobi library  
**Current maturity:** Pre-alpha / development only

## Summary

Koha Promotion & Engagement is a Koha-native plugin for recording library promotion activities, linking promoted resources to live Koha records, and measuring whether those activities change circulation and reading behaviour. The plugin is intentionally designed so **Koha remains the authoritative library system** while the plugin stores only promotion-specific operational data and derives analytics from Koha circulation history.

The long-term goal is not merely to count campaigns. It is to answer management questions such as which campaigns, channels, locations, subjects, languages, audiences, titles, classes/groups, and time windows create measurable engagement or circulation uplift.

## Problem being solved

Library promotion is currently spread across physical displays, signage, email, featured resources/authors, review programmes, and other recurring activities. These activities can be operationally visible yet analytically disconnected from Koha. The project creates a durable record of **what was promoted, how, where, when, to whom, and with which resources**, then measures outcomes against Koha transaction data.

## Primary users

- Library administrators and managers.
- Librarians/staff who create and maintain promotions.
- Staff who review promotion impact and circulation analytics.
- Future authorized external AJS applications consuming read-only promotion analytics through the plugin API.

## Stakeholders

- Aljamea-tus-Saifiyah Nairobi library management and staff.
- Future Aljamea campus libraries and other Koha libraries that may use the plugin.
- Koha administrators responsible for plugin installation, permissions, upgrades, backups, and compatibility.
- Institutional decision-makers who need evidence of campaign effectiveness.

## Primary use cases

1. Create a promotion/campaign with type, channel, dates, status, branch, audience, language, location, notes, and linked Koha items.
2. Paste or scan barcodes and validate them against live Koha items before saving.
3. Prevent duplicate item links and partial writes.
4. Preserve an audit trail of promotion operations.
5. Review campaign counts and linked-item counts.
6. Measure before/during/after circulation behaviour and configurable 7/14/30/60-day impact windows.
7. Compare campaign effectiveness by channel, location, subject/theme, language, audience, class/group/category, and other dimensions where the underlying data supports safe analysis.
8. Identify promoted items that convert to checkout, do not convert, or convert after a measurable delay.
9. Support recurring physical and digital promotion workflows without hard-coding one institution's vocabulary.
10. Package the plugin as a normal versioned KPZ and install it through Koha's plugin administration workflow.

## Major modules

### Implemented/partially implemented

- Koha plugin shell and metadata.
- Plugin-owned namespaced schema.
- Campaign creation workflow.
- Barcode validation and campaign-to-item linking.
- Duplicate-barcode prevention.
- Transactional campaign/item/audit writes.
- Dashboard shell with campaign and linked-item counts.
- Health REST endpoint.
- Koha-native CSRF and plugin permission integration.
- KPZ build script and historical clean-install test procedure.

### Planned

- Campaign listing/detail/edit/soft-delete lifecycle.
- Universal configurable types/channels/locations/languages/audiences/cadences.
- Multi-location campaigns.
- Analytics engine and baseline comparisons.
- Professional management dashboard.
- Reports and CSV/JSON exports.
- Additional read-only REST analytics endpoints.
- Historical spreadsheet import.
- E-resource/non-barcode resource support.
- Compatibility validation on Koha 26.05.x.
- Staging and production deployment.

## Real-world acceptance examples

The plugin must be generic enough to represent Nairobi workflows without source-code customization, including weekly subject/new-arrival displays, weekly English/Arabic/e-book email campaigns, daily multilingual digital signage, weekly physical signage, monthly featured e-resources/authors, weekly newspaper/magazine promotion, and recommended-for-review displays. These are **acceptance examples, not hard-coded defaults**.

## Scope boundaries and non-goals

- The plugin does not replace Koha catalogue, item, patron, branch, or circulation modules.
- It must not duplicate or rewrite Koha transaction history merely to calculate analytics.
- It must not require Koha core patches for plugin functionality.
- It is not currently an email-delivery, digital-signage publishing, social-media publishing, or marketing-automation platform; those are channels recorded by the campaign model unless a later integration is explicitly approved.
- Nairobi-specific operational vocabulary must not become universal hard-coded logic.
- Production deployment is not part of the current checkpoint.

## Core business constraints

- Koha is the source of truth for catalogue, items/barcodes, patrons, branches and circulation.
- Plugin-specific data must remain namespaced and independently manageable.
- Historical campaign data must not be silently destroyed on uninstall.
- Patron-identifiable analytics require restricted/approved handling and must not be exposed casually to external/general dashboards.
- Campaign measurements must use consistent business rules across Koha UI and future external applications.
- The plugin must support growth beyond physical books; future promoted resources may not have item barcodes.

## Technology summary

- Perl Koha plugin based on `Koha::Plugins::Base`.
- Template Toolkit for Koha staff UI.
- MariaDB/MySQL through Koha's database connection.
- Koha ORM/APIs such as `Koha::Items` and `Koha::Libraries`.
- Mojolicious/OpenAPI controller for plugin REST routes.
- Koha Testing Docker (KTD) for local development and validation.
- Python KPZ build helper under `scripts/`.
- Git/GitHub branch-based development.

## Compatibility and deployment targets

- Primary development target: Koha 25.11.x; active KTD tests have used Koha 25.11.02.
- Forward compatibility target: Koha 26.05.x.
- Initial production target: Aljamea-tus-Saifiyah Nairobi only after KTD, compatibility, staging, backup/rollback, and exact-KPZ validation gates pass.

## Branch/repository status

Repository default branch: `main`.  
Active v0.2 implementation branch as last verified: `feature/v0.2-campaign-crud`.  
Project Brain construction branch: `docs/project-brain`, based directly on the active v0.2 branch and intended to be fast-forwarded/merged back after validation.

## Project status

The project has moved beyond the v0.1 foundation and is in the **v0.2 campaign data-entry checkpoint**. Core campaign creation behaviours have passed several manual tests. The immediate runtime blocker is a KTD environment restart failure caused by recreating the Koha application container against an already-populated retained database; this is an environment lifecycle problem, not a verified plugin-code failure. See `CURRENT_STATE.md`, `ISSUES.md`, and `SESSION_HANDOFF.md`.