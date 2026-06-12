import pypdf
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r"C:\Users\Yehya\Pictures\Saber Academy\assets\mushaf\version2\kuran diyanet.pdf"

if not os.path.exists(pdf_path):
    print("PDF not found!")
    exit(1)

reader = pypdf.PdfReader(pdf_path)
total_pages = len(reader.pages)

# List of 114 Surahs in order
surah_names = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
    'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر', 'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
    'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
    'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة', 'الحديد', 'المجادلة', 'الحشـر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',
    'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
    'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
    'المسد', 'الإخلاص', 'الفلق', 'الناس'
]

print(f"Total pages: {total_pages}")

surah_matches = []

# Scan all pages for the word 'iChKźiŎ' (which represents "سورة")
for i in range(1, 607): # Quran pages are from PDF Page 2 to 607 (0-indexed 1 to 606)
    page = reader.pages[i]
    text = page.extract_text() or ""
    
    # Check if 'iChKźiŎ' is in the text
    if 'iChKźiŎ' in text:
        # Find the line containing it
        lines = text.split("\n")
        for line in lines:
            if 'iChKźiŎ' in line:
                surah_matches.append((i + 1, line.strip())) # Save 1-indexed page and the line

print(f"Found {len(surah_matches)} Surah header occurrences:")
for page_num, line in surah_matches:
    print(f"PDF Page {page_num}: {line}")

# Let's save them to a file for analysis
with open("tools/detected_surahs.txt", "w", encoding="utf-8") as f:
    for page_num, line in surah_matches:
        f.write(f"PDF Page {page_num}: {line}\n")
