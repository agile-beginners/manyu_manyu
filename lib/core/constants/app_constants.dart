/// Application-wide constants
class AppConstants {
  // API Configuration
  static const String geminiApiBaseUrl = 'https://generativelanguage.googleapis.com';
  static const String nanoBananaApiBaseUrl = 'https://api.nanobanana.com';
  
  // File constraints
  static const int maxVideoSizeBytes = 100 * 1024 * 1024; // 100MB
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  static const int maxManualSteps = 20;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Network
  static const int networkTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  
  // Storage
  static const String tempVideoDirectory = 'temp_videos';
  static const String extractedImagesDirectory = 'extracted_images';
  static const String annotatedImagesDirectory = 'annotated_images';
  static const String manualsDirectory = 'manuals';
}