#!/usr/bin/env bash
# Rebuild the Chinese web subsets from their official sources and update the unicode-range in
# index.html. Run after editing any Chinese copy. 字制区喜脉体 also draws the English headings
# and the wordmark, so its subset carries the Latin as well; PuHuiTi stays CJK-only.
#
# Needs: python3 with fontTools + brotli (pyftsubset on PATH), curl.
set -euo pipefail

cd "$(dirname "$0")/.."                       # repo root
WORK="${TMPDIR:-/tmp}/puhuiti-build"
mkdir -p "$WORK" fonts

BASE="https://fonts.alibabadesign.com/AlibabaPuHuiTi-3"
# The CDN is behind a Referer ACL; any alibabadesign referer is accepted.
REF="https://fonts.alibabadesign.com/"

fetch() { # weight-suffix
  local w="$1" name="AlibabaPuHuiTi-3-$1" out="$WORK/AlibabaPuHuiTi-3-$1.ttf"
  [ -s "$out" ] || curl -fL --max-time 900 -H "Referer: $REF" -H "Origin: $REF" \
      -A "Mozilla/5.0" -o "$out" "$BASE/$name/$name.ttf"
  echo "$out"
}

# 1. The character set: every CJK character in index.html, plus the punctuation a Chinese
#    editor would plausibly type next (the page itself only uses 、。，：).
python3 - "$WORK/charset.txt" <<'PY'
import io, re, sys
html = io.open("index.html", encoding="utf-8").read()
cjk = re.findall(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\u3000-\u303f\uff00-\uffef]", html)
extra = "、。，：《》〈〉「」『』【】〔〕！？；（）…—～·％＃＆＊＋－＝／"
io.open(sys.argv[1], "w", encoding="utf-8").write("".join(sorted(set(cjk) | set(extra) | {" "})))
print(f"  characters to embed: {len(set(cjk) | set(extra))}")
PY

# 1b. The ASCII and typographic marks the English headings and the wordmark need. They go only
#     into the 喜脉体 subset: the Latin body copy is Ubuntu's, and PuHuiTi is never asked for
#     Latin. Listed from what the face actually carries - it has no en dash (U+2013) and no
#     arrow (U+2192), which fall through to the next family in the stack.
python3 - "$WORK/latin.txt" <<'PY'
import io, sys
# ASCII only, plus the three marks the page already asks this face for. The quotes
# (U+2018-201D) are deliberately absent: in this font they are the full-width CJK punctuation,
# and claiming them for Latin text renders "what's" as "what'  s". Ubuntu owns them.
latin = "".join(chr(c) for c in range(0x20, 0x7F)) + "\u00b7\u2014\u2026"
io.open(sys.argv[1], "w", encoding="utf-8").write(latin)
print(f"  latin + punctuation for the display face: {len(latin)} characters")
PY
cat "$WORK/charset.txt" "$WORK/latin.txt" > "$WORK/ximai-charset.txt"

# 2. Subset each weight to woff2.
subset() { # ttf out [charset-file]
  pyftsubset "$1" --text-file="${3:-$WORK/charset.txt}" --flavor=woff2 --no-hinting \
      --layout-features=kern --output-file="$2"
  printf "  %-24s %s\n" "$(basename "$2")" "$(wc -c < "$2") bytes"
}
subset "$(fetch 55-Regular | tail -1)" fonts/puhuiti-regular.woff2
subset "$(fetch 85-Bold    | tail -1)" fonts/puhuiti-bold.woff2

# 2b. 字制区喜脉体 — the Chinese heading face, one weight so one file. 猫啃网 distributes it
#     with the author's permission and hosts the package itself; the author's own channel is a
#     WeChat account, and their site has closed.
XM_REL="https://www.maoken.com/freefonts/8918.html"
XM_ZIP="$WORK/maoken-ximaiti.zip"
XM_URL="https://oss.maoken.com/%E7%8C%AB%E5%95%83%E5%AD%97%E4%BD%93/%E4%B8%AD%E5%9B%BD%E5%A4%A7%E9%99%86/%E5%AD%97%E5%88%B6%E5%8C%BA%E5%96%9C%E8%84%89%E4%BD%932.000_%E7%8C%AB%E5%95%83%E7%BD%91.zip"
[ -s "$XM_ZIP" ] || curl -fL --max-time 900 -A "Mozilla/5.0" -e "$XM_REL" -o "$XM_ZIP" "$XM_URL"
rm -rf "$WORK/ximai" && unzip -o -q "$XM_ZIP" -d "$WORK/ximai"
XM_TTF="$(find "$WORK/ximai" -name '字制区喜脉体.ttf' | head -1)"
[ -n "$XM_TTF" ] || { echo "喜脉体.ttf not found in $XM_ZIP" >&2; exit 1; }
subset "$XM_TTF" fonts/ximaiti-regular.woff2 "$WORK/ximai-charset.txt"

# 3. Rewrite the unicode-range of the Chinese @font-face rules so the CSS keeps describing the
#    files truthfully. PuHuiTi's two weights share one range; 喜脉体 has its own.
python3 - <<'PY'
import io, re
from fontTools.ttLib import TTFont

def ranges_for(files, min_code=0x2000):
    # the floor keeps Latin out of the CJK faces' ranges, where Ubuntu owns it; the display
    # face is declared for its own Latin too, so its floor is 0.
    codes = set()
    for f in files:
        codes |= {c for c in TTFont(f, lazy=True).getBestCmap() if c > min_code}
    codes = sorted(codes)
    out, start, prev = [], codes[0], codes[0]
    for c in codes[1:]:
        if c == prev + 1:
            prev = c
            continue
        out.append((start, prev)); start = prev = c
    out.append((start, prev))
    return ",".join(f"U+{a:X}" if a == b else f"U+{a:X}-{b:X}" for a, b in out)

html = io.open("index.html", encoding="utf-8").read()
for pattern, files, floor in [
    (r"(puhuiti-(?:regular|bold)\.woff2'\) format\('woff2'\)[^}]*?unicode-range:)[^}]*",
     ["fonts/puhuiti-regular.woff2", "fonts/puhuiti-bold.woff2"], 0x2000),
    (r"(ximaiti-regular\.woff2'\) format\('woff2'\)[^}]*?unicode-range:)[^}]*",
     ["fonts/ximaiti-regular.woff2"], 0),
]:
    ur = ranges_for(files, floor)
    html, n = re.subn(pattern, lambda m: m.group(1) + ur, html)
    print(f"  unicode-range updated on {n} rule(s) for {files[0].split('/')[-1]} ({len(ur)} chars)")
io.open("index.html", "w", encoding="utf-8").write(html)
PY

echo "Done. Review the diff, then commit fonts/*.woff2 and index.html."
