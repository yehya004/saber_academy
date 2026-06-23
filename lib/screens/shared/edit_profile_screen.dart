import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _country;
  String? _avatarUrl;
  bool    _saving          = false;
  bool    _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    if (p != null) {
      _nameCtrl.text  = p.fullName;
      _phoneCtrl.text = p.phone ?? '';
      _country        = p.country;
      _avatarUrl      = p.avatarUrl;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _initials {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return '؟';
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '؟';
    return words.take(2).map((w) => w[0]).join();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source:       ImageSource.gallery,
      maxWidth:     512,
      maxHeight:    512,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes  = await file.readAsBytes();
      final ext    = file.path.split('.').last.toLowerCase();
      if (!mounted) return;
      final userId = context.read<AuthProvider>().profile!.id;
      final url    = await AuthService().uploadAvatar(userId, bytes, ext);
      if (mounted) setState(() { _avatarUrl = url; _uploadingAvatar = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).failedToUpload(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final isStudent = auth.profile?.role == 'student';
    setState(() => _saving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final currentEmail = user.email ?? '';
        final newEmail = _emailCtrl.text.trim();
        final newPassword = _passwordCtrl.text.trim();

        if (newEmail != currentEmail || newPassword.isNotEmpty) {
          final updates = UserAttributes(
            email: newEmail != currentEmail ? newEmail : null,
            password: newPassword.isNotEmpty ? newPassword : null,
          );
          await Supabase.instance.client.auth.updateUser(updates);

          final profileUpdates = <String, dynamic>{};
          if (newEmail != currentEmail) {
            profileUpdates['email'] = newEmail;
          }
          if (newPassword.isNotEmpty && isStudent) {
            profileUpdates['student_password'] = newPassword;
          }

          if (profileUpdates.isNotEmpty) {
            await Supabase.instance.client
                .from('profiles')
                .update(profileUpdates)
                .eq('id', user.id);
          }
        }
      }

      final ok   = await auth.updateProfile(
        fullName:  _nameCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        country:   _country,
        avatarUrl: _avatarUrl,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileSavedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).profileSaveError,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Gradient AppBar with avatar ──────────────────
            SliverAppBar(
              pinned:          true,
              expandedHeight:  220,
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: AppColors.surface),
              title: Text(
                l10n.editProfile,
                style: const TextStyle(
                  color:      AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1E6648)],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50), // below status bar
                        GestureDetector(
                          onTap: _uploadingAvatar ? null : _pickAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor:
                                    AppColors.secondary.withValues(alpha: 0.25),
                                backgroundImage: _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _uploadingAvatar
                                    ? const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          color:       AppColors.surface,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : (_avatarUrl == null
                                        ? Text(
                                            _initials,
                                            style: const TextStyle(
                                              color:      AppColors.surface,
                                              fontSize:   30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:  AppColors.secondary,
                                  shape:  BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size:  14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.changePhoto,
                          style: TextStyle(
                            color:    AppColors.surface.withValues(alpha: 0.70),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Form fields ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Personal info card ───────────────────
                    _SectionLabel(label: l10n.personalInfoSection),
                    const SizedBox(height: AppSpacing.small),
                    _Card(
                      children: [
                        _FieldTile(
                          controller: _nameCtrl,
                          label:      l10n.fullName,
                          icon:       Icons.person_outline,
                          onChanged:  (_) => setState(() {}),
                          validator:  (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? l10n.nameRequired
                                  : null,
                        ),
                        _divider(),
                        _FieldTile(
                          controller: _phoneCtrl,
                          label:      l10n.phoneNumber,
                          icon:       Icons.phone_outlined,
                          keyboard:   TextInputType.phone,
                        ),
                        _divider(),
                        _CountryTile(
                          value:    _country,
                          onChanged: (v) => setState(() => _country = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.large),

                    // ── Account credentials card ─────────────
                    _SectionLabel(
                      label: l10n.localeName == 'ar'
                          ? 'بيانات الحساب'
                          : l10n.localeName == 'tr'
                              ? 'Hesap Bilgileri'
                              : 'Account Credentials',
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _Card(
                      children: [
                        _FieldTile(
                          controller: _emailCtrl,
                          label:      l10n.email,
                          icon:       Icons.email_outlined,
                          keyboard:   TextInputType.emailAddress,
                          validator:  (v) => (v == null || v.trim().isEmpty)
                              ? (l10n.localeName == 'ar' ? 'البريد الإلكتروني مطلوب' : 'Email is required')
                              : null,
                        ),
                        _divider(),
                        _FieldTile(
                          controller: _passwordCtrl,
                          label:      l10n.localeName == 'ar'
                              ? 'كلمة المرور الجديدة'
                              : l10n.localeName == 'tr'
                                  ? 'Yeni Şifre'
                                  : 'New Password',
                          icon:       Icons.lock_outline,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.large),

                    // ── Save button ──────────────────────────
                    SizedBox(
                      width:  double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width:  22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color:       AppColors.surface,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                l10n.saveChanges,
                                style: const TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.large),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        indent: 56,
        color: AppColors.progressTrack,
      );
}

// ── Reusable sub-widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          right:  AppSpacing.small,
          bottom: 4,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color:      AppColors.textSecondary,
            fontSize:   13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard   = TextInputType.text,
    this.validator,
    this.onChanged,
  });

  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final TextInputType              keyboard;
  final String? Function(String?)? validator;
  final ValueChanged<String>?      onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: TextFormField(
          controller:  controller,
          keyboardType: keyboard,
          validator:   validator,
          onChanged:   onChanged,
          obscureText: icon == Icons.lock_outline,
          textAlign:   TextAlign.right,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            labelText:  label,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border:       InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      );
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({required this.value, required this.onChanged});
  final String?             value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText:  l10n.countryLabel,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(
            Icons.flag_outlined,
            color: AppColors.primary,
            size:  20,
          ),
          border:       InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        hint: Text(
          l10n.chooseStudentCountry,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        items: _kCountries
            .map(
              (c) => DropdownMenuItem(value: c, child: Text(getLocalizedCountry(context, c))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Country list ─────────────────────────────────────────────────────────────

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
  'أفغانستان',
  'بنغلاديش',
  'الهند',
  'الصين',
  'اليابان',
  'ماليزيا',
  'إندونيسيا',
  'تركمنستان',
  'أوزبكستان',
  'طاجيكستان',
  'قيرغيزستان',
  'كازاخستان',
  'أذربيجان',
  'جورجيا',
  'أرمينيا',
  'المملكة المتحدة',
  'ألمانيا',
  'فرنسا',
  'السويد',
  'النرويج',
  'الدنمارك',
  'هولندا',
  'بلجيكا',
  'سويسرا',
  'إيطاليا',
  'إسبانيا',
  'البرتغال',
  'النمسا',
  'اليونان',
  'بولندا',
  'أوكرانيا',
  'روسيا',
  'الولايات المتحدة الأمريكية',
  'كندا',
  'البرازيل',
  'الأرجنتين',
  'أستراليا',
  'جنوب إفريقيا',
  'دولة أخرى',
];

String getLocalizedCountry(BuildContext context, String countryName) {
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
      case 'أفغانستان': return 'Afghanistan';
      case 'بنغلاديش': return 'Bangladesh';
      case 'الهند': return 'India';
      case 'الصين': return 'China';
      case 'اليابان': return 'Japan';
      case 'ماليزيا': return 'Malaysia';
      case 'إندونيسيا': return 'Indonesia';
      case 'تركمنستان': return 'Turkmenistan';
      case 'أوزبكستان': return 'Uzbekistan';
      case 'طاجيكستان': return 'Tajikistan';
      case 'قيرغيزستان': return 'Kyrgyzstan';
      case 'كازاخستان': return 'Kazakhstan';
      case 'أذربيجان': return 'Azerbaijan';
      case 'جورجيا': return 'Georgia';
      case 'أرمينيا': return 'Armenia';
      case 'المملكة المتحدة': return 'United Kingdom';
      case 'ألمانيا': return 'Germany';
      case 'فرنسا': return 'France';
      case 'السويد': return 'Sweden';
      case 'النرويج': return 'Norway';
      case 'الدنمارك': return 'Denmark';
      case 'هولندا': return 'Netherlands';
      case 'بلجيكا': return 'Belgium';
      case 'سويسرا': return 'Switzerland';
      case 'إيطاليا': return 'Italy';
      case 'إسبانيا': return 'Spain';
      case 'البرتغال': return 'Portugal';
      case 'النمسا': return 'Austria';
      case 'اليونان': return 'Greece';
      case 'بولندا': return 'Poland';
      case 'أوكرانيا': return 'Ukraine';
      case 'روسيا': return 'Russia';
      case 'الولايات المتحدة الأمريكية': return 'United States';
      case 'كندا': return 'Canada';
      case 'البرازيل': return 'Brazil';
      case 'الأرجنتين': return 'Argentina';
      case 'أستراليا': return 'Australia';
      case 'جنوب إفريقيا': return 'South Africa';
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
      case 'أفغانستان': return 'Afganistan';
      case 'بنغلاديش': return 'Bangladeş';
      case 'الهند': return 'Hindistan';
      case 'الصين': return 'Çin';
      case 'اليابان': return 'Japonya';
      case 'ماليزيا': return 'Malezya';
      case 'إندونيسيا': return 'Endonezya';
      case 'تركمنستان': return 'Türkmenistan';
      case 'أوزبكستان': return 'Özbekistan';
      case 'طاجيكستان': return 'Tacikistan';
      case 'قيرغيزستان': return 'Kırgızistan';
      case 'كازاخستان': return 'Kazakistan';
      case 'أذربيجان': return 'Azerbaycan';
      case 'جورجيا': return 'Gürcistan';
      case 'أرمينيا': return 'Ermenistan';
      case 'المملكة المتحدة': return 'Birleşik Krallık';
      case 'ألمانيا': return 'Almanya';
      case 'فرنسا': return 'Fransa';
      case 'السويد': return 'İsveç';
      case 'النرويج': return 'Norveç';
      case 'الدنمارك': return 'Danimarka';
      case 'هولندا': return 'Hollanda';
      case 'بلجيكا': return 'Belçika';
      case 'سويسرا': return 'İsviçre';
      case 'إيطاليا': return 'İtalya';
      case 'إسبانيا': return 'İspanya';
      case 'البرتغال': return 'Portekiz';
      case 'النمسا': return 'Avusturya';
      case 'اليونان': return 'Yunanistan';
      case 'بولندا': return 'Polonya';
      case 'أوكرانيا': return 'Ukrayna';
      case 'روسيا': return 'Rusya';
      case 'الولايات المتحدة الأمريكية': return 'Amerika Birleşik Devletleri';
      case 'كندا': return 'Kanada';
      case 'البرازيل': return 'Brezilya';
      case 'الأرجنتين': return 'Arjantin';
      case 'أستراليا': return 'Avustralya';
      case 'جنوب إفريقيا': return 'Güney Afrika';
      case 'دولة أخرى': return 'Diğer Ülke';
      default: return countryName;
    }
  }
  return countryName;
}
