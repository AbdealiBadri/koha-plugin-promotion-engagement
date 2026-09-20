# Installation SOP — Koha Promotion & Engagement

This SOP is written for a Koha administrator who may not be a developer.

## Before you begin

1. Confirm that the Koha version is listed as supported in the release notes.
2. Use a test or staging Koha first. Do not begin with production.
3. Confirm that Koha plugins are enabled and that the plugin directory is configured.
4. Sign in with a staff account permitted to manage plugins.
5. Take a database backup using your institution's approved procedure.
6. Download the versioned `.kpz` file and its `.sha256` checksum from the GitHub release.
7. Keep the KPZ, checksum, backup location and maintenance-window approval together.

## Verify the downloaded package

On Linux, open a terminal in the download folder and run:

```bash
sha256sum PromotionEngagement-v0.4.0.kpz
```

Compare the displayed value with the contents of the supplied checksum file.
If the values differ, stop. Download the files again from the official release.
Do not install a package whose checksum does not match.
## Install through Koha

1. Sign in to the Koha staff interface.
2. Open **Administration**.
3. Open **Manage plugins**.
4. Select **Upload plugin**.
5. Click **Choose file**.
6. Select `PromotionEngagement-v0.4.0.kpz`.
7. Click **Upload**.
8. Koha will show the uploaded package and request confirmation.
9. Confirm the installation.
10. Wait for Koha to return to the plugins list.
11. Find **Promotion & Engagement**.
12. Confirm that the displayed version is **0.4.0** and that no load error is shown.
13. If the plugin is disabled, choose its enable action.
14. Use **Run tool** to open the dashboard.

## First configuration

1. In the plugin sidebar, open **Configuration**.
2. Review campaign types and channels.
3. Add each reusable display location used by your institution.
4. Use neutral, recognizable names such as “Main Entrance” or “First Floor.”
5. Add languages and audiences only when they will be used consistently.
6. Save each value and confirm that its success message appears.
7. Avoid creating two codes for the same meaning.
8. Return to the dashboard.
## Confirm the installation

Perform these checks in order:

1. Open **Dashboard**. It must show without a template error.
2. Open **New promotion**. Campaign Type and Channel must be selectable.
3. Open **Promotions**. Search and status filters must appear.
4. Open **Analytics**. A campaign selector and Calculate button must appear.
5. Open **Book Display Impact**. The page heading and campaign selector must appear.
6. Open **Reports**. Comparative tables and export actions must appear.
7. Create a small test campaign using one valid Koha barcode.
8. Open its detail page and confirm the title and barcode.
9. Open Analytics and confirm the test campaign can be selected.
10. Open Book Display Impact and confirm the displayed title appears.
11. Archive the temporary campaign when the checks finish.

## If something does not appear

- If the plugin is missing, confirm `enable_plugins` and the configured plugin directory.
- If Koha reports a load error, verify the KPZ checksum and supported Koha version.
- If a new page is missing after an upgrade, restart Plack using your normal Koha procedure.
- If barcodes are rejected, confirm the exact barcode in Koha Cataloging.
- If analytics are empty, confirm that the campaign has linked items and valid dates.
- If Suggestions submission is denied, grant the staff member Koha's purchase-suggestion permission.
- If the page says a recommendation was already submitted, open the recorded Koha suggestion instead of resubmitting.
- Never weaken CSRF or staff permissions to bypass an error.
## Upgrade

1. Read the release notes and compatibility matrix.
2. Back up the Koha database.
3. Record the currently installed plugin version.
4. Download and checksum the new KPZ.
5. Use **Administration → Manage plugins → Upload plugin**.
6. Upload the new package and confirm the upgrade.
7. Confirm the new version on the plugins page.
8. Open every main plugin page.
9. Confirm that older campaigns, locations, links and audit records remain.
10. Run the acceptance checklist for the upgraded module.

## Disable, uninstall and rollback

Disabling the plugin does not intentionally delete its historical tables.
Uninstall is also non-destructive in this release, but a database backup remains mandatory.
For rollback, restore the approved database backup and reinstall the previously approved KPZ.
Do not manually drop plugin tables unless following a separately reviewed data-purge procedure.

## Production authorization

Installation passing on a local KTD environment is not production authorization.
Production requires the supported-version test, institutional staging approval,
database-backup ownership, rollback owner and an approved maintenance window.
