import re

# Read detected_surahs.txt
with open("tools/detected_surahs.txt", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Keywords indicating a Surah header block (Meccan / Medinan)
keywords = [
    "fĹğžkjŭhŲ",   # Meccan (مكية)
    "fĹğžjȫhŉhŲ",   # Medinan (مدنية)
    "fĹhkžjȫhŉhŲ",  # Medinan variant
    "fĹhkžkjŭhŲ"   # Meccan variant
]

starts = []
seen_pages = {}

for line in lines:
    # Example line: "PDF Page 2: fĹğžkjŭhŲ jĹhjƕĵhŧlůA iChKźiŎ"
    match = re.match(r"PDF Page (\d+): (.*)", line)
    if match:
        page = int(match.group(1))
        content = match.group(2)
        
        # Check if any keyword matches
        is_start = any(k in content for k in keywords)
        if is_start:
            # We want to extract the Surah name token if possible, or just note the page
            # To avoid duplicates on the same page (e.g. page 606 has both Al-Falaq and An-Nas)
            # we keep all matches but record their order.
            starts.append((page, content.strip()))

print(f"Total starts found: {len(starts)}")
for idx, (page, text) in enumerate(starts):
    print(f"{idx+1}. Page {page}: {text}")

# Save the parsed starts
with open("tools/parsed_starts.txt", "w", encoding="utf-8") as out:
    for idx, (page, text) in enumerate(starts):
        out.write(f"Surah {idx+1}: Page {page} | {text}\n")
