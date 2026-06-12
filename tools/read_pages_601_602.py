import pypdf
import sys

sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r"C:\Users\Yehya\Pictures\Saber Academy\assets\mushaf\version2\kuran diyanet.pdf"
reader = pypdf.PdfReader(pdf_path)

# PDF Page 600 to 602 (0-indexed: 599 to 601)
for page_num in range(599, 602):
    print(f"\n--- PDF Page {page_num + 1} ---")
    page = reader.pages[page_num]
    text = page.extract_text()
    lines = text.split("\n")
    for i, line in enumerate(lines):
        print(f"Line {i+1}: {line}")
