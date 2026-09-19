# New Session Bootstrap Prompt

Use this short prompt in any new ChatGPT/Codex/Claude/Cursor session:

---

Continue the **Koha Promotion & Engagement** project from repository `AbdealiBadri/koha-plugin-promotion-engagement`.

Do **not** rely on the previous chat. The repository Project Brain is the durable source of truth.

Before changing anything:
1. Read root `AGENTS.md`.
2. Read `docs/brain/PROJECT_OVERVIEW.md`, `CURRENT_STATE.md`, `SESSION_HANDOFF.md`, `SESSION_LOG.md`, `ISSUES.md`, `ROADMAP.md`, and `TESTING.md`.
3. Read relevant `ARCHITECTURE.md`, `DATA_MODEL.md`, `DECISIONS.md`, `PRD.md`, `DEPLOYMENT.md`, and `DEVELOPMENT_GUIDE.md`.
4. Read `.project-memory/state.yaml`, `modules.yaml`, `issues.yaml`, and `decisions.yaml`.
5. Inspect the current Git branch, working tree, recent commits, local KTD/Docker state, and relevant source files.
6. Reconcile any contradiction using the source-of-truth hierarchy in `AGENTS.md`.
7. Tell me briefly: verified current state, current blocker, active module, and exact next action.
8. Continue from that exact point without asking me to restate old history unless a genuinely unresolved fact is required.
9. Keep unrelated repositories/containers untouched.
10. Before every handoff, update Project Brain and append material work/results to `SESSION_LOG.md`.

Do not deploy to production, alter Koha core, destroy historical plugin data, run global Docker cleanup, or introduce unapproved schema/architecture changes just to bypass a local development problem.

---

## User-facing continuity rule

For this project, after a material Project Brain update has actually been persisted, progress replies should include:

**The document is updated.**

Then include the short continuation prompt above, or the one-line version:

> Continue Koha Promotion & Engagement from the repository Project Brain. Read `AGENTS.md`, `SESSION_HANDOFF.md`, `SESSION_LOG.md`, current state/YAML, inspect Git/KTD runtime, and continue from the exact verified next action without relying on old chat history.
