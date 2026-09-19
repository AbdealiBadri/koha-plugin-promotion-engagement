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
