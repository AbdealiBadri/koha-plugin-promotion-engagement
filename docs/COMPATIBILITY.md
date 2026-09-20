# Compatibility Matrix

| Plugin version | Koha version | Evidence | Status |
|---|---|---|---|
| 0.4.0 development | 25.11.02 KTD | 72 automated assertions, authenticated render, complete Suggestions workflow smoke and exact-KPZ clean installation | PASS locally |
| 0.4.0 development | 26.05.x | Not yet executed | REQUIRED |
| 0.4.0 development | Institutional staging | Not yet executed | REQUIRED |
| 0.4.0 development | Production | Not authorized | BLOCKED |

A local PASS does not guarantee compatibility with local themes, permissions,
data volumes or customizations. Test the exact KPZ in staging and maintain a
database backup and rollback plan before production use.
