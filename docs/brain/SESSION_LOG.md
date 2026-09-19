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
