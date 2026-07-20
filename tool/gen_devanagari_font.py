#!/usr/bin/env python3
"""Generate the pre-shaped Devanagari PDF font + conjunct map.

The `pdf` Dart package renders glyphs by codepoint with no OpenType
shaping, so conjuncts (क्र, स्व, र्य…) degrade to visible-halant
typewriter forms. This script bakes properly shaped conjuncts into
glyphs reachable by plain codepoint lookup:

  1. every two-consonant core C1+virama+C2 over the full consonant set
     (exhaustive — covers any normal Hindi, including user content),
  2. every longer core found in the shipped Hindi corpus
     (lib/l10n/app_hi.arb + the intl month/weekday names),
  3. every consonant+matra pair that HarfBuzz ligates into a single
     glyph — the special base forms रु, रू, हृ… (गुरु was printing र
     with a detached hook without this),
  4. every repha core (र्X…) with each right/top matra — the repha
     repositions over the matra stem (र्मा in वर्मा), which a frozen
     core glyph followed by a loose matra cannot do,

each shaped with HarfBuzz against Noto Sans Devanagari, its glyph run
flattened into ONE new simple glyph (outlines drawn at the shaped
offsets, so half-forms, rakars and repha positioning are baked in),
mapped from a Private Use Area codepoint (U+E000…).

Outputs (both committed, so regeneration is only needed when this
script, the corpus triples, or the source font change):
  assets/kj_devanagari_pdf.ttf     — renamed per OFL ("Noto" is an RFN)
  lib/pdf/devanagari_conjuncts.g.dart — core string → PUA char

Run from the package root:
  python3 -m venv .venv && .venv/bin/pip install fonttools uharfbuzz
  .venv/bin/python tool/gen_devanagari_font.py
"""

import json
import re
import sys
from pathlib import Path

import uharfbuzz as hb
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
SRC_FONT = ROOT / "tool" / "fonts" / "NotoSansDevanagari-Regular.ttf"
OUT_FONT = ROOT / "assets" / "kj_devanagari_pdf.ttf"
OUT_DART = ROOT / "lib" / "pdf" / "devanagari_conjuncts.g.dart"
ARB = ROOT / "lib" / "l10n" / "app_hi.arb"

FAMILY = "KJ Devanagari PDF"
PUA_START = 0xE000

VIRAMA = "्"
NUKTA = "़"
# Base consonants क..ह, the precomposed nukta forms क़..य़, AND their
# decomposed spellings (base + ़) — arb strings arrive both ways
# (सॉफ़्टवेयर ships फ+़ decomposed) and the runtime matcher does exact
# codepoint lookup, so both spellings need map entries.
_NUKTA_BASES = "कखगजडढफय"
CONSONANTS = (
    [chr(c) for c in range(0x0915, 0x093A)]
    + [chr(c) for c in range(0x0958, 0x0960)]
    + [c + NUKTA for c in _NUKTA_BASES]
)

# The intl package's Hindi month + weekday names appear in every dasha
# table but live outside the arb, so their cores are pinned here.
INTL_HI = (
    "जनवरी फ़रवरी मार्च अप्रैल मई जून जुलाई अगस्त सितंबर अक्तूबर नवंबर दिसंबर "
    "रविवार सोमवार मंगलवार बुधवार गुरुवार शुक्रवार शनिवार"
)

# Dependent vowel signs that can ligate with their base
# (\u0930\u0941 \u0930\u0942 \u0939\u0943 = ru/ruu/hr etc.).
MATRAS = [chr(c) for c in (0x0941, 0x0942, 0x0943, 0x0944, 0x0962, 0x0963)]

# Right/top dependent vowels that pull a repha onto their stem.
REPHA_MATRAS = [chr(c) for c in
                (0x093E, 0x0940, 0x0947, 0x0948, 0x0949, 0x094B, 0x094C)]

_CC = r"[क-हक़-य़]़?"
CORE_RE = re.compile(f"{_CC}(?:{VIRAMA}{_CC})+")


def corpus_cores() -> set[str]:
    text = INTL_HI
    if ARB.exists():
        data = json.loads(ARB.read_text(encoding="utf-8"))
        text += " ".join(v for k, v in data.items()
                         if not k.startswith("@") and isinstance(v, str))
    else:
        sys.exit(f"missing {ARB}")
    return set(CORE_RE.findall(text))


def main() -> None:
    clusters = {f"{c1}{VIRAMA}{c2}" for c1 in CONSONANTS for c2 in CONSONANTS}
    from_corpus = corpus_cores() - clusters
    clusters |= from_corpus
    # Consonant+matra pairs join the set; only truly ligating ones
    # (single output glyph) are kept in the map below.
    ligature_pairs = sorted(f"{c}{m}" for c in CONSONANTS for m in MATRAS)
    repha_variants = sorted(
        f"{core}{m}"
        for core in clusters
        if core.startswith(("\u0930\u094D", "\u0931\u094D"))
        for m in REPHA_MATRAS)
    ordered = sorted(clusters)
    if (PUA_START + len(ordered) + len(ligature_pairs)
            + len(repha_variants)) > 0xF8FF:
        sys.exit("PUA exhausted — reduce the cluster set")

    blob = hb.Blob.from_file_path(str(SRC_FONT))
    hb_font = hb.Font(hb.Face(blob))
    upem = hb_font.face.upem
    hb_font.scale = (upem, upem)

    tt = TTFont(str(SRC_FONT))
    glyph_order = tt.getGlyphOrder()
    glyph_set = tt.getGlyphSet()
    glyf, hmtx = tt["glyf"], tt["hmtx"]
    halant_gid = tt.getBestCmap().get(0x094D)

    def shape(cluster):
        buf = hb.Buffer()
        buf.add_str(cluster)
        buf.guess_segment_properties()
        hb.shape(hb_font, buf)
        return buf

    mapping: dict[str, int] = {}
    unshaped = 0

    def bake(cluster, buf):
        pen = TTGlyphPen(glyph_set)
        x = 0
        for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
            name = glyph_order[info.codepoint]
            glyph_set[name].draw(
                TransformPen(pen, (1, 0, 0, 1, x + pos.x_offset, pos.y_offset)))
            x += pos.x_advance
        new_glyph = pen.glyph()
        pua = PUA_START + len(mapping)
        new_name = f"kjconj{pua:04X}"
        glyf[new_name] = new_glyph  # also appends to the shared glyphOrder
        new_glyph.recalcBounds(glyf)
        lsb = new_glyph.xMin if new_glyph.numberOfContours > 0 else 0
        hmtx[new_name] = (x, lsb)
        mapping[cluster] = pua

    for cluster in ordered:
        buf = shape(cluster)
        if halant_gid in (glyph_order[g.codepoint] for g in buf.glyph_infos):
            # No conjunct forms for this pair — bake it anyway so the
            # runtime map is total and the "no visible virama in shipped
            # strings" guard stays a simple invariant.
            unshaped += 1
        bake(cluster, buf)

    # Base+matra ligatures (रु रू हृ …): keep only pairs the font truly
    # fuses into one glyph — everything else is a plain mark attachment
    # that already renders acceptably.
    ligated = 0
    for pair in ligature_pairs:
        buf = shape(pair)
        if len(buf.glyph_infos) == 1:
            bake(pair, buf)
            ligated += 1

    # Repha cores + right/top matra: always baked — the repha moves
    # onto the matra stem, which the core glyph alone can't express.
    for variant in repha_variants:
        bake(variant, shape(variant))

    tt.setGlyphOrder(glyph_order)
    tt["maxp"].numGlyphs = len(glyph_order)
    for table in tt["cmap"].tables:
        if table.isUnicode():
            for cluster, pua in mapping.items():
                table.cmap[pua] = f"kjconj{pua:04X}"

    # The PDF renderer never shapes, so the layout tables are dead
    # weight in the asset.
    for tag in ("GSUB", "GPOS", "GDEF"):
        if tag in tt:
            del tt[tag]

    # OFL: "Noto" is a Reserved Font Name — the derivative must not
    # carry it. License + copyright records stay.
    name = tt["name"]
    for rec in name.names:
        if rec.nameID in (1, 3, 4, 6, 16):
            s = rec.toUnicode().replace("Noto Sans Devanagari", FAMILY)
            name.setName(s.replace(" ", "") if rec.nameID == 6 else s,
                         rec.nameID, rec.platformID, rec.platEncID, rec.langID)

    OUT_FONT.parent.mkdir(exist_ok=True)
    tt.save(str(OUT_FONT))

    lines = [
        "// GENERATED by tool/gen_devanagari_font.py — do not edit.",
        "// Conjunct cores (consonants+virama) and ligating base+matra",
        "// pairs (रु रू दृ हृ…) to the PUA codepoint whose glyph in",
        "// assets/kj_devanagari_pdf.ttf is the HarfBuzz-shaped form.",
        "// See lib/pdf/devanagari.dart.",
        "",
        "const Map<String, String> devanagariConjuncts = {",
    ]
    for cluster in sorted(mapping):
        lines.append(f"  '{cluster}': '\\u{mapping[cluster]:04X}',")
    lines.append("};")
    OUT_DART.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"clusters: {len(ordered)} ({len(from_corpus)} extra cores from "
          f"corpus, {unshaped} pairs with no conjunct form) + "
          f"{ligated} base+matra ligatures + "
          f"{len(repha_variants)} repha+matra variants")
    print(f"font: {OUT_FONT} ({OUT_FONT.stat().st_size // 1024} KB)")
    print(f"map:  {OUT_DART} ({OUT_DART.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
