# Fonts

Everything the page sets text in is served from this directory — no third-party font host, so
nothing here depends on a CORS rule or an external CDN staying up.

| file | family | declared weight | covers |
|---|---|---|---|
| `ubuntu-latin-400-normal.woff2` | Ubuntu | 400 | Latin subset (U+0000-00FF and friends) |
| `ubuntu-latin-700-normal.woff2` | Ubuntu | 700 | same |
| `puhuiti-regular.woff2` | Alibaba PuHuiTi (3 55 Regular) | 400-500 | 376 Chinese characters |
| `puhuiti-bold.woff2` | Alibaba PuHuiTi (3 85 Bold) | 600-900 | the same 376 |

`index.html` stacks them per language: `html[lang="zh-CN"] body` puts Ubuntu first for Latin and
digits, Alibaba PuHuiTi second for Chinese, then PingFang SC / Microsoft YaHei as the system
fallbacks. The English page does not download the Chinese faces at all.

## Why the Chinese faces are subsets

The page's Chinese is a few hundred characters, but the full family is 8.5 MB per weight
(20,976 hanzi). Subsetting to what the page actually renders takes each weight to ~44 KB —
about 0.5% of the original — which matters because GitHub Pages delivers to mainland China at
6-25 KB/s. A GB2312-sized safety margin (3,755 common hanzi) was measured at 995 KB for the
pair, i.e. ~49s on a China line, so the subset is deliberately tight.

**The consequence:** a Chinese character that is not in the subset falls back to PingFang SC /
Microsoft YaHei. If you edit Chinese copy, re-run `rebuild-subsets.sh` and commit the new
`.woff2` files; that also rewrites the `unicode-range` in `index.html` so the CSS keeps
describing the files truthfully.

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

## Unreferenced files

`inter-latin-wght-normal.woff2` (48 KB) and `../Comfortaa.ttf` (204 KB) are no longer referenced
by anything since the Ubuntu switch; they are kept only so that change can be reverted in one
commit, and no visitor downloads them.
