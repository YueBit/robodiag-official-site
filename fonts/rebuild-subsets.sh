#!/usr/bin/env bash
# Rebuild the Alibaba PuHuiTi web subsets from the official source and update the
# unicode-range in index.html. Run after editing any Chinese copy.
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

# 2. Subset each weight to woff2.
subset() { # ttf out weight-decl
  pyftsubset "$1" --text-file="$WORK/charset.txt" --flavor=woff2 --no-hinting \
      --layout-features=kern --output-file="$2"
  printf "  %-24s %s\n" "$(basename "$2")" "$(wc -c < "$2") bytes"
}
subset "$(fetch 55-Regular | tail -1)" fonts/puhuiti-regular.woff2
subset "$(fetch 85-Bold    | tail -1)" fonts/puhuiti-bold.woff2

# 3. Rewrite the unicode-range of the two PuHuiTi @font-face rules so the CSS keeps
#    describing the files truthfully.
python3 - <<'PY'
import io, re
from fontTools.ttLib import TTFont

codes = set()
for f in ("fonts/puhuiti-regular.woff2", "fonts/puhuiti-bold.woff2"):
    codes |= {c for c in TTFont(f, lazy=True).getBestCmap() if c > 0x2000}  # Ubuntu owns Latin
codes = sorted(codes)
ranges, start, prev = [], codes[0], codes[0]
for c in codes[1:]:
    if c == prev + 1:
        prev = c
        continue
    ranges.append((start, prev)); start = prev = c
ranges.append((start, prev))
ur = ",".join(f"U+{a:X}" if a == b else f"U+{a:X}-{b:X}" for a, b in ranges)

html = io.open("index.html", encoding="utf-8").read()
new, n = re.subn(r"(?<=puhuiti-(?:regular|bold)\.woff2'\)) format\('woff2'\)[^}]*?unicode-range:)[^}]*",
                 lambda m: m.group(1) + ur, html)
io.open("index.html", "w", encoding="utf-8").write(new)
print(f"  unicode-range updated on {n} @font-face rules ({len(ur)} chars)")
PY

echo "Done. Review the diff, then commit fonts/*.woff2 and index.html."
