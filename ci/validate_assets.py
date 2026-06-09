#!/usr/bin/env python3
"""CI validation of the WWTBAM data files.

Checks that the shipped archive and the unmasked assets are intact and in
the formats the game expects (see docs/REVERSE_ENGINEERING.md).
"""
import struct
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
failures = []


def check(ok, msg):
    print(("ok   " if ok else "FAIL ") + msg)
    if not ok:
        failures.append(msg)


# --- WWTBAM.DAT is a ZIP with the 17 game files -----------------------------
EXPECTED = {
    "WWTBAM.EXE",
    "F1.BBK", "F2.BBK", "F3.BBK", "F4.BBK", "F5.BBK",
    "P1.BBK",
    "QL1.BBK", "QL2.BBK", "QL3.BBK",
    "QM.BBK",
    "A1.BBK", "A2.BBK", "A31.BBK", "A32.BBK", "A4.BBK", "A5.BBK",
}
dat = ROOT / "WWTBAM.DAT"
check(dat.exists(), "WWTBAM.DAT exists")
zf = zipfile.ZipFile(dat)
names = set(zf.namelist())
check(names == EXPECTED, f"WWTBAM.DAT contains exactly the 17 game files (got {len(names)})")
check(zf.testzip() is None, "WWTBAM.DAT zip integrity")

# --- question banks: 7 lines per question, answer must be an option ---------
for name, path in [
    ("QL1.BBK", "assets/ql1-questions-easy.txt"),
    ("QL2.BBK", "assets/ql2-questions-medium.txt"),
    ("QL3.BBK", "assets/ql3-questions-hard.txt"),
]:
    raw = (ROOT / path).read_bytes()
    check(raw == zf.read(name), f"{path} matches {name} inside WWTBAM.DAT")
    lines = raw.decode("ascii", "replace").splitlines()
    check(len(lines) % 7 == 0, f"{path}: line count {len(lines)} is a multiple of 7")
    nq = len(lines) // 7
    check(nq >= 5, f"{path}: at least 5 questions (game minimum), has {nq}")
    for q in range(nq):
        rec = lines[q * 7:(q + 1) * 7]
        options, answer = rec[2:6], rec[6]
        if answer not in options:
            check(False, f"{path} question {q + 1}: answer {answer!r} not among options")

# --- fonts: 4-byte width/height header + 256 glyphs --------------------------
for name, path in [(f"F{i}.BBK", f"assets/f{i}.fnt") for i in range(1, 6)]:
    data = (ROOT / path).read_bytes()
    check(data == zf.read(name), f"{path} matches {name} inside WWTBAM.DAT")
    width, height = struct.unpack("<hh", data[:4])
    check((width, height) in ((8, 16), (8, 14)), f"{path}: glyph size {width}x{height}")
    check(len(data) == 4 + 256 * height, f"{path}: size {len(data)} = 4 + 256*{height}")

# --- the hidden BMP -----------------------------------------------------------
bmp = (ROOT / "assets/p1.bmp").read_bytes()
check(bmp == zf.read("P1.BBK"), "assets/p1.bmp matches P1.BBK inside WWTBAM.DAT")
check(bmp[:2] == b"BM", "p1.bmp: BMP magic")
w, h = struct.unpack_from("<ii", bmp, 18)
bpp = struct.unpack_from("<H", bmp, 28)[0]
check((w, h, bpp) == (239, 520, 24), f"p1.bmp: 239x520x24 (got {w}x{h}x{bpp})")

# --- the EXEs are MZ executables ----------------------------------------------
for name in ["WWTBAM.EXE", "QM.BBK", "A1.BBK", "A2.BBK", "A31.BBK", "A32.BBK", "A4.BBK", "A5.BBK"]:
    check(zf.read(name)[:2] == b"MZ", f"{name}: MZ executable magic")
for name in ["SETUP.EXE", "SETUP.DAT"]:
    check((ROOT / name).read_bytes()[:2] == b"MZ", f"{name}: MZ executable magic")

print()
if failures:
    print(f"{len(failures)} check(s) failed")
    sys.exit(1)
print("all checks passed")
