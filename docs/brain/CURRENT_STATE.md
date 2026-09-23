# Current State

**Last verified:** 2026-09-21
**Repository:** `AbdealiBadri/koha-plugin-promotion-engagement`
**Repository default branch:** `main`
**Active implementation branch:** `feature/v0.5-analytics-intelligence`
**Base checkpoint:** v0.4.1 acceptance/upgrade-survival fixes, commit `57a38bc` on `feature/v0.4-book-display-impact`
**Primary local runtime:** isolated KTD `promoeng`, Koha 25.11.02

## Current milestone

**v0.5.0 Analytics Intelligence — LOCAL IMPLEMENTATION/RUNTIME GATES COMPLETE; EXTERNAL ACCEPTANCE GATES REMAIN.**

The milestone was triggered by real Nairobi pilot evidence showing that the plugin had useful raw calculations but did not communicate impact clearly enough at first glance, and that an active campaign without an end date effectively collapsed to a one-day analytics period.

v0.5 corrects the active-campaign calculation and reorganizes all major analytics-bearing screens around Reach → Engagement → Impact → Action.

## Product problem now solved locally

The plugin can answer, from Koha circulation evidence:

- how many distinct titles were promoted;
- how many physical/item copies were linked;
- how many promoted titles were actually borrowed;
- what percentage of promoted titles were used;
- how many checkout events occurred during the campaign;
- how that compares with an equal pre-campaign baseline;
- which promoted titles increased, had no response, or generated repeat demand;
- whether copy/hold pressure warrants collection-development review;
- which campaign dimensions perform differently when attribution is defensible.

It continues to avoid claiming that promotion caused every loan.

## v0.5 working functionality — VERIFIED

### Active campaigns

- Started active campaign with no end date measures from start date through the current/as-of date.
- Started active campaign with a future planned end date also measures only through today.
- Active campaign with a configured end date already in the past uses that configured end and returns a data-quality warning that status is still active.
- Future campaign is Pending rather than failed.
- Baseline duration exactly matches the resolved During duration.
- Staff no longer need to falsely complete a live campaign merely to obtain analytics.

### Follow-up windows

After 7/14/30/60 windows now return explicit states:

- Pending;
- partial / To date;
- Complete.

Pending windows return null metrics and the UI renders “Pending”, not zero.

### Title-versus-copy model

- Promoted copies/items = distinct eligible `itemnumber`.
- Promoted titles = distinct `biblionumber`.
- Multiple copies of the same title are combined for title-utilization metrics.
- This makes cases such as 156 linked items representing 154 titles explicit rather than contradictory.

### Management KPIs

Shared Analytics service now exposes:

- promoted title count;
- promoted item/copy count;
- titles used;
- title utilization rate;
- campaign checkouts;
- baseline checkouts;
- daily checkout rates and uplift;
- increased-use titles;
- zero-response titles;
- repeat-demand titles;
- days to first checkout;
- portfolio de-duplicated totals;
- multi-attribution evidence.

### Dashboard

Primary cards now show promotion performance rather than mainly administration:

- Promoted titles;
- Titles used;
- Title utilization;
- Campaign checkouts with baseline context;
- Zero-response titles;
- Active campaigns.

Administrative campaign/completion/item/location counts remain secondary.

Recent campaign rows show Promoted, Used, Checkouts, Utilization and baseline change.

### Promotions

Campaign list now exposes impact measures directly:

- promoted titles and linked copies/items;
- titles used;
- campaign checkouts;
- utilization;
- change versus baseline;
- live-to-date status where applicable.

### Campaign Detail

Campaign Detail includes an **Impact at a glance** panel and direct links to full Campaign Analytics and Resource Impact.

### Campaign Analytics

Campaign Analytics now leads with:

- Promoted titles;
- Titles used;
- Title utilization;
- Campaign checkouts;
- Baseline checkouts;
- Change versus baseline.

It also shows increased-use, zero-response and repeat-demand signals, active live-to-date explanation, explicit window states and a biblio-level title-response table.

### Promoted Resource Impact

The former Book Display Impact UI is generalized to **Promoted Resource Impact** because physical, email, recommendation and digital campaigns can all promote Koha titles.

Primary engagement row:

- Promoted titles;
- Titles borrowed;
- Title utilization;
- Campaign checkouts with baseline;
- Increased-use titles;
- Zero-response titles.

Collection-development workflow remains secondary:

- High priority;
- Active holds;
- Approved;
- Sent to Koha.

The internal route `book_display_impact` and native Koha Suggestion reason `Book Display Impact` remain stable for compatibility.

### Reports

Comparative Reports now leads with campaign/title/use/utilization/baseline/campaign-checkout evidence. Multi-attribution is moved to a Measurement quality section.

Channel, location, campaign type, language and audience tables now include promoted titles, titles used, utilization, baseline checkouts, campaign checkouts, change, zero-response and increased-title counts.

Location conclusions still exclude ambiguous multi-location attribution from the “leading location” statement.

## Data and safety architecture

- Koha remains authoritative for catalogue, items, holds, patrons and circulation.
- Analytics uses Koha `issues` + `old_issues`, de-duplicated by `issue_id`.
- Plugin data stays in seven namespaced `plugin_ajsn_promo_*` tables.
- No Koha core patch or core schema column is required.
- Campaign/item/location history remains soft-preserved.
- General analytics remain aggregate-only.
- Native Koha Suggestions are created only after explicit librarian approval and authorization.
- Acquisitions retains vendor/fund/price/basket/order authority.

## Final local v0.5 verification — Koha 25.11.02

**PASS**

- `git diff --check`: PASS.
- Shell smoke-script syntax: PASS.
- Main plugin Perl syntax: PASS.
- Analytics service Perl syntax: PASS.
- Resource Impact service Perl syntax: PASS.
- Schema idempotence: PASS.
- Seven namespaced plugin tables preserved.
- Full automated suite: **5 files / 113 assertions / PASS**.
- Exact `PromotionEngagement-v0.5.0.kpz` build: PASS.
- ZIP integrity: PASS.
- Exact authenticated KPZ upload/upgrade to isolated `promoeng`: PASS.
- Installed version 0.5.0 and seven tables: PASS.
- Authenticated browser rendering: Dashboard, Promotions, Analytics, Reports, Configuration and Promoted Resource Impact: PASS.
- Synthetic approval → native Koha ASKED Suggestion → audit verification: PASS.
- Synthetic workflow campaign/suggestion/temp patron cleanup: PASS.
- Existing retained campaign 40 recommendation was not overwritten or deleted.

**Exact current v0.5.0 SHA-256:**
`931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670`

## Koha 26.05 compatibility

**VERIFIED-CODE / RUNTIME BLOCKED — HOST DISK CAPACITY**

A second isolated 26.05 KTD pull was attempted on 2026-09-21 after Windows C: showed about 16 GB free. During Docker layer expansion, free space fell through approximately 12 GB to 11 GB before the image completed. The pull process was stopped deliberately.

No completed `koha/koha-testing:26.05` image and no `promoeng2605` containers were created.

The prior 12–15 GB free-space estimate is therefore insufficient on this host. Do not retry until at least **20–25 GB of safe Windows C: free space** is available. Do not use global Docker pruning or delete unrelated projects as a workaround.

## Nairobi live-pilot note

The user installed the earlier v0.4.1 candidate on the live Nairobi Koha and reported that installation/runtime operation was normal. Real campaign screenshots exposed the active-campaign and first-glance analytics deficiencies that v0.5 corrects.

This user pilot observation is useful evidence but is **not** treated as formal v0.5 production acceptance. v0.5 has not been deployed to live Nairobi by this development session.

## Remaining gates

The remaining items are not unfinished local coding work:

1. human visual review of final v0.5 screens;
2. Koha 26.05 runtime matrix once 20–25 GB safe free host space is available;
3. institutional non-production staging acceptance;
4. explicit production backup/change-window ownership and deployment authorization.

## Exact next action

User visual review of the final v0.5 interface in the isolated/local runtime, then package handoff for controlled staging/live testing only after the deployment gates appropriate to that environment are accepted.

Detailed metric/formula/page documentation is in `V0.5_ANALYTICS_INTELLIGENCE.md`.
