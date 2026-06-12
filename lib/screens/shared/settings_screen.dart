import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final auth   = context.read<AuthProvider>();
    final l10n   = AppLocalizations.of(context);
    final name   = auth.profile?.fullName ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────
          SliverAppBar(
            pinned:          true,
            backgroundColor: AppColors.primary,
            iconTheme:       const IconThemeData(color: AppColors.surface),
            title: Text(
              l10n.settings,
              style: const TextStyle(
                color:      AppColors.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                children: [
                  // ── Profile header card ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset:     const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar: show photo if available
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.editProfile),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary,
                                backgroundImage: auth.profile?.avatarUrl != null
                                    ? CachedNetworkImageProvider(auth.profile!.avatarUrl!)
                                    : null,
                                child: auth.profile?.avatarUrl == null
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color:      AppColors.surface,
                                          fontSize:   24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.surface, width: 1.5),
                                  ),
                                  child: const Icon(Icons.edit, size: 10, color: AppColors.surface),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:   17,
                                  color:      AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:        AppColors.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  auth.isTeacher
                                      ? (l10n.localeName == 'ar' ? 'معلم' : l10n.localeName == 'tr' ? 'Öğretmen' : 'Teacher')
                                      : (l10n.localeName == 'ar' ? 'طالب' : l10n.localeName == 'tr' ? 'Öğrenci' : 'Student'),
                                  style: const TextStyle(
                                    color:    AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.large),

                  // ── Language section ─────────────────────────
                  _SectionLabel(label: l10n.language),
                  const SizedBox(height: AppSpacing.small),

                  Container(
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.language, color: AppColors.primary, size: 20),
                      ),
                      title: Text(l10n.language),
                      subtitle: Text(
                        locale.locale.languageCode == 'ar'
                            ? l10n.languageArabic
                            : locale.locale.languageCode == 'tr'
                                ? l10n.languageTurkish
                                : l10n.languageEnglish,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:            locale.locale.languageCode,
                          icon:             const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          dropdownColor:    AppColors.surface,
                          borderRadius:     BorderRadius.circular(12),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              locale.setLocale(Locale(newValue));
                              context.read<AuthProvider>().updateLocalLanguagePreference(newValue);
                              final userId = auth.profile?.id;
                              if (userId != null) {
                                AuthService().updateLanguagePreference(userId, newValue);
                              }
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text(l10n.languageArabic, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(l10n.languageEnglish, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            DropdownMenuItem(
                              value: 'tr',
                              child: Text(l10n.languageTurkish, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.large),

                  // ── Quran section ────────────────────────────
                  _SectionLabel(label: l10n.localeName == 'ar' ? 'القرآن الكريم' : l10n.localeName == 'tr' ? 'Kur\'an-ı Kerim' : 'Holy Quran'),
                  const SizedBox(height: AppSpacing.small),

                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.small),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_stories_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        l10n.quranMushaf,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.browseReadMushaf,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: () => context.push(AppRoutes.mushaf),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.small),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.download_for_offline_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        l10n.downloadsTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.localeName == 'ar' ? 'إدارة وتحميل المصاحف والتفاسير والتلاوات' : (l10n.localeName == 'tr' ? 'Mushafları, tefsirleri ve sesleri yönet' : 'Manage and download Mushafs, Tafsirs, and audios'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: () => context.push(AppRoutes.downloads),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.large),

                  if (auth.isTeacher) ...[
                    _SectionLabel(label: l10n.localeName == 'ar' ? 'إدارة الأكاديمية' : 'Academy Management'),
                    const SizedBox(height: AppSpacing.small),
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.large),
                      decoration: BoxDecoration(
                        color:        AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset:     const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color:        AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          l10n.localeName == 'ar' ? 'تعديل معلومات الأكاديمية' : 'Edit Academy Info',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.localeName == 'ar' ? 'تعديل السيرة الذاتية وفيديوهات اليوتيوب' : 'Edit bio and YouTube videos',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () => context.push(AppRoutes.editAcademyInfo),
                      ),
                    ),
                  ],

                  // ── Account section ──────────────────────────
                  _SectionLabel(label: l10n.localeName == 'ar' ? 'الحساب' : l10n.localeName == 'tr' ? 'Hesap' : 'Account'),
                  const SizedBox(height: AppSpacing.small),

                  // Edit profile tile
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.small),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                          size:  20,
                        ),
                      ),
                      title: Text(
                        l10n.localeName == 'ar' ? 'تعديل الملف الشخصي' : l10n.localeName == 'tr' ? 'Profili Düzenle' : 'Edit Profile',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color:        AppColors.error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout, color: AppColors.error, size: 20),
                      ),
                      title: Text(
                        l10n.signOut,
                        style: const TextStyle(
                          color:      AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        await auth.signOut();
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                    ),
                  ),



                  const SizedBox(height: AppSpacing.extraLarge),

                  // ── Footer ───────────────────────────────────
                  Text(
                    '${l10n.appTitle} • v1.0.0',
                    style: TextStyle(
                      color:    AppColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        label,
        style: const TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.bold,
          color:      AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
