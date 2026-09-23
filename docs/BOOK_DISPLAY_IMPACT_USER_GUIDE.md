# Promoted Resource Impact — User Guide and Acceptance Checklist

## What this module answers

Promoted Resource Impact shows whether Koha titles linked to a promotion were actually used, how that use compares with the equal pre-promotion baseline, and whether current holds/copy pressure warrants collection-development review.

It can be used for physical displays, email campaigns, recommendations and other campaigns that promote Koha item-linked titles.

It does **not** count physical views and it does not claim that every checkout was caused by the promotion.

The internal route and native Koha Suggestion reason remain **Book Display Impact** for backward compatibility.

## Open the module

1. Sign in through the normal Koha staff-interface login page.
2. Open **Koha Administration → Manage plugins**.
3. Find **Promotion & Engagement** and choose **Run tool**.
4. In the plugin sidebar, click **Resource Impact**.
5. Select a campaign.
6. Click **Calculate impact**.

## Active campaigns

A started campaign marked **Active** does not need to be completed before analysis.

- blank end date: analytics run from start date through today;
- future planned end date: analytics run from start date through today;
- results are marked live/provisional;
- future follow-up windows show **Pending**, not zero.

If an active campaign has an end date that is already in the past, the configured end date is used and the analytics service returns a data-quality warning that the campaign is still marked active.

## Understand the engagement summary

The first row is intentionally about resource use, not acquisitions workflow.

- **Promoted titles:** distinct Koha bibliographic titles represented by the linked item records.
- **Titles borrowed:** distinct promoted titles with at least one checkout during the measured campaign period.
- **Title utilization:** Titles borrowed ÷ Promoted titles × 100.
- **Campaign checkouts:** all qualifying checkout events during the measured campaign period; baseline count is shown for context.
- **Increased-use titles:** promoted titles whose During checkout count is higher than their own Baseline count.
- **Zero-response titles:** promoted titles with no checkout during the measured campaign period.

A campaign that has not started must show Pending/null rather than turning all promoted titles into zero-response titles.

## Titles versus copies/items

A campaign can contain more item records than titles.

Example:

- 156 linked copies/items;
- 154 distinct promoted titles.

This is valid when two or more linked copies belong to the same Koha bibliographic record.

Title utilization uses distinct bibliographic titles so multiple copies do not inflate the breadth-of-use result.

## Collection-development signals

The second section supports professional collection-development review.

- **High priority:** titles with strong hold/copy pressure and supporting circulation evidence.
- **Active holds:** current Koha holds across promoted titles.
- **Approved:** plugin recommendations approved by a librarian but not yet sent to Koha.
- **Sent to Koha:** recommendations already created as native Koha Suggestions.

These counters are useful actions/workflow indicators. They are not the primary evidence that a promotion was successful.

## Read one title row

1. **Response** compares checkouts before and during promotion. The 60-day follow-up remains Pending until the full follow-up window is available.
2. **Copies** shows total, serviceable and currently available Koha copies.
3. **Demand** shows active holds and holds per serviceable copy.
4. **Evidence** shows High, Review or Monitor priority and evidence strength.
5. **Recommendation** explains the signal and proposed copy quantity.
6. Click the title to open the authoritative Koha catalogue record.

The quantity uses Koha's configured hold-ratio target. A calculated result is decision support, not an automatic order.

## Approve or reject

1. Review the title response, copies and holds.
2. Adjust Quantity if professional judgment supports a different number.
3. Enter a short review note when helpful.
4. Click **Approve** or **Reject**.
5. Confirm the success message.
6. An approval remains inside the plugin until explicitly sent to Koha.
7. Every decision writes a plugin audit entry and evidence snapshot.

## Send an approval to Koha Suggestions

1. Confirm that the row says Approved.
2. Click **Send to Koha Suggestions**.
3. Confirm the success message containing the Koha suggestion number.
4. The row changes to **Sent to Koha**.
5. Click **Open Koha suggestion**.
6. Confirm title, author, quantity, branch and pending/ASKED status.
7. Confirm Management reason is **Book Display Impact**.
8. The plugin does not invent/overwrite Koha's patron-facing authorised-value reason.
9. An acquisitions-authorized librarian accepts or rejects the suggestion in Koha.
10. Vendor, fund, price, currency, basket and final order remain in native Koha Acquisitions.

The plugin prevents the same submitted recommendation from being overwritten or submitted twice through the normal workflow.

## Permission troubleshooting

- Plugin access requires Koha plugin-tool permission.
- Submitting to Koha Suggestions requires the applicable Koha suggestion-creation/management permission.
- Basket ordering separately requires Koha acquisitions permissions.
- A permission error should be resolved by an authorized Koha administrator.

## v0.5 visual acceptance checklist

Record each item as **PASS** or **FAIL**.

### Dashboard

1. Confirm Promoted titles is visible.
2. Confirm Titles used is visible.
3. Confirm Title utilization is visible.
4. Confirm Campaign checkouts includes baseline context.
5. Confirm Zero-response titles is visible.
6. Confirm Active campaigns is visible.
7. Confirm recent campaigns show Promoted / Used / Checkouts / Utilization / Change.

### Promotions

8. Confirm each measurable campaign shows Promoted titles and linked copy/item context.
9. Confirm Titles used, Checkouts, Utilization and Change vs baseline are visible.
10. Confirm an active campaign displays a to-date/provisional indicator where appropriate.

### Campaign Analytics

11. Select an active campaign that started in the past.
12. Confirm the banner says analytics are live through the current date.
13. Confirm you did not need to mark the campaign Completed.
14. Confirm Promoted titles, Titles used, Title utilization, Campaign checkouts, Baseline checkouts and Change vs baseline.
15. Confirm Response signals show increased-use, zero-response and repeat-demand titles.
16. Confirm future After windows show Pending rather than 0.
17. Confirm title response is grouped by bibliographic title and shows copy/barcode context.

### Resource Impact

18. Confirm the heading says **Promoted Resource Impact**.
19. Confirm engagement summary appears before collection-development signals.
20. Confirm Promoted titles / Titles borrowed / Title utilization / Campaign checkouts / Increased-use / Zero-response.
21. Confirm High priority / Holds / Approved / Sent to Koha remain available in the secondary section.
22. Confirm Configuration is present in the sidebar.

### Reports

23. Confirm portfolio cards show Campaigns measured, Promoted titles, Titles used, Title utilization, Campaign checkouts and Baseline checkouts.
24. Confirm Measurement quality contains de-duplication/multi-attribution information.
25. Confirm comparison tables include Utilization, Baseline, Campaign checkouts, Change, Zero response and Increased titles.
26. For location reports, confirm multi-location campaigns are not falsely named as the leading physical location.

If any step fails, record the page, exact step, visible message and a screenshot.
Do not repeat Submit if a Koha suggestion number was already returned.
