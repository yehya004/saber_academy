/// Mirrors the `profiles` table in Supabase.
class ProfileModel {
  final String id;
  final String role; // 'teacher' | 'student'
  final String fullName;
  final String languagePreference; // 'en' | 'ar'
  final DateTime createdAt;
  final String? phone;          // WhatsApp number
  final String? messengerLink;   // Messenger / Facebook profile link
  final String? country;
  final String? avatarUrl;
  final String? email;           // stored in profiles for teacher visibility
  final int     level;         // manual level set by teacher
  final double  lessonInLevel; // lesson number or hours within the current level
  final double  totalInLevel;  // total hours or lessons in the current level
  final bool    isPaid;        // whether student has paid for the current course
  final bool    isBlocked;     // whether student account is explicitly blocked by teacher
  final String  studySystem;   // 'hours' | 'classes'
  final double  studyBalance;  // remaining hours/classes

  const ProfileModel({
    required this.id,
    required this.role,
    required this.fullName,
    required this.languagePreference,
    required this.createdAt,
    this.phone,
    this.messengerLink,
    this.country,
    this.avatarUrl,
    this.email,
    this.level         = 1,
    this.lessonInLevel = 0.0,
    this.totalInLevel  = 20.0,
    this.isPaid        = false,
    this.isBlocked     = false,
    this.studySystem   = 'classes',
    this.studyBalance  = 0.0,
  });

  bool get isTeacher => role == 'teacher';

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
        id:                 (map['id']                  as String?) ?? '',
        role:               (map['role']                as String?) ?? 'student',
        fullName:           (map['full_name']           as String?) ?? '',
        languagePreference: (map['language_preference'] as String?) ?? 'ar',
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        phone:         map['phone']           as String?,
        messengerLink: map['messenger_link']   as String?,
        country:       map['country']         as String?,
        avatarUrl:     map['avatar_url']      as String?,
        email:         map['email']           as String?,
        level:         (map['level']          as int?) ?? 1,
        lessonInLevel: ((map['lesson_in_level'] as num?) ?? 0.0).toDouble(),
        totalInLevel:  ((map['total_in_level']  as num?) ?? 20.0).toDouble(),
        isPaid:        (map['is_paid']        as bool?) ?? false,
        isBlocked:     (map['is_blocked']     as bool?) ?? false,
        studySystem:   (map['study_system']   as String?) ?? 'classes',
        studyBalance:  ((map['study_balance'] as num?) ?? 0.0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id':                  id,
        'role':                role,
        'full_name':           fullName,
        'language_preference': languagePreference,
        'created_at':          createdAt.toIso8601String(),
        if (phone         != null) 'phone':          phone,
        if (messengerLink != null) 'messenger_link': messengerLink,
        if (country       != null) 'country':         country,
        if (avatarUrl     != null) 'avatar_url':      avatarUrl,
        if (email         != null) 'email':           email,
        'level':           level,
        'lesson_in_level': lessonInLevel,
        'total_in_level':  totalInLevel,
        'is_paid':         isPaid,
        'is_blocked':      isBlocked,
        'study_system':    studySystem,
        'study_balance':   studyBalance,
      };
}
