# v0.2 Tomorrow Test Runbook

**Branch sequence:** `feature/v0.2-campaign-crud` first, then `feature/v0.2-campaign-read`  
**Runtime:** local `kohadev` KTD  
**Purpose:** close the remaining security checkpoint and then verify the new read-only campaign-management slice before any merge.

## A. Confirm KTD is healthy

From Debian/WSL:

```bash
cd ~/git/koha-testing-docker
ktd --list
docker ps -a --filter name=kohadev --format "table {{.Names}}\t{{.Status}}"
```

Expected: `kohadev` is Up and the Koha, DB and memcached containers are Up.

## B. Finish v0.2 Checkpoint 1 on the current CRUD branch

```bash
cd "$PLUGINS_DIR/koha-plugin-promotion-engagement"
git fetch origin
git switch feature/v0.2-campaign-crud
git pull --ff-only origin feature/v0.2-campaign-crud
```

Re-initialise the mounted plugin if the branch changed:

```bash
cd ~/git/koha-testing-docker
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --shell
```

Inside the Koha shell:

```bash
cd /kohadevbox/koha
./misc/devel/install_plugins.pl
sudo koha-plack --restart kohadev
exit
```

### T-131 — invalid CSRF must be rejected

Use the **Promotion & Engagement New promotion form's own** hidden `csrf_token`, not one of Koha's header/search-form tokens.

The correct token is inside the form whose action is `/cgi-bin/koha/plugins/run.pl` and sits with these fields:

- `action=new_promotion`
- `op=cud-create_promotion`
- `csrf_token=...`

Replace only that token value with `INVALID-CSRF-TEST`, submit a campaign named `CSRF Rejection Test 2`, and verify:

- request is rejected;
- the campaign is not created;
- dashboard/database count does not increase.

### T-132 — plugin tool permission

Using a temporary logged-in staff user that does **not** have the plugin `tool` permission, verify the user cannot use the Promotion & Engagement write workflow.

Pass condition: access/write is denied and no campaign is created.

### T-133 — API catalogue permission

Using an authenticated staff/API user that lacks `catalogue` permission, request:

`/api/v1/contrib/ajsn_promotion/health`

Pass condition: request is denied. The existing unauthenticated denial has already passed.

### Authorized smoke test

After any temporary permission changes, return to the normal authorized admin account and verify:

- plugin still shows 0.2.0 Enabled;
- `/health` returns `status: ok` and `version: 0.2.0`;
- one normal campaign can be created.

Do not merge anything until these results are recorded.

## C. Test the new read-only campaign-management branch

After T-131/T-132/T-133 are complete:

```bash
cd "$PLUGINS_DIR/koha-plugin-promotion-engagement"
git fetch origin
git switch feature/v0.2-campaign-read
git pull --ff-only origin feature/v0.2-campaign-read
```

Then re-initialise the mounted plugin again:

```bash
cd ~/git/koha-testing-docker
KOHA_IMAGE=25.11 ktd --proxy --single-plugin "$PLUGINS_DIR/koha-plugin-promotion-engagement" --shell
```

Inside:

```bash
cd /kohadevbox/koha
./misc/devel/install_plugins.pl
sudo koha-plack --restart kohadev
exit
```

Run the read-view tests from `docs/V0_2_CAMPAIGN_READ_TEST.md`:

1. **CR-01** Promotions list opens with saved campaigns and linked-item counts.
2. **CR-02** Campaign detail opens and metadata matches the saved campaign.
3. **CR-03** Linked item shows live Koha barcode/title/author/biblionumber.
4. **CR-04** Campaign with zero items renders normally.
5. **CR-05** Audit history shows the existing `campaign_created` record.
6. **CR-06** Invalid/nonexistent campaign ID is handled without server/SQL error.
7. **CR-07** Existing New promotion write workflow still works after the read-view changes.

## Merge gate

Draft PR #1 must remain unmerged until:

- T-131, T-132 and T-133 pass;
- CR-01 through CR-07 pass;
- no new Plack/template/database errors appear;
- actual runtime results are written back to Project Brain/testing records.

If any test fails, stop at that test, capture the screen/logs, and fix the defect on the feature branch before continuing.