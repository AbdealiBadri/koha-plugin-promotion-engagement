# Monday Acceptance Guide — v0.3.0 Release Candidate

**Prepared:** 2026-09-20
**Branch:** `feature/v0.3-analytics-engine`
**Runtime:** isolated KTD `promoeng`
**Production status:** not deployed

## Start here

Log in through the normal Koha staff homepage, then open:

- Dashboard: `http://promoeng-intra.localhost/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool`
- Promotions: add `&action=promotions`
- Analytics: add `&action=analytics`
- Reports: add `&action=reports`
- Configuration: use Koha Administration > Plugins > Promotion & Engagement > Configure

Use Ctrl+F5 once before reviewing so the latest templates are loaded.

## Five-minute acceptance path

1. Dashboard loads with the navy/teal academic visual system and six summary cards.
2. Open Promotions; search for `MULTILOC` and filter status `Active`.
3. Open campaign 40 and confirm its linked Koha item, audit history and three locations.
4. Open Analytics from the sidebar; campaign 40 should be selected automatically.
5. Confirm KPI cards and Baseline/During/After 7/14/30/60 table render.
6. Open Reports; confirm channel, location, campaign-type, language and audience sections.
7. Download Channel CSV, Location CSV and Type JSON.

## Expected campaign 40 result

- Campaign: `MULTILOC-VISUAL-20260919`
- Eligible promoted items: 1
- Locations: Main Entrance, First Floor and Digital Screen
- Current isolated-KTD checkouts: 0
- Conversion: 0%
- Uplift: no baseline rate
- Days to first checkout: no response yet

Zero circulation is expected in this isolated development database; it is not a calculation failure.

## Automated evidence

- AN-01 through AN-15: PASS
- Analytics test suite: 48 assertions PASS
- Dashboard, Analytics, Reports and filtered Promotions render smoke: PASS
- Main plugin, Analytics service and Analytics API Perl syntax: PASS
- OpenAPI JSON validation: PASS
- Campaign and report service smoke: PASS
- Transaction rollback/residue verification: PASS
- Exact KPZ extraction and syntax validation: PASS
- KPZ checksum verification: PASS

## Release artifact

- File: `dist/PromotionEngagement-v0.3.0.kpz`
- SHA-256 file: `dist/PromotionEngagement-v0.3.0.kpz.sha256`
- This is a release candidate for KTD/staging acceptance, not authorization for production deployment.

## Items intentionally outside Monday acceptance

These require a separate approved milestone or institutional environment:

- Koha 26.05 compatibility environment
- AJSN institutional staging deployment
- production backup/rollback rehearsal
- production deployment
- non-barcode/e-resource resource abstraction
- recurrence/template scheduling
- historical spreadsheet importer
- restricted identifiable top-user analytics

No production database or patron-identifiable analytics were used for this release candidate.
