/// App-wide business rule constants for Saber Academy.
abstract final class AppConstants {
  /// Number of present sessions required to advance one level.
  static const int lessonsPerLevel = 20;

  /// Maximum character length for a chat message.
  static const int maxMessageLength = 2000;

  /// Maximum file size in bytes for uploads (5 MB).
  static const int maxUploadBytes = 5 * 1024 * 1024;

  /// Allowed MIME types for image uploads.
  static const List<String> allowedImageMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
}
