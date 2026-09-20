#!/usr/bin/env bash
set -euo pipefail
base_url="${PROMOENG_URL:-http://promoeng-intra.localhost}"
user="${KTD_USER:?Set KTD_USER}"
pass="${KTD_PASS:?Set KTD_PASS}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
cookie="$work_dir/cookie.txt"
login="$work_dir/login.html"
curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/mainpage.pl" -o "$login"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$login" | head -1)"
test -n "$csrf"
curl -fsS -L -c "$cookie" -b "$cookie" \
  --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-login" \
  --data-urlencode "koha_login_context=intranet" \
  --data-urlencode "login_userid=$user" --data-urlencode "login_password=$pass" \
  "$base_url/cgi-bin/koha/mainpage.pl" -o "$work_dir/home.html"
grep -q "Koha staff interface" "$work_dir/home.html"
impact_url="$base_url/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement&method=tool&action=book_display_impact&campaign_id=40"
curl -fsS -c "$cookie" -b "$cookie" "$impact_url" -o "$work_dir/impact.html"
grep -q "<h1>Book Display Impact</h1>" "$work_dir/impact.html"
grep -q "Displayed-title demand and additional-copy review" "$work_dir/impact.html"
! grep -q "Template process failed" "$work_dir/impact.html"
if [[ -n "${OUTPUT_HTML:-}" ]]; then cp "$work_dir/impact.html" "$OUTPUT_HTML"; fi
printf 'browser-acceptance-smoke PASS\n'
