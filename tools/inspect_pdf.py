import sys
import pypdf
import os

# Reconfigure stdout to use UTF-8
sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r"C:\Users\Yehya\Pictures\Saber Academy\assets\mushaf\version2\kuran diyanet.pdf"

if not os.path.exists(pdf_path):
    print("PDF not found!")
    exit(1)

reader = pypdf.PdfReader(pdf_path)
total_pages = len(reader.pages)
print(f"Total pages in PDF: {total_pages}")

# Let's inspect the first 25 pages and check if we can extract text or if it's purely image-based.
print("\n--- Inspecting First 25 Pages ---")
for i in range(min(25, total_pages)):
    page = reader.pages[i]
    text = page.extract_text() or ""
    text_snippet = text.strip().replace("\n", " ")[:150]
    print(f"Page {i+1} (0-indexed {i}): length of text = {len(text)}, snippet: {text_snippet}")

# Check pages around 600
print("\n--- Inspecting Last Pages ---")
for i in range(max(0, total_pages - 15), total_pages):
    page = reader.pages[i]
    text = page.extract_text() or ""
    text_snippet = text.strip().replace("\n", " ")[:150]
    print(f"Page {i+1} (0-indexed {i}): length of text = {len(text)}, snippet: {text_snippet}")
