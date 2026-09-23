# Current State

**Last verified:** 2026-09-23
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`
**Active branch:** `feature/v0.6-usability-visualization`
**Implementation commit:** `1f0c993`
**Plugin version:** 0.6.0
**Primary runtime:** isolated KTD `promoeng`, Koha 25.11.02

## Current milestone

**v0.6.0 Usability & Visualization — READY FOR USER TESTING on the verified Koha 25.11.02 line.**

v0.6 preserves the v0.5 analytics model while improving discoverability, interaction, visualization, terminology and beginner guidance.

## Implemented

- Academic/professional terminology with deliberately simple explanations.
- Dashboard evidence-cycle text simplified under the existing academic headings.
- “Titles Used” → **Titles Issued / Borrowed**.
- “Increased-Use Titles” → **Titles with Increased Issues**.
- Searchable campaign/vocabulary selectors and natural sorting.
- Multi-campaign selection for comparison/reporting where appropriate.
- Shared Koha DataTables behavior for major tables: search/filter/sort/export.
- KPI drill-down/filter behavior.
- Resource Impact response-color cues plus legend.
- Redesigned Collection-development signals.
- Campaign Analytics charts, data labels, Table View and JPEG download.
- Comparative Report charts, Table View and JPEG download.
- Page-specific **How to Use** content across the main workflow.
- Detailed Configuration help for global reusable vocabulary.

## Verification

- Full automated suite: **6 files / 163 assertions / PASS**.
- Schema idempotence: PASS.
- Exact authenticated v0.6.0 KPZ upgrade: PASS.
- Seven plugin tables retained.
- Exact upgrade smoke preserved all observed plugin table row counts.
- Authenticated browser matrix: Dashboard, Promotions, Analytics, Reports, Configuration, Resource Impact, Campaign Detail, Edit Promotion and New Promotion: PASS.
- Synthetic approve → Koha ASKED Suggestion workflow: PASS.
- Workflow fixture cleanup: PASS.

**Exact KPZ:** `PromotionEngagement-v0.6.0.kpz`
**SHA-256:** `6ca98215bcce431f7877633e3af45aa0aff8024e87c4411bd55769862c25ed28`

## External gates

- User visual/real-data acceptance of v0.6.
- Koha 26.05 runtime matrix remains blocked by local host disk capacity; no 26.05 PASS is claimed.
- Institutional staging/change-window rules remain applicable before a formal production release.

## Next action

User uploads the exact v0.6.0 KPZ as an in-place plugin upgrade and performs the visual/real-data acceptance checklist. Do not uninstall the prior version first.

See `V0.6_USABILITY_VISUALIZATION.md` for the detailed implementation and acceptance scope.
