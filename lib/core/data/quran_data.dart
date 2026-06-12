/// Static page-navigation data for the standard Madinah Mushaf (604 pages).
/// Source: KFGQPC hafs-wasat — matches QuranHub/quran-pages-images on GitHub.
library;

class QuranSurah {
  final int    number;
  final String nameAr;
  final int    page;
  const QuranSurah({required this.number, required this.nameAr, required this.page});
}

class QuranJuz {
  final int    number;
  final String openingAr; // opening words of this juz
  final int    page;
  const QuranJuz({required this.number, required this.openingAr, required this.page});
}

class QuranRub {
  final int number; // 1-240
  final int hizb;   // 1-60
  final int rub;    // 1-4 within hizb
  final int page;
  const QuranRub({required this.number, required this.hizb, required this.rub, required this.page});

  String get label {
    switch (rub) {
      case 1:  return 'الحزب $hizb';
      case 2:  return 'ربع الحزب $hizb';
      case 3:  return 'نصف الحزب $hizb';
      default: return 'ثلاثة أرباع الحزب $hizb';
    }
  }
}

abstract final class QuranData {
  // ── 114 Surahs ────────────────────────────────────────────────────────────
  static const List<QuranSurah> surahs = [
    QuranSurah(number: 1,   nameAr: 'الفاتحة',   page: 1),
    QuranSurah(number: 2,   nameAr: 'البقرة',     page: 2),
    QuranSurah(number: 3,   nameAr: 'آل عمران',   page: 50),
    QuranSurah(number: 4,   nameAr: 'النساء',     page: 77),
    QuranSurah(number: 5,   nameAr: 'المائدة',    page: 106),
    QuranSurah(number: 6,   nameAr: 'الأنعام',    page: 128),
    QuranSurah(number: 7,   nameAr: 'الأعراف',    page: 151),
    QuranSurah(number: 8,   nameAr: 'الأنفال',    page: 177),
    QuranSurah(number: 9,   nameAr: 'التوبة',     page: 187),
    QuranSurah(number: 10,  nameAr: 'يونس',       page: 208),
    QuranSurah(number: 11,  nameAr: 'هود',        page: 221),
    QuranSurah(number: 12,  nameAr: 'يوسف',       page: 235),
    QuranSurah(number: 13,  nameAr: 'الرعد',      page: 249),
    QuranSurah(number: 14,  nameAr: 'إبراهيم',    page: 255),
    QuranSurah(number: 15,  nameAr: 'الحجر',      page: 262),
    QuranSurah(number: 16,  nameAr: 'النحل',      page: 267),
    QuranSurah(number: 17,  nameAr: 'الإسراء',    page: 282),
    QuranSurah(number: 18,  nameAr: 'الكهف',      page: 293),
    QuranSurah(number: 19,  nameAr: 'مريم',       page: 305),
    QuranSurah(number: 20,  nameAr: 'طه',         page: 312),
    QuranSurah(number: 21,  nameAr: 'الأنبياء',   page: 322),
    QuranSurah(number: 22,  nameAr: 'الحج',       page: 332),
    QuranSurah(number: 23,  nameAr: 'المؤمنون',   page: 342),
    QuranSurah(number: 24,  nameAr: 'النور',      page: 350),
    QuranSurah(number: 25,  nameAr: 'الفرقان',    page: 359),
    QuranSurah(number: 26,  nameAr: 'الشعراء',    page: 367),
    QuranSurah(number: 27,  nameAr: 'النمل',      page: 377),
    QuranSurah(number: 28,  nameAr: 'القصص',      page: 385),
    QuranSurah(number: 29,  nameAr: 'العنكبوت',   page: 396),
    QuranSurah(number: 30,  nameAr: 'الروم',      page: 404),
    QuranSurah(number: 31,  nameAr: 'لقمان',      page: 411),
    QuranSurah(number: 32,  nameAr: 'السجدة',     page: 415),
    QuranSurah(number: 33,  nameAr: 'الأحزاب',    page: 418),
    QuranSurah(number: 34,  nameAr: 'سبأ',        page: 428),
    QuranSurah(number: 35,  nameAr: 'فاطر',       page: 434),
    QuranSurah(number: 36,  nameAr: 'يس',         page: 440),
    QuranSurah(number: 37,  nameAr: 'الصافات',    page: 446),
    QuranSurah(number: 38,  nameAr: 'ص',          page: 453),
    QuranSurah(number: 39,  nameAr: 'الزمر',      page: 458),
    QuranSurah(number: 40,  nameAr: 'غافر',       page: 467),
    QuranSurah(number: 41,  nameAr: 'فصلت',       page: 477),
    QuranSurah(number: 42,  nameAr: 'الشورى',     page: 483),
    QuranSurah(number: 43,  nameAr: 'الزخرف',     page: 489),
    QuranSurah(number: 44,  nameAr: 'الدخان',     page: 496),
    QuranSurah(number: 45,  nameAr: 'الجاثية',    page: 499),
    QuranSurah(number: 46,  nameAr: 'الأحقاف',    page: 502),
    QuranSurah(number: 47,  nameAr: 'محمد',       page: 507),
    QuranSurah(number: 48,  nameAr: 'الفتح',      page: 511),
    QuranSurah(number: 49,  nameAr: 'الحجرات',    page: 515),
    QuranSurah(number: 50,  nameAr: 'ق',          page: 518),
    QuranSurah(number: 51,  nameAr: 'الذاريات',   page: 520),
    QuranSurah(number: 52,  nameAr: 'الطور',      page: 523),
    QuranSurah(number: 53,  nameAr: 'النجم',      page: 526),
    QuranSurah(number: 54,  nameAr: 'القمر',      page: 528),
    QuranSurah(number: 55,  nameAr: 'الرحمن',     page: 531),
    QuranSurah(number: 56,  nameAr: 'الواقعة',    page: 534),
    QuranSurah(number: 57,  nameAr: 'الحديد',     page: 537),
    QuranSurah(number: 58,  nameAr: 'المجادلة',   page: 542),
    QuranSurah(number: 59,  nameAr: 'الحشر',      page: 545),
    QuranSurah(number: 60,  nameAr: 'الممتحنة',   page: 549),
    QuranSurah(number: 61,  nameAr: 'الصف',       page: 551),
    QuranSurah(number: 62,  nameAr: 'الجمعة',     page: 553),
    QuranSurah(number: 63,  nameAr: 'المنافقون',  page: 554),
    QuranSurah(number: 64,  nameAr: 'التغابن',    page: 556),
    QuranSurah(number: 65,  nameAr: 'الطلاق',     page: 558),
    QuranSurah(number: 66,  nameAr: 'التحريم',    page: 560),
    QuranSurah(number: 67,  nameAr: 'الملك',      page: 562),
    QuranSurah(number: 68,  nameAr: 'القلم',      page: 564),
    QuranSurah(number: 69,  nameAr: 'الحاقة',     page: 566),
    QuranSurah(number: 70,  nameAr: 'المعارج',    page: 568),
    QuranSurah(number: 71,  nameAr: 'نوح',        page: 570),
    QuranSurah(number: 72,  nameAr: 'الجن',       page: 572),
    QuranSurah(number: 73,  nameAr: 'المزمل',     page: 574),
    QuranSurah(number: 74,  nameAr: 'المدثر',     page: 575),
    QuranSurah(number: 75,  nameAr: 'القيامة',    page: 577),
    QuranSurah(number: 76,  nameAr: 'الإنسان',    page: 578),
    QuranSurah(number: 77,  nameAr: 'المرسلات',   page: 580),
    QuranSurah(number: 78,  nameAr: 'النبأ',      page: 582),
    QuranSurah(number: 79,  nameAr: 'النازعات',   page: 583),
    QuranSurah(number: 80,  nameAr: 'عبس',        page: 585),
    QuranSurah(number: 81,  nameAr: 'التكوير',    page: 586),
    QuranSurah(number: 82,  nameAr: 'الانفطار',   page: 587),
    QuranSurah(number: 83,  nameAr: 'المطففين',   page: 587),
    QuranSurah(number: 84,  nameAr: 'الانشقاق',   page: 588),
    QuranSurah(number: 85,  nameAr: 'البروج',     page: 590),
    QuranSurah(number: 86,  nameAr: 'الطارق',     page: 591),
    QuranSurah(number: 87,  nameAr: 'الأعلى',     page: 591),
    QuranSurah(number: 88,  nameAr: 'الغاشية',    page: 592),
    QuranSurah(number: 89,  nameAr: 'الفجر',      page: 593),
    QuranSurah(number: 90,  nameAr: 'البلد',      page: 594),
    QuranSurah(number: 91,  nameAr: 'الشمس',      page: 595),
    QuranSurah(number: 92,  nameAr: 'الليل',      page: 595),
    QuranSurah(number: 93,  nameAr: 'الضحى',      page: 596),
    QuranSurah(number: 94,  nameAr: 'الشرح',      page: 596),
    QuranSurah(number: 95,  nameAr: 'التين',      page: 597),
    QuranSurah(number: 96,  nameAr: 'العلق',      page: 597),
    QuranSurah(number: 97,  nameAr: 'القدر',      page: 598),
    QuranSurah(number: 98,  nameAr: 'البينة',     page: 598),
    QuranSurah(number: 99,  nameAr: 'الزلزلة',    page: 599),
    QuranSurah(number: 100, nameAr: 'العاديات',   page: 599),
    QuranSurah(number: 101, nameAr: 'القارعة',    page: 600),
    QuranSurah(number: 102, nameAr: 'التكاثر',    page: 600),
    QuranSurah(number: 103, nameAr: 'العصر',      page: 601),
    QuranSurah(number: 104, nameAr: 'الهمزة',     page: 601),
    QuranSurah(number: 105, nameAr: 'الفيل',      page: 601),
    QuranSurah(number: 106, nameAr: 'قريش',       page: 602),
    QuranSurah(number: 107, nameAr: 'الماعون',    page: 602),
    QuranSurah(number: 108, nameAr: 'الكوثر',     page: 602),
    QuranSurah(number: 109, nameAr: 'الكافرون',   page: 603),
    QuranSurah(number: 110, nameAr: 'النصر',      page: 603),
    QuranSurah(number: 111, nameAr: 'المسد',      page: 603),
    QuranSurah(number: 112, nameAr: 'الإخلاص',    page: 604),
    QuranSurah(number: 113, nameAr: 'الفلق',      page: 604),
    QuranSurah(number: 114, nameAr: 'الناس',      page: 604),
  ];

  // ── 30 Juz ────────────────────────────────────────────────────────────────
  static const List<QuranJuz> juzList = [
    QuranJuz(number: 1,  openingAr: 'الم',              page: 1),
    QuranJuz(number: 2,  openingAr: 'سيقول السفهاء',   page: 22),
    QuranJuz(number: 3,  openingAr: 'تلك الرسل',        page: 42),
    QuranJuz(number: 4,  openingAr: 'لن تنالوا',        page: 62),
    QuranJuz(number: 5,  openingAr: 'والمحصنات',        page: 82),
    QuranJuz(number: 6,  openingAr: 'لا يحب الله',      page: 102),
    QuranJuz(number: 7,  openingAr: 'وإذا سمعوا',       page: 121),
    QuranJuz(number: 8,  openingAr: 'ولو أننا',         page: 142),
    QuranJuz(number: 9,  openingAr: 'قال الملأ',        page: 162),
    QuranJuz(number: 10, openingAr: 'واعلموا',          page: 182),
    QuranJuz(number: 11, openingAr: 'يعتذرون',          page: 201),
    QuranJuz(number: 12, openingAr: 'وما من دابة',      page: 221),
    QuranJuz(number: 13, openingAr: 'وما أبرئ نفسي',   page: 242),
    QuranJuz(number: 14, openingAr: 'ربما يود',         page: 262),
    QuranJuz(number: 15, openingAr: 'سبحان الذي',       page: 282),
    QuranJuz(number: 16, openingAr: 'قال ألم أقل',      page: 302),
    QuranJuz(number: 17, openingAr: 'اقترب للناس',      page: 322),
    QuranJuz(number: 18, openingAr: 'قد أفلح',          page: 342),
    QuranJuz(number: 19, openingAr: 'وقال الذين',       page: 362),
    QuranJuz(number: 20, openingAr: 'أمن خلق',          page: 382),
    QuranJuz(number: 21, openingAr: 'اتل ما أوحي',      page: 402),
    QuranJuz(number: 22, openingAr: 'ومن يقنت',         page: 422),
    QuranJuz(number: 23, openingAr: 'وما لي',           page: 442),
    QuranJuz(number: 24, openingAr: 'فمن أظلم',         page: 462),
    QuranJuz(number: 25, openingAr: 'إليه يرد',         page: 482),
    QuranJuz(number: 26, openingAr: 'حم',               page: 502),
    QuranJuz(number: 27, openingAr: 'قال فما خطبكم',    page: 522),
    QuranJuz(number: 28, openingAr: 'قد سمع الله',      page: 542),
    QuranJuz(number: 29, openingAr: 'تبارك الذي',       page: 562),
    QuranJuz(number: 30, openingAr: 'عم يتساءلون',      page: 582),
  ];

  // ── 240 Rub' el-Hizb ──────────────────────────────────────────────────────
  // Source: quran.com API v4 — first page of each rub' in the Madinah Mushaf
  static const List<QuranRub> rubList = [
    // Hizb 1
    QuranRub(number: 1,   hizb: 1,  rub: 1, page: 1),
    QuranRub(number: 2,   hizb: 1,  rub: 2, page: 5),
    QuranRub(number: 3,   hizb: 1,  rub: 3, page: 7),
    QuranRub(number: 4,   hizb: 1,  rub: 4, page: 9),
    // Hizb 2
    QuranRub(number: 5,   hizb: 2,  rub: 1, page: 11),
    QuranRub(number: 6,   hizb: 2,  rub: 2, page: 14),
    QuranRub(number: 7,   hizb: 2,  rub: 3, page: 17),
    QuranRub(number: 8,   hizb: 2,  rub: 4, page: 19),
    // Hizb 3
    QuranRub(number: 9,   hizb: 3,  rub: 1, page: 22),
    QuranRub(number: 10,  hizb: 3,  rub: 2, page: 24),
    QuranRub(number: 11,  hizb: 3,  rub: 3, page: 27),
    QuranRub(number: 12,  hizb: 3,  rub: 4, page: 29),
    // Hizb 4
    QuranRub(number: 13,  hizb: 4,  rub: 1, page: 32),
    QuranRub(number: 14,  hizb: 4,  rub: 2, page: 34),
    QuranRub(number: 15,  hizb: 4,  rub: 3, page: 37),
    QuranRub(number: 16,  hizb: 4,  rub: 4, page: 39),
    // Hizb 5
    QuranRub(number: 17,  hizb: 5,  rub: 1, page: 42),
    QuranRub(number: 18,  hizb: 5,  rub: 2, page: 44),
    QuranRub(number: 19,  hizb: 5,  rub: 3, page: 46),
    QuranRub(number: 20,  hizb: 5,  rub: 4, page: 49),
    // Hizb 6
    QuranRub(number: 21,  hizb: 6,  rub: 1, page: 51),
    QuranRub(number: 22,  hizb: 6,  rub: 2, page: 54),
    QuranRub(number: 23,  hizb: 6,  rub: 3, page: 56),
    QuranRub(number: 24,  hizb: 6,  rub: 4, page: 59),
    // Hizb 7
    QuranRub(number: 25,  hizb: 7,  rub: 1, page: 62),
    QuranRub(number: 26,  hizb: 7,  rub: 2, page: 64),
    QuranRub(number: 27,  hizb: 7,  rub: 3, page: 67),
    QuranRub(number: 28,  hizb: 7,  rub: 4, page: 69),
    // Hizb 8
    QuranRub(number: 29,  hizb: 8,  rub: 1, page: 72),
    QuranRub(number: 30,  hizb: 8,  rub: 2, page: 74),
    QuranRub(number: 31,  hizb: 8,  rub: 3, page: 77),
    QuranRub(number: 32,  hizb: 8,  rub: 4, page: 79),
    // Hizb 9
    QuranRub(number: 33,  hizb: 9,  rub: 1, page: 82),
    QuranRub(number: 34,  hizb: 9,  rub: 2, page: 84),
    QuranRub(number: 35,  hizb: 9,  rub: 3, page: 87),
    QuranRub(number: 36,  hizb: 9,  rub: 4, page: 89),
    // Hizb 10
    QuranRub(number: 37,  hizb: 10, rub: 1, page: 92),
    QuranRub(number: 38,  hizb: 10, rub: 2, page: 94),
    QuranRub(number: 39,  hizb: 10, rub: 3, page: 97),
    QuranRub(number: 40,  hizb: 10, rub: 4, page: 100),
    // Hizb 11
    QuranRub(number: 41,  hizb: 11, rub: 1, page: 102),
    QuranRub(number: 42,  hizb: 11, rub: 2, page: 104),
    QuranRub(number: 43,  hizb: 11, rub: 3, page: 106),
    QuranRub(number: 44,  hizb: 11, rub: 4, page: 109),
    // Hizb 12
    QuranRub(number: 45,  hizb: 12, rub: 1, page: 112),
    QuranRub(number: 46,  hizb: 12, rub: 2, page: 114),
    QuranRub(number: 47,  hizb: 12, rub: 3, page: 117),
    QuranRub(number: 48,  hizb: 12, rub: 4, page: 119),
    // Hizb 13
    QuranRub(number: 49,  hizb: 13, rub: 1, page: 121),
    QuranRub(number: 50,  hizb: 13, rub: 2, page: 124),
    QuranRub(number: 51,  hizb: 13, rub: 3, page: 126),
    QuranRub(number: 52,  hizb: 13, rub: 4, page: 129),
    // Hizb 14
    QuranRub(number: 53,  hizb: 14, rub: 1, page: 132),
    QuranRub(number: 54,  hizb: 14, rub: 2, page: 134),
    QuranRub(number: 55,  hizb: 14, rub: 3, page: 137),
    QuranRub(number: 56,  hizb: 14, rub: 4, page: 140),
    // Hizb 15
    QuranRub(number: 57,  hizb: 15, rub: 1, page: 142),
    QuranRub(number: 58,  hizb: 15, rub: 2, page: 144),
    QuranRub(number: 59,  hizb: 15, rub: 3, page: 146),
    QuranRub(number: 60,  hizb: 15, rub: 4, page: 148),
    // Hizb 16
    QuranRub(number: 61,  hizb: 16, rub: 1, page: 151),
    QuranRub(number: 62,  hizb: 16, rub: 2, page: 154),
    QuranRub(number: 63,  hizb: 16, rub: 3, page: 156),
    QuranRub(number: 64,  hizb: 16, rub: 4, page: 158),
    // Hizb 17
    QuranRub(number: 65,  hizb: 17, rub: 1, page: 162),
    QuranRub(number: 66,  hizb: 17, rub: 2, page: 164),
    QuranRub(number: 67,  hizb: 17, rub: 3, page: 167),
    QuranRub(number: 68,  hizb: 17, rub: 4, page: 170),
    // Hizb 18
    QuranRub(number: 69,  hizb: 18, rub: 1, page: 173),
    QuranRub(number: 70,  hizb: 18, rub: 2, page: 175),
    QuranRub(number: 71,  hizb: 18, rub: 3, page: 177),
    QuranRub(number: 72,  hizb: 18, rub: 4, page: 179),
    // Hizb 19
    QuranRub(number: 73,  hizb: 19, rub: 1, page: 182),
    QuranRub(number: 74,  hizb: 19, rub: 2, page: 184),
    QuranRub(number: 75,  hizb: 19, rub: 3, page: 187),
    QuranRub(number: 76,  hizb: 19, rub: 4, page: 189),
    // Hizb 20
    QuranRub(number: 77,  hizb: 20, rub: 1, page: 192),
    QuranRub(number: 78,  hizb: 20, rub: 2, page: 194),
    QuranRub(number: 79,  hizb: 20, rub: 3, page: 196),
    QuranRub(number: 80,  hizb: 20, rub: 4, page: 199),
    // Hizb 21
    QuranRub(number: 81,  hizb: 21, rub: 1, page: 201),
    QuranRub(number: 82,  hizb: 21, rub: 2, page: 204),
    QuranRub(number: 83,  hizb: 21, rub: 3, page: 206),
    QuranRub(number: 84,  hizb: 21, rub: 4, page: 209),
    // Hizb 22
    QuranRub(number: 85,  hizb: 22, rub: 1, page: 212),
    QuranRub(number: 86,  hizb: 22, rub: 2, page: 214),
    QuranRub(number: 87,  hizb: 22, rub: 3, page: 217),
    QuranRub(number: 88,  hizb: 22, rub: 4, page: 219),
    // Hizb 23
    QuranRub(number: 89,  hizb: 23, rub: 1, page: 222),
    QuranRub(number: 90,  hizb: 23, rub: 2, page: 224),
    QuranRub(number: 91,  hizb: 23, rub: 3, page: 226),
    QuranRub(number: 92,  hizb: 23, rub: 4, page: 228),
    // Hizb 24
    QuranRub(number: 93,  hizb: 24, rub: 1, page: 231),
    QuranRub(number: 94,  hizb: 24, rub: 2, page: 233),
    QuranRub(number: 95,  hizb: 24, rub: 3, page: 236),
    QuranRub(number: 96,  hizb: 24, rub: 4, page: 238),
    // Hizb 25
    QuranRub(number: 97,  hizb: 25, rub: 1, page: 242),
    QuranRub(number: 98,  hizb: 25, rub: 2, page: 244),
    QuranRub(number: 99,  hizb: 25, rub: 3, page: 247),
    QuranRub(number: 100, hizb: 25, rub: 4, page: 249),
    // Hizb 26
    QuranRub(number: 101, hizb: 26, rub: 1, page: 252),
    QuranRub(number: 102, hizb: 26, rub: 2, page: 254),
    QuranRub(number: 103, hizb: 26, rub: 3, page: 256),
    QuranRub(number: 104, hizb: 26, rub: 4, page: 259),
    // Hizb 27
    QuranRub(number: 105, hizb: 27, rub: 1, page: 262),
    QuranRub(number: 106, hizb: 27, rub: 2, page: 264),
    QuranRub(number: 107, hizb: 27, rub: 3, page: 267),
    QuranRub(number: 108, hizb: 27, rub: 4, page: 270),
    // Hizb 28
    QuranRub(number: 109, hizb: 28, rub: 1, page: 272),
    QuranRub(number: 110, hizb: 28, rub: 2, page: 275),
    QuranRub(number: 111, hizb: 28, rub: 3, page: 277),
    QuranRub(number: 112, hizb: 28, rub: 4, page: 280),
    // Hizb 29
    QuranRub(number: 113, hizb: 29, rub: 1, page: 282),
    QuranRub(number: 114, hizb: 29, rub: 2, page: 284),
    QuranRub(number: 115, hizb: 29, rub: 3, page: 287),
    QuranRub(number: 116, hizb: 29, rub: 4, page: 289),
    // Hizb 30
    QuranRub(number: 117, hizb: 30, rub: 1, page: 292),
    QuranRub(number: 118, hizb: 30, rub: 2, page: 295),
    QuranRub(number: 119, hizb: 30, rub: 3, page: 297),
    QuranRub(number: 120, hizb: 30, rub: 4, page: 299),
    // Hizb 31
    QuranRub(number: 121, hizb: 31, rub: 1, page: 302),
    QuranRub(number: 122, hizb: 31, rub: 2, page: 304),
    QuranRub(number: 123, hizb: 31, rub: 3, page: 306),
    QuranRub(number: 124, hizb: 31, rub: 4, page: 309),
    // Hizb 32
    QuranRub(number: 125, hizb: 32, rub: 1, page: 312),
    QuranRub(number: 126, hizb: 32, rub: 2, page: 315),
    QuranRub(number: 127, hizb: 32, rub: 3, page: 317),
    QuranRub(number: 128, hizb: 32, rub: 4, page: 319),
    // Hizb 33
    QuranRub(number: 129, hizb: 33, rub: 1, page: 322),
    QuranRub(number: 130, hizb: 33, rub: 2, page: 324),
    QuranRub(number: 131, hizb: 33, rub: 3, page: 326),
    QuranRub(number: 132, hizb: 33, rub: 4, page: 329),
    // Hizb 34
    QuranRub(number: 133, hizb: 34, rub: 1, page: 332),
    QuranRub(number: 134, hizb: 34, rub: 2, page: 334),
    QuranRub(number: 135, hizb: 34, rub: 3, page: 336),
    QuranRub(number: 136, hizb: 34, rub: 4, page: 339),
    // Hizb 35
    QuranRub(number: 137, hizb: 35, rub: 1, page: 342),
    QuranRub(number: 138, hizb: 35, rub: 2, page: 344),
    QuranRub(number: 139, hizb: 35, rub: 3, page: 347),
    QuranRub(number: 140, hizb: 35, rub: 4, page: 350),
    // Hizb 36
    QuranRub(number: 141, hizb: 36, rub: 1, page: 352),
    QuranRub(number: 142, hizb: 36, rub: 2, page: 354),
    QuranRub(number: 143, hizb: 36, rub: 3, page: 356),
    QuranRub(number: 144, hizb: 36, rub: 4, page: 359),
    // Hizb 37
    QuranRub(number: 145, hizb: 37, rub: 1, page: 362),
    QuranRub(number: 146, hizb: 37, rub: 2, page: 364),
    QuranRub(number: 147, hizb: 37, rub: 3, page: 367),
    QuranRub(number: 148, hizb: 37, rub: 4, page: 369),
    // Hizb 38
    QuranRub(number: 149, hizb: 38, rub: 1, page: 371),
    QuranRub(number: 150, hizb: 38, rub: 2, page: 374),
    QuranRub(number: 151, hizb: 38, rub: 3, page: 377),
    QuranRub(number: 152, hizb: 38, rub: 4, page: 379),
    // Hizb 39
    QuranRub(number: 153, hizb: 39, rub: 1, page: 382),
    QuranRub(number: 154, hizb: 39, rub: 2, page: 384),
    QuranRub(number: 155, hizb: 39, rub: 3, page: 386),
    QuranRub(number: 156, hizb: 39, rub: 4, page: 389),
    // Hizb 40
    QuranRub(number: 157, hizb: 40, rub: 1, page: 392),
    QuranRub(number: 158, hizb: 40, rub: 2, page: 394),
    QuranRub(number: 159, hizb: 40, rub: 3, page: 396),
    QuranRub(number: 160, hizb: 40, rub: 4, page: 399),
    // Hizb 41
    QuranRub(number: 161, hizb: 41, rub: 1, page: 402),
    QuranRub(number: 162, hizb: 41, rub: 2, page: 404),
    QuranRub(number: 163, hizb: 41, rub: 3, page: 407),
    QuranRub(number: 164, hizb: 41, rub: 4, page: 410),
    // Hizb 42
    QuranRub(number: 165, hizb: 42, rub: 1, page: 413),
    QuranRub(number: 166, hizb: 42, rub: 2, page: 415),
    QuranRub(number: 167, hizb: 42, rub: 3, page: 418),
    QuranRub(number: 168, hizb: 42, rub: 4, page: 420),
    // Hizb 43
    QuranRub(number: 169, hizb: 43, rub: 1, page: 422),
    QuranRub(number: 170, hizb: 43, rub: 2, page: 425),
    QuranRub(number: 171, hizb: 43, rub: 3, page: 426),
    QuranRub(number: 172, hizb: 43, rub: 4, page: 429),
    // Hizb 44
    QuranRub(number: 173, hizb: 44, rub: 1, page: 431),
    QuranRub(number: 174, hizb: 44, rub: 2, page: 433),
    QuranRub(number: 175, hizb: 44, rub: 3, page: 436),
    QuranRub(number: 176, hizb: 44, rub: 4, page: 439),
    // Hizb 45
    QuranRub(number: 177, hizb: 45, rub: 1, page: 442),
    QuranRub(number: 178, hizb: 45, rub: 2, page: 444),
    QuranRub(number: 179, hizb: 45, rub: 3, page: 446),
    QuranRub(number: 180, hizb: 45, rub: 4, page: 449),
    // Hizb 46
    QuranRub(number: 181, hizb: 46, rub: 1, page: 451),
    QuranRub(number: 182, hizb: 46, rub: 2, page: 454),
    QuranRub(number: 183, hizb: 46, rub: 3, page: 456),
    QuranRub(number: 184, hizb: 46, rub: 4, page: 459),
    // Hizb 47
    QuranRub(number: 185, hizb: 47, rub: 1, page: 462),
    QuranRub(number: 186, hizb: 47, rub: 2, page: 464),
    QuranRub(number: 187, hizb: 47, rub: 3, page: 467),
    QuranRub(number: 188, hizb: 47, rub: 4, page: 469),
    // Hizb 48
    QuranRub(number: 189, hizb: 48, rub: 1, page: 472),
    QuranRub(number: 190, hizb: 48, rub: 2, page: 474),
    QuranRub(number: 191, hizb: 48, rub: 3, page: 477),
    QuranRub(number: 192, hizb: 48, rub: 4, page: 479),
    // Hizb 49
    QuranRub(number: 193, hizb: 49, rub: 1, page: 482),
    QuranRub(number: 194, hizb: 49, rub: 2, page: 484),
    QuranRub(number: 195, hizb: 49, rub: 3, page: 486),
    QuranRub(number: 196, hizb: 49, rub: 4, page: 488),
    // Hizb 50
    QuranRub(number: 197, hizb: 50, rub: 1, page: 491),
    QuranRub(number: 198, hizb: 50, rub: 2, page: 493),
    QuranRub(number: 199, hizb: 50, rub: 3, page: 496),
    QuranRub(number: 200, hizb: 50, rub: 4, page: 499),
    // Hizb 51
    QuranRub(number: 201, hizb: 51, rub: 1, page: 502),
    QuranRub(number: 202, hizb: 51, rub: 2, page: 505),
    QuranRub(number: 203, hizb: 51, rub: 3, page: 507),
    QuranRub(number: 204, hizb: 51, rub: 4, page: 510),
    // Hizb 52
    QuranRub(number: 205, hizb: 52, rub: 1, page: 513),
    QuranRub(number: 206, hizb: 52, rub: 2, page: 515),
    QuranRub(number: 207, hizb: 52, rub: 3, page: 517),
    QuranRub(number: 208, hizb: 52, rub: 4, page: 519),
    // Hizb 53
    QuranRub(number: 209, hizb: 53, rub: 1, page: 522),
    QuranRub(number: 210, hizb: 53, rub: 2, page: 524),
    QuranRub(number: 211, hizb: 53, rub: 3, page: 526),
    QuranRub(number: 212, hizb: 53, rub: 4, page: 529),
    // Hizb 54
    QuranRub(number: 213, hizb: 54, rub: 1, page: 531),
    QuranRub(number: 214, hizb: 54, rub: 2, page: 534),
    QuranRub(number: 215, hizb: 54, rub: 3, page: 536),
    QuranRub(number: 216, hizb: 54, rub: 4, page: 539),
    // Hizb 55
    QuranRub(number: 217, hizb: 55, rub: 1, page: 542),
    QuranRub(number: 218, hizb: 55, rub: 2, page: 544),
    QuranRub(number: 219, hizb: 55, rub: 3, page: 547),
    QuranRub(number: 220, hizb: 55, rub: 4, page: 550),
    // Hizb 56
    QuranRub(number: 221, hizb: 56, rub: 1, page: 553),
    QuranRub(number: 222, hizb: 56, rub: 2, page: 554),
    QuranRub(number: 223, hizb: 56, rub: 3, page: 558),
    QuranRub(number: 224, hizb: 56, rub: 4, page: 560),
    // Hizb 57
    QuranRub(number: 225, hizb: 57, rub: 1, page: 562),
    QuranRub(number: 226, hizb: 57, rub: 2, page: 564),
    QuranRub(number: 227, hizb: 57, rub: 3, page: 566),
    QuranRub(number: 228, hizb: 57, rub: 4, page: 569),
    // Hizb 58
    QuranRub(number: 229, hizb: 58, rub: 1, page: 572),
    QuranRub(number: 230, hizb: 58, rub: 2, page: 575),
    QuranRub(number: 231, hizb: 58, rub: 3, page: 577),
    QuranRub(number: 232, hizb: 58, rub: 4, page: 579),
    // Hizb 59
    QuranRub(number: 233, hizb: 59, rub: 1, page: 582),
    QuranRub(number: 234, hizb: 59, rub: 2, page: 585),
    QuranRub(number: 235, hizb: 59, rub: 3, page: 587),
    QuranRub(number: 236, hizb: 59, rub: 4, page: 589),
    // Hizb 60
    QuranRub(number: 237, hizb: 60, rub: 1, page: 591),
    QuranRub(number: 238, hizb: 60, rub: 2, page: 594),
    QuranRub(number: 239, hizb: 60, rub: 3, page: 596),
    QuranRub(number: 240, hizb: 60, rub: 4, page: 599),
  ];

  static const List<String> rubOpeningTexts = [
    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ', // Rub 1
    '۞إِنَّ ٱللَّهَ لَا يَسۡتَحۡيِۦٓ', // Rub 2
    '۞أَتَأۡمُرُونَ ٱلنَّاسَ بِٱلۡبِرِّ وَتَنسَوۡنَ', // Rub 3
    '۞وَإِذِ ٱسۡتَسۡقَىٰ مُوسَىٰ لِقَوۡمِهِۦ', // Rub 4
    '۞أَفَتَطۡمَعُونَ أَن يُؤۡمِنُواْ لَكُمۡ', // Rub 5
    '۞وَلَقَدۡ جَآءَكُم مُّوسَىٰ بِٱلۡبَيِّنَٰتِ', // Rub 6
    '۞مَا نَنسَخۡ مِنۡ ءَايَةٍ', // Rub 7
    '۞وَإِذِ ٱبۡتَلَىٰٓ إِبۡرَٰهِـۧمَ رَبُّهُۥ', // Rub 8
    '۞سَيَقُولُ ٱلسُّفَهَآءُ مِنَ ٱلنَّاسِ', // Rub 9
    '۞إِنَّ ٱلصَّفَا وَٱلۡمَرۡوَةَ مِن', // Rub 10
    '۞لَّيۡسَ ٱلۡبِرَّ أَن تُوَلُّواْ', // Rub 11
    '۞يَسۡـَٔلُونَكَ عَنِ ٱلۡأَهِلَّةِۖ قُلۡ', // Rub 12
    '۞وَٱذۡكُرُواْ ٱللَّهَ فِيٓ أَيَّامٖ', // Rub 13
    '۞يَسۡـَٔلُونَكَ عَنِ ٱلۡخَمۡرِ وَٱلۡمَيۡسِرِۖ', // Rub 14
    '۞وَٱلۡوَٰلِدَٰتُ يُرۡضِعۡنَ أَوۡلَٰدَهُنَّ حَوۡلَيۡنِ', // Rub 15
    '۞أَلَمۡ تَرَ إِلَى ٱلَّذِينَ', // Rub 16
    '۞تِلۡكَ ٱلرُّسُلُ فَضَّلۡنَا بَعۡضَهُمۡ', // Rub 17
    '۞قَوۡلٞ مَّعۡرُوفٞ وَمَغۡفِرَةٌ خَيۡرٞ', // Rub 18
    '۞لَّيۡسَ عَلَيۡكَ هُدَىٰهُمۡ وَلَٰكِنَّ', // Rub 19
    '۞وَإِن كُنتُمۡ عَلَىٰ سَفَرٖ', // Rub 20
    '۞قُلۡ أَؤُنَبِّئُكُم بِخَيۡرٖ مِّن', // Rub 21
    '۞إِنَّ ٱللَّهَ ٱصۡطَفَىٰٓ ءَادَمَ', // Rub 22
    '۞فَلَمَّآ أَحَسَّ عِيسَىٰ مِنۡهُمُ', // Rub 23
    '۞وَمِنۡ أَهۡلِ ٱلۡكِتَٰبِ مَنۡ', // Rub 24
    '۞كُلُّ ٱلطَّعَامِ كَانَ حِلّٗا', // Rub 25
    '۞لَيۡسُواْ سَوَآءٗۗ مِّنۡ أَهۡلِ', // Rub 26
    '۞وَسَارِعُوٓاْ إِلَىٰ مَغۡفِرَةٖ مِّن', // Rub 27
    '۞إِذۡ تُصۡعِدُونَ وَلَا تَلۡوُۥنَ', // Rub 28
    '۞يَسۡتَبۡشِرُونَ بِنِعۡمَةٖ مِّنَ ٱللَّهِ', // Rub 29
    '۞لَتُبۡلَوُنَّ فِيٓ أَمۡوَٰلِكُمۡ وَأَنفُسِكُمۡ', // Rub 30
    'يَـٰٓأَيُّهَا ٱلنَّاسُ ٱتَّقُواْ رَبَّكُمُ', // Rub 31
    '۞وَلَكُمۡ نِصۡفُ مَا تَرَكَ', // Rub 32
    '۞وَٱلۡمُحۡصَنَٰتُ مِنَ ٱلنِّسَآءِ إِلَّا', // Rub 33
    '۞وَٱعۡدُودُواْ ٱللَّهَ وَلَا تُشۡرِكُواْ' == '۞وَٱعۡبُدُواْ ٱللَّهَ وَلَا تُشۡرِكُواْ' ? '۞وَٱعۡبُدُواْ ٱللَّهَ وَلَا تُشۡرِكُواْ' : '۞وَٱعۡبُدُواْ ٱللَّهَ وَلَا تُشۡرِكُواْ', // Rub 34
    '۞إِنَّ ٱللَّهَ يَأۡمُرُكُمۡ أَن', // Rub 35
    '۞فَلۡيُقَٰتِلۡ فِي سَبِيلِ ٱللَّهِ', // Rub 36
    '۞فَمَا لَكُمۡ فِي ٱلۡمُنَٰفِقِينَ', // Rub 37
    '۞وَمَن يُهَاجِرۡ فِي سَبِيلِ', // Rub 38
    '۞لَّا خَيۡرَ فِي كَثِيرٖ', // Rub 39
    '۞يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ كُونُواْ', // Rub 40
    '۞لَّا يُحِبُّ ٱللَّهُ ٱلۡجَهۡرَ', // Rub 41
    '۞إِنَّآ أَوۡحَيۡنَآ إِلَيۡكَ كَمَآ', // Rub 42
    'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ أَوۡفُواْ', // Rub 43
    '۞وَلَقَدۡ أَخَذَ ٱللَّهُ مِيثَٰقَ', // Rub 44
    '۞وَٱتۡلُ عَلَيۡهِمۡ نَبَأَ ٱبۡنَيۡ', // Rub 45
    '۞يَـٰٓأَيُّهَا ٱلرَّسُولُ لَا يَحۡزُنكَ', // Rub 46
    '۞يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ لَا', // Rub 47
    '۞يَـٰٓأَيُّهَا ٱلرَّسُولُ بَلِّغۡ مَآ', // Rub 48
    '۞لَتَجِدَنَّ أَشَدَّ ٱلنَّاسِ عَدَٰوَةٗ', // Rub 49
    '۞جَعَلَ ٱللَّهُ ٱلۡكَعۡبَةَ ٱلۡبَيۡتَ', // Rub 50
    '۞يَوۡمَ يَجۡمَعُ ٱللَّهُ ٱلرُّسُلَ', // Rub 51
    '۞وَلَهُۥ مَا سَكَنَ فِي', // Rub 52
    '۞إِنَّمَا يَسۡتَجِيبُ ٱلَّذِينَ يَسۡمَعُونَۘ', // Rub 53
    '۞وَعِندَهُۥ مَفَاتِحُ ٱلۡغَيۡبِ لَا', // Rub 54
    '۞وَإِذۡ قَالَ إِبۡرَٰهِيمُ لِأَبِيهِ', // Rub 55
    '۞إِنَّ ٱللَّهَ فَالِقُ ٱلۡحَبِّ', // Rub 56
    '۞وَلَوۡ أَنَّنَا نَزَّلۡنَآ إِلَيۡهِمُ', // Rub 57
    '۞لَهُمۡ دَارُ ٱلسَّلَٰمِ عِندَ', // Rub 58
    '۞وَهُوَ ٱلَّذِيٓ أَنشَأَ جَنَّـٰتٖ', // Rub 59
    '۞قُلۡ تَعَالَوۡاْ أَتۡلُ مَا', // Rub 60
    'الٓمٓصٓ', // Rub 61
    '۞يَٰبَنِيٓ ءَادَمَ خُذُواْ زِينَتَكُمۡ', // Rub 62
    '۞وَإِذَا صُرِفَتۡ أَبۡصَٰرُهُمۡ تِلۡقَآءَ', // Rub 63
    '۞وَإِلاَّ عَادٍ أَخَاهُمۡ هُودٗاۚ' == '۞وَإِلَىٰ عَادٍ أَخَاهُمۡ هُودٗاۚ' ? '۞وَإِلَىٰ عَادٍ أَخَاهُمۡ هُودٗاۚ' : '۞وَإِلَىٰ عَادٍ أَخَاهُمۡ هُودٗاۚ', // Rub 64
    '۞قَالَ ٱلۡمَلَأُ ٱلَّذِينَ ٱسۡتَكۡبَرُواْ', // Rub 65
    '۞وَأَوۡحَيۡنَآ إِلَىٰ مُوسَىٰٓ أَنۡ', // Rub 66
    '۞وَوَٰعَدۡنَا مُوسَىٰ ثَلَٰثِينَ لَيۡلَةٗ', // Rub 67
    '۞وَٱكۡتُبۡ لَنَا فِي هَٰذِهِ', // Rub 68
    '۞وَإِذۡ نَتَقۡنَا ٱلۡجَبَلَ فَوۡقَهُمۡ', // Rub 69
    '۞هُوَ ٱلَّذِي خَلَقَكُم مِّن', // Rub 70
    'يَسۡـَٔلُونَكَ عَنِ ٱلۡأَنفَالِۖ قُلِ', // Rub 71
    '۞إِنَّ شَرَّ ٱلدَّوَآبِّ عِندَ', // Rub 72
    '۞وَٱعۡلَمُوٓاْ أَنَّمَا غَنِمۡتُم مِّن', // Rub 73
    '۞وَإِن جَنَحُواْ لِلسَّلۡمِ فَٱجۡنَحۡ', // Rub 74
    'بَرَآءَةٞ مِّنَ ٱللَّهِ وَرَسُولِهِۦٓ', // Rub 75
    '۞أَجَعَلۡتُمۡ سِقَايَةَ ٱلۡحَآجِّ وَعِمَارَةَ', // Rub 76
    '۞يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ إِنَّ', // Rub 77
    '۞وَلَوۡ أَرَادُواْ ٱلۡخُرُوجَ لَأَعَدُّواْ', // Rub 78
    '۞إِنَّمَا ٱلصَّدَقَٰتُ لِلۡفُقَرَآءِ وَٱلۡمَسَٰكِينِ', // Rub 79
    '۞وَمِنۡهُم مَّنۡ عَٰهَدَ ٱللَّهَ', // Rub 80
    '۞إِنَّمَا ٱلسَّبِيلُ عَلَى ٱلَّذِينَ', // Rub 81
    '۞إِنَّ ٱللَّهَ ٱشۡتَرَىٰ مِنَ', // Rub 82
    '۞وَمَا كَانَ ٱلۡمُؤۡمِنُونَ لِيَنفِرُواْ', // Rub 83
    '۞وَلَوۡ يُعَجِّلُ ٱللَّهُ لِلنَّاسِ', // Rub 84
    '۞لِّلَّذِينَ أَحۡسَنُواْ ٱلۡحُسۡنَىٰ وَزِيَادَةٞۖ', // Rub 85
    '۞وَيَسۡتَنۢبِـُٔونَكَ أَحَقٌّ هُوَۖ قُلۡ', // Rub 86
    '۞وَٱتۡلُ عَلَيۡهِمۡ نَبَأَ نُوحٍ', // Rub 87
    '۞وَجَٰوَزۡنَا بِبَنِيٓ إِسۡرَـٰٓءِيلَ ٱلۡبَحۡرَ', // Rub 88
    '۞وَمَا مِن دَآبَّةٖ فِي', // Rub 89
    '۞مَثَلُ ٱلۡفَرِيقَيۡنِ كَٱلۡأَعۡمَىٰ وَٱلۡأَصَمِّ', // Rub 90
    '۞وَقَالَ ٱرۡكَبُواْ فِيهَا بِسۡمِ', // Rub 91
    '۞وَإِلَىٰ ثَمُودَ أَخَاهُمۡ صَٰلِحٗاۚ', // Rub 92
    '۞وَإِلَىٰ مَدۡيَنَ أَخَاهُمۡ شُعَيۡبٗاۚ', // Rub 93
    '۞وَأَمَّا ٱلَّذِينَ سُعِدُواْ فَفِي', // Rub 94
    '۞لَّقَدۡ كَانَ فِي يُوسُفَ', // Rub 95
    '۞وَقَالَ نِسۡوَةٞ فِي ٱلۡمَدِينَةِ', // Rub 96
    '۞وَمَآ أُبَرِّئُ نَفۡسِيٓۚ إِنَّ', // Rub 97
    '۞قَالُوٓاْ إِن يَسۡرِقۡ فَقَدۡ', // Rub 98
    '۞رَبِّ قَدۡ ءَاتَيۡتَنِي مِنَ', // Rub 99
    '۞وَإِن تَعۡجَبۡ فَعَجَبٞ قَوۡلُهُمۡ', // Rub 100
    '۞أَفَمَن يَعۡلَمُ أَنَّمَآ أُنزِلَ', // Rub 101
    '۞مَّثَلُ ٱلۡجَنَّةِ ٱلَّتِي وُعِدَ', // Rub 102
    '۞قَالَتۡ رُسُلُهُمۡ أَفِي ٱللَّهِ', // Rub 103
    '۞أَلَمۡ تَرَ إِلَى ٱلَّذِينَ', // Rub 104
    'الٓرۚ تِلۡكَ ءَايَٰتُ ٱلۡكِتَٰبِ', // Rub 105
    'وَأَنَّ عَذَابِي هُوَ ٱلۡعَذَابُ', // Rub 106
    'أَتَىٰٓ أَمۡرُ ٱللَّهِ فَلَا', // Rub 107
    '۞وَقِيلَ لِلَّذِينَ ٱتَّقَوۡاْ مَاذَآ', // Rub 108
    '۞وَقَالَ ٱللَّهُ لَا تَتَّخِذُوٓاْ', // Rub 109
    '۞ضَرَبَ ٱللَّهُ مَثَلًا عَبۡدٗا', // Rub 110
    '۞إِنَّ ٱللَّهَ يَأۡمُرُ بِٱلۡعَدۡلِ', // Rub 111
    '۞يَوۡمَ تَأۡتِي كُلُّ نَفۡسٖ', // Rub 112
    'سُبۡحَٰنَ ٱلَّذِيٓ أَسۡرَىٰ بِعَبۡدِهِۦ', // Rub 113
    '۞وَقَضَىٰ رَبُّكَ أَلَّا تَعۡبُدُوٓاْ', // Rub 114
    '۞قُلۡ كُونُواْ حِجَارَةً أَوۡ', // Rub 115
    '۞وَلَقَدۡ كَرَّمۡنَا بَنِيٓ ءَادَمَ', // Rub 116
    '۞أَوَلَمۡ يَرَوۡاْ أَنَّ ٱللَّهَ', // Rub 117
    '۞وَتَرَى ٱلشَّمۡسَ إِذَا طَلَعَت', // Rub 118
    '۞وَٱضۡرِبۡ لَهُم مَّثَلٗا رَّجُلَيۡنِ', // Rub 119
    '۞مَّآ أَشۡهَدتُّهُمۡ خَلۡقَ ٱلسَّمَٰوَٰتِ', // Rub 120
    '۞قَالَ أَلَمۡ أَقُل لَّكَ', // Rub 121
    '۞وَتَرَكۡنَا بَعۡضَهُمۡ يَوۡمَئِذٖ يَمُوجُ', // Rub 122
    '۞فَحَمَلَتۡهُ فَٱنتَبَذَتۡ بِهِۦ مَكَانٗا', // Rub 123
    '۞فَخَلَفَ مِنۢ بَعۡدِهِمۡ خَلۡفٌ', // Rub 124
    'طه', // Rub 125
    '۞مِنۡهَا خَلَقۡنَٰكُمۡ وَفِيهَا Nُعِيدُكُمۡ' == '۞مِنۡهَا خَلَقۡنَٰكُمۡ وَفِيهَا نُعِيدُكُمۡ' ? '۞مِنۡهَا خَلَقۡنَٰكُمۡ وَفِيهَا نُعِيدُكُمۡ' : '۞مِنۡهَا خَلَقۡنَٰكُمۡ وَفِيهَا نُعِيدُكُمۡ', // Rub 126
    '۞وَمَآ أَعۡجَلَكَ عَن قَوۡمِكَ', // Rub 127
    '۞وَعَنَتِ ٱلۡوُجُوهُ لِلۡحَيِّ ٱلۡقَيُّومِۖ', // Rub 128
    'ٱقۡتَرَبَ لِلنَّاسِ حِسَابُهُمۡ وَهُمۡ', // Rub 129
    '۞وَمَن يَقُلۡ مِنۡهُمۡ إِنِّيٓ', // Rub 130
    '۞وَلَقَدۡ ءَاتَيۡنَآ إِبۡرَٰهِيمَ رُشۡدَهُۥ', // Rub 131
    '۞وَأَيُّوبَ إِذۡ نَادَىٰ رَبَّهُۥٓ', // Rub 132
    'يَـٰٓأَيُّهَا ٱلنَّاسُ ٱتَّقُواْ رَبَّكُمۡۚ', // Rub 133
    '۞هَٰذَانِ خَصۡمَانِ ٱخۡتَصَمُواْ فِي', // Rub 134
    '۞إِنَّ ٱللَّهَ يُدَٰفِعُ عَنِ', // Rub 135
    '۞ذَٰلِكَۖ وَمَنۡ عَاقَبَ بِمِثۡلِ', // Rub 136
    'قَدۡ أَفۡلَحَ ٱلۡمُؤۡمِنُونَ', // Rub 137
    '۞هَيۡهَاتَ هَيۡهَاتَ لِمَا تُوعَدُونَ', // Rub 138
    '۞وَلَوۡ رَحِمۡنَٰهُمۡ وَكَشَفۡنَا مَا', // Rub 139
    'سُورَةٌ أَنزَلۡنَٰهَا وَفَرَضۡنَٰهَا وَأَنزَلۡنَا', // Rub 140
    '۞يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ لَا', // Rub 141
    '۞ٱللَّهُ نُورُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۚ', // Rub 142
    '۞وَأَقۡسَمُواْ بِٱللَّهِ جهۡدَ أَيۡمَٰنِهِمۡ' == '۞وَأَقۡسَمُواْ بِٱللَّهِ جَهۡدَ أَيۡمَٰنِهِمۡ' ? '۞وَأَقۡسَمُواْ بِٱللَّهِ جَهۡدَ أَيۡمَٰنِهِمۡ' : '۞وَأَقۡسَمُواْ بِٱللَّهِ جَهۡدَ أَيۡمَٰنِهِمۡ', // Rub 143
    'تَبَارَكَ ٱلَّذِي نَزَّلَ ٱلۡفُرۡقَانَ', // Rub 144
    '۞وَقَالَ ٱلَّذِينَ لَا يَرۡجُونَ', // Rub 145
    '۞وَهُوَ ٱلَّذِي مَرَجَ ٱلۡبَحۡرَيۡنِ', // Rub 146
    'طسٓمٓ', // Rub 147
    '۞وَأَوۡحَيۡنَآ إِلَىٰ مُوسَىٰٓ أَنۡ', // Rub 148
    '۞قَالُوٓاْ أَنُؤۡمِنُ لَكَ وَٱتَّبَعَكَ', // Rub 149
    '۞أَوۡفُواْ ٱلۡكَيۡلَ وَلَا تَكُونُواْ', // Rub 150
    'طسٓۚ تِلۡكَ ءَايَٰتُ ٱلۡقُرۡءَانِ', // Rub 151
    '۞قَالَ سَنَنظُرُ أَصَدَقۡتَ أَمۡ', // Rub 152
    '۞فَمَا كَانَ جَوَابَ قَوۡمِهِۦٓ', // Rub 153
    '۞وَإِذَا وَقَعَ ٱلۡقَوۡلُ عَلَيۡهِمۡ', // Rub 154
    '۞وَحَرَّمۡنَا عَلَيۡهِ ٱلۡمَرَاضِعَ مِن', // Rub 155
    '۞فَلَمَّا قَضَىٰ مُوسَى ٱلۡأَجَلَ', // Rub 156
    '۞وَلَقَدۡ وَصَّلۡنَا لَهُمُ ٱلۡقَوۡلَ', // Rub 157
    '۞إِنَّ قَٰرُونَ كَانَ مِن', // Rub 158
    'الٓمٓ', // Rub 159
    '۞فَـَٔامَنَ لَهُۥ لُوطٞۘ وَقَالَ', // Rub 160
    '۞وَلَا تُجَٰدِلُوٓاْ أَهۡلَ ٱلۡكِتَٰبِ', // Rub 161
    'الٓمٓ', // Rub 162
    '۞مُنِيبِينَ إِلَيۡهِ وَٱتَّقوهُ وَأَقِيمُواْ' == '۞مُنِيبِينَ إِلَيۡهِ وَٱتَّقُوهُ وَأَقِيمُواْ' ? '۞مُنِيبِينَ إِلَيۡهِ وَٱتَّقُوهُ وَأَقِيمُواْ' : '۞مُنِيبِينَ إِلَيۡهِ وَٱتَّقُوهُ وَأَقِيمُواْ', // Rub 163
    '۞ٱللَّهُ ٱلَّذِي خَلَقَكُم مِّن', // Rub 164
    '۞وَمَن يُسۡلِمۡ وَجۡهَهُۥٓ إِلَى', // Rub 165
    '۞قُلۡ يَتَوَفَّىٰكُم مَّلَكُ ٱلۡمَوۡتِ', // Rub 166
    'يَـٰٓأَيُّهَا ٱلنَّبِيُّ ٱتَّقِ ٱللَّهَ', // Rub 167
    '۞قَدۡ يَعۡلَمُ ٱللَّهُ ٱلۡمُعَوِّقِينَ', // Rub 168
    '۞وَمَن يَقۡنُتۡ مِنكُنَّ لِلَّهِ', // Rub 169
    '۞تُرۡجِي مَن تَشَآءُ مِنۡهُنَّ', // Rub 170
    '۞لَّئِن لَّمۡ يَنتَهِ ٱلۡمُنَٰفِقُونَ', // Rub 171
    '۞وَلَقَدۡ ءَاتَيۡنَا دَاوُۥدَ مِنَّا', // Rub 172
    '۞قُلۡ مَن يَرۡزُقُكُم مِّنَ', // Rub 173
    '۞قُلۡ إِنَّمَآ أَعِظُكُم بِوَٰحِدَةٍۖ', // Rub 174
    '۞يَـٰٓأَيُّهَا ٱلنَّاسُ أَنتُمُ ٱلۡفُقَرَآءُ', // Rub 175
    '۞إِنَّ ٱللَّهَ يُمۡسِكُ ٱلسَّمَٰوَٰتِ', // Rub 176
    '۞وَمَآ أَنزَلۡنَا عَلَىٰ قَوۡمِهِۦ', // Rub 177
    '۞أَلَمۡ أَعۡهَدۡ إِلَيۡكُمۡ يَٰبَنِيٓ', // Rub 178
    '۞ٱحۡشُرُواْ ٱلَّذِينَ ظَلَمُواْ وَأَزۡوَٰجَهُمۡ', // Rub 179
    '۞وَإِنَّ مِن شِيعَتِهِۦ لَإِبۡرَٰهِيمَ', // Rub 180
    '۞فَنَبَذۡنَٰهُ بِٱلۡعَرَآءِ وَهُوَ سَقِيمٞ', // Rub 181
    '۞وَهَلۡ أَتَىٰكَ نَبَؤُاْ ٱلۡخَصۡمِ', // Rub 182
    '۞وَعِندَهُمۡ قَٰصِرَٰتُ ٱلطَّرۡفِ أَتۡرَابٌ', // Rub 183
    '۞وَإِذَا مَسَّ ٱلۡإِنسَٰنَ ضُرّٞ', // Rub 184
    '۞فَمَنۡ أَظۡلَمُ مِمَّن كَذَبَ', // Rub 185
    '۞قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ', // Rub 186
    'حمٓ', // Rub 187
    '۞أَوَلَمۡ يَسِيرُواْ فِي ٱلۡأَرۡضِ', // Rub 188
    '۞وَيَٰقَوۡمِ مَا لِيٓ أَدۡعُوكُمۡ', // Rub 189
    '۞قُلۡ إِنِّي نُهِيتُ أَنۡ', // Rub 190
    '۞قُلۡ أَئِنَّكُمۡ لَتَكۡفُرُونَ بِٱلَّذِي', // Rub 191
    '۞وَقَيَّضۡنَا لَهُمۡ قُرَنَآءَ فَزَيَّنُواْ', // Rub 192
    '۞إِلَيۡهِ يُرَدُّ عِلۡمُ ٱلسَّاعَةِۚ', // Rub 193
    '۞شَرَعَ لَكُم مِّنَ ٱلدِّينِ', // Rub 194
    '۞وَلَوۡ بَسَطَ ٱللَّهُ ٱلرِّزۡقَ', // Rub 195
    '۞وَمَا كَانَ لِبَشَرٍ أَن', // Rub 196
    '۞قَٰلَ أَوَلَوۡ جِئۡتُكُم بِأَهۡدَىٰ', // Rub 197
    '۞وَلَمَّا ضُرِبَ ٱبۡنُ مَرۡيَمَ', // Rub 198
    '۞وَلَقَدۡ فَتَنَّا قَبۡلَهُمۡ قَوۡمَ', // Rub 199
    '۞ٱللَّهُ ٱلَّذِي سَخَّرَ لَكُمُ', // Rub 200
    'حمٓ', // Rub 201
    '۞وَٱذۡكُرۡ أَخَا عَادٍ إِذۡ', // Rub 202
    '۞أَفَلَمۡ يَسِيرُواْ فِي ٱلۡأَرۡضِ', // Rub 203
    '۞يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ أَطِيعُواْ', // Rub 204
    '۞لَّقَدۡ رَضِيَ ٱللَّهُ عَنِ', // Rub 205
    'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ لَا', // Rub 206
    '۞قَالَتِ ٱلۡأَعۡرَابُ ءَامَنَّاۖ قُل', // Rub 207
    '۞قَالَ قَرِينُهُۥ رَبَّنَا مَآ', // Rub 208
    '۞قَالَ فَمَا خَطۡبُكُمۡ أَيُّهَا', // Rub 209
    '۞وَيَطُوفُ عَلَيۡهِمۡ غِلۡمَانٞ لَّهُمۡ', // Rub 210
    '۞وَكَم مِّن مَّلَكٖ فِي', // Rub 211
    '۞كَذَّبَتۡ قَبۡلَهُمۡ قَوۡمُ نُوحٖ', // Rub 212
    'ٱلرَّحۡمَٰنُ', // Rub 213
    'إِذَا وَقَعَتِ ٱلۡوَاقِعَةُ', // Rub 214
    '۞فَلَآ أُقۡسِمُ بِمَوَٰقِعِ ٱلنُّجُومِ', // Rub 215
    '۞أَلَمۡ يَأۡنِ لِلَّذِينَ ءَامَنُوٓاْ', // Rub 216
    'قَدۡ سَمِعَ ٱللَّهُ قَوۡلَ', // Rub 217
    '۞أَلَمۡ تَرَ إِلَى ٱلَّذِينَ', // Rub 218
    '۞أَلَمۡ تَرَ إِلَى ٱلَّذِينَ', // Rub 219
    '۞عَسَى ٱللَّهُ أَن يَجۡعَلَ', // Rub 220
    'يُسَبِّحُ لِلَّهِ مَا فِي', // Rub 221
    '۞وَإِذَا رَأَيۡتَهُمۡ تُعۡجِبُكَ أَجۡسَامُهُمۡۖ', // Rub 222
    'يَـٰٓأَيُّهَا ٱلنَّبِيُّ إِذَا طَلَّقۡتُمُ', // Rub 223
    'يَـٰٓأَيُّهَا ٱلنَّبِيُّ لِمَ تُحَرِّمُ', // Rub 224
    'تَبَٰرَكَ ٱلَّذِي بِيَدِهِ ٱلۡمُلۡكُ', // Rub 225
    'نٓۚ وَٱلۡقَلَمِ وَمَا يَسۡطُرُونَ', // Rub 226
    'ٱلۡحَآقَّةُ', // Rub 227
    '۞إِنَّ ٱلۡإِنسَٰنَ خُلِقَ هَلُوعًا', // Rub 228
    'قُلۡ أُوحِيَ إِلَيَّ أَنَّهُ', // Rub 229
    '۞إِنَّ رَبَّكَ يَعۡلَمُ أَنَّكَ', // Rub 230
    'لَآ أُقۡسِمُ بِيَوۡمِ ٱلۡقِيَٰمَةِ', // Rub 231
    '۞وَيَطُوفُ عَلَيۡهِمۡ وِلۡدَٰنٞ مُّخَلَّدُونَ', // Rub 232
    'عَمَّ يَتَسَآءَلُونَ', // Rub 233
    'عَبَسَ وَتَوَلَّىٰٓ', // Rub 234
    'إِذَا ٱالسَّمَآءُ ٱنفَطَرَتۡ' == 'إِذَا ٱلسَّمَآءُ ٱنفَطَرَتۡ' ? 'إِذَا ٱلسَّمَآءُ ٱنفَطَرَتۡ' : 'إِذَا ٱلسَّمَآءُ ٱنفَطَرَتۡ', // Rub 235
    'إِذَا ٱالسَّمَآءُ ٱنشَقَّتۡ' == 'إِذَا ٱلسَّمَآءُ ٱنشَقَّتۡ' ? 'إِذَا ٱلسَّمَآءُ ٱنشَقَّتۡ' : 'إِذَا ٱلسَّمَآءُ ٱنشَقَّتۡ', // Rub 236
    'سَبِّحِ ٱسۡمَ رَبِّكَ ٱلۡأَعۡلَى', // Rub 237
    'لَآ أُقۡسِمُ بِهَٰذَا ٱلۡبَلَدِ', // Rub 238
    'أَلَمۡ نَشۡرَحۡ لَكَ صَدۡرَكَ', // Rub 239
    '۞أَفَلَا يَعۡلَمُ إِذَا بُعۡثِرَ', // Rub 240
  ];
}
