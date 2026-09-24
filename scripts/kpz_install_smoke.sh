#!/usr/bin/env bash
set -euo pipefail

base_url="${PROMOENG_URL:?Set PROMOENG_URL}"
user="${KTD_USER:?Set KTD_USER}"
pass="${KTD_PASS:?Set KTD_PASS}"
kpz="${KPZ_PATH:?Set KPZ_PATH}"
container="${KTD_CONTAINER:?Set KTD_CONTAINER}"
expected_version="${EXPECTED_VERSION:-0.6.1}"
filename="$(basename "$kpz")"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cookie="$work/cookie.txt"

sql(){
  docker exec "$container" sudo koha-mysql kohadev -N -e "$1"
}

plugin_counts(){
  sql "SELECT CONCAT(
    (SELECT COUNT(*) FROM plugin_ajsn_promo_campaigns),'|',
    (SELECT COUNT(*) FROM plugin_ajsn_promo_items),'|',
    (SELECT COUNT(*) FROM plugin_ajsn_promo_audit),'|',
    (SELECT COUNT(*) FROM plugin_ajsn_promo_settings),'|',
    (SELECT COUNT(*) FROM plugin_ajsn_promo_vocab_values),'|',
    (SELECT COUNT(*) FROM plugin_ajsn_promo_campaign_locations),'|',
    (SELECT COUNT(*) FROM plugin_ajsn_promo_recommendations)
  )"
}

before_counts="$(plugin_counts)"

curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work/login.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work/login.html" | head -1)"
test -n "$csrf"

curl -fsS -L -c "$cookie" -b "$cookie" \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-login" \
 --data-urlencode "koha_login_context=intranet" --data-urlencode "login_userid=$user" \
 --data-urlencode "login_password=$pass" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work/home.html"
grep -q "Koha staff interface" "$work/home.html"

curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/plugins/plugins-upload.pl" -o "$work/upload.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work/upload.html" | head -1)"
test -n "$csrf"

curl -fsS -L -c "$cookie" -b "$cookie" \
 -F "csrf_token=$csrf" -F "op=cud-Upload" -F "uploadfile=@$kpz;filename=$filename" \
 "$base_url/cgi-bin/koha/plugins/plugins-upload.pl" -o "$work/plugins.html"

grep -q "Promotion &amp; Engagement" "$work/plugins.html"
grep -q "$expected_version" "$work/plugins.html"

docker exec "$container" sudo koha-plack --restart kohadev >/dev/null

ready=0
for _ in $(seq 1 30); do
  if curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work/ready.html" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [[ "$ready" != 1 ]]; then
  printf 'kpz-install-smoke FAIL Koha staff interface did not become ready after Plack restart\n' >&2
  exit 1
fi

tables="$(sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name LIKE 'plugin_ajsn_promo_%'")"
test "$tables" = 7

after_counts="$(plugin_counts)"
if [[ "$before_counts" != "$after_counts" ]]; then
  printf 'kpz-install-smoke FAIL plugin row counts changed\nBEFORE %s\nAFTER  %s\n' "$before_counts" "$after_counts" >&2
  exit 1
fi

curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool&action=book_display_impact" -o "$work/impact.html"
grep -q "<h1>Promoted Resource Impact</h1>" "$work/impact.html"
grep -q "How to Use" "$work/impact.html"
! grep -q "Template process failed" "$work/impact.html"

printf 'kpz-install-smoke PASS version=%s tables=%s preserved_counts=%s\n' "$expected_version" "$tables" "$after_counts"
