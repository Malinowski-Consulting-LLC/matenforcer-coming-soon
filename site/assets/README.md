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
| `logo-82x112.png`, `logo-164x224.png`, `logo-246x336.png` | `index.html`, under 600 px | 82 x 112 at 1x, 2x, 3x |
| `logo-117x160.png`, `logo-234x320.png`, `logo-351x480.png` | `index.html`, 600 to 1023 px | 117 x 160 at 1x, 2x, 3x |
| `logo-235x320.png`, `logo-470x640.png`, `logo-705x960.png` | `index.html`, 1024 px and up | 235 x 320 at 1x, 2x, 3x |
| `logo-47x64.png`, `logo-94x128.png`, `logo-141x192.png` | `thanks.html`, `privacy.html` | 47 x 64 at 1x, 2x, 3x |

The app's asset build produces these twelve sizes the same way as its own: scaled from the master,
with metadata removed.
