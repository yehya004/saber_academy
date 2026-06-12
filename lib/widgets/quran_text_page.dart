import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/quran_database_helper.dart';

class QuranTextPage extends StatelessWidget {
  final int pageNum;
  final int? playingSurah;
  final int? playingAyah;
  final Function(int surahNum, int ayahNum) onVerseTap;

  const QuranTextPage({
    super.key,
    required this.pageNum,
    this.playingSurah,
    this.playingAyah,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: QuranDatabaseHelper().getLinesForPage(pageNum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.secondary,
              strokeWidth: 2,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "تعذر تحميل الصفحة أوفلاين",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          );
        }

        final lines = snapshot.data!;

        // Filter out empty lines to handle page 1 and page 2 centered layouts
        final visibleLines = lines.where((line) {
          final text = line['text_ar'] as String? ?? '';
          return text.trim().isNotEmpty;
        }).toList();

        return Container(
          color: const Color(0xFFFAF6EB), // Classic warm cream/sepia page background
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFD4AF37), // Outer Gold line
                width: 1.2,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF0F5132), // Middle Green frame block
                  width: 3.0,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD4AF37), // Inner Gold line
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner Ornaments
                    const Positioned(
                      top: 4, left: 6,
                      child: Text("❈", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                    ),
                    const Positioned(
                      top: 4, right: 6,
                      child: Text("❈", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                    ),
                    const Positioned(
                      bottom: 4, left: 6,
                      child: Text("❈", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                    ),
                    const Positioned(
                      bottom: 4, right: 6,
                      child: Text("❈", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                    ),

                    // Page Number Indicator centered at bottom
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          _getArabicNumber(pageNum),
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F5132),
                          ),
                        ),
                      ),
                    ),

                    // Main Layout Container (fills the rest)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            final availableWidth = constraints.maxWidth;
                            
                            // We divide by 15 always to keep vertical spacing identical to Medina pages
                            final lineSpace = availableHeight / 15;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: visibleLines.map((line) {
                                final lineType = line['line_type'] as String;
                                final suraNum = line['sura'] as int?;
                                final textAr = line['text_ar'] as String;
                                final tokensJson = line['tokens_json'] as String;
                                final tokens = jsonDecode(tokensJson) as List<dynamic>;

                                if (lineType == 'banner') {
                                  final name = textAr.startsWith('سُورَةُ ')
                                      ? textAr.replaceFirst('سُورَةُ ', '')
                                      : textAr;
                                  return SizedBox(
                                    height: lineSpace,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: _buildSurahBanner(suraNum ?? 1, availableWidth, lineSpace - 4, name),
                                    ),
                                  );
                                }

                                if (lineType == 'bismillah') {
                                  return SizedBox(
                                    height: lineSpace,
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: _buildBismillah(lineSpace),
                                      ),
                                    ),
                                  );
                                }

                                // Content line
                                return SizedBox(
                                  height: lineSpace,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: _buildContentLine(tokens, lineSpace, context),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Convert page number to Arabic Eastern digits
  String _getArabicNumber(int number) {
    const Map<String, String> digits = {
      '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
      '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩'
    };
    return number.toString().split('').map((c) => digits[c] ?? c).join('');
  }

  Widget _buildSurahBanner(int suraNum, double width, double height, String name) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF1A3E2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 12,
            child: Text("❈", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
          ),
          const Positioned(
            right: 12,
            child: Text("❈", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
          ),
          Text(
            "سُورَةُ $name",
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: height * 0.45,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah(double height) {
    return Text(
      "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: height * 0.50,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildContentLine(List<dynamic> tokens, double height, BuildContext context) {
    // Normal content line styling
    final double fs = height * 0.52; // Golden ratio for Arabic text within line spacing

    return Text.rich(
      TextSpan(
        children: tokens.map((token) {
          final text = token['text'] as String;
          final sNum = token['sura'] as int;
          final aNum = token['ayah'] as int;
          final type = token['type'] as String;

          final isHighlighted = playingSurah == sNum && playingAyah == aNum;

          return TextSpan(
            text: type == 'word' ? "$text " : "$text ",
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: fs,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? AppColors.primary : Colors.black87,
              backgroundColor: isHighlighted
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onVerseTap(sNum, aNum),
          );
        }).toList(),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}
