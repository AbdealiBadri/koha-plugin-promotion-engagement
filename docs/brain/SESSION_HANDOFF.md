# Session Handoff

**Last updated:** 2026-09-21
**Active branch:** `feature/v0.5-analytics-intelligence`
**Plugin version:** 0.5.0
**Primary runtime:** isolated KTD `promoeng`, Koha 25.11.02
**Milestone:** v0.5 Analytics Intelligence — local implementation/runtime closure complete; external visual/forward-compatibility/staging gates remain.

## Why v0.5 exists

Real Nairobi pilot screenshots proved two product problems:

1. an active campaign with no end date effectively measured only its start day, making staff think they had to complete the campaign before analytics became useful;
2. useful evidence existed underneath the plugin, but Dashboard and Resource Impact foregrounded administrative/workflow counters rather than immediately answering whether promoted titles were actually used.

The approved v0.5 redesign makes every major analytical surface answer: Reach → Engagement → Impact → Action.

## Built

- Active campaigns calculate from campaign start through the current/as-of date without forced completion.
- Future planned end dates are clamped to today while a campaign remains active.
- Past configured end dates are respected and inconsistent active status produces a warning.
- Future campaigns are Pending rather than failed.
- Follow-up windows expose Pending / To date / Complete state and never show future zeroes.
- Distinct promoted titles (`biblionumber`) are separated from promoted copies/items (`itemnumber`).
- Added Titles Used, Title Utilization, Increased-use, Zero-response and Repeat-demand title metrics.
- Added portfolio title/item/event de-duplication.
- Dashboard, Promotions, Campaign Detail, Campaign Analytics, Promoted Resource Impact and Comparative Reports were redesigned around meaningful promotion-use evidence.
- Multi-location attribution safeguard remains intact.
- Promoted Resource Impact keeps acquisitions/workflow counters in a secondary Collection-development signals section.
- Native Koha Suggestion integration keeps `reason = Book Display Impact`, leaves `patronreason` untouched, and keeps evidence in staff note/audit.
- Resource Impact sidebar now includes Configuration consistently.
- Browser smoke diagnostics now identify the exact failed page/marker.
- Book Display workflow smoke now creates its own temporary campaign and no longer assumes campaign 40 is free of retained recommendations.

## Final local verification — PASS

On Koha 25.11.02 `promoeng`:

- diff check: PASS;
- shell syntax: PASS;
- plugin/Analytics/Resource Impact Perl syntax: PASS;
- schema idempotence: PASS;
- **5 files / 113 automated assertions: PASS**;
- exact v0.5.0 KPZ build and ZIP integrity: PASS;
- exact authenticated KPZ upload/upgrade: PASS;
- installed plugin version 0.5.0: PASS;
- seven plugin tables: PASS;
- authenticated browser render:
  - Dashboard PASS;
  - Promotions PASS;
  - Analytics PASS;
  - Reports PASS;
  - Configuration PASS;
  - Promoted Resource Impact PASS;
- synthetic decision → native Koha ASKED Suggestion → audit workflow: PASS;
- synthetic fixture/temp patron/suggestion cleanup: PASS.

Current exact KPZ checksum:

`931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670`

## 26.05 forward compatibility

Code/dependency review remains favorable, but **do not claim a Koha 26.05 runtime PASS**.

A fresh isolated `promoeng2605` image pull was attempted after C: had about 16 GB free. Docker layer expansion reduced free space to about 12 GB and then 11 GB before completion. The pull was stopped to protect the workstation.

- no completed 26.05 image;
- no `promoeng2605` containers;
- primary `promoeng` untouched;
- no global Docker cleanup performed.

The previous 12–15 GB recommendation is superseded. Require **20–25 GB safe Windows C: free space** before retrying 26.05.

## External gates still open

- User human visual review of v0.5.
- Koha 26.05 runtime matrix after safe disk headroom exists.
- Institutional non-production staging.
- Explicit production backup/change-window/release authorization.

These are external/environmental release gates, not unfinished v0.5 local coding tasks.

## Important preserved development data

Campaign 40 remains a retained multi-location visual/analytics fixture. It already had a submitted recommendation. The revised workflow smoke deliberately uses a synthetic campaign so it does not delete or overwrite this retained evidence.

## Project Brain references

Read in this order before further work:

1. `AGENTS.md`
2. `docs/brain/PROJECT_OVERVIEW.md`
3. `docs/brain/CURRENT_STATE.md`
4. `docs/brain/SESSION_HANDOFF.md`
5. `docs/brain/ISSUES.md`
6. `docs/brain/ROADMAP.md`
7. `docs/brain/DECISIONS.md`
8. `docs/brain/ANALYTICS_SPEC.md`
9. `docs/brain/V0.5_ANALYTICS_INTELLIGENCE.md`
10. `docs/brain/TESTING.md`
11. `.project-memory/state.yaml`
12. current Git/runtime state

## Exact next action

The software is ready for the user's visual review. Do not make additional metric changes merely for novelty. Address only evidence-based visual/logic findings from the review, then retest the affected surface plus full regression before any package replacement.

After sufficient disk headroom is available, create a **dedicated disposable** Koha 26.05 project and run the matrix in `docs/UPGRADE_SURVIVAL_AUDIT.md`; do not modify `promoeng`.

## Continuation prompt

> Continue Koha Promotion & Engagement from the repository Project Brain. Read `AGENTS.md`, `SESSION_HANDOFF.md`, `SESSION_LOG.md`, current state/YAML, inspect Git/KTD runtime, and continue from the exact verified next action without relying on old chat history.
