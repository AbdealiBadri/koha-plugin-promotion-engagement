#!/usr/bin/env bash
set -euo pipefail
base_url="${PROMOENG_URL:?Set PROMOENG_URL}"
user="${KTD_USER:?Set KTD_USER}"
pass="${KTD_PASS:?Set KTD_PASS}"
kpz="${KPZ_PATH:?Set KPZ_PATH}"
container="${KTD_CONTAINER:?Set KTD_CONTAINER}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cookie="$work/cookie.txt"
curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work/login.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work/login.html" | head -1)"
curl -fsS -L -c "$cookie" -b "$cookie" \
 --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-login" \
 --data-urlencode "koha_login_context=intranet" --data-urlencode "login_userid=$user" \
 --data-urlencode "login_password=$pass" "$base_url/cgi-bin/koha/mainpage.pl" -o "$work/home.html"
grep -q "Koha staff interface" "$work/home.html"
curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/plugins/plugins-upload.pl" -o "$work/upload.html"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$work/upload.html" | head -1)"
curl -fsS -L -c "$cookie" -b "$cookie" \
 -F "csrf_token=$csrf" -F "op=cud-Upload" -F "uploadfile=@$kpz;filename=PromotionEngagement-v0.4.1.kpz" \
 "$base_url/cgi-bin/koha/plugins/plugins-upload.pl" -o "$work/plugins.html"
grep -q "Promotion &amp; Engagement" "$work/plugins.html"
grep -q "0.4.1" "$work/plugins.html"
docker exec "$container" sudo koha-plack --restart kohadev >/dev/null
tables="$(docker exec "$container" sudo koha-mysql kohadev -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name LIKE 'plugin_ajsn_promo_%'")"
test "$tables" = 7
curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool&action=book_display_impact" -o "$work/impact.html"
grep -q "<h1>Book Display Impact</h1>" "$work/impact.html"
! grep -q "Template process failed" "$work/impact.html"
printf 'kpz-install-smoke PASS version=0.4.1 tables=%s\n' "$tables"
