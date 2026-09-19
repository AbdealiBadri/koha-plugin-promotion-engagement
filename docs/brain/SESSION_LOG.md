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
- Planned isolated KTD project name: `promoeng`; unrelated repositories and containers must remain untouched.

### Continuity hardening
- Added repository rule requiring a chronological `SESSION_LOG.md`.
- Added explicit chat-limit/new-session recovery protocol to `AGENTS.md`.
- Updated `NEW_SESSION_PROMPT.md` with a short durable continuation prompt.
- Added rule prohibiting global Docker cleanup when unrelated projects may share the same Docker/WSL host.

### Current next action
Create and verify a dedicated `promoeng` KTD instance using only the Promotion & Engagement plugin path, confirm it reaches KTD READY, then resume the remaining v0.2 security/checkpoint tests and module-by-module completion.
