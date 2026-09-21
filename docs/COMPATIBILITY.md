# Compatibility Matrix

| Plugin version | Koha version | Evidence | Status |
|---|---|---|---|
| 0.4.1 development | 25.11.02 KTD | 81 automated assertions, syntax/render/report/workflow checks and prior exact-KPZ clean installation | PASS locally |
| 0.4.1 development | 26.05.x | Code/dependency audit complete; runtime image pull stopped safely because host disk space fell below 1 GB | RUNTIME BLOCKED — disk capacity |
| 0.4.1 development | Institutional staging | Not yet executed | REQUIRED |
| 0.4.1 development | Production | Not authorized | BLOCKED |

A local PASS does not guarantee compatibility with local themes, permissions,
data volumes or customizations. Test the exact KPZ in staging and maintain a
database backup and rollback plan before production use. See
[`UPGRADE_SURVIVAL_AUDIT.md`](UPGRADE_SURVIVAL_AUDIT.md) for the module matrix,
watch points and exact upgrade/rollback procedure.
