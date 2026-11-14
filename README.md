# matenforcer-coming-soon

The temporary coming-soon page for `matenforcer.net`, served by GitHub Pages until MatEnforcer
launches. Three static pages, one stylesheet, no script, and a signup form that posts straight to
Kit. The site is retired at launch, when the apex moves back to the app.

## Fixed dates

| | Date |
|---|---|
| Go-live, the day the page first goes live on `matenforcer.net` | 15 November 2026 (2026-11-15) |
| Deletion, 24 months after go-live | 15 November 2028 (2028-11-15) |

`site/privacy.html` prints these same two dates: "This page went live on 15 November 2026. If
MatEnforcer hasn't launched by 15 November 2028, we delete the whole list." The deletion clock runs
from the go-live date only, never from the notice's "Last updated" date. If the first publish on
the domain slips past 15 November 2026, both dates move together here and in `site/privacy.html`
before that publish.

**Deletion reminder:** if MatEnforcer has not launched by 15 November 2028, delete the whole launch
list in Kit that day and record the deletion outside this repo.

## Layout

```
site/                 the only directory published
  index.html          the page
  thanks.html         where Kit sends the visitor after the post and after confirming
  privacy.html        the privacy notice for the launch list
  robots.txt          allows every crawler and names the sitemap
  sitemap.txt         the two indexable pages, one URL per line
  llms.txt            a plain summary for AI agents; keep its feature list in step with index.html
  styles.css          hand-written; values copied from the app's tokens.css
  assets/             logo, favicon, touch icon and share image (see site/assets/README.md)
  fonts/              Archivo variable woff2 and its licence, OFL.txt
scripts/
  check-no-third-party.sh   the publish check
  test-checker.sh           proves the check catches every known bypass
  fixtures/                 one passing page and one failing page per bypass; never published
.github/workflows/pages.yml   checks the fixtures, then site/, uploads only site/, deploys, probes for 404
CNAME                 matenforcer.net, documentation only (see Domain)
```

## Sources

- **Logo assets:** copied byte for byte from MatEnforcer `public/brand` and `public/favicon.ico`.
  Source commit: `6fcf05b16` (`BRAND_ASSET_VERSION` `bc2aec4d3a`). The fifteen files in `site/assets/`
  are the twelve `logo-<W>x<H>.png` marks, `apple-touch-icon.png`, `og-image.png` and `favicon.ico`.
- **Colours, type and spacing:** copied by hand from MatEnforcer `app/frontend/styles/tokens.css` at
  commit `9a7d52476`. No brand-red token is copied; the red lives only inside the logo artwork.
- **Font:** `archivo-latin-wdth-normal.woff2` from `@fontsource-variable/archivo` 5.3.0
  (SHA-256 `e3a28eade21a900c7155a247757f4b2834c07bb7ef07ad7efa55cebaac1e8f5e`). It carries the weight
  and width axes. Licence: SIL Open Font License 1.1, in `site/fonts/OFL.txt`.

## The signup form

- `index.html` posts `email_address` to `https://app.kit.com/forms/10161980/subscriptions`, both
  copied from Kit's Embed > HTML tab. Never use `app.convertkit.com`: it answers a POST with a 301,
  which browsers replay as a GET, and the address is lost.
- **No honeypot field.** Kit's static HTML embed carries no honeypot input. Kit adds its bot controls
  through its own script, which this page does not load. So the page has no honeypot, and none is
  invented: Kit discards only its own. The bot defences are Kit's server-side CAPTCHA and double
  opt-in.
- In Kit, both redirects (after the post, and after confirming) point to
  `https://matenforcer.net/thanks.html`, and "Send subscriber data to thank you page" is off, so no
  landing URL carries personal data.

## The publish check

```
scripts/test-checker.sh                  # every bypass fixture must fail by its own rule
scripts/check-no-third-party.sh site     # then the directory that is published
```

The check is an allowlist. Every page must open its head with `<meta charset>`, the pinned CSP, the
referrer meta and the viewport, in that order. Every URL-bearing attribute must be relative, or one
of five exact URLs: the Kit action, `mailto:support@matenforcer.net`, and the
`https://matenforcer.net/` canonical, privacy canonical and share-image URLs. It also refuses:
- script, frames, objects, `<base>`, `<style>`, inline SVG and MathML;
- event-handler attributes, inline `style` attributes and HTML comments;
- a meta refresh or any other `http-equiv`;
- CSS `@import`, absolute or protocol-relative `url()`, and CSS escapes;
- any file type other than html, css, png, ico, woff2, txt and md;
- any `.webp` anywhere in the repo, because the logo master stays private;
- any `TO COMPLETE` marker.

It reports every finding as `FAIL [rule-id] file: detail` and exits 1 if there is any.

Fixture URLs point at `example.invalid`. There are two deliberate exceptions. Every fixture carries
the real pinned CSP, which names `app.kit.com` and `matenforcer.net`. And the `convertkit-action`
fixture names `app.convertkit.com`, because that host is the bypass it tests. The passing fixture
uses the real Kit action, so the allowlist itself is exercised.

**Before the first publish,** `site/privacy.html` still holds three `TO COMPLETE` markers: the Kit
sending subdomain, the transfer mechanism from Kit's current Data Processing Addendum, and Kit's
private mailbox address. The check refuses to publish until all three are copied in from Kit.
Update "Last updated" in the same commit.

## Runbook: subscription bombing

A bot can submit other people's addresses, so Kit sends them confirmation emails they never asked
for. Double opt-in keeps those addresses off the list, but the emails still go out.

**Every week, until launch:**
1. In Kit, read the form's unconfirmed-subscriber count and its confirmed count.
2. Note both, with the date, outside this repo.
3. A spike in unconfirmed signups with no matching rise in confirmed ones means bombing.

**If it spikes:**
1. Pause the form in its settings in Kit, so it stops accepting signups.
2. If Kit has no pause for the form, remove the "Join the list" section from `site/index.html` and
   push. The page keeps the support address, and the check still passes.
3. Raise it with Kit support, with the dates and counts.
4. Restore the form once Kit confirms the source is blocked.

## Domain

With a custom Actions workflow, GitHub ignores a `CNAME` file. The domain is the repository's
Pages setting. `CNAME` here only documents the intended domain. Before any DNS record points at
GitHub, `matenforcer.net` is verified on the owner account. The `_github-pages-challenge` TXT record
it adds stays permanently, including after retirement.

## Retirement at launch

DNS leaves GitHub before the site is unpublished, so no visitor ever lands on GitHub's 404.

1. **DNS.** Confirm the app answers the apex host, then move the apex `A` and `AAAA` records and the
   `www` CNAME to the app. Keep the `_github-pages-challenge` TXT record. Leave Resend's MX, SPF,
   DKIM and DMARC records untouched. Capture the zone before and after.
2. **`dig` check.** After propagation, `dig matenforcer.net A`, `dig matenforcer.net AAAA` and
   `dig www.matenforcer.net` show no GitHub Pages address and no `github.io` target. Both
   `https://matenforcer.net/` and `https://www.matenforcer.net/` answer from the app.
3. **Unpublish.** Unpublish the Pages site (Settings > Pages), then check that the `github.io`
   project URL no longer serves the page.
4. **Archive.** Archive this repository.

## Rollback

The same order as retirement:

1. **DNS.** Restore the apex `A` and `AAAA` records and the `www` CNAME from the zone captured before
   the change, so no apex or `www` record points at GitHub. Keep the `_github-pages-challenge` TXT
   record.
2. **`dig` check.** Confirm with `dig` that no record resolves to GitHub Pages.
3. **Unpublish.** Only then disable Pages.
4. **Archive.** Archive this repository if the site is not coming back.
