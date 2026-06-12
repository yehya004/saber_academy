/// Mirrors the `homework_files` table in Supabase.
class HomeworkFileModel {
  final String id;
  final String homeworkId;
  final String telegramFileId;
  final String fileName;
  final DateTime createdAt;

  const HomeworkFileModel({
    required this.id,
    required this.homeworkId,
    required this.telegramFileId,
    required this.fileName,
    required this.createdAt,
  });

  factory HomeworkFileModel.fromMap(Map<String, dynamic> map) => HomeworkFileModel(
        id:             map['id']              as String,
        homeworkId:     map['homework_id']     as String,
        telegramFileId: map['telegram_file_id'] as String,
        fileName:       (map['file_name']      as String?) ?? '',
        createdAt:      DateTime.parse(map['created_at'] as String),
      );
}
