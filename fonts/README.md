# Fonts

Everything the page sets text in is served from this directory — no third-party font host, so
nothing here depends on a CORS rule or an external CDN staying up.

| file | family | declared weight | covers |
|---|---|---|---|
| `ubuntu-latin-400-normal.woff2` | Ubuntu | 400 | Latin subset (U+0000-00FF and friends) |
| `ubuntu-latin-700-normal.woff2` | Ubuntu | 700 | same |
| `puhuiti-regular.woff2` | Alibaba PuHuiTi (3 55 Regular) | 400-500 | 376 Chinese characters |
| `puhuiti-bold.woff2` | Alibaba PuHuiTi (3 85 Bold) | 600-900 | the same 376 |
| `ximaiti-regular.woff2` | 字制区喜脉体 (FontQu Smile) | 400-900 | the same 376, headings only |

`index.html` stacks them per language: `html[lang="zh-CN"] body` puts Ubuntu first for Latin and
digits, Alibaba PuHuiTi second for Chinese, then PingFang SC / Microsoft YaHei as the system
fallbacks. `h1`-`h4` insert 喜脉体 ahead of PuHuiTi, so Chinese headings take the display face
while body copy stays on PuHuiTi; the Latin inside those headings still comes from Ubuntu, since
喜脉体 has no Latin at all. The English page does not download the Chinese faces.

喜脉体 is declared across the whole `400 900` range although it has a single weight. That is
deliberate: a static face declared across the range the page asks for is used exactly as drawn,
whereas a face declared at one weight would leave the browser synthesising a faux bold for the
800/900 headings — which on a condensed CJK face fills in the counters.

## Why the Chinese faces are subsets

The page's Chinese is a few hundred characters, but the full family is 8.5 MB per weight
(20,976 hanzi) and 2.7 MB for 喜脉体 (7,093 glyphs). Subsetting to what the page renders takes
each PuHuiTi weight to ~44 KB — about 0.5% of the original — and 喜脉体 to ~30 KB, which matters
because GitHub Pages delivers to mainland China at 6-25 KB/s. A GB2312-sized safety margin
(3,755 common hanzi) was measured at 995 KB for the PuHuiTi pair, i.e. ~49s on a China line, so
the subsets are deliberately tight.

**The consequence:** a Chinese character that is not in the subset falls back to PingFang SC /
Microsoft YaHei (or, inside a heading, to PuHuiTi). If you edit Chinese copy, re-run
`rebuild-subsets.sh` and commit the new `.woff2` files; that also rewrites the `unicode-range` in
`index.html` so the CSS keeps describing the files truthfully.

## 喜脉体 and the classical 望聞問切

喜脉体 carries 6,763 **simplified** hanzi (《通用规范汉字表》一级 + 二级字表) and no traditional
forms. The section headline is written with the traditional characters — 望 · 聞 · 問 · 切 — and
a further `望聞問切` appears in the watermark, in the chain-rail nodes and in the origin note.

聞 (U+805E) and 問 (U+554F) are the only two characters anywhere on this page that the face does
not have, so `index.html` carries one targeted exception: `.four-senses h2` keeps the previous
stack, i.e. PuHuiTi. That keeps the classical term in a single face everywhere it appears rather
than showing two of its four glyphs in a different typeface.

Two ways to put that heading in 喜脉体 as well, if wanted:

* write the headline with the simplified forms (闻 · 问) — both are in the subset already, so it
  is a copy change only, and it matches the mostly-simplified body copy; or
* delete the `.four-senses h2` exception and accept that 聞/問 fall back to PuHuiTi inside the
  heading.

## Sources and licences

* **Ubuntu** — the latin subsets as served by Google Fonts. Licensed under the Ubuntu Font
  Licence 1.0, kept here as `Ubuntu-LICENSE.txt`.
* **Alibaba PuHuiTi 3** — downloaded from Alibaba's own font CDN, which is the download target
  of the official site (fonts.alibabadesign.com) and sits behind a Referer ACL:

  ```
  https://fonts.alibabadesign.com/AlibabaPuHuiTi-3/AlibabaPuHuiTi-3-55-Regular/AlibabaPuHuiTi-3-55-Regular.ttf
  https://fonts.alibabadesign.com/AlibabaPuHuiTi-3/AlibabaPuHuiTi-3-85-Bold/AlibabaPuHuiTi-3-85-Bold.ttf
  ```

  Alibaba licenses the family free of charge for commercial and non-commercial use. Their
  statement: "阿里巴巴授权个人、企业等用户在遵守本声明相关条款的前提下，可以下载、安装和使用上述阿里巴巴字体，
  该授权是免费的普通许可，用户可基于合法目的用于商业用途或非商业用途" — the grant covers downloading,
  installing and using the fonts; the older statement adds that the font *files* themselves are
  not to be republished or sold as a font product. Self-hosting a subset for this site's own
  pages is use, not redistribution as a font, but if you would rather not carry the file at all
  the alternative is to leave Chinese on the system fallbacks.
* **字制区喜脉体 (FontQu Smile) v2.000** — 字制区's first free public-interest font, published
  2021-01-01 and open to both individuals and companies. The author's own statement, shipped
  inside the font package as `字制区喜脉体授权声明.rtf`:

  > 字制区喜脉体版权声明：
  > 1、允许任何个人和企业免费使用，包括商用用途，但禁止用于违法用途!
  > 2、字制区喜脉体版权归属字制区（fontqu.com）未经授权，任何人和第三方媒介不得上传、发布、转载字体文件，禁止售卖，违者必究。
  > 3、为确保字体文件不被篡改，保障用户可以安全使用请务必从字制区官方指定通道下载。

  Free for any individual or company to use, including commercially; not for illegal use; the
  copyright stays with 字制区 (fontqu.com); third parties may not republish the font *files*.
  字制区's own site has since closed and their later notice states the font "面对全社会免费商用！
  支持内嵌！" (free commercial use, embedding supported) and lists it as already embedded by
  快手, 抖音 and 小红书 — so web embedding is within the terms.

  The file here came from 猫啃网 (maoken.com), which distributes free Chinese fonts with the
  authors' permission and states that permission for this family on its page
  (`https://www.maoken.com/freefonts/8918.html`, package `字制区喜脉体2.000_猫啃网.zip`). The
  subset was checked against the independently published v1.083 file (`ziti.net.cn`): identical
  glyph count (7,093) and identical letterforms, so the package is the genuine typeface.

  Two caveats worth knowing: the author asks that font files not be tampered with and not be
  republished, and a `.woff2` subset hosted here is both a modified file and a copy of the font.
  That is the same footing as the PuHuiTi subset above — web use of a subset, not a font
  product — and it is what makes a 30 KB download possible instead of 2.7 MB. If you would rather
  hold to the strictest reading, drop the subset, keep the `.ttf` out of the repo, and leave
  Chinese headings on the PuHuiTi / system fallbacks.

