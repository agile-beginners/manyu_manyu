import 'env_config.dart';

/// API設定管理
/// APIの設定にアクセスするためのクリーンなインターフェースを提供するクラス
class ApiConfig {
  /// Gemini APIキーを取得する
  static String get geminiApiKey => EnvConfig.geminiApiKey;

  /// Gemini APIのベースURLを取得する
  static String get geminiApiBaseUrl => EnvConfig.geminiApiBaseUrl;

  /// Nano Banana APIキーを取得する
  static String get nanoBananaApiKey => EnvConfig.nanoBananaApiKey;

  /// Nano Banana APIのベースURLを取得する
  static String get nanoBananaApiBaseUrl => EnvConfig.nanoBananaApiBaseUrl;

  /// 必要なAPIキーが全て存在することを検証する
  static void validateApiKeys() => EnvConfig.validateConfiguration();
}