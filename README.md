# robodiag.cn

The Robodiag marketing site: one static page, served by GitHub Pages at
[robodiag.cn](https://robodiag.cn). No build step, no framework, no package manager — `index.html`
is the whole site, and what is in this repository is what ships.

## Layout

| path | what it is |
|---|---|
| `index.html` | the entire site: markup, inlined CSS, and the page's JavaScript |
| `CNAME` | the custom domain GitHub Pages serves (`robodiag.cn`) |
| `robodiag-brand.mp4`, `robodiag-brand-poster.jpg` | the hero film and its poster frame, served to visitors outside mainland China |
| `favicon.ico`, `favicon-32.png`, `favicon-192.png`, `apple-touch-icon.png` | the browser and home-screen icons |
| `robodiag-mark.png`, `robodiag-mark-dark.png` | the header mark, one file per theme |
| `fonts/` | the self-hosted families, their licences, and `rebuild-subsets.sh`; see [fonts/README.md](fonts/README.md) |

## Previewing and editing

```bash
python3 -m http.server 8080     # then open http://localhost:8080
```

Everything lives in `index.html`:

* **Copy is in two places.** The markup carries the English text, and the Chinese text lives in the
  `i18n` dictionary near the end of the body — `data-i18n` swaps plain text, `data-i18n-html` swaps
  markup, which is how headings that contain a `<br>` or an arrow are translated. Edit the English
  copy and its dictionary entry together, or the two languages drift apart. A script in `<head>`
  hides the English source text until the right language has been applied, so it never flashes.
* **The Chinese fonts are subsets** — only the characters this page actually renders, because the
  full families are megabytes and GitHub Pages delivers to mainland China at a trickle. If you edit
  the Chinese copy, run `fonts/rebuild-subsets.sh` and commit the new `.woff2` files; a character
  outside the subset silently falls back to the system font.
* **Images are cache-busted by a `?v=` query** on every reference in `<head>` and in the header.
  Bump it when you replace an image, or returning visitors keep the old one for a while.
* **The tab title is deliberately just `Robodiag`**, in both languages.

## The hero film plays from wherever it is fast

The film is hosted twice: in this repository, which GitHub Pages serves quickly outside mainland
China, and in an Aliyun OSS bucket in Hangzhou, which is quick inside it. On load, the page asks
both origins for the same poster image and the first to deliver it wins. The poster is needed
either way, so the probe is free — and it measures the path the video itself will take, throttling
included, which a plain latency check would not catch. The loser's download is released as soon as
the race is decided. With scripting off, the OSS source written into the markup stands.

Reduced-motion visitors see the poster instead of the film; it follows the same winner through the
`--hero-poster` custom property.

The two hosts hold different encodes of the same 720p, 24 fps film: about 3.0 MB in the repository
and 2.1 MB on OSS. To host the film somewhere else, change the two base URLs in the hero script and
the fallback URL in the `.hero-media` background rule.

## Page state

Three choices are remembered in `localStorage` and applied by the `head` script before the first
paint, so the page never renders in the wrong theme or language and then corrects itself:

| key | values | default |
|---|---|---|
| `robodiag-theme` | `light` / `dark` | light, whatever the OS prefers |
| `robodiag-lang` | `en` / `zh` | Chinese only when the browser asks for Chinese |
| `robodiag-evidence` | `open` / anything else | the Diagnostic Evidence panel starts collapsed |

The **Diagnostic Evidence section is currently hidden**: its wrapper is
`<div class="four-senses" hidden>`. Delete the `hidden` attribute to bring it back — its markup,
styles and script are all still in place.

## Deploying

Push to `main`. GitHub Pages publishes in roughly 30-60 seconds; there is nothing else to run.

## Fonts and licences

Latin text is set in **Ubuntu** and the Chinese body in **Alibaba PuHuiTi**, with
**字制区喜脉体** for the Chinese headings. Everything is self-hosted and subset, and all three are
free for commercial use. `fonts/README.md` records where each file came from, the size of each
subset, and the authors' licence terms.
