import sys
import re

# Reconfigure stdout for utf-8 output to avoid Windows console encoding issues
sys.stdout.reconfigure(encoding='utf-8')

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

# Read detected_surahs.txt
with open("tools/detected_surahs.txt", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Clean the lines to extract the core Surah name pattern
def clean_surah_name(text):
    # Remove 'iChKźiŎ' (سورة)
    text = text.replace("iChKźiŎ", "")
    # Remove Meccan/Medinan indicators and common header filler words
    fillers = [
        "fĹğžkjŭhŲ", "fĹğžjȫhŉhŲ", "fĹhkžjȫhŉhŲ", "fĹhkžkjŭhŲ",
        "hjǗhb", "hżjŸhb", "eĹhŽŠA", "h`źišlĸhŎhb", "fōlhƨ", "g`ĵhųhȪ",
        "h`biŋjŦhǾlůA", "jlǲğȍA", "lĺğĸhȩ", "h`biŋjŦhǾlůA", "h`bilǬjŠhb", "fşlŏjȶ"
    ]
    for filler in fillers:
        text = text.replace(filler, "")
    
    # Remove Juz' indicators or Arabic numbers that might appear in the headers
    # e.g., "ÐÍ É ÌǄÉÌŪÈ¦", "ÔÕ É¨È°ȂČǈǳÈ¦"
    text = re.sub(r"[\u00c0-\u00ff]\u00cd\s+É¨È°ȂČǈǳÈ¦", "", text) # page/juz indicators
    text = re.sub(r"É¨È°ȂČǈǳÈ¦", "", text)
    text = re.sub(r"É ÌǄÉÌŪÈ¦", "", text)
    # Remove any extra punctuation or spaces
    text = re.sub(r"[\s\d\.\:\-\|\,]+", " ", text).strip()
    return text

# Map each page to its cleaned Surah name candidates
page_candidates = {}
for line in lines:
    match = re.match(r"PDF Page (\d+): (.*)", line)
    if match:
        page = int(match.group(1))
        content = match.group(2)
        cleaned = clean_surah_name(content)
        if cleaned:
            if page not in page_candidates:
                page_candidates[page] = []
            if cleaned not in page_candidates[page]:
                page_candidates[page].append(cleaned)

# Let's print out what we see for the first 100 pages to inspect
with open("tools/cleaned_names.txt", "w", encoding="utf-8") as f:
    for p in sorted(page_candidates.keys()):
        f.write(f"Page {p}: {page_candidates[p]}\n")

print("Cleaned Surah names written to tools/cleaned_names.txt")
