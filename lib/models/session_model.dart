/// Mirrors the `sessions` table in Supabase.
class SessionModel {
  final String id;
  final String studentId;
  final String teacherId;
  final DateTime sessionDate;
  final String status; // 'present' | 'absent'
  final String? absenceExcuse;
  final String? topic;       // what was covered this session
  final String? homework;    // homework assigned
  final String? resourceUrl; // link to book / resource
  final DateTime createdAt;
  final double deductedAmount; // amount deducted from student balance (hours or classes)

  const SessionModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.sessionDate,
    required this.status,
    this.absenceExcuse,
    this.topic,
    this.homework,
    this.resourceUrl,
    required this.createdAt,
    this.deductedAmount = 1.0,
  });

  bool get isPresent => status == 'present' || status == 'late';

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
        id:            map['id']             as String,
        studentId:     map['student_id']     as String,
        teacherId:     map['teacher_id']     as String,
        sessionDate:   DateTime.parse(map['session_date'] as String),
        status:        map['status']         as String,
        absenceExcuse: map['absence_excuse'] as String?,
        topic:         map['topic']          as String?,
        homework:      map['homework']       as String?,
        resourceUrl:   map['resource_url']   as String?,
        createdAt:     DateTime.parse(map['created_at']   as String),
        deductedAmount: ((map['deducted_amount'] as num?) ?? 1.0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id':             id,
        'student_id':     studentId,
        'teacher_id':     teacherId,
        'session_date':   sessionDate.toIso8601String().split('T').first,
        'status':         status,
        if (absenceExcuse != null) 'absence_excuse': absenceExcuse,
        if (topic         != null) 'topic':          topic,
        if (homework      != null) 'homework':       homework,
        if (resourceUrl   != null) 'resource_url':   resourceUrl,
        'created_at':     createdAt.toIso8601String(),
        'deducted_amount': deductedAmount,
      };
}
