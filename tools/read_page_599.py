import pypdf
import sys

sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r"C:\Users\Yehya\Pictures\Saber Academy\assets\mushaf\version2\kuran diyanet.pdf"
reader = pypdf.PdfReader(pdf_path)

# PDF Page 597 to 599 (0-indexed: 596 to 598)
for page_num in range(596, 599):
    print(f"\n--- PDF Page {page_num + 1} ---")
    page = reader.pages[page_num]
    text = page.extract_text()
    lines = text.split("\n")
    for i, line in enumerate(lines):
        print(f"Line {i+1}: {line}")
