# site/assets

Copied byte for byte from MatEnforcer `public/brand` and `public/favicon.ico` at source commit
`6fcf05b16` (`BRAND_ASSET_VERSION` `bc2aec4d3a`), which the repo README also records. Never add a `.webp` here; the publish
check refuses one anywhere in this repo.

The pages reference these final names:

| File | Used by | Displayed at |
|---|---|---|
| `favicon.ico` (16, 32 and 48) | every page | browser tab |
| `apple-touch-icon.png` | every page | iOS home screen |
| `og-image.png` (1200 x 630) | `index.html` share tags | link previews |
| `logo-47x64.png`, `logo-94x128.png`, `logo-141x192.png` | every page's header (32 px tall) and footer (24 px tall) | by width, through `srcset` |
| `logo-235x320.png`, `logo-351x480.png`, `logo-470x640.png`, `logo-705x960.png` | `index.html` hero, 1024 px and up | 235 x 320 up to 3x, through `srcset` |
| `logo-82x112.png`, `logo-164x224.png`, `logo-246x336.png`, `logo-117x160.png`, `logo-234x320.png` | not referenced since the page redesign; kept as copied | none |

The app's asset build produces these twelve sizes the same way as its own: scaled from the master,
with metadata removed.
