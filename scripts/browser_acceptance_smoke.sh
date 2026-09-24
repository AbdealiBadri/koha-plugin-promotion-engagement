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

curl -fsS -L -c "$cookie" -b "$cookie" \
  --data-urlencode "csrf_token=$csrf" \
  --data-urlencode "op=cud-login" \
  --data-urlencode "koha_login_context=intranet" \
  --data-urlencode "login_userid=$user" \
  --data-urlencode "login_password=$pass" \
  "$base_url/cgi-bin/koha/mainpage.pl" -o "$work_dir/home.html"
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
  local url="$1" file="$2"
  shift 2
  curl -fsS -c "$cookie" -b "$cookie" "$url" -o "$work_dir/$file"
  ! grep -q "Template process failed" "$work_dir/$file"
  ! grep -q "Internal Server Error" "$work_dir/$file"
  for marker in "$@"; do require_marker "$file" "$marker"; done
  printf 'browser-render PASS %s\n' "$file"
}

fetch_check "$plugin_base&method=tool" "dashboard.html" \
  "Promotion &amp; Engagement" "How to Use" "Titles Issued / Borrowed" "How promotion becomes evidence"

fetch_check "$plugin_base&method=tool&action=promotions" "promotions.html" \
  "Promotion portfolio" "How to Use" "Campaign selection" "Compare selected campaigns" "promo-searchable-select"

fetch_check "$plugin_base&method=tool&action=analytics&campaign_id=40" "analytics.html" \
  "Promotion analytics" "How to Use" "Visual analysis" "Chart View" "Table View" "Download JPEG" "Titles with Increased Issues"

fetch_check "$plugin_base&method=tool&action=reports" "reports.html" \
  "Promotion impact reports" "How to Use" "Campaign-by-campaign comparison" "Chart View" "Table View" "Download JPEG"

fetch_check "$plugin_base&method=configure" "configuration.html" \
  "Promotion &amp; Engagement configuration" "How to Use" "Campaign types" "Cadence / frequency" "promo-data-table"

impact_url="$plugin_base&method=tool&action=book_display_impact&campaign_id=40"
fetch_check "$impact_url" "impact.html" \
  "Promoted Resource Impact" "How to Use" "Collection-development signals" "Titles Issued / Borrowed" "Zero-Response Titles" "promo-response-legend"

fetch_check "$plugin_base&method=tool&action=promotion_detail&campaign_id=40" "detail.html" \
  "How to Use" "Impact at a glance" "Audit history"

fetch_check "$plugin_base&method=tool&action=edit_promotion&campaign_id=40" "edit.html" \
  "Edit promotion" "How to Use" "promo-searchable-select"

fetch_check "$plugin_base&method=tool&action=new_promotion" "new.html" \
  "New promotion" "How to Use" "promo-searchable-select"

if [[ -n "${OUTPUT_HTML:-}" ]]; then
  cp "$work_dir/impact.html" "$OUTPUT_HTML"
fi

printf 'browser-acceptance-smoke PASS v0.6.1 dashboard promotions analytics reports configuration impact detail edit new\n'
