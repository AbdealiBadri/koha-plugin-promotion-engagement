# Integrations

## 1. Koha ILS core

- **Purpose:** authoritative catalogue, items/barcodes, patrons, branches and circulation.
- **Data flow:** mostly Koha -> plugin reads; plugin writes only plugin-owned promotion tables.
- **Interfaces currently used:** `C4::Context`, `Koha::Items`, `Koha::Libraries`, Koha DB connection, plugin framework, staff templates and REST framework.
- **Authentication:** Koha staff session/plugin permissions; REST authorization through Koha OpenAPI permission checks.
- **Current status:** ACTIVE / REQUIRED.
- **Failure modes:** unavailable/incorrect item barcode blocks campaign item validation; KTD/Koha runtime failure blocks all plugin testing.
- **Ownership:** Koha is source of truth.

## 2. Koha Plugins framework

- **Purpose:** installation, tool execution, configure/disable/uninstall, API namespace/routes and KPZ distribution.
- **Current status:** ACTIVE.
- **Requirements:** plugin support enabled, correct plugin directory, appropriate staff plugin permissions, writable install path for KPZ install.
- **Known historical failure:** plugin discovery/module load errors when KTD plugin path/configuration was not correctly recognized; resolved in foundation testing.

## 3. Koha circulation/statistics data

- **Purpose:** future analytics source.
- **Direction:** Koha -> analytics engine.
- **Current status:** PLANNED USE; not yet implemented as analytics engine.
- **Intended measures:** before/during/after circulation, 7/14/30/60 windows, conversion, days-to-first-checkout, turnover/uplift.
- **Limitation:** exact queries/business definitions remain to be designed and tested.

## 4. Koha patrons / attributes

- **Purpose:** future audience/class/group/user benefit analytics.
- **Direction:** Koha -> restricted analytics.
- **Current status:** PLANNED.
- **Privacy limitation:** patron-identifiable rankings must stay restricted to approved staff use and must not be exposed to general external dashboards.
- **Needs verification:** authoritative fields for Darajah/class/standard/group/category.

## 5. Koha libraries / locations / authorized values

- **Libraries:** live `Koha::Libraries` integration is current; form lists branches and validates selected branchcode.
- **Locations/authorized values:** candidate future source for reusable campaign locations/configuration.
- **Current status:** location source design is OPEN; current campaign stores free-text location.

## 6. Plugin REST API

- **Namespace:** `/api/v1/contrib/ajsn_promotion/`
- **Current endpoint:** `GET /health`.
- **Authentication/authorization:** Koha REST framework; health route requires `catalogue` permission.
- **Current status:** HEALTH IMPLEMENTED; v0.2 runtime version regression re-verification blocked by KTD environment.
- **Future:** campaign/detail/report/analytics read endpoints, OAuth2 integration guide, external AJS applications.

## 7. External AJS applications

- **Purpose:** future authorized consumers of promotion analytics.
- **Direction:** plugin API -> external application, primarily read-only analytics.
- **Current status:** PLANNED, no external application integration verified.
- **Rule:** external figures must use the same business rules as Koha staff UI; no independent KPI implementations.
- **Authentication:** OAuth2 is roadmap direction; exact client setup not yet implemented.

## 8. Historical spreadsheet/manual records

- **Purpose:** migrate past campaign/promotion records into the plugin.
- **Direction:** controlled import -> plugin-owned campaign/resource/audit structures.
- **Current status:** PLANNED for later/v1.0.
- **Requirements:** validation, duplicate detection, audit logging, dry-run/rollback planning and no corruption of Koha core.

## 9. Promotion channels such as email/signage

Email, digital signage, physical signage and displays are currently **campaign channels**, not active third-party integrations. The plugin records that a campaign used a channel; it does not currently send email or publish signage.

Any future direct connector to email/signage systems must be approved and documented separately.

## 10. Koha Testing Docker (KTD)

- **Purpose:** local integration/compatibility environment.
- **Current status:** ACTIVE development dependency.
- **Main instance:** `kohadev`.
- **Historical clean package instance:** `kpztest`, disposable.
- **Known limitation:** container lifecycle must remain consistent; recreating only app container over retained populated DB caused current startup blocker.

## Secrets policy

This file intentionally contains no passwords, API keys, database credentials, tokens, OAuth secrets or cookies. Document environment-variable/configuration names when they become defined; never commit values.