# AI Agent Operating Instructions

This repository is the durable project memory for **Koha Promotion & Engagement**. Do not rely on an old chat transcript as the primary source of truth.

## Before making changes

Read, at minimum, in this order:

1. `docs/brain/PROJECT_OVERVIEW.md`
2. `docs/brain/CURRENT_STATE.md`
3. `docs/brain/SESSION_HANDOFF.md`
4. `docs/brain/ISSUES.md`
5. `docs/brain/ROADMAP.md`
6. relevant sections of `docs/brain/ARCHITECTURE.md`
7. relevant records in `docs/brain/DECISIONS.md`
8. `docs/brain/TESTING.md`
9. `.project-memory/state.yaml`
10. current Git branch, `git status`, recent commits, and the source files relevant to the task.

Also consult existing project references when relevant: `README.md`, `docs/ARCHITECTURE.md`, `docs/SAFETY.md`, `docs/REAL_WORLD_USE_CASES.md`, `docs/KPZ_TEST_PLAN.md`, and checkpoint-specific test documents.

## Source-of-truth hierarchy

When sources conflict, investigate rather than silently choosing the most convenient one. Use this authority order:

1. Current application source code and current database migrations/schema code.
2. Accepted engineering decisions in `docs/brain/DECISIONS.md` that have not been superseded.
3. Verified runtime evidence: executed tests, logs, database queries, screenshots, and release artifacts.
4. `docs/brain/CURRENT_STATE.md` and `.project-memory/state.yaml`.
5. Approved requirements in `docs/brain/PRD.md`.
6. Test plans and historical repository documentation.
7. Old chat transcripts or recollections.

A chat statement must never override verified current implementation without investigation.

## Non-negotiable project safeguards

- Koha remains the source of truth for catalogue, item, patron, branch, and circulation data.
- Do not patch Koha core or add plugin-specific columns to Koha core tables.
- Store plugin data only in namespaced plugin-owned structures.
- Do not silently destroy historical promotion data on uninstall.
- Do not put credentials, passwords, tokens, private keys, cookies, or secrets in source or Project Brain files.
- Do not hard-code Nairobi-specific campaign names, locations, languages, branch codes, or staff names into universal plugin logic.
- Do not mark a test PASS unless it was actually executed and the result was observed.
- Do not deploy to production without the documented KTD, compatibility, staging, backup, and KPZ release gates.
- Do not expose patron-identifiable analytics to general/external dashboards without an explicitly approved privacy design.

## Evidence discipline

For material claims, distinguish:

- `VERIFIED-CODE` — confirmed in current source.
- `VERIFIED-RUNTIME` — confirmed by executed test/log/database evidence.
- `APPROVED-REQUIREMENT` — explicitly approved but not necessarily implemented.
- `INFERRED` — plausible but not proven.
- `NEEDS-VERIFICATION` — evidence is incomplete or contradictory.

Do not convert `INFERRED` or `NEEDS-VERIFICATION` into fact.

## Development workflow

Before editing code:

- confirm the branch;
- confirm the working tree is clean or understand every local change;
- inspect the current implementation before proposing replacement code;
- read related issue, decision, data-model, and test records;
- preserve backwards compatibility and historical plugin data unless an approved migration says otherwise.

For schema changes, require an idempotent upgrade path and document rollback/backup implications.

For API or analytics changes, keep staff UI and external API calculations on shared business rules so figures cannot diverge.

## Definition of Done includes Project Brain maintenance

A feature is not complete merely because code was written. When relevant, update the affected memory files:

- `docs/brain/CURRENT_STATE.md`
- `docs/brain/SESSION_HANDOFF.md`
- `docs/brain/ISSUES.md`
- `docs/brain/TESTING.md`
- `docs/brain/DECISIONS.md`
- `docs/brain/ROADMAP.md`
- `docs/brain/DATA_MODEL.md`
- `docs/brain/SESSION_LOG.md`
- `.project-memory/state.yaml`
- `.project-memory/modules.yaml`
- `.project-memory/issues.yaml`
- `.project-memory/decisions.yaml`

Do not mechanically rewrite every document after a trivial change; update only knowledge materially affected by the change.

## Continuity and chat-limit protocol

- The repository Project Brain is the continuity mechanism if a ChatGPT conversation ends or reaches its context limit.
- Maintain `docs/brain/SESSION_LOG.md` as a chronological engineering log of material actions, commands/tests, observed results, decisions, blockers, and next actions.
- Update `docs/brain/SESSION_HANDOFF.md` whenever the current blocker, active module, branch, environment, or next action changes.
- In user-facing progress replies for this project, explicitly state: **"The document is updated."** only after the relevant Project Brain update has actually been committed or otherwise persisted.
- Include the short continuation prompt from `docs/brain/NEW_SESSION_PROMPT.md` in progress/handoff replies so the user can recover immediately in a new chat.
- Do not claim documentation is updated if the write/commit failed.
- Prefer dedicated project-specific KTD/container names and never run global Docker cleanup commands when unrelated projects may share Docker/WSL.

## Before ending a development session

1. Re-run the tests relevant to the code changed.
2. Record actual results, not expectations.
3. Update open/closed issue status with evidence.
4. Record any architectural/product decision made during the session.
5. Update the exact current blocker and next action.
6. Update `SESSION_HANDOFF.md` so another agent can continue without the previous conversation.
7. Ensure Markdown and YAML state agree.
8. Append the session's material actions and results to `SESSION_LOG.md`.

## Current branch caution

The repository default branch is `main`, but active v0.2 development has been occurring on `feature/v0.2-campaign-crud`. Always inspect branch state before assuming `main` represents the latest implementation.