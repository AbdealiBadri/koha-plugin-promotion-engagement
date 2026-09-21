#!/usr/bin/env bash
set -euo pipefail
base_url="${PROMOENG_URL:-http://promoeng-intra.localhost}"
user="${KTD_USER:?Set KTD_USER}"
pass="${KTD_PASS:?Set KTD_PASS}"
work_dir="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_WORKDIR:-0}" == "1" ]]; then
    printf 'browser-acceptance workdir retained: %s\n' "$work_dir"
  else
    rm -rf "$work_dir"
  fi
}
trap cleanup EXIT
cookie="$work_dir/cookie.txt"
login="$work_dir/login.html"
curl -fsS -c "$cookie" -b "$cookie" "$base_url/cgi-bin/koha/mainpage.pl" -o "$login"
csrf="$(sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' "$login" | head -1)"
test -n "$csrf"
curl -fsS -L -c "$cookie" -b "$cookie"   --data-urlencode "csrf_token=$csrf" --data-urlencode "op=cud-login"   --data-urlencode "koha_login_context=intranet"   --data-urlencode "login_userid=$user" --data-urlencode "login_password=$pass"   "$base_url/cgi-bin/koha/mainpage.pl" -o "$work_dir/home.html"
grep -q "Koha staff interface" "$work_dir/home.html"

plugin_base="$base_url/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AAJSN%3A%3APromotionEngagement"

require_marker() {
  local file="$1" marker="$2"
  if ! grep -q "$marker" "$work_dir/$file"; then
    printf 'browser-acceptance FAIL %s missing marker: %s\n' "$file" "$marker" >&2
    return 1
  fi
}

fetch_check() {
  local url="$1" file="$2" marker="$3"
  curl -fsS -c "$cookie" -b "$cookie" "$url" -o "$work_dir/$file"
  require_marker "$file" "$marker"
  ! grep -q "Template process failed" "$work_dir/$file"
  ! grep -q "Internal Server Error" "$work_dir/$file"
  printf 'browser-render PASS %s\n' "$file"
}
fetch_check "$plugin_base&method=tool" "dashboard.html" "Promotion &amp; Engagement"
grep -q "Configuration" "$work_dir/dashboard.html"
grep -q "Display-location intelligence" "$work_dir/dashboard.html"

fetch_check "$plugin_base&method=tool&action=promotions" "promotions.html" "Promotion portfolio"
grep -q "Configuration" "$work_dir/promotions.html"

fetch_check "$plugin_base&method=tool&action=analytics&campaign_id=40" "analytics.html" "Promotion analytics"
grep -q "Compare all campaigns" "$work_dir/analytics.html"
grep -q "Configuration" "$work_dir/analytics.html"

fetch_check "$plugin_base&method=tool&action=reports" "reports.html" "Promotion impact reports"
grep -q "All campaigns" "$work_dir/reports.html"
grep -q "All statuses" "$work_dir/reports.html"
grep -q "Display-location evidence" "$work_dir/reports.html"
grep -q "Configuration" "$work_dir/reports.html"

fetch_check "$plugin_base&method=configure" "configuration.html" "Promotion &amp; Engagement configuration"

impact_url="$plugin_base&method=tool&action=book_display_impact&campaign_id=40"
fetch_check "$impact_url" "impact.html" "Promoted Resource Impact"
grep -q "Promoted-title demand and additional-copy review" "$work_dir/impact.html"
grep -q "Configuration" "$work_dir/impact.html"

if [[ -n "${OUTPUT_HTML:-}" ]]; then cp "$work_dir/impact.html" "$OUTPUT_HTML"; fi
printf 'browser-acceptance-smoke PASS dashboard promotions analytics reports configuration impact\n'
