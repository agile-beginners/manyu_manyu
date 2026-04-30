/// データストレージとファイル操作に関連する定数
class StorageConstants {
  // ローカルストレージのファイル名
  static const String videoMetadataFileName = 'video_metadata.json';
  static const String manualsFileName = 'manuals.json';
  static const String appSettingsFileName = 'app_settings.json';

  // ディレクトリ名
  static const String videosDirectoryName = 'videos';
  static const String imagesDirectoryName = 'images';
  static const String manualsDirectoryName = 'manuals';
  static const String tempDirectoryName = 'temp';
  static const String exportsDirectoryName = 'exports';

  // ファイルサイズ制限
  static const int maxVideoFileSizeBytes = 500 * 1024 * 1024; // 500MB
  static const int maxImageFileSizeBytes = 10 * 1024 * 1024; // 10MB

  // サポートされる形式
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];

  // マニュアルの制約
  static const int maxManualSteps = 20;
  static const int minManualSteps = 1;
  static const int maxStepTitleLength = 100;
  static const int maxStepDescriptionLength = 1000;
  static const int maxManualTitleLength = 200;
  static const int maxManualDescriptionLength = 2000;

  // キャッシュ設定
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // バックアップ設定
  static const int maxBackupFiles = 5;
  static const Duration backupInterval = Duration(hours: 6);
}