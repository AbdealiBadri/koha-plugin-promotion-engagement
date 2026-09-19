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
