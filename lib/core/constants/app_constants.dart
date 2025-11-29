/// Application-wide constants
class AppConstants {
  // Gemini API configuration
  static const String geminiApiBaseUrl =
      'https://generativelanguage.googleapis.com';
  static const String geminiModel = 'gemini-3-pro-preview';
  static const String geminiImageModel = 'gemini-3-pro-image-preview';
  static const String geminiApiVersion = 'v1beta';

  // File constraints
  static const int maxVideoSizeBytes = 200 * 1024 * 1024; // 200MB
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  static const int maxManualSteps = 20;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Network
  static const int networkTimeoutSeconds = 300;
  static const int maxRetryAttempts = 3;

  // Storage
  static const String tempVideoDirectory = 'temp_videos';
  static const String extractedImagesDirectory = 'extracted_images';
  static const String annotatedImagesDirectory = 'annotated_images';
  static const String manualsDirectory = 'manuals';
}
