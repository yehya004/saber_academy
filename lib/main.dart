import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/app_qcf_font_loader.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load QCF Quran fonts in background
  AppQcfFontLoader.setupFontsAtStartup(
    onProgress: (_) {},
  ).catchError((e) {
    debugPrint("AppQcfFontLoader error: $e");
  });

  // Initialize FFI for Windows SQLite support
  if (!kIsWeb && Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialise the bundled IANA timezone database (needed by TimezoneService).
  tz.initializeTimeZones();

  Object? initError;
  try {
    // Load environment variables from .env (never commit real secrets).
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception("SUPABASE_URL or SUPABASE_ANON_KEY is missing in the .env file.");
    }

    await Supabase.initialize(
      url:     url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
    );

    // Initialize Firebase (non-Windows, non-Web) and Notification Services
    try {
      if (kIsWeb) {
        await NotificationService().initialize();
      } else if (Platform.isWindows) {
        await NotificationService().initialize();
      } else {
        await Firebase.initializeApp();
        await NotificationService().initialize();
      }
    } catch (e) {
      debugPrint("Firebase/Notification initialization failed: $e");
    }
  } catch (e) {
    debugPrint("Initialization failed: $e");
    initError = e;
  }

  // Load saved language preference and login status on startup to prevent reset/flashing and web refresh logouts
  String? savedLang;
  bool wasLoggedIn = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    savedLang = prefs.getString('app_language_pref');
    wasLoggedIn = prefs.getBool('was_logged_in') ?? false;
  } catch (_) {}

  AppRouter.wasLoggedIn = wasLoggedIn;

  if (initError != null) {
    runApp(InitializationErrorApp(error: initError));
    return;
  }

  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(initialLanguageCode: savedLang)),
        ChangeNotifierProvider(create: (_) => authProvider),
      ],
      child: const SaberAcademyApp(),
    ),
  );
}

class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E24),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D35),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ أثناء تشغيل البرنامج',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Failed to initialize application. Please ensure your configuration file (.env) exists and is correct.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    error.toString(),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

