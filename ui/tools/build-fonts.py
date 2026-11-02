"""Builds static, subsetted TTFs from the Google Sans Flex variable font.

Usage (from UI): python tools\build-fonts.py [path\to\flex.ttf]
Requires: pip install fonttools brotli
"""
import os
import shutil
import sys
import urllib.request
from urllib.parse import quote

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "assets", "fonts"))
SRC_DIR = os.path.join(os.environ.get("TEMP", HERE), "gsf")
BASE_URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/googlesansflex/"
VF_NAME = "GoogleSansFlex[ROND,opsz,slnt,wdth,wght].ttf"

WEIGHTS = [("Regular", 400), ("Medium", 500), ("SemiBold", 600), ("Bold", 700)]
FAMILIES = [("GoogleSansFlex", "Google Sans Flex", 0), ("GoogleSansFlexRounded", "Google Sans Flex Rounded", 100)]

RANGES = [
    (0x0020, 0x007E), (0x00A0, 0x00FF), (0x0100, 0x017F), (0x2000, 0x206F),
    (0x2190, 0x21FF), (0x20A0, 0x20CF), (0x0400, 0x04FF), (0x0370, 0x03FF),
]
EXTRA = [0x2022, 0x2713, 0x2715, 0x00D7, 0x2212, 0x2026]
FEATURES = ["kern", "liga", "calt", "ccmp", "locl", "mark", "mkmk"]


def unicodes():
    s = set(EXTRA)
    for a, b in RANGES:
        s.update(range(a, b + 1))
    return sorted(s)


def fetch(path, name, url_name):
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        urllib.request.urlretrieve(BASE_URL + quote(url_name), path)


def set_names(font, family, style, weight):
    ribbi = style in ("Regular", "Bold")
    legacy_family = family if ribbi else f"{family} {style}"
    legacy_style = style if ribbi else "Regular"
    ps = family.replace(" ", "") + "-" + style
    full = f"{family} {style}"
    name = font["name"]
    keep = {0, 7, 8, 9, 11, 12, 13, 14, 15}
    name.names = [n for n in name.names if n.nameID in keep]
    for pid, eid, lid in ((3, 1, 0x409), (1, 0, 0)):
        for nid, val in (
            (1, legacy_family), (2, legacy_style), (3, f"{ps};static"), (4, full), (6, ps),
            (16, family), (17, style),
        ):
            name.setName(val, nid, pid, eid, lid)
    os2 = font["OS/2"]
    os2.usWeightClass = weight
    sel = os2.fsSelection & ~(0x01 | 0x20 | 0x40)
    sel |= 0x20 if style == "Bold" else 0x40 if style == "Regular" else 0x40
    if style != "Bold":
        sel &= ~0x20
    os2.fsSelection = sel
    font["head"].macStyle = 1 if style == "Bold" else 0
    font["post"].italicAngle = 0


def build(vf_path):
    uni = unicodes()
    for file_base, family, rond in FAMILIES:
        for style, wght in WEIGHTS:
            vf = TTFont(vf_path)
            inst = instancer.instantiateVariableFont(
                vf, {"wght": wght, "ROND": rond, "wdth": 100, "opsz": 16, "slnt": 0},
                inplace=False,
            )
            opts = subset.Options()
            opts.layout_features = FEATURES
            opts.hinting = False
            opts.flavor = None
            opts.notdef_outline = True
            opts.name_IDs = [0, 1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17]
            opts.name_languages = [0x409]
            opts.glyph_names = False
            opts.drop_tables += ["STAT", "DSIG", "MVAR", "HVAR", "VVAR", "avar", "fvar", "gvar", "cvar"]
            sub = subset.Subsetter(opts)
            sub.populate(unicodes=uni)
            sub.subset(inst)
            set_names(inst, family, style, wght)
            out = os.path.join(OUT, f"{file_base}-{style}.ttf")
            inst.save(out)
            print("wrote", out, os.path.getsize(out))


def verify():
    ok = True
    for file_base, family, _ in FAMILIES:
        for style, wght in WEIGHTS:
            p = os.path.join(OUT, f"{file_base}-{style}.ttf")
            f = TTFont(p)
            cmap = f.getBestCmap()
            ascii_ok = all(c in cmap for c in range(0x20, 0x7F))
            has_gpos = "GPOS" in f
            good = "fvar" not in f and ascii_ok and f["OS/2"].usWeightClass == wght
            ok &= good
            print(f"{os.path.basename(p):38} glyphs={len(f.getGlyphOrder()):5} size={os.path.getsize(p):7} "
                  f"fvar={'fvar' in f} ascii={ascii_ok} GPOS={has_gpos} "
                  f"name={f['name'].getDebugName(4)!r} {'OK' if good else 'FAIL'}")
    return ok


def main():
    vf = sys.argv[1] if len(sys.argv) > 1 else os.path.join(SRC_DIR, "flex.ttf")
    fetch(vf, "flex", VF_NAME)
    ofl = os.path.join(os.path.dirname(vf), "OFL.txt")
    fetch(ofl, "OFL", "OFL.txt")
    os.makedirs(OUT, exist_ok=True)
    shutil.copyfile(ofl, os.path.join(OUT, "OFL.txt"))
    build(vf)
    if not verify():
        sys.exit(1)


if __name__ == "__main__":
    main()
