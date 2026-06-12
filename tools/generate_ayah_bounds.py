"""
generate_ayah_bounds.py
Precomputes accurate bounding boxes for all 6236 Quran verses using:
  - assets/quran/ayah_positions.csv  (QuranHub: aya_id,page,x,y of verse-number circle)
  - Quran.com API v4 (line_number per word → which line(s) each verse occupies)

Output: assets/quran/ayah_bounds.csv  (aya_id,page,x1,y1,x2,y2)
"""

import csv, time, sys, json
from collections import defaultdict

try:
    import requests
except ImportError:
    sys.exit("Run: pip install requests")

# ── Constants (QuranHub KFGQPC Hafs-Wasat image dimensions) ──────────────────
TEXT_LEFT   = 78.0   # left margin of text block in original image px
TEXT_RIGHT  = 652.0  # right margin
LINE_HALF_H = 27.0   # half the vertical line pitch (~53 px pitch → 26.5)
PAGE_TOP_Y  = 60.0   # approximate Y of the top text line centre on any page
LINE_PITCH  = 53.0   # default line pitch estimate (refined per page)

# ── Load data.csv ─────────────────────────────────────────────────────────────
print("Loading ayah_positions.csv …")
positions   = {}                      # aya_id → (page, x, y)
page_verses = defaultdict(list)       # page  → [(aya_id, x, y)]

with open("assets/quran/ayah_positions.csv", newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        aid = int(row["aya_id"])
        pg  = int(row["page"])
        x   = float(row["x"])
        y   = float(row["y"])
        positions[aid] = (pg, x, y)
        page_verses[pg].append((aid, x, y))

for pg in page_verses:
    page_verses[pg].sort()   # sort by aya_id

print(f"  {len(positions)} verses loaded across {len(page_verses)} pages")

# ── Fetch line-number data from Quran.com API ─────────────────────────────────
# aya_id → (first_line, last_line)  on the page typesetting
ayah_lines = {}

SESSION = requests.Session()
SESSION.headers.update({"Accept": "application/json"})

print("Fetching line numbers from Quran.com API (604 pages) …")
failed = []

for pg in range(1, 605):
    url = (f"https://api.quran.com/api/v4/verses/by_page/{pg}"
           f"?words=true&word_fields=line_number&per_page=50")
    for attempt in range(4):
        try:
            r = SESSION.get(url, timeout=30)
            if r.status_code == 200:
                break
            time.sleep(1 + attempt)
        except Exception:
            time.sleep(2 + attempt)
    else:
        print(f"  ⚠ failed page {pg}")
        failed.append(pg)
        continue

    for verse in r.json().get("verses", []):
        aid   = verse["id"]
        lines = [w["line_number"] for w in verse.get("words", [])
                 if w.get("line_number")]
        if lines:
            ayah_lines[aid] = (min(lines), max(lines))

    if pg % 100 == 0:
        print(f"  … page {pg}/604  ({len(ayah_lines)} verses processed)")
    time.sleep(0.05)   # gentle rate-limit

print(f"Got line data for {len(ayah_lines)} verses  (failed pages: {failed})")

# ── Compute bounding boxes ────────────────────────────────────────────────────
print("Computing bounding boxes …")

results = []   # (aya_id, page, x1, y1, x2, y2)

for pg in range(1, 605):
    verses = page_verses.get(pg, [])
    if not verses:
        continue

    # Build line→Y mapping.
    # The circle Y in data.csv = vertical centre of the LAST line of that verse.
    line_y = {}                       # line_number → Y_centre
    for aid, x, y in verses:
        if aid in ayah_lines:
            _, last_line = ayah_lines[aid]
            line_y[last_line] = y     # a later verse on same line overwrites → fine

    # Estimate per-page line pitch from consecutive known lines
    sorted_lines = sorted(line_y)
    pitches = []
    for i in range(len(sorted_lines) - 1):
        lA, lB = sorted_lines[i], sorted_lines[i + 1]
        if lB - lA == 1:
            pitches.append(line_y[lB] - line_y[lA])
    pitch = sum(pitches) / len(pitches) if pitches else LINE_PITCH

    def y_for_line(ln):
        """Estimate Y centre for any line number, interpolating if needed."""
        if ln in line_y:
            return line_y[ln]
        # find nearest known line and extrapolate
        nearest = min(line_y, key=lambda l: abs(l - ln))
        return line_y[nearest] + (ln - nearest) * pitch

    for aid, x, y in verses:
        if aid not in ayah_lines:
            # fallback: single-line box around circle
            results.append((aid, pg,
                            TEXT_LEFT, round(y - LINE_HALF_H, 1),
                            TEXT_RIGHT, round(y + LINE_HALF_H, 1)))
            continue

        first_line, last_line = ayah_lines[aid]

        top_y    = y_for_line(first_line) - LINE_HALF_H
        bottom_y = y_for_line(last_line)  + LINE_HALF_H

        results.append((aid, pg,
                        TEXT_LEFT,  round(max(0, top_y),  1),
                        TEXT_RIGHT, round(bottom_y,        1)))

print(f"  {len(results)} bounding boxes computed")

# ── Write output ──────────────────────────────────────────────────────────────
out_path = "assets/quran/ayah_bounds.csv"
with open(out_path, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["aya_id", "page", "x1", "y1", "x2", "y2"])
    w.writerows(results)

print(f"Saved → {out_path}  ({len(results)} rows)")
if failed:
    print(f"WARNING: data for pages {failed} was estimated (API failures)")
