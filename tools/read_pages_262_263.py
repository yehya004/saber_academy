import pypdf
import sys

sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r"C:\Users\Yehya\Pictures\Saber Academy\assets\mushaf\version2\kuran diyanet.pdf"
reader = pypdf.PdfReader(pdf_path)

# PDF Page 261 to 264 (0-indexed: 260 to 263)
for page_num in range(260, 264):
    print(f"\n--- PDF Page {page_num + 1} ---")
    page = reader.pages[page_num]
    text = page.extract_text()
    lines = text.split("\n")
    for i, line in enumerate(lines):
        print(f"Line {i+1}: {line}")
