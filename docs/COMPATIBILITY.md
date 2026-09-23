# Compatibility Matrix

| Plugin version | Koha version | Evidence | Status |
|---|---|---|---|
| 0.5.0 development candidate | 25.11.02 KTD | 113 automated assertions; Perl/shell/schema checks; exact authenticated KPZ upload/upgrade; seven tables; authenticated Dashboard/Promotions/Analytics/Reports/Configuration/Resource Impact browser matrix; native Suggestion workflow and cleanup | **PASS locally** |
| 0.5.0 development candidate | 26.05.x | Code/dependency audit favorable; 2026-09-21 dedicated image pull retried from ~16 GB free but stopped when layer expansion reduced Windows C: to ~11 GB before completion | **RUNTIME BLOCKED — disk capacity** |
| 0.5.0 development candidate | Institutional staging | Not yet executed | **REQUIRED** |
| 0.5.0 development candidate | Production | v0.5 not formally accepted/deployed by this development session | **BLOCKED pending release gates** |

## Exact local package evidence

Artifact:

PromotionEngagement-v0.5.0.kpz

SHA-256:

931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670

The exact package was uploaded through Koha's authenticated plugin uploader into isolated promoeng on Koha 25.11.02 and then exercised through the major staff screens and native Koha Suggestions workflow.

## Forward-test host requirement

The previous 12–15 GB free-space estimate proved insufficient on this Windows/WSL/Docker host. Do not retry the Koha 26.05 image/runtime matrix until at least **20–25 GB of safe Windows C: free space** is available.

Do not use global Docker pruning or remove unrelated project containers/volumes as a compatibility-test workaround.

## Interpretation

A local PASS does not guarantee compatibility with institutional themes, permissions, data volume or local customizations. Test the exact KPZ on a non-production copy and keep a restorable database backup plus rollback plan before a production upgrade.

See docs/UPGRADE_SURVIVAL_AUDIT.md for the module matrix, watch points and exact upgrade/rollback procedure.
