# Session Log

Chronological engineering log for durable project continuity. Record only material actions, observed results, decisions, blockers, and next actions. Do not store secrets.

## 2026-09-19

### Environment/access verification
- Desktop Commander device `C0158` verified online with valid connection.
- WSL Debian verified available: Linux/WSL2 responded successfully.
- Docker Engine verified running; server version reported `29.7.2`.
- Internet/GitHub connectivity already available through connected GitHub tooling.
- Current local plugin repository verified at `~/git/plugins/koha-plugin-promotion-engagement`.
- Current local branch verified as `feature/v0.2-campaign-crud`; working tree was clean at inspection time.
- KTD inspection showed legacy instance `kohadev` in exited state; only `kohadev-db-1` and shared proxy were running at direct Docker inspection time.
- `ktd --list` subsequently confirmed `kohadev [Exited (1)]`.
- Decision: do not use generic `kohadev` as the long-term isolated environment for this plugin while other projects share WSL/Docker.

### Dedicated project isolation
- Created dedicated KTD project `promoeng` with the single plugin mounted from `~/git/plugins/koha-plugin-promotion-engagement`.
- Created `promoeng_kohanet`, `promoeng-db-1`, `promoeng-memcached-1`, and `promoeng-koha-1`.
- Verified all three `promoeng` containers are Up.
- Verified `promoeng-intra.localhost` returns HTTP 200.
- Verified KTD startup log reports `koha-testing-docker has started up and is ready to be enjoyed!`.
- Verified startup discovered and installed Promotion & Engagement version 0.2.0.
- Legacy `kohadev` remains exited and is not the primary environment for future tests.
- No unrelated project container was stopped or removed.

### Continuity hardening
- Added repository rule requiring a chronological `SESSION_LOG.md`.
- Added explicit chat-limit/new-session recovery protocol to `AGENTS.md`.
- Updated `NEW_SESSION_PROMPT.md` with a short durable continuation prompt.
- Added rule prohibiting global Docker cleanup when unrelated projects may share the same Docker/WSL host.
- Updated `SESSION_HANDOFF.md` and `.project-memory/state.yaml` to make `promoeng` the primary test environment.

### Current next action
Run T-131 invalid-CSRF rejection, T-132 plugin tool-permission denial, and T-133 API catalogue-permission denial against `promoeng`. Record runtime evidence, close v0.2 Checkpoint 1 if all pass, then continue into campaign read/detail and subsequent modules.

### Clarification on environment naming
- `promoeng` is only the dedicated KTD/Docker project name/container namespace for this plugin; it is not a new source-code repository or duplicate project folder.
- Existing source folders remain unchanged: `~/git/plugins/koha-plugin-promotion-engagement` for the plugin and `~/git/koha-testing-docker` for KTD.
- The older `kohadev` KTD instance is separate from the source folders and is no longer the primary runtime for this plugin.

### Visual monitoring protocol
- User asked to visually monitor ongoing work instead of following terminal commands.
- Added a repository rule: every active module must report current status, exact local Koha review page/URL, relevant Docker/KTD names, and separate Built/Tested/Ready-for-visual-check states.
- Current active work remains v0.2 security checkpoint (T-131/T-132/T-133) in the isolated `promoeng` runtime before feature expansion.

### Live plugin status check
- `promoeng` KTD instance remains Up; `promoeng-koha-1`, `promoeng-db-1`, and `promoeng-memcached-1` are running.
- Live request to `http://promoeng-intra.localhost/api/v1/contrib/ajsn_promotion/health` returned Mojolicious `Page Not Found` rather than the plugin health JSON.
- Source still contains `/health` in `openapi.json` and the `API/Health.pm` controller.
- Therefore v0.2 Checkpoint 1 is **not yet closed**: API route registration/loading in the isolated `promoeng` runtime is the current blocker and must be fixed before T-131/T-132/T-133 can be completed reliably.
- Next action: diagnose plugin API route registration in `promoeng`, restore the health endpoint, then execute the remaining security matrix.

### API route blocker resolved
- Diagnosed `promoeng` health-route 404 as stale Plack routing after plugin installation/startup; KTD log had shown `Plack already running for kohadev: failed!`.
- Restarted Plack inside `promoeng-koha-1` using `sudo koha-plack --restart kohadev`.
- Re-tested `GET http://promoeng-intra.localhost/api/v1/contrib/ajsn_promotion/health` without authentication.
- Result: HTTP 401 with `{"error":"Authentication failure."}`. This proves the plugin route is now registered and Koha authorization is active.
- Current next action: execute T-131/T-132/T-133 security matrix against the now-correct `promoeng` runtime.

### Security checkpoint continuation
- Confirmed the plugin API route is registered after Plack restart.
- Attempted an authenticated health check using the generic KTD `.env` `KOHA_USER/KOHA_PASS` pair via HTTP Basic auth.
- Result: HTTP 403 with `Invalid password`; therefore the generic environment credentials are not a valid API test identity for this Koha runtime.
- No plugin code change was made from this failed credential test.
- Next action: use/create dedicated Koha test identities with explicit permission sets for T-132/T-133, and complete T-131 with the normal authenticated staff workflow. Do not weaken permissions or CSRF for testing.

### Test identity plan
- Dedicated permission-test identities will be created directly inside the isolated `promoeng` Koha test environment using Koha-supported patron/permission mechanisms rather than manual UI entry where possible.
- No user action is required for creating these temporary test identities.
- Test identities must remain confined to `promoeng`, use clearly recognizable test names, receive only the minimum permissions needed for T-132/T-133, and be removed or disabled after verification.
- Manual user involvement is only needed if a visual browser confirmation is specifically required after the automated/runtime test passes.

### Security checkpoint progress — 2026-09-19
- T-133 is now PASS in the isolated `promoeng` runtime.
- Used existing KTD test identity `term1` (original flags = 2, no `catalogue` permission) against `GET /api/v1/contrib/ajsn_promotion/health`.
- HTTP Basic authentication succeeded and Koha returned HTTP 403 with `Authorization failure. Missing required permission(s).` and required permission `{"catalogue":"1"}`.
- This distinguishes T-133 from the unauthenticated 401 test and proves the endpoint permission gate is active.
- Temporarily changed `term1` flags from 2 to 6 only to prepare a lower-permission staff scenario for T-132, then restored flags back to the original value 2 after credentialed browser automation was blocked by the remote execution safety layer. No permanent account/permission change remains.
- T-131 and the full end-to-end T-132 browser denial test remain open. Code inspection confirms plugin `run.pl` requires `plugins => tool`, and the campaign form uses Koha's `cud-` operation plus generated CSRF token, but these are not yet counted as PASS without end-to-end evidence.

### Immediate next work
- User confirmed continuation.
- Immediate active task: T-131, an end-to-end forged/missing CSRF submission against the campaign-create workflow in the isolated `promoeng` environment, with verification that no campaign row is written.
- After T-131: run T-132 plugin-tool permission denial, then one authorized campaign-creation smoke test. If all three are clean, close v0.2 Checkpoint 1 and move to runtime-testing Draft PR #1 (Campaign List + Campaign Detail).

### Local KTD login reminder
- User requested the local `promoeng` Koha staff login reminder for visual testing.
- Credentials are intentionally **not** written into Project Brain or source control. Use the local KTD environment values only.

### Campaign read acceptance and session isolation — 2026-09-19
- T-131, T-132, T-133 and T-134 all passed; v0.2 Checkpoint 1 is closed.
- Campaign read runtime suite CR-01 through CR-07 passed in isolated promoeng.
- Human visual review passed for the Promotions list, linked-item campaign detail, zero-item campaign detail and audit display.
- User initially observed repeated Koha session-timeout prompts when entering through the plugin/deep-link login path.
- User then logged in through the normal Koha staff homepage and confirmed navigation no longer logged out.
- Therefore the repeated-login behavior is isolated to stale/deep-link browser session state in the test environment and is not treated as a plugin CSRF regression.
- feature/v0.2-campaign-read was synchronized with the advanced feature/v0.2-campaign-crud base; documentation conflicts were resolved in favor of the latest verified runtime state.
- CR-01 through CR-07 were rerun after the sync and all passed again.
- Immediate next action: merge Draft PR #1, then begin Edit / Update / Archive.

### Campaign management transition — 2026-09-19
- Draft PR #1 (Campaign List + Campaign Detail) was marked ready and merged successfully into feature/v0.2-campaign-crud.
- Merge commit: 21a209fff1709743657393b6a849fd4cc89aa151.
- Local base branch was fast-forwarded to the merged state.
- Created new working branch: feature/v0.2-campaign-edit-archive.
- Immediate implementation scope: Edit campaign, Update campaign, controlled status transitions, Archive/soft-delete, and audit rows for each write action.
- Existing create/read behavior and Koha source-of-truth rules must remain unchanged.

### Immediate hurdle clarified — 2026-09-19
- Current milestone is Edit / Update / Archive.
- Success gate: edit existing campaign data safely, enforce the same validation/integrity rules as create, record audit history for changes/status transitions, archive via soft-delete using deleted_at rather than destructive deletion, and keep Create/List/Detail regressions green.
- After this gate, the next hurdle is universal configuration plus multi-location campaigns.

### Edit / Update / Archive runtime gate completed — 2026-09-19
- Added pre-filled Edit Promotion screen.
- Added transactional update with current create-equivalent validation rules.
- Added item reconciliation: new links insert, removed links soft-delete, removed links can reactivate without duplicates.
- Added audit actions `campaign_updated`, `campaign_status_changed`, and `campaign_archived`.
- Added Archive POST with Koha CSRF, explicit confirmation, campaign soft-delete and active item-link soft-delete.
- Hardened dashboard linked-item count so archived links are excluded.
- EA-01 through EA-13 PASS.
- Forged-CSRF update/archive requests return HTTP 403 with no state change.
- Invalid status values are rejected.
- CR-01 through CR-07 regression suite PASS after final changes.
- Perl syntax OK; git diff check clean; no new Plack/intranet application errors observed.
- Retained visual fixture EDIT-VISUAL-20260919, campaign_id 13, status active, one linked item, three audit rows.
- Next action: human visual acceptance, then final regression and merge.

### Draft PR for Edit / Update / Archive
- Draft PR #2 opened: v0.2 campaign edit/update/archive lifecycle.
- Automated/runtime gate is green; only human visual acceptance of EDIT-VISUAL-20260919 remains before merge.

### Edit / Update / Archive human acceptance — 2026-09-19
- User supplied screenshots of campaign detail and Edit Promotion.
- Visual acceptance PASS: Edit and Archive actions visible; live linked-item data and audit history render; edit form is fully pre-filled including barcode.
- Normal Koha staff login kept navigation/session stable.
- Non-blocking polish noted: friendly display labels for machine values and stronger status badge contrast can be addressed later.
- Final post-visual regression rerun PASS: EA lifecycle suite, EA CSRF/security suite, dashboard archive-count test, and CR-01..CR-07.
- Draft PR #2 is cleared for merge.

### Transition to Universal Configuration + Multi-location — 2026-09-19
- User screenshots confirmed Edit / Update / Archive visual acceptance.
- Final EA lifecycle/security/dashboard-count and CR-01..CR-07 regression passed.
- PR #2 merged successfully into feature/v0.2-campaign-crud as commit 82a69d4.
- Created active branch feature/v0.2-config-multilocation.
- Reviewed TECHDEBT-007/008, PRD, architecture and decisions before changing the configuration model.
- Accepted DEC-019: plugin-managed universal vocabularies are canonical for promotion configuration; Koha Authorized Values may be an optional source later, but no Koha core changes are required.
- Multi-location will use a normalized namespaced campaign-to-location relation with reusable configured locations and soft-remove semantics.
- Existing legacy campaign fields remain during migration to preserve current records.

### Universal configuration foundation implemented — 2026-09-19
- Added plugin_ajsn_promo_vocab_values for reusable campaign type, channel, location, language, audience and cadence values.
- Added plugin_ajsn_promo_campaign_locations as the normalized campaign-to-location relation table.
- Seeded only the existing generic campaign type/channel values; no Nairobi-specific values were added.
- Replaced the foundation-only Configure page with writable configuration management for stable code, label, sort order and active/disabled state.
- CFG-01 through CFG-07 PASS, including forged-CSRF rejection and invalid-code validation.
- Re-ran CR-01..CR-07, EA lifecycle/security and archive-count suites; all remain PASS.
- Immediate next action: adopt configured type/channel values in campaign forms and implement multi-location Create/Edit persistence/rendering with legacy fallback.

### Multi-location campaign integration runtime gate completed — 2026-09-19
- New/Edit Campaign Type and Channel selectors now read plugin configuration instead of hard-coded option lists.
- New/Edit Location now supports multiple reusable configured locations.
- Campaign creation writes normalized campaign-location links transactionally.
- Campaign update reconciles location additions, removals and reactivations transactionally and records added/removed location IDs in audit details.
- Promotions list and Campaign Detail render friendly configured Type/Channel labels and multiple location labels.
- Existing legacy display_location remains as a backward-compatible fallback.
- Disabled locations already linked to an existing campaign remain visible during edit; normal create flow does not offer disabled locations.
- Campaign archive also soft-deletes active campaign-location links.
- ML-01 through ML-08 PASS.
- CFG-01 through CFG-07, CR-01 through CR-07, and EA lifecycle/security/archive-count suites all PASS after final Plack reload.
- Retained visual fixture MULTILOC-VISUAL-20260919, campaign_id 40, with Main Entrance, First Floor and Digital Screen.
- Next action: human visual acceptance, then final regression and merge. Analytics Engine follows.
- Draft PR #3 opened for Universal Configuration + Multi-location. Automated CFG/ML/CR/EA gates are green; human visual acceptance of campaign 40 is the remaining merge gate.

### Multi-location visual review — detail screen PASS — 2026-09-19
- User supplied screenshot of MULTILOC-VISUAL-20260919 campaign detail (campaign ID 40).
- Visual PASS for configured friendly Type/Channel labels and all three locations: Main Entrance, First Floor, Digital Screen.
- Screenshot exposed weak contrast for the status/location badge styling under this Koha theme.
- Replaced faint badges on Campaign Detail with readable plain text/strong status presentation; no data-model change.
- Re-ran ML-01..ML-08 and CR-01..CR-07 after the presentation change; all PASS.
- Remaining human gate: open Edit Promotion for campaign 40 and confirm the three locations are pre-selected in the multi-select.

### Multi-location visual acceptance and runtime closure — 2026-09-19
- User supplied the Edit Promotion screenshot for MULTILOC-VISUAL-20260919, campaign ID 40.
- Visual PASS: Main Entrance, First Floor and Digital Screen are all pre-selected.
- Detail and Edit visual gates are therefore complete.
- Branch `feature/v0.2-config-multilocation` is clean and synchronized at `a3e2fe4`.
- Dedicated `promoeng-koha-1`, `promoeng-db-1` and `promoeng-memcached-1` are Up; intranet returns HTTP 200.
- Plugin Perl syntax check: PASS.
- Runtime SQL confirms campaign 40 is active and has exactly three active normalized location links matching the visual evidence.
- Existing post-readability-change ML-01..ML-08 and CR-01..CR-07 regression remains PASS; prior CFG and EA regression gates remain PASS.
- Draft PR #3 is cleared for merge.
- Exact next action: commit/push Project Brain closure, merge PR #3, then begin Analytics Engine KPI/attribution design.

### PR #3 merge and Analytics Engine transition — 2026-09-19
- Visual-acceptance closure committed and pushed as `08306c5`.
- PR #3 body updated with complete automated, runtime and human evidence.
- PR #3 marked ready and merged into `feature/v0.2-campaign-crud` as `17915cd`.
- Local base fast-forwarded to the merged commit.
- Created active branch `feature/v0.3-analytics-engine`.
- Inspected live Koha schemas: `issues`, `old_issues`, `statistics` and plugin campaign-item links.
- Isolated `promoeng` currently has zero circulation rows; v0.3 correctness will use transaction-scoped synthetic fixtures.
- Accepted DEC-020 and created `ANALYTICS_SPEC.md`: issues/old_issues checkout source, equal-duration baseline, inclusive campaign period through half-open ranges, 7/14/30/60 After windows, distinct-item conversion, null uplift on zero baseline, transparent overlap attribution, portfolio de-duplication and privacy suppression below five borrowers.
- Exact next action: implement the shared Analytics Engine service and execute AN-01..AN-15 before dashboard UI.

### Analytics Engine first implementation checkpoint — 2026-09-19
- Added shared `Analytics.pm` service using Koha `issues` + `old_issues` and fixed campaign item cohorts.
- Added exact Baseline, During and After 7/14/30/60 windows, conversion, daily rate, absolute delta, uplift and days-to-first-checkout.
- Added Koha-native Analytics page, campaign selector, KPI cards, measurement-window table and aggregate-only privacy notice.
- Enabled Analytics navigation from Dashboard, Promotions and Campaign Detail.
- Campaign 40 no-circulation smoke: PASS with one eligible item, valid 12-day Baseline/During windows, zero checkouts and null uplift.
- Added rollback-safe `t/analytics_engine.t`; 23 assertions PASS covering AN-01..AN-10 behavior.
- Verified rollback left zero synthetic rows in `issues`, `old_issues` and plugin campaigns.
- Main plugin and Analytics module Perl syntax: PASS; git diff check PASS; Plack restart PASS.
- Exact next action: human visual confirmation of campaign 40 Analytics page, then implement AN-11..AN-15.
