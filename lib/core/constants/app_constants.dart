/// アプリケーション全体の定数
class AppConstants {
  // Gemini API設定
  static const String geminiApiBaseUrl =
      'https://generativelanguage.googleapis.com';
  static const String geminiModel = 'gemini-3-pro-preview';
  static const String geminiImageModel = 'gemini-3-pro-image-preview';
  static const String geminiApiVersion = 'v1beta';

  // ファイル制約
  static const int maxVideoSizeBytes = 200 * 1024 * 1024; // 200MB
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  static const int maxManualSteps = 20;

  // UI定数
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // ネットワーク
  static const int networkTimeoutSeconds = 300;
  static const int maxRetryAttempts = 3;

  // ストレージ
  static const String tempVideoDirectory = 'temp_videos';
  static const String extractedImagesDirectory = 'extracted_images';
  static const String annotatedImagesDirectory = 'annotated_images';
  static const String manualsDirectory = 'manuals';
}
