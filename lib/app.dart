import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'providers/locale_provider.dart';

class SaberAcademyApp extends StatelessWidget {
  const SaberAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,

      // ── Localization ──────────────────────────────────────
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('tr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Theme (Design.md §2 tokens) ───────────────────────
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary:   AppColors.primary,
          secondary: AppColors.secondary,
          surface:   AppColors.surface,
          onPrimary: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error:     AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        // Switch font family based on active locale.
        fontFamily: localeProvider.isArabic ? 'Cairo' : 'Outfit',
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),

      routerConfig: AppRouter.router,
    );
  }
}
