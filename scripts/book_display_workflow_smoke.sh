#!/usr/bin/env bash
set -euo pipefail
base_url="${PROMOENG_URL:-http://promoeng-intra.localhost}"
user="${KTD_USER:?Set KTD_USER}"
pass="${KTD_PASS:?Set KTD_PASS}"
container="${KTD_CONTAINER:-promoeng-koha-1}"
sql(){ docker exec "$container" sudo koha-mysql kohadev -N -e "$1"; }
biblio="$(sql "SELECT i.biblionumber FROM plugin_ajsn_promo_items pi JOIN items i ON i.itemnumber=pi.itemnumber WHERE pi.campaign_id=40 AND pi.deleted_at IS NULL LIMIT 1")"
test -n "$biblio"
test "$(sql "SELECT COUNT(*) FROM plugin_ajsn_promo_recommendations WHERE campaign_id=40 AND biblionumber=$biblio")" = 0
suggestion_id=""
cleanup(){
 if [[ -n "$suggestion_id" ]]; then sql "DELETE FROM suggestions WHERE suggestionid=$suggestion_id" >/dev/null; fi
 sql "DELETE FROM plugin_ajsn_promo_recommendations WHERE campaign_id=40 AND biblionumber=$biblio" >/dev/null
 sql "DELETE FROM plugin_ajsn_promo_audit WHERE campaign_id=40 AND action_type IN ('impact_decision_recorded','impact_suggestion_submitted')" >/dev/null
 rm -rf "$work_dir"
}
work_dir="$(mktemp -d)"
trap cleanup EXIT
cookie="$work_dir/cookie.txt"
curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work_dir/login.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work_dir/login.html" | head -1)"
curl -fsS -L -c "$cookie" -b "$cookie" \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-login" \
 --data-urlencode "koha_login_context=intranet" --data-urlencode "login_userid=$user" \
 --data-urlencode "login_password=$pass" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work_dir/home.html"
grep -q "Koha staff interface" "$work_dir/home.html"
impact_url="$base_url/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool&action=book_display_impact&campaign_id=40"
curl -fsS -c "$cookie" -b "$cookie" "$impact_url" -o "$work_dir/impact.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work_dir/impact.html" | head -1)"
curl -fsS -c "$cookie" -b "$cookie" -X POST \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-save_impact_decision" \
 --data-urlencode "class=Koha::Plugin::Com::AJSN::PromotionEngagement" --data-urlencode "method=tool" \
 --data-urlencode "action=book_display_impact" --data-urlencode "campaign_id=40" \
 --data-urlencode "biblionumber=$biblio" --data-urlencode "decision_status=approved" \
 --data-urlencode "recommended_quantity=2" --data-urlencode "reviewer_note=Workflow smoke test" \
 "$impact_url" -o "$work_dir/approved.html"
grep -q "Approved decision saved with audit history" "$work_dir/approved.html"
test "$(sql "SELECT COUNT(*) FROM plugin_ajsn_promo_recommendations WHERE campaign_id=40 AND biblionumber=$biblio AND decision_status='approved' AND recommended_quantity=2")" = 1
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work_dir/approved.html" | head -1)"
curl -fsS -c "$cookie" -b "$cookie" -X POST \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-submit_impact_suggestion" \
 --data-urlencode "class=Koha::Plugin::Com::AJSN::PromotionEngagement" --data-urlencode "method=tool" \
 --data-urlencode "action=book_display_impact" --data-urlencode "campaign_id=40" \
 --data-urlencode "biblionumber=$biblio" "$impact_url" -o "$work_dir/submitted.html"
grep -q "Koha purchase suggestion" "$work_dir/submitted.html"
grep -q "was created successfully" "$work_dir/submitted.html"
suggestion_id="$(sql "SELECT koha_suggestion_id FROM plugin_ajsn_promo_recommendations WHERE campaign_id=40 AND biblionumber=$biblio")"
test -n "$suggestion_id"
test "$(sql "SELECT COUNT(*) FROM suggestions WHERE suggestionid=$suggestion_id AND STATUS='ASKED' AND quantity=2 AND biblionumber=$biblio")" = 1
test "$(sql "SELECT COUNT(*) FROM plugin_ajsn_promo_audit WHERE campaign_id=40 AND action_type='impact_suggestion_submitted'")" = 1
printf 'book-display-workflow-smoke PASS suggestion=%s\n' "$suggestion_id"
