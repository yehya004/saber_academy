import sys
import pypdf
import os

sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r"C:\Users\Yehya\Pictures\Saber Academy\assets\mushaf\version2\kuran diyanet.pdf"

if not os.path.exists(pdf_path):
    print("PDF not found!")
    exit(1)

reader = pypdf.PdfReader(pdf_path)

def print_outline(outline, depth=0):
    for item in outline:
        if isinstance(item, list):
            print_outline(item, depth + 1)
        else:
            title = item.title
            page_num = None
            try:
                page_num = reader.get_destination_page_number(item) + 1  # 1-indexed
            except Exception as e:
                pass
            print("  " * depth + f"- {title}: Page {page_num}")

outline = reader.outline
if outline:
    print("PDF Outline found:")
    print_outline(outline)
else:
    print("No PDF Outline found.")
