import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final _client = Supabase.instance.client;

  /// Returns all profiles with role = 'student' and is_guest = false.
  Future<List<ProfileModel>> fetchStudents() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', 'student')
        .eq('is_guest', false)
        .order('full_name');
    return data.map((e) => ProfileModel.fromMap(e)).toList();
  }

  /// Returns all profiles with role = 'student' and is_guest = true.
  Future<List<ProfileModel>> fetchGuests() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', 'student')
        .eq('is_guest', true)
        .order('full_name');
    return data.map((e) => ProfileModel.fromMap(e)).toList();
  }

  /// Returns a single student profile by id.
  Future<ProfileModel?> fetchStudentById(String studentId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', studentId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromMap(data);
  }

  /// Teacher updates a student's manual level, lesson number, payment, and block status.
  Future<void> updateStudentLevel({
    required String studentId,
    required int    level,
    required double lessonInLevel,
    double?         totalInLevel,
    bool?           isPaid,
    bool?           isBlocked,
    String?         studySystem,
    double?         studyBalance,
  }) {
    final updates = <String, dynamic>{
      'level':           level,
      'lesson_in_level': lessonInLevel,
    };
    if (totalInLevel != null) updates['total_in_level'] = totalInLevel;
    if (isPaid != null) updates['is_paid'] = isPaid;
    if (isBlocked != null) updates['is_blocked'] = isBlocked;
    if (studySystem != null) updates['study_system'] = studySystem;
    if (studyBalance != null) updates['study_balance'] = studyBalance;
    return _client.from('profiles').update(updates).eq('id', studentId);
  }

  /// Teacher updates a student's contact info (phone, messenger, country).
  Future<void> updateStudentContact({
    required String  studentId,
    required String? phone,
    required String? messengerLink,
    required String? country,
  }) =>
      _client.from('profiles').update({
        'phone':           phone,
        'messenger_link':  messengerLink,
        'country':         country,
      }).eq('id', studentId);

  /// Returns the teacher profile for a given student.
  /// Uses a SECURITY DEFINER PostgreSQL function that bypasses RLS,
  /// so this always works regardless of which policies are active.
  Future<ProfileModel?> fetchTeacherForStudent(String studentId) async {
    try {
      // Call the RPC function which has SECURITY DEFINER (bypasses RLS)
      final rows = await _client
          .rpc('get_teacher_for_student', params: {'p_student_id': studentId});
      if (rows != null && (rows as List).isNotEmpty) {
        return ProfileModel.fromMap(rows[0] as Map<String, dynamic>);
      }
    } catch (_) {}

    // Direct fallback if the RPC function doesn't exist yet
    try {
      final teacherData = await _client
          .from('profiles')
          .select()
          .eq('role', 'teacher')
          .limit(1)
          .maybeSingle();
      if (teacherData != null) return ProfileModel.fromMap(teacherData);
    } catch (_) {}

    return null;
  }
}
