/// Constants related to data storage and file operations
class StorageConstants {
  // File names for local storage
  static const String videoMetadataFileName = 'video_metadata.json';
  static const String manualsFileName = 'manuals.json';
  static const String appSettingsFileName = 'app_settings.json';
  
  // Directory names
  static const String videosDirectoryName = 'videos';
  static const String imagesDirectoryName = 'images';
  static const String manualsDirectoryName = 'manuals';
  static const String tempDirectoryName = 'temp';
  static const String exportsDirectoryName = 'exports';
  
  // File size limits
  static const int maxVideoFileSizeBytes = 500 * 1024 * 1024; // 500MB
  static const int maxImageFileSizeBytes = 10 * 1024 * 1024; // 10MB
  
  // Supported formats
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Manual constraints
  static const int maxManualSteps = 20;
  static const int minManualSteps = 1;
  static const int maxStepTitleLength = 100;
  static const int maxStepDescriptionLength = 1000;
  static const int maxManualTitleLength = 200;
  static const int maxManualDescriptionLength = 2000;
  
  // Cache settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Backup settings
  static const int maxBackupFiles = 5;
  static const Duration backupInterval = Duration(hours: 6);
}