"""
generate_madani_bounds.py
Generates ayah position data for the official Madani mushaf images
(files.quran.app/hafs/madani/width_1260/pageNNN.png, 1260×2038 px).

Outputs:
  assets/quran/ayah_bounds.csv      – aya_id,page,x1,y1,x2,y2
  assets/quran/ayah_positions.csv   – aya_id,page,x,y  (end-marker estimates)

Data source: Quran.com API v4 (line_number per word, 604 pages).
Y calibration: measured from pixel analysis of page003.png (1260×2038).
"""

import csv, time, sys, json
from collections import defaultdict

import json as _json
from http.client import HTTPSConnection
import ssl as _ssl

_SSL_CTX = _ssl.create_default_context()

def _get_json(path: str, host: str = "api.quran.com") -> dict:
    """Simple HTTPS GET returning parsed JSON (no third-party deps)."""
    for attempt in range(5):
        try:
            conn = HTTPSConnection(host, context=_SSL_CTX, timeout=30)
            conn.request("GET", path, headers={"Accept": "application/json"})
            resp = conn.getresponse()
            if resp.status == 200:
                data = _json.loads(resp.read())
                conn.close()
                return data
            conn.close()
        except Exception:
            pass
        time.sleep(1.5 + attempt)
    return {}

# ── Image constants (1260×2038 Madani PNG) ────────────────────────────────────
IMG_W       = 1260.0
IMG_H       = 2038.0
TEXT_LEFT   = 91.0    # leftmost text column (measured from page003 pixel scan)
TEXT_RIGHT  = 1178.0  # rightmost text column
LINE_HALF_H = 65.0    # half of ~130 px line pitch

# Y centres of lines 1–15 on a standard page (measured from page003.png).
# Lines 1–2 may be the surah header on pages that start a new surah.
_LINE_Y_TABLE = {
    1:  82,
    2:  215,
    3:  345,
    4:  478,
    5:  609,
    6:  744,
    7:  874,
    8:  1007,
    9:  1140,
    10: 1269,
    11: 1406,
    12: 1540,
    13: 1676,
    14: 1804,
    15: 1940,
}
_LINE_PITCH = 133.0   # average spacing between consecutive lines

def line_y(line_num: int) -> float:
    """Return the Y centre for any line number (extrapolate outside 1–15)."""
    if line_num in _LINE_Y_TABLE:
        return float(_LINE_Y_TABLE[line_num])
    # Extrapolate from the nearest boundary
    if line_num < 1:
        return _LINE_Y_TABLE[1] + (line_num - 1) * _LINE_PITCH
    return _LINE_Y_TABLE[15] + (line_num - 15) * _LINE_PITCH


# ── Fetch line data from Quran.com API ────────────────────────────────────────
print("Fetching word/line data from Quran.com API (604 pages)…")

# ayah_lines[aya_id] = (first_line, last_line)
ayah_lines: dict[int, tuple[int, int]] = {}

# For each page/line: ordered list of (aya_id, word_count_on_this_line)
#   The API returns words in Quran order (right-to-left in the image).
page_line_verses: dict[int, dict[int, list[tuple[int, int]]]] = {}
#   page → line → [(aya_id, words_count_on_line)]

# ayah page mapping
ayah_page: dict[int, int] = {}

failed = []
for pg in range(1, 605):
    path = (f"/api/v4/verses/by_page/{pg}"
            f"?words=true&word_fields=line_number&per_page=50")
    data = _get_json(path)
    if not data:
        print(f"  ⚠ page {pg} failed, skipping")
        failed.append(pg)
        continue

    page_line_verses[pg] = defaultdict(list)

    for verse in data.get("verses", []):
        aid = verse["id"]
        ayah_page[aid] = pg
        words = verse.get("words", [])
        lines_seen = [w["line_number"] for w in words if w.get("line_number")]
        if not lines_seen:
            continue
        first_line = min(lines_seen)
        last_line  = max(lines_seen)
        ayah_lines[aid] = (first_line, last_line)

        # Count words per line for this verse
        from collections import Counter
        line_counts = Counter(lines_seen)
        for ln, cnt in line_counts.items():
            page_line_verses[pg][ln].append((aid, cnt))

    if pg % 100 == 0:
        print(f"  … {pg}/604  ({len(ayah_lines)} verses)")
    time.sleep(0.05)

print(f"Done. Got line data for {len(ayah_lines)} verses.  Failed pages: {failed}")

# ── Compute bounding boxes and circle X estimates ─────────────────────────────
# For the circle X estimate:
#   Arabic is RTL → on a shared line verse N (earlier) is to the RIGHT of verse N+1.
#   We estimate the circle X of each verse as the LEFT boundary of its words on
#   its last line = TEXT_RIGHT minus the fraction of words that precede this
#   verse (from verses read BEFORE it on the same line).
#   fraction = words_before / total_words_on_line
#   circle_x = TEXT_RIGHT - fraction * (TEXT_RIGHT - TEXT_LEFT)
# (When a verse is the ONLY one on its last line, circle_x = TEXT_LEFT.)

print("Computing bounding boxes and circle positions…")

bounds_rows:    list[tuple] = []  # (aya_id, page, x1, y1, x2, y2)
positions_rows: list[tuple] = []  # (aya_id, page, x, y)

for pg in range(1, 605):
    # Build per-page circle-X lookup using word-count fractions
    circle_x: dict[int, float] = {}

    for ln, verse_list in page_line_verses.get(pg, {}).items():
        # verse_list is in Quran order (RTL → first = rightmost in image)
        total_words = sum(cnt for _, cnt in verse_list)
        if total_words == 0:
            continue
        words_before = 0
        for aid, cnt in verse_list:
            # This verse's LAST segment on this line (may not be last line overall)
            if aid in ayah_lines and ayah_lines[aid][1] == ln:
                # ln IS the last line of this verse
                fraction = words_before / total_words
                cx = TEXT_RIGHT - fraction * (TEXT_RIGHT - TEXT_LEFT)
                circle_x[aid] = cx
            words_before += cnt

    # Verses on this page that the API returned
    page_aids = sorted([aid for aid, p in ayah_page.items() if p == pg])
    for aid in page_aids:
        if aid not in ayah_lines:
            # Fallback: use mid-page single-line band
            cy = IMG_H / 2
            bounds_rows.append((aid, pg,
                                 TEXT_LEFT, round(cy - LINE_HALF_H, 1),
                                 TEXT_RIGHT, round(cy + LINE_HALF_H, 1)))
            positions_rows.append((aid, pg, round((TEXT_LEFT + TEXT_RIGHT) / 2, 1), round(cy, 1)))
            continue

        first_ln, last_ln = ayah_lines[aid]
        top_y    = line_y(first_ln) - LINE_HALF_H
        bottom_y = line_y(last_ln)  + LINE_HALF_H
        top_y    = max(0.0, top_y)
        bottom_y = min(IMG_H, bottom_y)

        cx = circle_x.get(aid, TEXT_LEFT)
        cy = line_y(last_ln)  # Y of last line = where circle sits

        bounds_rows.append((aid, pg,
                             TEXT_LEFT,  round(top_y,    1),
                             TEXT_RIGHT, round(bottom_y, 1)))
        positions_rows.append((aid, pg, round(cx, 1), round(cy, 1)))

print(f"  {len(bounds_rows)} bounding boxes  |  {len(positions_rows)} circle positions")

# ── Write CSVs ────────────────────────────────────────────────────────────────
import os

def _write_csv(path: str, header: list, rows: list):
    """Write CSV directly (or to alt name if original is locked)."""
    targets = [path, path.replace(".csv", "_new.csv")]
    for t in targets:
        try:
            with open(t, "w", newline="", encoding="utf-8") as f:
                w2 = csv.writer(f)
                w2.writerow(header)
                w2.writerows(rows)
            print(f"Saved → {t}")
            return
        except PermissionError:
            continue
    raise IOError(f"Cannot write {path} (locked by another process)")

_write_csv("assets/quran/ayah_bounds.csv",
           ["aya_id", "page", "x1", "y1", "x2", "y2"], bounds_rows)
_write_csv("assets/quran/ayah_positions.csv",
           ["aya_id", "page", "x", "y"], positions_rows)

if failed:
    print(f"\nWARNING: pages {failed} had API failures — those verses use fallback bounds.")
print("Done.")
