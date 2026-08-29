# Product Requirements Document

## Status legend

- `IMPLEMENTED` — present in current source and materially working.
- `PARTIAL` — some required behaviour exists, but the requirement is not complete.
- `PLANNED` — approved future requirement.
- `BLOCKED` — approved but currently prevented by a known blocker.
- `REJECTED` — explicitly or effectively rejected by project decisions.
- `DEPRECATED` — superseded behaviour/approach.
- `UNKNOWN / NEEDS VERIFICATION` — discussed or implied but not sufficiently verified.

## 1. Product objective

Build a reusable Koha-native Promotion & Engagement plugin that records library promotion activity and measures circulation/engagement impact using Koha as the source of truth. The plugin must support Aljamea Nairobi's real workflows without hard-coding them, remain portable to other campuses/libraries, and eventually provide professional analytics and reporting.

## 2. Core product principles

| Requirement | Status | Notes |
|---|---|---|
| Koha remains authoritative for catalogue, items, patrons, branches and circulation | IMPLEMENTED | Current code reads Koha items/libraries and stores only plugin-specific records. |
| No Koha core patching for plugin functionality | IMPLEMENTED | Architectural safety rule. |
| Plugin data uses namespaced plugin-owned tables | IMPLEMENTED | `plugin_ajsn_promo_*`. |
| Uninstall must not silently destroy historical campaign data | IMPLEMENTED | Current `uninstall` returns without dropping tables. |
| Nairobi examples must not be hard-coded universal defaults | PARTIAL | Requirement documented; current allowed type/channel lists are still hard-coded generic enums and need configurable vocabularies later. |
| Staff UI and future external API must use the same business rules | PLANNED | Health API exists; analytics/business service layer is not yet built. |
| Production only after KTD, staging, compatibility and KPZ gates | PLANNED | No production deployment verified. |

## 3. Campaign management

| Requirement | Status | Acceptance criteria |
|---|---|---|
| Create campaign | IMPLEMENTED | Required type, channel, name and start date validate and a campaign row is written. |
| Optional end date | IMPLEMENTED | Blank allowed; end before start rejected. |
| Status | PARTIAL | `draft`, `active`, `completed` supported; workflow semantics are minimal. |
| Koha library/branch | IMPLEMENTED | Dropdown from live Koha libraries; selected branch is validated. |
| Target audience | IMPLEMENTED | Free-text field stored. |
| Language | PARTIAL | Free-text/short code stored; configurable language model not built. |
| Location | PARTIAL | One free-text `display_location` field exists; one campaign with multiple reusable locations is not implemented. |
| Notes | IMPLEMENTED | Free-text notes stored. |
| Campaign detail view | PLANNED | Dashboard currently shows summary rows only. |
| Campaign edit/update | PLANNED | Not implemented. |
| Campaign soft delete/archive | PLANNED | `deleted_at` exists but no UI/service workflow uses it. |
| Campaign list/filter/search | PLANNED | Recent ten rows only. |
| Recurring/cadence-aware activities | PLANNED | Must support daily/weekly/monthly workflows without forcing unrelated duplicates. |
| Staff responsible | PLANNED | `created_by` exists; separate responsible/owner workflow not implemented. |

## 4. Promotion dimensions and universal configuration

The product must support configurable values rather than institution-specific code.

| Dimension | Status | Notes |
|---|---|---|
| Campaign/activity type | PARTIAL | Generic hard-coded allowed list currently. |
| Channel | PARTIAL | Generic hard-coded allowed list currently. |
| Physical/digital locations | PLANNED | Multi-select/reusable model required. Source may be Koha authorized values and/or plugin-managed values; final UX/source is not yet decided. |
| Languages | PLANNED | Must support multilingual campaigns and future additional languages. |
| Audiences | PLANNED | Current free text is temporary. |
| Frequency/cadence | PLANNED | Needed for daily/weekly/monthly activities. |
| Workflow statuses | PARTIAL | Three statuses currently. |
| Impact windows/defaults | PLANNED | 7/14/30/60 day windows planned. |

## 5. Linked resources

| Requirement | Status | Acceptance criteria |
|---|---|---|
| Paste/scan barcodes | IMPLEMENTED | Multiple entries accepted by line/comma/semicolon splitting. |
| Validate barcodes against live Koha items before save | IMPLEMENTED | Invalid entries block entire campaign save. |
| Duplicate barcode detection within campaign | IMPLEMENTED | Duplicate input ignored and warning shown. |
| One campaign-item link per Koha item | IMPLEMENTED | Unique `(campaign_id,itemnumber)` key. |
| Transactional campaign + item + audit save | IMPLEMENTED | Any DB failure rolls back; mixed valid/invalid input saves nothing. |
| Save campaign with no linked barcode | IMPLEMENTED | Required for non-item or future resource campaigns. |
| Link multiple items/titles | IMPLEMENTED | Multiple validated items can be inserted. |
| Show linked title/author/barcode in campaign detail | PLANNED | Backend link exists; current dashboard does not display resource details. |
| Promote e-resources/non-barcode objects | PLANNED | Model must not assume all resources have physical item barcodes. |
| Promote author/theme/collection while linking many resources | PARTIAL | Campaign metadata can represent theme; dedicated entity/configuration model not built. |
| Serials/newspapers/magazines | PARTIAL | Koha item links can work if represented in Koha; dedicated serial-specific UX not built. |

## 6. Audit and data integrity

| Requirement | Status | Notes |
|---|---|---|
| Audit successful campaign creation | IMPLEMENTED | `campaign_created` audit row written in same transaction. |
| Actor attribution | IMPLEMENTED | Koha borrower/staff number captured where available. |
| Audit edits/deletes/status changes | PLANNED | Those operations do not yet exist. |
| Preserve historical plugin data on disable/re-enable | IMPLEMENTED | Manually verified for plugin settings during v0.1 lifecycle test. |
| Preserve historical plugin data on uninstall | PARTIAL | Code is non-destructive; full upgrade/uninstall matrix still needs release testing. |
| Historical spreadsheet import with validation, duplicate checks, audit and rollback | PLANNED | v1.0 roadmap. |

## 7. Dashboard and analytics

### Current dashboard

| Requirement | Status |
|---|---|
| Total saved promotions | IMPLEMENTED |
| Total linked campaign-item rows | IMPLEMENTED |
| Recent campaigns table | IMPLEMENTED |
| Plugin version display | IMPLEMENTED |
| Professional/modern analytics dashboard | PLANNED |

### Approved analytics direction

The dashboard must eventually answer, where the required Koha data exists and privacy rules permit:

- campaign count by week/month/term/channel/location;
- promoted titles/items subsequently issued;
- conversion rate: unique promoted resources with at least one checkout;
- days to first checkout after promotion;
- circulation before, during and after campaign;
- campaign uplift versus an appropriate non-campaign/baseline window;
- 7/14/30/60-day impact windows;
- strongest campaign types/channels;
- strongest physical display locations;
- subject/collection performance;
- language and audience response;
- email vs physical display vs digital signage vs physical signage performance;
- promoted titles with no response;
- repeated-title campaigns and outcomes;
- top users/students benefiting from promotions, only in appropriately restricted staff analytics;
- top Darajah/class/standard/group/category benefiting from promotions where reliable patron attributes exist;
- circulation turnover when resources are promoted versus periods when they are not promoted.

**Status:** `PLANNED`. The current UI explicitly labels conversion analytics as a later phase.

## 8. Real-world workflows that must be expressible

These are approved acceptance examples, not default records:

- Weekly subject-wise/new-arrivals physical displays, potentially at multiple locations.
- Weekly email promotions in English, Arabic and e-book/resource categories.
- Daily English/Arabic digital signage.
- Weekly physical signage.
- Monthly e-resource feature.
- Monthly author feature.
- Weekly newspaper/magazine feature.
- Recommended-for-review display.

The system must remain universal enough to add new activities without code changes.

## 9. REST API and integrations

| Requirement | Status | Notes |
|---|---|---|
| Reserved plugin namespace `/api/v1/contrib/ajsn_promotion/` | IMPLEMENTED | Current namespace. |
| Authenticated health endpoint | IMPLEMENTED-CODE / NEEDS RUNTIME RE-VERIFICATION | Code reports current `$VERSION`; latest runtime verification is blocked by KTD startup issue. |
| Health endpoint requires Koha authorization | IMPLEMENTED | OpenAPI requires `catalogue` permission. |
| Campaign/detail/analytics APIs | PLANNED | Not implemented. |
| External AJS applications consume read-only analytics | PLANNED | Must reuse same business rules. |
| OAuth2 integration guide | PLANNED | v0.4 roadmap. |

## 10. Security and permissions

| Requirement | Status | Notes |
|---|---|---|
| Koha plugin `tool` permission enforced | IMPLEMENTED | Core runner controls tool access. |
| Koha-native CSRF protection on writes | IMPLEMENTED-CODE | POST uses `cud-` operation and generated token; dedicated adversarial manual test remains pending. |
| Invalid input must not partially save | IMPLEMENTED / VERIFIED | Mixed valid+invalid rollback test passed. |
| Least-privilege accounts | PLANNED/OPERATING RULE | Must be applied in staging/production. |
| Do not expose identifiable patron analytics to general external dashboard | APPROVED REQUIREMENT | Privacy design required before patron-ranking features ship. |
| No secrets in repository/docs | APPROVED REQUIREMENT | Project Brain follows this rule. |

## 11. Packaging and release

| Requirement | Status |
|---|---|
| Build versioned KPZ from tracked `Koha/` files | IMPLEMENTED |
| Produce SHA-256 checksum | IMPLEMENTED |
| Clean install through Koha Administration > Plugins | VERIFIED historically for v0.1.0 |
| Disable/re-enable without data loss | VERIFIED historically |
| Upgrade from v0.1 to v0.2 with data preservation | PARTIAL / current dev testing |
| Koha 25.11.x validation | PARTIAL |
| Koha 26.05.x validation | NOT RUN |
| AJSN staging validation | NOT RUN |
| Production release | NOT RUN |

## 12. UI/UX requirements

- Current priority is correct data, permissions, integrity and analytics foundations.
- Modern visual redesign is explicitly deferred until core workflows are stable.
- Final UI should be professional, management-friendly and responsive within Koha's staff interface constraints.
- Campaign creation should evolve toward reusable configured values and multi-select locations rather than repetitive free text.

Status: current Koha-native UI is `PARTIAL`; modern dashboard is `PLANNED`.

## 13. Rejected/superseded approaches

- `REJECTED`: patching Koha core or adding plugin columns to core Koha tables.
- `REJECTED`: hard-coding Nairobi's seven locations/campaign names/languages as universal application constants.
- `REJECTED`: treating every campaign as requiring a physical barcode.
- `REJECTED`: saving valid items from a submission that also contains invalid barcodes; the approved rule is all-or-nothing.
- `DEPRECATED`: v0.1 read-only New Promotion mockup; v0.2 uses a writable form.
- `DEPRECATED`: health API version hard-coded to `0.1.0`; commit `3537b8e` changes it to use the plugin's authoritative `$VERSION`.
- `REJECTED FOR CURRENT CHECKPOINT`: using the disposable `kpztest` instance for normal feature development. The checkpoint specifies the existing `kohadev` KTD instance; `kpztest` is for clean KPZ acceptance testing.

## 14. Open product questions

1. Final source and UX for locations: Koha authorized values, plugin-managed vocabulary, free text fallback, or combination.
2. Exact data model for one campaign to many locations.
3. Representation of e-resources/external resources without Koha item barcodes.
4. Exact audience/class/Darajah mapping source and privacy rules for top-user/top-class analytics.
5. Baseline methodology for circulation uplift when a campaign is not running.
6. Whether recurring activities should use recurrence definitions, campaign templates, generated occurrences, or another model.
7. Exact permissions matrix beyond current Koha plugin tool and catalogue health permissions.