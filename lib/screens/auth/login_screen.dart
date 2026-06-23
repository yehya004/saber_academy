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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService        = AuthService();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.loadProfile();
      if (!mounted) return;

      if (auth.profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileNotFound),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Apply saved language preference
      final lang = auth.profile?.languagePreference;
      if (lang != null && (lang == 'ar' || lang == 'en' || lang == 'tr')) {
        await context.read<LocaleProvider>().setLocale(Locale(lang));
      }

      if (!mounted) return;
      context.go(auth.isTeacher ? AppRoutes.teacherHome : AppRoutes.studentHome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top green arc
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),

          // Language selector on top of green background
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: _buildLanguageFlags(),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical:   AppSpacing.small,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.large),

                    // Logo in white circle
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset:     const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.menu_book_rounded,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        color:         AppColors.surface,
                        fontSize:      28,
                        fontWeight:    FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.loginSubtitle,
                      style: TextStyle(
                        color:    AppColors.surface.withValues(alpha: 0.80),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.extraLarge),

                    // White form card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      decoration: BoxDecoration(
                        color:        AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset:     const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.login,
                              style: const TextStyle(
                                fontSize:   22,
                                fontWeight: FontWeight.bold,
                                color:      AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.large),

                            TextFormField(
                              controller:   _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText:  l10n.email,
                                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                                filled:    true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? l10n.emailValidationError
                                      : null,
                            ),
                            const SizedBox(height: AppSpacing.medium),

                            TextFormField(
                              controller:  _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText:  l10n.password,
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                                filled:    true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.length < 6)
                                      ? l10n.passwordValidationError
                                      : null,
                            ),

                            const SizedBox(height: AppSpacing.extraLarge),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.surface,
                                  elevation:       2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.surface,
                                        ),
                                      )
                                    : Text(
                                        l10n.login,
                                        style: const TextStyle(
                                          fontSize:   16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 40, height: 2, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Container(width: 40, height: 2, color: AppColors.secondary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.large),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.aboutAcademy),
                      icon: const Icon(Icons.explore_outlined, color: AppColors.primary, size: 20),
                      label: Text(
                        l10n.localeName == 'ar'
                            ? 'تعرف على الأكاديمية (دخول الزوار)'
                            : l10n.localeName == 'tr'
                                ? 'Akademiyi Tanıyın (Ziyaretçi Girişi)'
                                : 'Explore the Academy (Visitor Entry)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageFlags() {
    final currentLocale = Provider.of<LocaleProvider>(context).locale;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFlagButton('ar', 'assets/images/flag_sa.png', 'العربية', currentLocale.languageCode == 'ar'),
        const SizedBox(width: 8),
        _buildFlagButton('en', 'assets/images/flag_gb.png', 'English', currentLocale.languageCode == 'en'),
        const SizedBox(width: 8),
        _buildFlagButton('tr', 'assets/images/flag_tr.png', 'Türkçe', currentLocale.languageCode == 'tr'),
      ],
    );
  }

  Widget _buildFlagButton(String langCode, String flagAsset, String label, bool isSelected) {
    return GestureDetector(
      onTap: () async {
        await context.read<LocaleProvider>().setLocale(Locale(langCode));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withValues(alpha: 0.20) 
              : Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.white.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                flagAsset,
                width: 22,
                height: 15,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
