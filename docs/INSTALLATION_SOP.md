# Installation SOP — Koha Promotion & Engagement

This SOP is written for a Koha administrator who may not be a developer.

## Current candidate

Plugin candidate: **0.5.0**

Locally verified runtime: **Koha 25.11.02**

Exact locally tested package:

PromotionEngagement-v0.5.0.kpz

SHA-256:

931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670

Koha 26.05 runtime validation is not yet complete. Do not interpret the primary-version PASS as automatic forward compatibility.

## Before you begin

1. Confirm that your Koha version is listed in docs/COMPATIBILITY.md.
2. Use a test/staging Koha first whenever possible.
3. Confirm that Koha plugins are enabled and the plugin directory is configured.
4. Sign in with a staff account permitted to manage plugins.
5. Take a complete database backup using your institution's approved procedure.
6. Keep the KPZ file, checksum, backup location and change authorization together.
7. Record the currently installed plugin version before upgrading.
8. Do not delete plugin tables as part of a normal upgrade.

## Verify the package

On Linux:

    sha256sum PromotionEngagement-v0.5.0.kpz

For the locally verified candidate, the value must be:

    931e79ec2a9bf210f6a35f8cdd0f858cf76c9d4f77ccf121cf692f92dc86d670

If the checksum differs from the approved release/checksum supplied for your deployment, stop.

## Install or upgrade through Koha

1. Sign in to the Koha staff interface.
2. Open **Administration**.
3. Open **Manage plugins**.
4. Select **Upload plugin**.
5. Choose PromotionEngagement-v0.5.0.kpz.
6. Click **Upload**.
7. Confirm the installation/upgrade when Koha asks.
8. Return to the plugins list.
9. Find **Promotion & Engagement**.
10. Confirm displayed version **0.5.0** and no plugin load error.
11. Enable the plugin if the approved environment requires it.
12. Use **Run tool** to open the dashboard.

## First configuration

1. Open **Configuration** from the plugin sidebar.
2. Review campaign types and channels.
3. Add reusable display/promotion locations used by the institution.
4. Use stable recognizable labels such as “Main Entrance” or “First Floor.”
5. Add languages/audiences only when they will be used consistently.
6. Save each value and verify the success message.
7. Do not create duplicate codes for the same meaning.

## Confirm the main screens

Open these pages before creating any acquisition workflow action:

1. **Dashboard**
2. **New promotion**
3. **Promotions**
4. **Analytics**
5. **Resource Impact**
6. **Reports**
7. **Configuration**

No page should show Template process failure or Internal Server Error.

### Dashboard should show

- Promoted titles;
- Titles used;
- Title utilization;
- Campaign checkouts with baseline context;
- Zero-response titles;
- Active campaigns.

### Analytics should show

- Promoted titles and linked copies/items;
- Titles used;
- Title utilization;
- Campaign checkouts;
- Baseline checkouts;
- Change versus baseline;
- response signals;
- measurement-window states.

For an active campaign that has already started, analytics must calculate through today without forcing the campaign to Completed.

Future follow-up windows must say **Pending**, not 0.

### Resource Impact should show

Primary engagement:

- Promoted titles;
- Titles borrowed;
- Title utilization;
- Campaign checkouts;
- Increased-use titles;
- Zero-response titles.

Secondary Collection-development signals:

- High priority;
- Active holds;
- Approved;
- Sent to Koha.

## Safe first campaign test

1. Create one small test campaign with known valid Koha barcodes.
2. Use real start/end dates appropriate to the test.
3. Open Campaign Detail and confirm titles/barcodes.
4. Open Analytics and confirm the campaign.
5. Confirm Promoted titles vs linked copies/items make sense.
6. Confirm the Baseline and During periods are the expected equal duration.
7. If the campaign is Active, confirm the live-through-today banner.
8. Open Resource Impact and confirm engagement metrics.
9. Do not submit to Koha Suggestions until the analytics/read-only views are verified.
10. Archive/remove only the temporary test campaign according to institutional practice.

## Historical/back-dated campaign test

Historical campaigns are useful for validating analytics because Koha can immediately supply before/during/follow-up circulation evidence.

For a back-dated campaign verify:

- linked resources represent the actual promoted collection;
- campaign dates are historically accurate;
- Baseline is the equal immediately preceding period;
- follow-up windows are complete only when their dates have actually elapsed.

## Koha Suggestions test

Perform only after the analytics screens pass.

1. Select a known Resource Impact title.
2. Review copies, holds and circulation evidence.
3. Approve a test recommendation.
4. Confirm the row remains inside the plugin until explicit submission.
5. Click **Send to Koha Suggestions**.
6. Open the resulting native Koha Suggestion.
7. Confirm title, quantity, biblionumber and ASKED/Pending state.
8. Confirm Management reason **Book Display Impact**.
9. Do not expect the plugin to add a new value to Koha's patron-facing Reason for suggestion authorised-value list.
10. Acquisitions staff retain vendor/fund/price/currency/basket/order decisions.

## If something does not appear

- Missing plugin: confirm enable_plugins and plugin directory.
- Plugin load error: verify package/checksum/Koha version.
- New screen missing after upgrade: restart Plack using the normal institution procedure.
- Barcode rejected: verify the exact Koha item barcode.
- Empty analytics: verify campaign start date and linked resources.
- Active campaign appears one-day only: stop and report it; v0.5 must calculate live through today.
- Future follow-up shows 0: stop and report it; v0.5 must show Pending.
- Suggestions submission denied: verify Koha suggestion permissions.
- Already submitted recommendation: open the existing Koha suggestion; do not resubmit.
- Never weaken CSRF or staff permissions to bypass an error.

## Upgrade procedure

1. Read CHANGELOG.md, docs/COMPATIBILITY.md and docs/UPGRADE_SURVIVAL_AUDIT.md.
2. Back up the complete Koha database.
3. Record installed plugin version and approved package checksum.
4. Upload the new exact KPZ through Koha.
5. Confirm the new version.
6. Confirm all seven plugin-owned tables still exist.
7. Confirm old campaigns, item links, location links, recommendations and audit rows remain.
8. Open every main screen.
9. Test one active campaign.
10. Test one completed/historical campaign.
11. Run the Resource Impact/Suggestion acceptance only with an authorized temporary fixture.
12. Review logs for template/database/authorization errors.

## Disable, uninstall and rollback

Disabling does not intentionally delete historical plugin tables.

Uninstall is designed to be non-destructive in the current candidate, but a database backup remains mandatory.

Rollback principle:

- keep the previously approved KPZ/checksum;
- restore the database backup if incompatible data/schema changes occurred;
- do not manually drop plugin tables or blindly downgrade schema.

## Production authorization

A local KTD PASS is not by itself production authorization.

Production requires the institutionally required combination of:

- target Koha compatibility evidence;
- non-production staging acceptance;
- restorable database backup;
- rollback owner;
- approved change/maintenance window;
- exact package/checksum record.

See docs/UPGRADE_SURVIVAL_AUDIT.md for the complete matrix.
