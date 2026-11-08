#!/usr/bin/env bash
# Proves check-no-third-party.sh catches every known bypass before it is trusted with site/.
# Each fixture under fixtures/fail/ is the passing fixture with exactly one bypass added, and
# must fail with its own rule id, so a fixture that fails for an unrelated reason is caught too.
set -uo pipefail

scripts_dir="$(cd "$(dirname "$0")" && pwd)"
checker="$scripts_dir/check-no-third-party.sh"
fixtures="$scripts_dir/fixtures"

# fixture-name:expected-rule-id
expectations="
script:banned-tag
iframe:banned-tag
object:banned-tag
embed:banned-tag
base:banned-tag
style-element:banned-tag
event-handler:event-handler
meta-refresh:meta-refresh
http-equiv-other:http-equiv
protocol-relative-src:external-url
srcset-candidate:external-url
formaction:external-url
poster:external-url
data:external-url
javascript-href:external-url
entity-href:external-url
convertkit-action:convertkit
meta-content-url:meta-url
csp-differs:csp-mismatch
csp-after-viewport:head-order
viewport-zoom:viewport-zoom
inline-style:inline-style
comment:comment
to-complete:to-complete
css-url:css-url
css-import:css-import
file-type:file-type
"

failures=0

report() {
  local verdict="$1" message="$2"
  printf '%s  %s\n' "$verdict" "$message"
  if [ "$verdict" = "FAIL" ]; then
    failures=$((failures + 1))
  fi
}

expect_rejected() {
  local dir="$1" rule="$2" output status
  output="$(bash "$checker" "$dir" 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    report FAIL "$(basename "$dir"): checker passed a bypass (expected [$rule])"
  elif ! printf '%s\n' "$output" | grep -qF "[$rule]"; then
    report FAIL "$(basename "$dir"): rejected, but not by [$rule]: $output"
  else
    report ok "$(basename "$dir") rejected by [$rule]"
  fi
}

expect_accepted() {
  local dir="$1" label="$2" output
  if output="$(bash "$checker" "$dir" 2>&1)"; then
    report ok "$label accepted"
  else
    report FAIL "$label rejected: $output"
  fi
}

check_fixture_inventory() {
  local listed on_disk
  listed="$(printf '%s\n' "$expectations" | sed -n 's/^\([a-z-]*\):.*/\1/p' | sort)"
  on_disk="$(ls "$fixtures/fail" | sort)"
  if [ "$listed" != "$on_disk" ]; then
    report FAIL "fixtures/fail/ and the expectation list differ"
  fi
}

run_bypass_fixtures() {
  local name rule
  while IFS=: read -r name rule; do
    [ -n "$name" ] || continue
    expect_rejected "$fixtures/fail/$name" "$rule"
  done <<EOF
$expectations
EOF
}

# A committed .webp would fail every deploy, so the rule is proved on a throwaway directory.
run_webp_round_trip() {
  local tmp
  tmp="$(mktemp -d)"
  : > "$tmp/master.webp"
  expect_rejected "$tmp" webp
  rm -f "$tmp/master.webp"
  expect_accepted "$tmp" "empty temporary directory after removing the .webp"
  rmdir "$tmp"
}

if [ ! -f "$checker" ]; then
  echo "FAIL  $checker does not exist"
  exit 1
fi

check_fixture_inventory
run_bypass_fixtures
expect_accepted "$fixtures/pass" "fixtures/pass"
run_webp_round_trip

if [ "$failures" -gt 0 ]; then
  echo "test-checker: $failures failing expectation(s)"
  exit 1
fi
echo "test-checker: all expectations met"
