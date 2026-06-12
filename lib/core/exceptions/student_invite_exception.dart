/// Typed exception thrown by [StudentInviteService].
class StudentInviteException implements Exception {
  final String message;
  const StudentInviteException(this.message);

  @override
  String toString() => message;
}
