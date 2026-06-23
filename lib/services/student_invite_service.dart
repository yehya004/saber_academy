import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/exceptions/student_invite_exception.dart';

/// Handles teacher-initiated student account creation.
class StudentInviteService {
  /// Creates a new student account and profile row.
  ///
  /// [password] is set by the teacher.
  /// Returns [StudentCredentials] on success, throws an Arabic string on failure.
  Future<StudentCredentials> createStudentAccount({
    required String fullName,
    required String email,
    required String password,
    String? country,
    String? whatsapp,
    String? messengerLink,
    int level = 1,
    double lessonInLevel = 0.0,
    double totalInLevel = 20.0,
    bool isPaid = false,
    String studySystem = 'classes',
    double studyBalance = 0.0,
  }) async {
    final url = dotenv.env['SUPABASE_URL']!;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;

    // ── Step 1: sign up via a temporary client ──────────────────
    // Use implicit flow to avoid PKCE asyncStorage requirement.
    final tempClient = SupabaseClient(
      url,
      anonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    try {
      final res = await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final userId = res.user?.id;
      if (userId == null) {
        throw const StudentInviteException(
            'فشل إنشاء الحساب – تحقق من صحة البريد الإلكتروني.');
      }

      // ── Step 2: insert profile row ────────────────────────────
      // Always use the teacher's authenticated client.
      // Using tempClient (student session) would fail RLS because the student
      // has no profile row yet, so auth.uid() lookup returns null ≠ 'teacher'.
      final insertClient = Supabase.instance.client;

      final profileData = <String, dynamic>{
        'id': userId,
        'role': 'student',
        'full_name': fullName,
        'language_preference': 'ar',
        'level': level,
        'lesson_in_level': lessonInLevel,
        'total_in_level': totalInLevel,
        'email': email,
        'student_password': password,
        'is_paid': isPaid,
        'study_system': studySystem,
        'study_balance': studyBalance,
        if (country != null && country.isNotEmpty) 'country': country,
        if (whatsapp != null && whatsapp.isNotEmpty) 'phone': whatsapp,
        if (messengerLink != null && messengerLink.isNotEmpty)
          'messenger_link': messengerLink,
      };

      await insertClient.from('profiles').upsert(profileData);

      return StudentCredentials(
        email: email,
        password: password,
        fullName: fullName,
        country: country,
        whatsapp: whatsapp,
        messengerLink: messengerLink,
        level: level,
        lessonInLevel: lessonInLevel,
        totalInLevel: totalInLevel,
        studySystem: studySystem,
        studyBalance: studyBalance,
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.message.contains('already been registered')) {
        throw const StudentInviteException(
            'هذا البريد الإلكتروني مسجّل مسبقاً.');
      }
      throw StudentInviteException('خطأ في المصادقة: ${e.message}');
    } catch (e) {
      if (e is StudentInviteException) rethrow;
      throw StudentInviteException('حدث خطأ غير متوقع: $e');
    } finally {
      tempClient.dispose();
    }
  }
}

class StudentCredentials {
  final String email;
  final String password;
  final String fullName;
  final String? country;
  final String? whatsapp;
  final String? messengerLink;
  final int level;
  final double lessonInLevel;
  final double totalInLevel;
  final String studySystem;
  final double studyBalance;

  const StudentCredentials({
    required this.email,
    required this.password,
    required this.fullName,
    this.country,
    this.whatsapp,
    this.messengerLink,
    this.level = 1,
    this.lessonInLevel = 0.0,
    this.totalInLevel = 20.0,
    this.studySystem = 'classes',
    this.studyBalance = 0.0,
  });

  /// Ready-to-share Arabic text for copy/paste.
  String get shareText {
    final buf = StringBuffer();
    buf.writeln('🎓 بيانات تسجيل الدخول – أكاديمية صابر\n');
    buf.writeln('الاسم: $fullName');
    buf.writeln('البريد الإلكتروني: $email');
    buf.writeln('كلمة المرور: $password');
    final sysName = studySystem == 'hours' ? 'ساعات' : 'حصص';
    buf.writeln('نظام الدراسة: $sysName');
    buf.writeln('الرصيد الابتدائي: $studyBalance');
    if (country != null && country!.isNotEmpty) buf.writeln('الدولة: $country');
    if (whatsapp != null && whatsapp!.isNotEmpty) {
      buf.writeln('واتساب: $whatsapp');
    }
    if (messengerLink != null && messengerLink!.isNotEmpty) {
      buf.writeln('ماسنجر: $messengerLink');
    }
    buf.writeln('\nيُرجى تسجيل الدخول وتغيير كلمة المرور من الإعدادات.');
    return buf.toString();
  }
}
