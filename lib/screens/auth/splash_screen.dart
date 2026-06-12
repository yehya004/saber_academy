import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

import '../../services/profile_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<double>    _scaleAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    _ctrl.forward();
    _redirect();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go(AppRoutes.login);
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.loadProfile();
    if (!mounted) return;

    if (auth.profile == null) {
      // Profile missing or load failed — force re-login
      context.go(AppRoutes.login);
      return;
    }

    // Sync language preference between device (SharedPreferences) and database
    try {
      final localeProv = context.read<LocaleProvider>();
      final dbLang = auth.profile?.languagePreference;
      final localLang = localeProv.locale.languageCode;

      if (localeProv.hasSavedLocale) {
        if (dbLang != localLang && dbLang != null) {
          await AuthService().updateLanguagePreference(auth.profile!.id, localLang);
          try {
            await auth.loadProfile();
          } catch (_) {}
        }
      } else {
        if (dbLang != null && (dbLang == 'ar' || dbLang == 'en' || dbLang == 'tr')) {
          await localeProv.setLocale(Locale(dbLang));
        }
      }
    } catch (e) {
      debugPrint("Offline/Network error during language sync: $e");
    }

    if (!mounted) return;

    if (auth.profile?.isGuest == true) {
      final teacher = await ProfileService().fetchTeacherForStudent(auth.profile!.id);
      if (teacher != null && mounted) {
        context.go(AppRoutes.chat, extra: {
          'partnerId': teacher.id,
          'partnerName': teacher.fullName,
        });
        return;
      } else {
        await auth.signOut();
        if (mounted) context.go(AppRoutes.aboutAcademy);
        return;
      }
    }

    context.go(auth.isTeacher ? AppRoutes.teacherHome : AppRoutes.studentHome);

    // Trigger pending notification navigation after redirecting to Home Screen
    final pending = NotificationService.pendingNotificationPayload;
    if (pending != null) {
      NotificationService.pendingNotificationPayload = null;
      Future.delayed(const Duration(milliseconds: 500), () {
        NotificationService.handleNotificationPayload(pending);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF1E6147)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80, left: -50,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          color:  AppColors.surface,
                          shape:  BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black.withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset:     const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.menu_book_rounded,
                              size:  70,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),

                      // App name
                      Text(
                        AppLocalizations.of(context).appTitle,
                        style: const TextStyle(
                          color:         AppColors.surface,
                          fontSize:      26,
                          fontWeight:    FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        AppLocalizations.of(context).loginSubtitle,
                        style: TextStyle(
                          color:    AppColors.surface.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.extraLarge),

                      // Gold divider ornament
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 50, height: 1.5, color: AppColors.secondary),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.star_rounded,
                            size:  14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 10),
                          Container(width: 50, height: 1.5, color: AppColors.secondary),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.extraLarge),

                      // Loading indicator
                      SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:       AppColors.secondary.withValues(alpha: 0.80),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
