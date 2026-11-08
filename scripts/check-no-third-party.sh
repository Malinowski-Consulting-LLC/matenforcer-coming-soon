#!/usr/bin/env bash
# Publish gate for the coming-soon site: an allowlist, not a denylist.
#
# Usage: scripts/check-no-third-party.sh <directory>
#
# Every page must open its <head> with charset, the pinned CSP, the referrer meta and the viewport,
# in that order. Every URL-bearing attribute must be relative, or one of the exact allowed URLs below.
# Anything the check cannot read with confidence (comments, inline styles, escapes, unknown file
# types) is refused rather than guessed at. Tags and attributes are matched case-insensitively.
# Every finding is printed as "FAIL [rule-id] file: detail"; the exit code is 1 if there is any.
set -uo pipefail

# Copied from Kit's Embed > HTML tab. Kit's old host, app.convertkit.com, answers a POST with a 301,
# which browsers replay as a GET, so a form pointed there loses the address.
KIT_ACTION="https://app.kit.com/forms/10161980/subscriptions"

PINNED_CSP="default-src 'none'; img-src 'self'; style-src 'self'; font-src 'self'; form-action https://app.kit.com https://matenforcer.net/thanks.html; base-uri 'none'"

ALLOWED_URLS="$KIT_ACTION mailto:support@matenforcer.net https://matenforcer.net/"
ALLOWED_URLS="$ALLOWED_URLS https://matenforcer.net/privacy.html https://matenforcer.net/assets/og-image.png"

ALLOWED_EXTENSIONS="html css png ico woff2 txt md"

scripts_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$scripts_dir/.." && pwd)"

read -r -d '' PAGE_RULES <<'AWK'
{ gsub(/[\t\r]/, " "); doc = doc $0 " " }

END {
  split(allowed, list, " ")
  for (i in list) ok[list[i]] = 1
  banned_re = "^(script|iframe|object|embed|base|frame|frameset|applet|style|portal|fencedframe|noembed|param|svg|math)$"
  url_attr_re = "^(src|href|xlink:href|action|formaction|poster|data|background|cite|longdesc|ping|manifest|icon|codebase|archive|usemap|profile|lowsrc|dynsrc)$"
  scan(doc)
  if (!head_seen) fail("head-order", "no <head> element")
  else if (head_pos < 5) fail("head-order", "the head does not open with charset, CSP, referrer and viewport")
  if (csp_count != 1) fail("csp-mismatch", "expected exactly one CSP meta, found " csp_count)
}

function fail(rule, detail) { printf "FAIL [%s] %s: %s\n", rule, path, detail }

function get(key) { return (key in attr) ? attr[key] : "" }

function scan(s,   n, i, j) {
  n = length(s)
  i = 1
  while (i <= n) {
    if (substr(s, i, 1) != "<") { i++; continue }
    if (substr(s, i, 4) == "<!--") {
      fail("comment", "comments can hide markup from this check")
      j = index(substr(s, i + 4), "-->")
      i = j ? i + j + 6 : n + 1
      continue
    }
    j = tag_end(s, i + 1, n)
    if (substr(s, i + 1, 1) ~ /[A-Za-z]/) check_tag(substr(s, i + 1, j - i - 1))
    i = j + 1
  }
}

function tag_end(s, i, n,   c, q) {
  q = ""
  for (; i <= n; i++) {
    c = substr(s, i, 1)
    if (q != "") { if (c == q) q = ""; continue }
    if (c == "\"" || c == "'") q = c
    else if (c == ">") return i
  }
  return n + 1
}

function check_tag(tag) {
  match(tag, /^[A-Za-z][A-Za-z0-9:-]*/)
  cur_tag = tolower(substr(tag, 1, RLENGTH))
  split("", attr)
  parse_attrs(substr(tag, RLENGTH + 1))
  if (cur_tag ~ banned_re) fail("banned-tag", "<" cur_tag ">")
  if (cur_tag == "meta") check_meta()
  if (cur_tag == "head") { head_seen = 1; head_pos = 1; return }
  if (head_pos >= 1 && head_pos <= 4) check_head_slot()
}

function skip_spaces(s, i, n) {
  while (i <= n && substr(s, i, 1) == " ") i++
  return i
}

function parse_attrs(s,   n, i, c, name, value, q, j) {
  n = length(s)
  i = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == " " || c == "/") { i++; continue }
    name = ""
    while (i <= n && (c = substr(s, i, 1)) !~ /[ \/=]/) { name = name c; i++ }
    i = skip_spaces(s, i, n)
    value = ""
    if (substr(s, i, 1) == "=") {
      i = skip_spaces(s, i + 1, n)
      q = substr(s, i, 1)
      if (q == "\"" || q == "'") {
        j = index(substr(s, i + 1), q)
        if (!j) j = n - i + 1
        value = substr(s, i + 1, j - 1)
        i += j + 1
      } else {
        while (i <= n && (c = substr(s, i, 1)) != " ") { value = value c; i++ }
      }
    }
    if (name != "") on_attr(tolower(name), value)
  }
}

# Every occurrence is checked, not just the first, so a duplicate attribute cannot slip past.
function on_attr(name, value) {
  if (!(name in attr)) attr[name] = value
  if (name ~ /^on/) fail("event-handler", "<" cur_tag " " name "=...>")
  if (name == "style") fail("inline-style", "<" cur_tag " style=...>; the CSP blocks inline styles")
  if (name ~ url_attr_re) check_url(name, value)
  if (name == "srcset" || name == "imagesrcset") check_srcset(name, value)
}

function check_url(name, value,   url) {
  url = value
  gsub(/[[:space:][:cntrl:]]/, "", url)
  if (url in ok) return
  if (url ~ /&/ || tolower(url) ~ /^[a-z][a-z0-9+.-]*:/ || url ~ /^[\/\\][\/\\]/)
    fail("external-url", "<" cur_tag " " name "=\"" value "\">")
}

function check_srcset(name, value,   candidates, count, k, candidate) {
  count = split(value, candidates, ",")
  for (k = 1; k <= count; k++) {
    candidate = candidates[k]
    sub(/^ +/, "", candidate)
    sub(/ .*$/, "", candidate)
    check_url(name, candidate)
  }
}

function check_meta(   equiv) {
  if (!("http-equiv" in attr)) { check_meta_content(get("content")); return }
  equiv = tolower(get("http-equiv"))
  if (equiv == "refresh") fail("meta-refresh", "meta refresh")
  else if (equiv != "content-security-policy") fail("http-equiv", "http-equiv=\"" get("http-equiv") "\"")
  else {
    csp_count++
    if (get("content") != csp) fail("csp-mismatch", "CSP differs from the pinned string: " get("content"))
  }
}

function check_meta_content(value,   url) {
  url = value
  gsub(/[[:space:]]/, "", url)
  if (url in ok) return
  if (url ~ /:\/\// || url ~ /^\/\// || tolower(url) ~ /^(javascript|data|vbscript):/)
    fail("meta-url", "<meta content=\"" value "\">")
}

function check_head_slot(   expected, matched) {
  if (head_pos == 1) {
    expected = "meta charset=utf-8"
    matched = cur_tag == "meta" && tolower(get("charset")) == "utf-8"
  } else if (head_pos == 2) {
    expected = "the CSP meta"
    matched = cur_tag == "meta" && tolower(get("http-equiv")) == "content-security-policy"
  } else if (head_pos == 3) {
    expected = "meta referrer no-referrer"
    matched = cur_tag == "meta" && tolower(get("name")) == "referrer" && get("content") == "no-referrer"
  } else {
    expected = "meta viewport"
    matched = cur_tag == "meta" && tolower(get("name")) == "viewport"
    if (matched && tolower(get("content")) ~ /maximum-scale|user-scalable/)
      fail("viewport-zoom", "the viewport must never limit zoom: " get("content"))
  }
  if (!matched) fail("head-order", "head element " head_pos " is <" cur_tag ">, expected " expected)
  head_pos++
}
AWK

read -r -d '' STYLE_RULES <<'AWK'
{ gsub(/\r/, ""); css = css $0 "\n" }

END {
  if (css ~ /["'][^"'\n]*\/\*/) fail("css-escape", "a comment marker inside a string")
  css = strip_comments(css)
  lower = tolower(css)
  if (lower ~ /@import/) fail("css-import", "@import")
  if (index(css, "\\")) fail("css-escape", "backslash escapes can hide url( or @import")
  if (index(css, "//")) fail("css-url", "a protocol-relative or absolute URL")
  if (lower ~ /url\([ \t\n]*["']?[ \t\n]*[a-z][a-z0-9+.-]*:/) fail("css-url", "url( with a scheme")
  if (lower ~ /["'][ \t]*[a-z][a-z0-9+.-]*:/) fail("css-url", "a string with a scheme")
}

function fail(rule, detail) { printf "FAIL [%s] %s: %s\n", rule, path, detail }

function strip_comments(s,   out, i, j) {
  out = ""
  while ((i = index(s, "/*")) > 0) {
    out = out substr(s, 1, i - 1)
    s = substr(s, i + 2)
    j = index(s, "*/")
    if (!j) return out
    s = substr(s, j + 2)
  }
  return out s
}
AWK

check_file_types() {
  local file ext
  find "$target" -type f | while IFS= read -r file; do
    ext="$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')"
    case " $ALLOWED_EXTENSIONS " in
      *" $ext "*) ;;
      *) echo "FAIL [file-type] $file: only $ALLOWED_EXTENSIONS files may be published" ;;
    esac
  done
}

# The WebP is the private master; it must never reach this public repo, published or not.
check_webp() {
  find "$target" "$repo_root" -path "$repo_root/.git" -prune -o -type f -iname '*.webp' -print \
    | sort -u | while IFS= read -r file; do
      echo "FAIL [webp] $file: the WebP master never enters this repo"
    done
}

check_markers() {
  grep -rIin "TO COMPLETE" "$target" | while IFS= read -r hit; do
    echo "FAIL [to-complete] $hit"
  done
}

check_convertkit() {
  grep -rIin 'app\.convertkit\.com' "$target" | while IFS= read -r hit; do
    echo "FAIL [convertkit] $hit (use $KIT_ACTION)"
  done
}

# A second, cruder layer over the raw text, in case markup ever confuses the tag reader.
check_raw_markup() {
  local page="$1" hit
  grep -inE '<[[:space:]]*/?(script|iframe|object|embed|base|frame|frameset|applet|style|portal|svg|math)([[:space:]/>]|$)' \
    "$page" | while IFS= read -r hit; do echo "FAIL [banned-tag] $page:$hit"; done
  grep -inE "[[:space:]\"'/]on[a-z]+[[:space:]]*=" "$page" \
    | while IFS= read -r hit; do echo "FAIL [event-handler] $page:$hit"; done
}

check_pages() {
  local page
  find "$target" -type f \( -iname '*.html' -o -iname '*.htm' \) | sort | while IFS= read -r page; do
    awk -v path="$page" -v csp="$PINNED_CSP" -v allowed="$ALLOWED_URLS" "$PAGE_RULES" "$page"
    check_raw_markup "$page"
  done
}

check_styles() {
  local sheet
  find "$target" -type f -iname '*.css' | sort | while IFS= read -r sheet; do
    awk -v path="$sheet" "$STYLE_RULES" "$sheet"
  done
}

run_checks() {
  check_file_types
  check_webp
  check_markers
  check_convertkit
  check_pages
  check_styles
}

if [ $# -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: $0 <directory>" >&2
  exit 2
fi
target="${1%/}"

findings="$(run_checks)"
if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  echo "check-no-third-party: $(printf '%s\n' "$findings" | grep -c '^FAIL') finding(s) in $target"
  exit 1
fi
echo "check-no-third-party: $target is clean"
