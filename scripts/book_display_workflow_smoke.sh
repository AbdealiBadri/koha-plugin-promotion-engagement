#!/usr/bin/env bash
set -euo pipefail

base_url="${PROMOENG_URL:-http://promoeng-intra.localhost}"
user="${KTD_USER:?Set KTD_USER}"
pass="${KTD_PASS:?Set KTD_PASS}"
container="${KTD_CONTAINER:-promoeng-koha-1}"

sql(){ docker exec "$container" sudo koha-mysql kohadev -N -e "$1"; }

source_item="$(sql "SELECT pi.itemnumber FROM plugin_ajsn_promo_items pi WHERE pi.campaign_id=40 AND pi.deleted_at IS NULL ORDER BY pi.campaign_item_id LIMIT 1")"
test -n "$source_item"
biblio="$(sql "SELECT biblionumber FROM items WHERE itemnumber=$source_item")"
barcode="$(sql "SELECT barcode FROM items WHERE itemnumber=$source_item")"
test -n "$biblio"

campaign_id=""
suggestion_id=""
work_dir="$(mktemp -d)"

cleanup(){
  if [[ -n "$suggestion_id" ]]; then
    sql "DELETE FROM suggestions WHERE suggestionid=$suggestion_id" >/dev/null || true
  fi
  if [[ -n "$campaign_id" ]]; then
    sql "DELETE FROM plugin_ajsn_promo_recommendations WHERE campaign_id=$campaign_id" >/dev/null || true
    sql "DELETE FROM plugin_ajsn_promo_audit WHERE campaign_id=$campaign_id" >/dev/null || true
    sql "DELETE FROM plugin_ajsn_promo_campaign_locations WHERE campaign_id=$campaign_id" >/dev/null || true
    sql "DELETE FROM plugin_ajsn_promo_items WHERE campaign_id=$campaign_id" >/dev/null || true
    sql "DELETE FROM plugin_ajsn_promo_campaigns WHERE campaign_id=$campaign_id AND name='BDI-WORKFLOW-SMOKE'" >/dev/null || true
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT

campaign_id="$(sql "INSERT INTO plugin_ajsn_promo_campaigns
  (campaign_uuid,campaign_type,channel,name,start_date,end_date,branchcode,target_audience,language_code,display_location,notes,status,created_by)
 SELECT UUID(),campaign_type,channel,'BDI-WORKFLOW-SMOKE',start_date,end_date,branchcode,target_audience,language_code,display_location,'Synthetic runtime workflow fixture','completed',51
   FROM plugin_ajsn_promo_campaigns WHERE campaign_id=40;
 SELECT LAST_INSERT_ID();")"
test -n "$campaign_id"

sql "INSERT INTO plugin_ajsn_promo_items
  (campaign_id,itemnumber,barcode,added_by)
 VALUES ($campaign_id,$source_item,'$barcode',51)" >/dev/null

test "$(sql "SELECT COUNT(*) FROM plugin_ajsn_promo_recommendations WHERE campaign_id=$campaign_id AND biblionumber=$biblio")" = 0

cookie="$work_dir/cookie.txt"
curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work_dir/login.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work_dir/login.html" | head -1)"
curl -fsS -L -c "$cookie" -b "$cookie" \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-login" \
 --data-urlencode "koha_login_context=intranet" --data-urlencode "login_userid=$user" \
 --data-urlencode "login_password=$pass" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work_dir/home.html"
grep -q "Koha staff interface" "$work_dir/home.html"

impact_url="$base_url/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool&action=book_display_impact&campaign_id=$campaign_id"
curl -fsS -c "$cookie" -b "$cookie" "$impact_url" -o "$work_dir/impact.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work_dir/impact.html" | head -1)"
test -n "$csrf"

curl -fsS -c "$cookie" -b "$cookie" -X POST \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-save_impact_decision" \
 --data-urlencode "class=Koha::Plugin::Com::AJSN::PromotionEngagement" --data-urlencode "method=tool" \
 --data-urlencode "action=book_display_impact" --data-urlencode "campaign_id=$campaign_id" \
 --data-urlencode "biblionumber=$biblio" --data-urlencode "decision_status=approved" \
 --data-urlencode "recommended_quantity=2" --data-urlencode "reviewer_note=Workflow smoke test" \
 "$impact_url" -o "$work_dir/approved.html"

grep -q "Approved decision saved with audit history" "$work_dir/approved.html"
test "$(sql "SELECT COUNT(*) FROM plugin_ajsn_promo_recommendations WHERE campaign_id=$campaign_id AND biblionumber=$biblio AND decision_status='approved' AND recommended_quantity=2")" = 1

csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work_dir/approved.html" | head -1)"
test -n "$csrf"

curl -fsS -c "$cookie" -b "$cookie" -X POST \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-submit_impact_suggestion" \
 --data-urlencode "class=Koha::Plugin::Com::AJSN::PromotionEngagement" --data-urlencode "method=tool" \
 --data-urlencode "action=book_display_impact" --data-urlencode "campaign_id=$campaign_id" \
 --data-urlencode "biblionumber=$biblio" "$impact_url" -o "$work_dir/submitted.html"

grep -q "Koha purchase suggestion" "$work_dir/submitted.html"
grep -q "was created successfully" "$work_dir/submitted.html"

suggestion_id="$(sql "SELECT koha_suggestion_id FROM plugin_ajsn_promo_recommendations WHERE campaign_id=$campaign_id AND biblionumber=$biblio")"
test -n "$suggestion_id"
test "$(sql "SELECT COUNT(*) FROM suggestions WHERE suggestionid=$suggestion_id AND STATUS='ASKED' AND quantity=2 AND biblionumber=$biblio")" = 1
test "$(sql "SELECT COUNT(*) FROM suggestions WHERE suggestionid=$suggestion_id AND reason='Book Display Impact' AND (patronreason IS NULL OR patronreason='')")" = 1
test "$(sql "SELECT COUNT(*) FROM suggestions WHERE suggestionid=$suggestion_id AND staff_note LIKE 'Evidence-based additional-copy recommendation.%'")" = 1
test "$(sql "SELECT COUNT(*) FROM plugin_ajsn_promo_audit WHERE campaign_id=$campaign_id AND action_type='impact_suggestion_submitted'")" = 1

printf 'book-display-workflow-smoke PASS synthetic_campaign=%s suggestion=%s reason=Book_Display_Impact\n' "$campaign_id" "$suggestion_id"
