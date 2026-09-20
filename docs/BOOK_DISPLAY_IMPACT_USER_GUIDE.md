# Book Display Impact — User Guide and Acceptance Checklist

## What this module answers

Book Display Impact shows whether books linked to a promotion received circulation
response and whether current holds indicate access pressure. It does not count
physical views and it does not claim that every checkout was caused by the display.

## Open the module

1. Sign in through the normal Koha staff-interface login page.
2. Open **Koha Administration → Manage plugins**.
3. Find **Promotion & Engagement** and choose **Run tool**.
4. In the plugin sidebar, click **Book Display Impact**.
5. Select a campaign.
6. Click **Calculate impact**.

## Understand the five summary cards

- **Displayed titles:** distinct Koha bibliographic titles represented in the display.
- **High priority:** titles with strong enough hold/copy pressure for urgent review.
- **Active holds:** current Koha holds across the displayed titles.
- **Approved:** recommendations approved inside the plugin but not yet submitted.
- **Sent to Koha:** recommendations already created as native Koha Suggestions.
## Read one title row

1. **Response** compares checkouts before, during and during the 60-day follow-up.
2. **Copies** shows total, serviceable and currently available Koha copies.
3. **Demand** shows active holds and holds per serviceable copy.
4. **Evidence** shows High, Review or Monitor priority and evidence strength.
5. **Recommendation** explains the signal and proposed copy quantity.
6. Click the title to open the authoritative Koha catalogue record.

The quantity uses Koha's configured hold-ratio target. A calculated result is
decision support, not an automatic order.

## Approve or reject

1. Review the title, copies, holds and circulation response.
2. Adjust Quantity if professional judgment supports a different number.
3. Enter a short review note when helpful.
4. Click **Approve** or **Reject**.
5. Confirm the green success message.
6. An approval remains inside the plugin until explicitly sent to Koha.
7. Every decision writes a plugin audit entry and an evidence snapshot.
## Send an approval to Koha Suggestions

1. Confirm that the row says Approved.
2. Click **Send to Koha Suggestions**.
3. Confirm the success message containing the Koha suggestion number.
4. The row changes to **Sent to Koha**.
5. Click **Open Koha suggestion**.
6. Confirm title, author, quantity, branch and pending status.
7. An acquisitions-authorized librarian reviews and accepts or rejects it in Koha.
8. After acceptance, use Koha's normal acquisitions workflow to order it from a vendor basket.
9. Select the vendor, fund, price, currency and final quantity in Koha—not in this plugin.

The plugin prevents the same submitted recommendation from being overwritten or
submitted twice through the normal workflow.

## Permission troubleshooting

- Plugin access requires Koha plugin-tool permission.
- Submitting to Koha Suggestions requires `suggestions_create` or `suggestions_manage`.
- Basket ordering separately requires Koha acquisitions permissions.
- A permission error should be resolved by an authorized Koha administrator.
## Tomorrow acceptance test — campaign 40

Record each item as **PASS** or **FAIL**.

1. Open Dashboard; confirm **Book Display Impact** appears.
2. Open Book Display Impact; confirm campaign 40 is selected or selectable.
3. Click Calculate impact; confirm **E Street shuffle** appears.
4. Confirm barcode **3999900000001** appears.
5. Confirm Before, During and After 60 days are visible.
6. Confirm Total, Serviceable and Available copies are visible.
7. Confirm Active holds and Holds/copy are visible.
8. Confirm priority, evidence grade and recommendation explanation are visible.
9. Enter Quantity **2** and note **Monday acceptance test**.
10. Click Approve; confirm the approval message and Send button.
11. Click Send to Koha Suggestions; record the returned suggestion number.
12. Open the Koha suggestion; confirm title, quantity 2, biblionumber link and ASKED/Pending state.
13. Confirm the plugin row says Sent to Koha and does not offer another submission.
14. Ask an acquisitions-authorized tester to accept or reject the suggestion.
15. Do not create a vendor order unless it is an approved institutional test.

If any step fails, record the page, exact step, visible message and a screenshot.
Do not repeat Submit if a suggestion number was already returned.
