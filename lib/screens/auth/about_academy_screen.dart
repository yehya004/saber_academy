import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../models/profile_model.dart';
import '../../l10n/app_localizations.dart';

class AboutAcademyScreen extends StatefulWidget {
  const AboutAcademyScreen({super.key});

  @override
  State<AboutAcademyScreen> createState() => _AboutAcademyScreenState();
}

class _AboutAcademyScreenState extends State<AboutAcademyScreen> {
  final _client = Supabase.instance.client;

  ProfileModel? _teacher;
  Map<String, dynamic>? _academyData;
  bool _loading = true;

  // Interactive mockup state variables
  String _selectedMushafType = 'madina';
  String _selectedDashboardView = 'excellent';
  String _selectedChatView = 'student';

  @override
  void initState() {
    super.initState();
    _loadAllInfo();
  }

  Future<void> _loadAllInfo() async {
    try {
      final results = await Future.wait([
        _client.from('profiles').select().eq('role', 'teacher').limit(1).maybeSingle(),
        _client.from('academy_info').select().eq('id', 1).maybeSingle(),
      ]);

      if (mounted) {
        setState(() {
          if (results[0] != null) {
            _teacher = ProfileModel.fromMap(results[0] as Map<String, dynamic>);
          }
          if (results[1] != null) {
            _academyData = results[1] as Map<String, dynamic>;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contactWhatsApp() async {
    final phoneNum = (_teacher?.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final urlString = phoneNum.isNotEmpty
        ? 'https://wa.me/$phoneNum'
        : 'https://wa.me/201289212204'; // Default fallback
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showGuestForm(BuildContext context, String lang) {
    final isAr = lang == 'ar';
    final isTr = lang == 'tr';

    final dialogTitle = isAr
        ? 'بيانات الزائر لبدء المحادثة'
        : (isTr ? 'Sohbet Öncesi Ziyaretçi Bilgileri' : 'Guest Information Before Chat');

    final nameLabel = isAr ? 'الاسم الكامل' : (isTr ? 'Ad Soyad' : 'Full Name');
    final phoneLabel = isAr ? 'رقم الهاتف أو الواتساب' : (isTr ? 'Telefon Numarası veya WhatsApp' : 'WhatsApp or Phone Number');
    final countryLabel = isAr ? 'البلد' : (isTr ? 'Ülke' : 'Country');
    final emailLabel = isAr ? 'البريد الإلكتروني (اختياري)' : (isTr ? 'E-posta (İsteğe bağlı)' : 'Email (Optional)');
    final messengerLabel = isAr ? 'رابط حساب ماسنجر (اختياري)' : (isTr ? 'Messenger Bağlantısı (İsteğe bağlı)' : 'Messenger Profile Link (Optional)');
    final submitTxt = isAr ? 'بدء المحادثة الآن' : (isTr ? 'Sohbeti Şimdi Başlat' : 'Start Chat Now');
    final cancelTxt = isAr ? 'إلغاء' : (isTr ? 'İptal' : 'Cancel');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _GuestFormSheet(
          dialogTitle: dialogTitle,
          nameLabel: nameLabel,
          phoneLabel: phoneLabel,
          countryLabel: countryLabel,
          emailLabel: emailLabel,
          messengerLabel: messengerLabel,
          submitTxt: submitTxt,
          cancelTxt: cancelTxt,
          lang: lang,
          teacher: _teacher,
        );
      },
    );
  }

  String? _getYoutubeThumbnail(String url) {
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      final videoId = match.group(2);
      if (videoId != null && videoId.length == 11) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    final isTr = locale == 'tr';

    final contactWhatsAppBtn = isAr
        ? 'تواصل عبر الواتساب للتسجيل'
        : (isTr ? 'Kayıt için WhatsApp ile İletişim' : 'Contact via WhatsApp to Register');

    // Fallback default static texts if database is empty
    const defaultSheikhBio = 'الشيخ صابر هو معلم ومحفظ معتمد للقرآن الكريم، يتمتع بخبرة واسعة في تعليم التجويد والقراءات ومساعدة الطلاب من كافة المستويات على تحسين تلاوتهم وحفظ كتاب الله.';
    const defaultProgramDesc = 'برنامج تعليمي متكامل يعتمد على الحصص الفردية والمتابعة المستمرة. يمكنك اختيار نظام الساعات أو نظام الحصص وتلقي تعليقات مباشرة وتصحيح التلاوات.';

    String sheikhBio = defaultSheikhBio;
    String programDesc = defaultProgramDesc;

    if (_academyData != null) {
      if (locale == 'en') {
        sheikhBio = _academyData!['sheikh_bio_en'] as String? ?? sheikhBio;
        programDesc = _academyData!['program_desc_en'] as String? ?? programDesc;
      } else if (locale == 'tr') {
        sheikhBio = _academyData!['sheikh_bio_tr'] as String? ?? sheikhBio;
        programDesc = _academyData!['program_desc_tr'] as String? ?? programDesc;
      } else {
        sheikhBio = _academyData!['sheikh_bio'] as String? ?? sheikhBio;
        programDesc = _academyData!['program_desc'] as String? ?? programDesc;
      }
    }

    List<String> videoUrls = [];
    if (_academyData != null && _academyData!['youtube_urls'] != null) {
      videoUrls = List<String>.from(_academyData!['youtube_urls']);
    }

    final title = isAr ? 'أكاديمية صابر للقرآن الكريم' : (isTr ? 'Saber Kur\'an Akademisi' : 'Saber Quran Academy');

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F3A2E), // Brand dark green
                  Color(0xFF081C17), // Deep pine green
                  Color(0xFF040C0A), // Near black
                ],
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : Column(
                    children: [
                      // AppBar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sheikh Biography Card
                              _buildCard(
                                icon: Icons.person_outline_rounded,
                                title: isAr ? 'من هو الشيخ صابر؟' : (isTr ? 'Şeyh Saber Kimdir?' : 'Who is Sheikh Saber?'),
                                content: sheikhBio,
                              ),
                              const SizedBox(height: 16),

                              // Program Details Card
                              _buildCard(
                                icon: Icons.menu_book_rounded,
                                title: isAr ? 'ما هو برنامج الأكاديمية؟' : (isTr ? 'Akademi Programı Nedir?' : 'What is the Academy Program?'),
                                content: programDesc,
                              ),
                              const SizedBox(height: 16),

                              // YouTube Promotional Videos Section
                              if (videoUrls.isNotEmpty) ...[
                                Text(
                                  isAr ? 'فيديوهات تعريفية' : (isTr ? 'Tanıtım Videoları' : 'Promotional Videos'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 140,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: videoUrls.length,
                                    itemBuilder: (ctx, i) {
                                      final url = videoUrls[i];
                                      final thumb = _getYoutubeThumbnail(url);
                                      if (thumb == null) return const SizedBox();
                                      return GestureDetector(
                                        onTap: () => _playVideoDialog(context, url),
                                        child: Container(
                                          width: 220,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white24, width: 1),
                                            image: DecorationImage(
                                              image: NetworkImage(thumb),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(15),
                                                  color: Colors.black26,
                                                ),
                                              ),
                                              const Center(
                                                child: Icon(Icons.play_circle_fill, color: Colors.red, size: 50),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Interactive Feature Showcase Title
                              Text(
                                isAr ? 'استكشف مزايا التطبيق الذكي' : (isTr ? 'Akıllı Uygulama Özelliklerini Keşfet' : 'Explore Smart App Features'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 12),

                              // Showcase grid or list
                               _buildShowcaseTab(
                                title: isAr ? 'المصحف الشريف وتفاعل الصفحات' : (isTr ? 'Kur\'an-ı Kerim ve Mushaf Sayfaları' : 'Holy Quran & Mushaf Pages'),
                                description: isAr
                                    ? 'يحتوي المصحف على ٣ مصاحف متكاملة: مصحف المدينة المنورة، ومصحف ديانت التركي، والمصحف الكتابي. يدعم تشغيل تكرار الآيات للتحفيظ، مع إمكانية البحث والترجمة الفورية والتفسير.'
                                    : 'The app features 3 integrated Mushafs: Medina layout, Turkish Diyanet layout, and digital Written layout. Supports verse-by-verse repetition for memorization, translation, and tafsir search.',
                                mockup: _buildMushafMockup(),
                              ),
                              const SizedBox(height: 16),

                              _buildShowcaseTab(
                                title: isAr ? 'نظام الحصص والحضور المتميز' : (isTr ? 'Ders ve Katılım Takip Sistemi' : 'Attendance & Lessons Tracking'),
                                description: isAr
                                    ? 'يتيح التطبيق إدارة تقدمك ومتابعة حصصك وحضورك وغيابك بسهولة مع الشيخ، مع معرفة مستواك الحالي وعدد الحصص والدروس المنجزة.'
                                    : 'Track study progression, attendance, absences, and lessons easily with your teacher, and monitor your current level and completed sessions.',
                                mockup: _buildSystemsMockup(isAr),
                              ),
                              const SizedBox(height: 16),

                              _buildShowcaseTab(
                                title: isAr ? 'الداشبورد ومتابعة مستويات التقدم' : (isTr ? 'Öğrenci Paneli ve Gelişim Takibi' : 'Student Dashboard & Progress Tracking'),
                                description: isAr
                                    ? 'لوحة تحكم تفاعلية ذكية لكل طالب تعرض نسبة الحضور، والدرس الحالي، وتقييمات الشيخ، بالإضافة لإحصائيات تقدمك لتشجيعك على الاستمرار في الحفظ.'
                                    : 'A smart dashboard for each student displaying attendance rates, current memorization lessons, grades, and charts tracking retention and performance.',
                                mockup: _buildDashboardMockup(),
                              ),
                              const SizedBox(height: 16),

                              _buildShowcaseTab(
                                title: isAr ? 'المحادثات المباشرة بين الطالب والمعلم' : (isTr ? 'Öğrenci-Öğretmen Sohbetleri' : 'Direct Student-Teacher Conversations'),
                                description: isAr
                                    ? 'تواصل فوري مباشر عبر شات ذكي بين الطالب والمعلم لدعم إرسال الرسائل الصوتية والصور وملفات الواجبات والرد على الاستفسارات الفقهية والتجويدية.'
                                    : 'Real-time chat between student and teacher supporting text, voice notes, homework images, and files for instant query resolution.',
                                mockup: _buildChatMockup(),
                              ),

                              const SizedBox(height: 32),

                              // Bottom Buttons
                              ElevatedButton.icon(
                                onPressed: _contactWhatsApp,
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
                                label: Text(
                                  contactWhatsAppBtn,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _showGuestForm(context, locale),
                                icon: const Icon(Icons.forum_outlined, color: AppColors.secondary, size: 22),
                                label: Text(
                                  isAr ? 'بدء محادثة مباشرة كزائر' : (isTr ? 'Ziyaretçi Olarak Sohbeti Başlat' : 'Start Direct Chat as Guest'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondary,
                                  side: const BorderSide(color: AppColors.secondary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseTab({
    required String title,
    required String description,
    required Widget mockup,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          mockup,
        ],
      ),
    );
  }

  // ── MOCKUPS DRAWINGS (Premium Vector Simulated Previews) ────────────────────

  Widget _buildMushafMockup() {
    final isAr = AppLocalizations.of(context).localeName == 'ar';
    
    Color pageColor;
    Color borderColor;
    Widget pageContent;
    
    if (_selectedMushafType == 'madina') {
      pageColor = const Color(0xFFFBF4E7);
      borderColor = const Color(0xFFC49A45);
      pageContent = Column(
        children: [
          _buildSimulatedVerseLine('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ﴿١﴾', isTajweed: false),
          const SizedBox(height: 6),
          _buildSimulatedVerseLine('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ﴿٢﴾ الرَّحْمَٰنِ ﴿٣﴾', isTajweed: false),
          const SizedBox(height: 6),
          _buildSimulatedVerseLine('مَالِكِ يَوْمِ الدِّينِ ﴿٤﴾ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ ﴿٥﴾', isTajweed: false),
        ],
      );
    } else if (_selectedMushafType == 'diyanet') {
      pageColor = const Color(0xFFE8F1ED);
      borderColor = const Color(0xFF1E513C);
      pageContent = Column(
        children: [
          Text(
            isAr ? '• مصحف الشؤون الدينية التركية (رسم ديانت)' : '• Turkish Diyanet Layout (Diyanet Script)',
            style: const TextStyle(fontSize: 10, color: Color(0xFF1E513C), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildSimulatedVerseLine('بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ', isTajweed: false),
          const SizedBox(height: 6),
          _buildSimulatedVerseLine('اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِينَۙ ﴿٢﴾ اَلرَّحْمٰنِ الرَّحِيمِۙ ﴿٣﴾', isTajweed: false),
        ],
      );
    } else {
      pageColor = const Color(0xFF161E1A);
      borderColor = Colors.grey.shade800;
      pageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  isAr ? 'بحث: الحمد' : 'Search: الحمد',
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n',
                    style: TextStyle(fontSize: 9, color: Colors.white38, fontFamily: 'Amiri'),
                  ),
                  WidgetSpan(
                    child: Container(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: const Text(
                        'الْحَمْدُ لِلَّهِ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, fontFamily: 'Amiri'),
                      ),
                    ),
                  ),
                  const TextSpan(
                    text: ' رَبِّ الْعَالَمِينَ',
                    style: TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Amiri'),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              _buildMushafTabButton('madina', isAr ? 'مصحف المدينة' : 'Medina Mushaf'),
              _buildMushafTabButton('diyanet', isAr ? 'مصحف ديانت' : 'Diyanet Mushaf'),
              _buildMushafTabButton('text', isAr ? 'المصحف الكتابي' : 'Written Mushaf'),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 155,
            decoration: BoxDecoration(
              color: pageColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                if (_selectedMushafType != 'text')
                  Container(
                    height: 18,
                    margin: const EdgeInsets.only(bottom: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 1),
                      color: borderColor.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Text(
                        isAr ? 'سُورَةُ الفَاتِحَةِ' : 'Surah Al-Fatihah',
                        style: TextStyle(fontSize: 9, color: borderColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Expanded(child: Center(child: SingleChildScrollView(child: pageContent))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMushafTabButton(String type, String label) {
    final active = _selectedMushafType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: InkWell(
          onTap: () => setState(() => _selectedMushafType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppColors.secondary : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedVerseLine(String text, {required bool isTajweed}) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Amiri',
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E2E2E),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSystemsMockup(bool isAr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'حصص الطالب: سارة علي' : 'Sara Ali\'s Classes',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                isAr ? 'الاشتراك: نشط / تم الدفع' : 'Payment Status: Active / Paid',
                style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildClassCheckTile(isAr ? 'حصة ١: الفاتحة' : 'Class 1: Al-Fatihah', true),
              const SizedBox(width: 6),
              _buildClassCheckTile(isAr ? 'حصة ٢: البقرة' : 'Class 2: Al-Baqarah', true),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildClassCheckTile(isAr ? 'حصة ٣: ال عمران' : 'Class 3: Al-Imran', true),
              const SizedBox(width: 6),
              _buildClassCheckTile(isAr ? 'حصة ٤: متبقية' : 'Class 4: Scheduled', false),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? '• يتم تسجيل الدروس والحضور وغياب الطالب بالتفصيل وتحديث التقدم تلقائياً' : '• Lessons, attendance, and absences are recorded in detail and progress updates dynamically',
            style: const TextStyle(fontSize: 8, color: Colors.white38, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCheckTile(String label, bool completed) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: completed ? Colors.green.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: completed ? Colors.green.withValues(alpha: 0.3) : Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              completed ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
              color: completed ? Colors.green : Colors.white38,
              size: 10,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: completed ? Colors.green.shade100 : Colors.white54, fontSize: 8),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardMockup() {
    final isAr = AppLocalizations.of(context).localeName == 'ar';
    final excellent = _selectedDashboardView == 'excellent';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDashboardView = 'excellent'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: excellent ? AppColors.secondary : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAr ? 'طالب ممتاز' : 'Excellent Student',
                        style: TextStyle(
                          color: excellent ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight: excellent ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDashboardView = 'average'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: !excellent ? AppColors.secondary : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAr ? 'طالب متوسط (متابعة)' : 'Average Student',
                        style: TextStyle(
                          color: !excellent ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight: !excellent ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E19),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: excellent ? 1.0 : 0.8,
                            backgroundColor: Colors.white10,
                            color: excellent ? Colors.green : AppColors.secondary,
                            strokeWidth: 4,
                          ),
                        ),
                        Text(
                          excellent ? '100%' : '80%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: excellent ? Colors.green : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr ? 'نسبة الحضور' : 'Attendance',
                      style: const TextStyle(fontSize: 8, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            excellent ? (isAr ? 'الدرس: سورة الكهف' : 'Lesson: Al-Kahf') : (isAr ? 'الدرس: سورة الملك' : 'Lesson: Al-Mulk'),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: excellent ? Colors.green.withValues(alpha: 0.15) : AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              excellent ? (isAr ? 'حفظ' : 'Memorize') : (isAr ? 'مراجعة' : 'Review'),
                              style: TextStyle(
                                fontSize: 8,
                                color: excellent ? Colors.green : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr ? 'ملاحظة المعلم:' : 'Sheikh Comment:',
                        style: const TextStyle(fontSize: 8, color: Colors.white38),
                      ),
                      Text(
                        excellent 
                            ? (isAr ? 'حفظ ممتاز جداً ومخارج الحروف سليمة' : 'Excellent retention and proper pronunciation')
                            : (isAr ? 'يحتاج لمراجعة أحكام المدود والمخارج' : 'Needs to review elongation rules and articulation'),
                        style: TextStyle(
                          fontSize: 9, 
                          color: excellent ? Colors.white70 : AppColors.secondary, 
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: excellent ? 0.95 : 0.65,
                              backgroundColor: Colors.white10,
                              color: excellent ? Colors.green : AppColors.secondary,
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            excellent ? '95%' : '65%',
                            style: const TextStyle(fontSize: 8, color: Colors.white38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMockup() {
    final isAr = AppLocalizations.of(context).localeName == 'ar';
    final studentView = _selectedChatView == 'student';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedChatView = 'student'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: studentView ? AppColors.secondary : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAr ? 'منظور الطالب' : 'Student View',
                        style: TextStyle(
                          color: studentView ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight: studentView ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedChatView = 'teacher'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: !studentView ? AppColors.secondary : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAr ? 'منظور المعلم' : 'Teacher View',
                        style: TextStyle(
                          color: !studentView ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight: !studentView ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 155,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1412),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF15221E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, size: 10, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        studentView 
                            ? (isAr ? 'الشيخ صابر (المعلم)' : 'Sheikh Saber (Teacher)')
                            : (isAr ? 'أحمد محمد (الطالب)' : 'Ahmed Mohamed (Student)'),
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(Icons.fiber_manual_record, color: Colors.green, size: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(6),
                    physics: const NeverScrollableScrollPhysics(),
                    children: studentView 
                        ? [
                            _buildChatBubble(
                              text: isAr ? 'السلام عليكم يا أحمد، أين واجب اليوم؟' : 'Assalamu Alaikum Ahmed, where is today\'s homework?',
                              isMe: false,
                              time: '7:10 PM',
                            ),
                            _buildVoiceNoteBubble(
                              isMe: true,
                              duration: '0:45',
                              time: '7:12 PM',
                            ),
                            _buildChatBubble(
                              text: isAr ? 'أحسن الله إليك، تلاوة ممتازة ومخارج سليمة!' : 'Well done! Excellent recitation and clear articulation!',
                              isMe: false,
                              time: '7:15 PM',
                            ),
                          ]
                        : [
                            _buildChatBubble(
                              text: isAr ? 'يا شيخي، هل مد الصلة الصغرى يمد بمقدار حركتين؟' : 'Sheikh, is the minor connection elongation lengthened by two counts?',
                              isMe: false,
                              time: '8:00 PM',
                            ),
                            _buildChatBubble(
                              text: isAr ? 'نعم يا بني، يمد بمقدار حركتين كالمد الطبيعي.' : 'Yes, my son. It is lengthened by two counts like natural elongation.',
                              isMe: true,
                              time: '8:02 PM',
                            ),
                            _buildVoiceNoteBubble(
                              isMe: true,
                              duration: '0:25',
                              time: '8:03 PM',
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({required String text, required bool isMe, required String time}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E4D3A) : const Color(0xFF222B28),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: isMe ? const Radius.circular(8) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(8),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 8, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(fontSize: 6, color: Colors.white38),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceNoteBubble({required bool isMe, required String duration, required String time}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E4D3A) : const Color(0xFF222B28),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: isMe ? const Radius.circular(8) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(8),
          ),
        ),
        width: 140,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.play_arrow_rounded, color: AppColors.secondary, size: 14),
                const SizedBox(width: 4),
                const Expanded(
                  child: SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      value: 0.3,
                      backgroundColor: Colors.white10,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: const TextStyle(fontSize: 7, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.mic, color: Colors.white30, size: 7),
                const SizedBox(width: 2),
                Text(
                  time,
                  style: const TextStyle(fontSize: 6, color: Colors.white38),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _getYoutubeId(String url) {
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      final videoId = match.group(2);
      if (videoId != null && videoId.length == 11) {
        return videoId;
      }
    }
    return null;
  }

  void _playVideoDialog(BuildContext context, String url) {
    final videoId = _getYoutubeId(url);
    if (videoId == null) {
      _launchExternalUrl(url);
      return;
    }

    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    final isTr = locale == 'tr';

    bool useEmbeddedPlayer = kIsWeb;
    if (!kIsWeb) {
      useEmbeddedPlayer = Platform.isAndroid || Platform.isIOS;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A1E1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr
                            ? 'فيديو تعريفي'
                            : (isTr ? 'Tanıtım Videosu' : 'Promotional Video'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                if (useEmbeddedPlayer)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: _EmbeddedYoutubePlayer(videoId: videoId),
                  )
                else
                  _buildWindowsVideoFallback(ctx, url, videoId, isAr, isTr),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildWindowsVideoFallback(
    BuildContext ctx,
    String url,
    String videoId,
    bool isAr,
    bool isTr,
  ) {
    final thumb = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(thumb),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAr
                ? 'تشغيل الفيديو في المتصفح'
                : (isTr ? 'Videoyu Tarayıcıda Oynat' : 'Play Video in Browser'),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'التشغيل المدمج مدعوم حالياً على الهواتف فقط. هل تود فتح الفيديو في المتصفح الخارجي؟'
                : (isTr
                    ? 'İç içe oynatma şu an sadece mobil cihazlarda desteklenmektedir. Harici tarayıcıda açmak ister misiniz?'
                    : 'Embedded playback is currently supported on mobile devices. Would you like to open it in an external browser?'),
            style: const TextStyle(color: Colors.white60, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : (isTr ? 'İptal' : 'Cancel'),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchExternalUrl(url);
                },
                icon: const Icon(Icons.open_in_browser, color: Colors.white, size: 18),
                label: Text(
                  isAr ? 'فتح الرابط' : (isTr ? 'Aç' : 'Open Link'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestFormSheet extends StatefulWidget {
  final String dialogTitle;
  final String nameLabel;
  final String phoneLabel;
  final String countryLabel;
  final String emailLabel;
  final String messengerLabel;
  final String submitTxt;
  final String cancelTxt;
  final String lang;
  final ProfileModel? teacher;

  const _GuestFormSheet({
    required this.dialogTitle,
    required this.nameLabel,
    required this.phoneLabel,
    required this.countryLabel,
    required this.emailLabel,
    required this.messengerLabel,
    required this.submitTxt,
    required this.cancelTxt,
    required this.lang,
    required this.teacher,
  });

  @override
  State<_GuestFormSheet> createState() => _GuestFormSheetState();
}

class _GuestFormSheetState extends State<_GuestFormSheet> {
  final _client = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCountry;
  final _emailController = TextEditingController();
  final _messengerController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messengerController.dispose();
    super.dispose();
  }

  Future<void> _submitGuestChat() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final country = _selectedCountry ?? '';
    final email = _emailController.text.trim();
    final messenger = _messengerController.text.trim();

    final isAr = widget.lang == 'ar';
    final isTr = widget.lang == 'tr';

    if (name.isEmpty || phone.isEmpty || country.isEmpty) {
      final errorMsg = isAr
          ? 'يرجى إدخال الاسم ورقم الهاتف والبلد.'
          : (isTr ? 'Lütfen adınızı, telefon numaranızı ve ülkenizi girin.' : 'Please enter your name, phone number, and country.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      final errorMsg = isAr
          ? 'يرجى إدخال بريد إلكتروني صحيح.'
          : (isTr ? 'Lütfen geçerli bir e-posta adresi girin.' : 'Please enter a valid email address.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // 1. Generate anonymous guest account credentials
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final generatedEmail = email.isNotEmpty ? email : 'guest_$timestamp@saberacademy.com';
      final generatedPassword = 'GuestPass_$timestamp!';

      // 2. Register via Supabase signup
      final signUpRes = await _client.auth.signUp(
        email: generatedEmail,
        password: generatedPassword,
        data: {'full_name': 'زائر: $name'},
      );

      final guestUserId = signUpRes.user?.id;
      if (guestUserId == null) {
        throw Exception('Sign up failed');
      }

      // 3. Insert profile row with RLS bypass using the new self-registration policy
      final profileData = <String, dynamic>{
        'id': guestUserId,
        'role': 'student',
        'full_name': 'زائر: $name',
        'email': generatedEmail,
        'phone': phone,
        'country': country,
        'messenger_link': messenger.isNotEmpty ? messenger : null,
        'level': 1,
        'lesson_in_level': 0.0,
        'total_in_level': 20.0,
        'is_paid': false,
        'study_system': 'classes',
        'study_balance': 0.0,
      };

      await _client.from('profiles').insert(profileData);

      // 4. Find the teacher (the Sheikh)
      ProfileModel? sheikh = widget.teacher;
      if (sheikh == null) {
        // Direct backup fetch just in case
        final sheikhData = await _client
            .from('profiles')
            .select()
            .eq('role', 'teacher')
            .limit(1)
            .maybeSingle();
        if (sheikhData != null) {
          sheikh = ProfileModel.fromMap(sheikhData);
        }
      }

      if (sheikh == null) {
        throw Exception('Teacher profile not found');
      }

      if (!mounted) return;

      // 5. Navigate to Home and request auto-opening of the chat
      Navigator.pop(context); // Close bottom sheet
      final routeUri = Uri(
        path: AppRoutes.studentHome,
        queryParameters: {
          'chat_partner_id': sheikh.id,
          'chat_partner_name': sheikh.fullName,
        },
      ).toString();
      context.go(routeUri);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.dialogTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.nameLabel,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: widget.phoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: widget.countryLabel,
                prefixIcon: const Icon(Icons.public_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _kCountries
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(_getLocalizedCountry(context, c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCountry = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: widget.emailLabel,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messengerController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: widget.messengerLabel,
                prefixIcon: const Icon(Icons.link_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.textSecondary),
                    ),
                    child: Text(
                      widget.cancelTxt,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitGuestChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.submitTxt,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedYoutubePlayer extends StatefulWidget {
  final String videoId;

  const _EmbeddedYoutubePlayer({required this.videoId});

  @override
  State<_EmbeddedYoutubePlayer> createState() => _EmbeddedYoutubePlayerState();
}

class _EmbeddedYoutubePlayerState extends State<_EmbeddedYoutubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
    );
  }
}

const List<String> _kCountries = [
  'المملكة العربية السعودية',
  'مصر',
  'الأردن',
  'فلسطين',
  'الإمارات العربية المتحدة',
  'الكويت',
  'البحرين',
  'قطر',
  'عُمان',
  'اليمن',
  'العراق',
  'سوريا',
  'لبنان',
  'ليبيا',
  'تونس',
  'الجزائر',
  'المغرب',
  'السودان',
  'الصومال',
  'موريتانيا',
  'تركيا',
  'باكستان',
  'ماليزيا',
  'إندونيسيا',
  'المملكة المتحدة',
  'ألمانيا',
  'فرنسا',
  'الولايات المتحدة الأمريكية',
  'كندا',
  'أستراليا',
  'دولة أخرى',
];

String _getLocalizedCountry(BuildContext context, String countryName) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'en') {
    switch (countryName) {
      case 'المملكة العربية السعودية': return 'Saudi Arabia';
      case 'مصر': return 'Egypt';
      case 'الأردن': return 'Jordan';
      case 'فلسطين': return 'Palestine';
      case 'الإمارات العربية المتحدة': return 'United Arab Emirates';
      case 'الكويت': return 'Kuwait';
      case 'البحرين': return 'Bahrain';
      case 'قطر': return 'Qatar';
      case 'عُمان': return 'Oman';
      case 'اليمن': return 'Yemen';
      case 'العراق': return 'Iraq';
      case 'سوريا': return 'Syria';
      case 'لبنان': return 'Lebanon';
      case 'ليبيا': return 'Libya';
      case 'تونس': return 'Tunisia';
      case 'الجزائر': return 'Algeria';
      case 'المغرب': return 'Morocco';
      case 'السودان': return 'Sudan';
      case 'الصومال': return 'Somalia';
      case 'موريتانيا': return 'Mauritania';
      case 'تركيا': return 'Turkey';
      case 'باكستان': return 'Pakistan';
      case 'ماليزيا': return 'Malaysia';
      case 'إندونيسيا': return 'Indonesia';
      case 'المملكة المتحدة': return 'United Kingdom';
      case 'ألمانيا': return 'Germany';
      case 'فرنسا': return 'France';
      case 'الولايات المتحدة الأمريكية': return 'United States';
      case 'كندا': return 'Canada';
      case 'أستراليا': return 'Australia';
      case 'دولة أخرى': return 'Other Country';
      default: return countryName;
    }
  } else if (locale == 'tr') {
    switch (countryName) {
      case 'المملكة العربية السعودية': return 'Suudi Arabistan';
      case 'مصر': return 'Mısır';
      case 'الأردن': return 'Ürdün';
      case 'فلسطين': return 'Filistin';
      case 'الإمارات العربية المتحدة': return 'Birleşik Arap Emirlikleri';
      case 'الكويت': return 'Kuveyt';
      case 'البحرين': return 'Bahreyn';
      case 'قطر': return 'Katar';
      case 'عُمان': return 'Umman';
      case 'اليمن': return 'Yemen';
      case 'العراق': return 'Irak';
      case 'سوريا': return 'Suriye';
      case 'لبنان': return 'Lübnan';
      case 'ليبيا': return 'Libya';
      case 'تونس': return 'Tunus';
      case 'الجزائر': return 'Cezayir';
      case 'المغرب': return 'Fas';
      case 'السودان': return 'Sudan';
      case 'الصومال': return 'Somali';
      case 'موريتانيا': return 'Moritanya';
      case 'تركيا': return 'Türkiye';
      case 'باكستان': return 'Pakistan';
      case 'ماليزيا': return 'Malezya';
      case 'إندونيسيا': return 'Endonezya';
      case 'المملكة المتحدة': return 'Birleşik Krallık';
      case 'ألمانيا': return 'Almanya';
      case 'فرنسا': return 'Fransa';
      case 'الولايات المتحدة الأمريكية': return 'Amerika Birleşik Devletleri';
      case 'كندا': return 'Kanada';
      case 'أستراليا': return 'Avustralya';
      case 'دولة أخرى': return 'Diğer Ülke';
      default: return countryName;
    }
  }
  return countryName;
}
