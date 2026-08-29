# New Session Bootstrap Prompt

Copy/paste the following into a completely new AI/coding-agent conversation:

---

I want you to continue development of the **Koha Promotion & Engagement** project in the repository `AbdealiBadri/koha-plugin-promotion-engagement`.

**Do not rely on previous chat history. The repository Project Brain is the persistent project memory.**

Before proposing or changing code:

1. Identify and verify the repository and available branches.
2. Read root `AGENTS.md` completely.
3. Read at minimum:
   - `docs/brain/PROJECT_OVERVIEW.md`
   - `docs/brain/CURRENT_STATE.md`
   - `docs/brain/SESSION_HANDOFF.md`
   - `docs/brain/ISSUES.md`
   - `docs/brain/ROADMAP.md`
   - `docs/brain/TESTING.md`
   - relevant `ARCHITECTURE.md`, `DATA_MODEL.md`, `DECISIONS.md`, `PRD.md`, `DEPLOYMENT.md` and `DEVELOPMENT_GUIDE.md` sections.
4. Read `.project-memory/state.yaml`, `modules.yaml`, `issues.yaml`, and `decisions.yaml`.
5. Inspect the current Git branch, working-tree state, recent relevant commits and actual source files.
6. Reconcile any contradiction between Project Brain, source code, runtime evidence and older repository docs using the source-of-truth hierarchy in `AGENTS.md`.
7. Identify the current milestone, unresolved blocker and exact next action.
8. Briefly tell me what you believe the verified project state is, what is blocked, and what you will do next.
9. Then continue the project from that exact point without asking me to re-explain old history unless a genuinely unresolved fact is required.
10. At the end of the session, update the affected Project Brain files and YAML state as part of Definition of Done.

Do not deploy to production, alter Koha core, destroy historical plugin data, or introduce unapproved schema/architecture changes merely to bypass a local development problem.

---