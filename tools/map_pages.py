import pypdf
import os
import re

pdf_path = r"C:\Users\Yehya\Pictures\Saber Academy\assets\mushaf\version2\kuran diyanet.pdf"

if not os.path.exists(pdf_path):
    with open("tools/page_mapping.txt", "w", encoding="utf-8") as f:
        f.write("PDF not found!")
    exit(1)

reader = pypdf.PdfReader(pdf_path)
total_pages = len(reader.pages)

results = []
results.append(f"Total pages in PDF: {total_pages}\n")

# Let's inspect pages from idx 0 to total_pages-1
for i in range(total_pages):
    page = reader.pages[i]
    text = page.extract_text() or ""
    
    # Try to find page numbers
    # Remove whitespace from beginning and search for digits
    stripped = text.strip()
    match_start = re.match(r'^([\d٠١٢٣٤٥٦٧٨٩]+)', stripped)
    start_num = match_start.group(1) if match_start else ""
    
    # Also find if there is a number at the end
    match_end = re.search(r'([\d٠١٢٣٤٥٦٧٨٩]+)$', stripped)
    end_num = match_end.group(1) if match_end else ""
    
    # Let's check some surah names in this page
    # Since fonts are custom, we will just print the page snippet
    first_line = stripped.split("\n")[0] if stripped else ""
    last_line = stripped.split("\n")[-1] if stripped else ""
    
    results.append(f"PDF Page {i+1} (idx {i}): StartNum='{start_num}' EndNum='{end_num}' | First: '{first_line[:50]}' | Last: '{last_line[:50]}'")

with open("tools/page_mapping.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(results))

print("Done! Mapping written to tools/page_mapping.txt")
