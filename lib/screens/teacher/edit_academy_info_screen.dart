import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

class TeacherEditAcademyInfoScreen extends StatefulWidget {
  const TeacherEditAcademyInfoScreen({super.key});

  @override
  State<TeacherEditAcademyInfoScreen> createState() => _TeacherEditAcademyInfoScreenState();
}

class _TeacherEditAcademyInfoScreenState extends State<TeacherEditAcademyInfoScreen> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _bioArCtrl = TextEditingController();
  final _bioEnCtrl = TextEditingController();
  final _bioTrCtrl = TextEditingController();

  final _descArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _descTrCtrl = TextEditingController();

  final _newVideoCtrl = TextEditingController();

  List<String> _videoUrls = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bioArCtrl.dispose();
    _bioEnCtrl.dispose();
    _bioTrCtrl.dispose();
    _descArCtrl.dispose();
    _descEnCtrl.dispose();
    _descTrCtrl.dispose();
    _newVideoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _client
          .from('academy_info')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _bioArCtrl.text = data['sheikh_bio'] as String? ?? '';
          _bioEnCtrl.text = data['sheikh_bio_en'] as String? ?? '';
          _bioTrCtrl.text = data['sheikh_bio_tr'] as String? ?? '';

          _descArCtrl.text = data['program_desc'] as String? ?? '';
          _descEnCtrl.text = data['program_desc_en'] as String? ?? '';
          _descTrCtrl.text = data['program_desc_tr'] as String? ?? '';

          _videoUrls = List<String>.from(data['youtube_urls'] ?? []);
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _addVideoUrl() {
    final url = _newVideoCtrl.text.trim();
    if (url.isEmpty) return;

    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رابط يوتيوب صحيح.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _videoUrls.add(url);
      _newVideoCtrl.clear();
    });
  }

  void _removeVideoUrl(int index) {
    setState(() {
      _videoUrls.removeAt(index);
    });
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _client.from('academy_info').upsert({
        'id': 1,
        'sheikh_bio': _bioArCtrl.text.trim(),
        'sheikh_bio_en': _bioEnCtrl.text.trim(),
        'sheikh_bio_tr': _bioTrCtrl.text.trim(),
        'program_desc': _descArCtrl.text.trim(),
        'program_desc_en': _descEnCtrl.text.trim(),
        'program_desc_tr': _descTrCtrl.text.trim(),
        'youtube_urls': _videoUrls,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ البيانات بنجاح!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    final titleTxt = isAr ? 'تعديل معلومات الأكاديمية' : 'Edit Academy Info';
    final saveTxt = isAr ? 'حفظ التغييرات' : 'Save Changes';

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching premium theme
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
            child: Column(
              children: [
                // AppBar style matching the About screen
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
                          titleTxt,
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
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                      : Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- Biography Card ---
                                _buildCardSection(
                                  title: isAr ? 'السيرة الذاتية للشيخ صابر' : 'Sheikh Biography',
                                  icon: Icons.person_outline_rounded,
                                  children: [
                                    _buildTextField(
                                      _bioArCtrl,
                                      isAr ? 'السيرة الذاتية باللغة العربية' : 'Bio in Arabic',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      _bioEnCtrl,
                                      isAr ? 'السيرة الذاتية باللغة الإنجليزية' : 'Bio in English (Optional)',
                                      isRequired: false,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      _bioTrCtrl,
                                      isAr ? 'السيرة الذاتية باللغة التركية' : 'Bio in Turkish (Optional)',
                                      isRequired: false,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // --- Program Description Card ---
                                _buildCardSection(
                                  title: isAr ? 'شرح برنامج الأكاديمية والمميزات' : 'Program Description',
                                  icon: Icons.menu_book_rounded,
                                  children: [
                                    _buildTextField(
                                      _descArCtrl,
                                      isAr ? 'شرح البرنامج باللغة العربية' : 'Description in Arabic',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      _descEnCtrl,
                                      isAr ? 'شرح البرنامج باللغة الإنجليزية' : 'Description in English (Optional)',
                                      isRequired: false,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      _descTrCtrl,
                                      isAr ? 'شرح البرنامج باللغة التركية' : 'Description in Turkish (Optional)',
                                      isRequired: false,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // --- YouTube Videos Card ---
                                _buildCardSection(
                                  title: isAr ? 'فيديوهات ترويجية يوتيوب' : 'YouTube Promo Videos',
                                  icon: Icons.video_collection_outlined,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _newVideoCtrl,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: isAr ? 'أدخل رابط فيديو يوتيوب هنا' : 'Enter YouTube video link',
                                              hintStyle: const TextStyle(color: Colors.white38),
                                              filled: true,
                                              fillColor: Colors.white.withValues(alpha: 0.05),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton.filled(
                                          onPressed: _addVideoUrl,
                                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                                          style: IconButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.all(12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Previews inside Horizontal Scroll
                                    if (_videoUrls.isNotEmpty)
                                      SizedBox(
                                        height: 140,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _videoUrls.length,
                                          itemBuilder: (ctx, i) {
                                            final url = _videoUrls[i];
                                            final thumb = _getYoutubeThumbnail(url);
                                            return Container(
                                              width: 200,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.white24, width: 1.2),
                                                image: thumb != null
                                                    ? DecorationImage(
                                                        image: NetworkImage(thumb),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                                color: Colors.white10,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(15),
                                                      color: Colors.black45,
                                                    ),
                                                  ),
                                                  const Center(
                                                    child: Icon(Icons.play_circle_fill, color: Colors.red, size: 40),
                                                  ),
                                                  Positioned(
                                                    top: 6, right: 6,
                                                    child: GestureDetector(
                                                      onTap: () => _removeVideoUrl(i),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.black87,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Text(
                                          isAr ? 'لم يتم إضافة فيديوهات ترويجية بعد.' : 'No promotional videos added yet.',
                                          style: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // --- Save Button ---
                                ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Text(
                                          saveTxt,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
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

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
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
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool isRequired = true,
  }) {
    final isAr = AppLocalizations.of(context).localeName == 'ar';
    return TextFormField(
      controller: ctrl,
      maxLines: 4,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.trim().isEmpty)) {
          return isAr ? 'هذا الحقل مطلوب' : 'This field is required';
        }
        return null;
      },
    );
  }
}
