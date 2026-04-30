import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境設定サービス
/// .envファイルからAPIキーやその他の設定を読み込む
class EnvConfig {
  static bool _isInitialized = false;

  /// 環境設定を初期化する
  /// main()内でrunApp()より前に呼び出す必要がある
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // .envファイルを読み込む
      await dotenv.load(fileName: '.env');
      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Environment configuration loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  Warning: Could not load .env file: $e');
        print('💡 Make sure to copy .env.example to .env and fill in your API keys');
      }

      // 本番環境または.envファイルが存在しない場合でも、
      // 環境変数やdart-defineの値を使用できる
      _isInitialized = true;
    }
  }

  /// フォールバックオプション付きで設定値を取得する
  /// 1. まず.envファイルを試す
  /// 2. 次にシステム環境変数を試す
  /// 3. 次にdart-defineの値を試す
  /// 4. 最後に提供されたデフォルト値を使用する
  static String _getValue(String key, {String? defaultValue}) {
    // まず.envファイルを試す
    String? value = dotenv.env[key];

    // システム環境変数にフォールバック
    value ??= Platform.environment[key];

    // dart-define（コンパイル時定数）にフォールバック
    value ??= String.fromEnvironment(key);

    // 提供された場合はデフォルト値を使用
    value = value.isEmpty ? defaultValue : value;
    
    if (value == null || value.isEmpty) {
      throw Exception(
        'Configuration value for "$key" not found. '
        'Please set it in .env file, environment variables, or dart-define.',
      );
    }
    
    return value;
  }

  /// Gemini APIキー
  static String get geminiApiKey {
    return _getValue('GEMINI_API_KEY');
  }

  /// Gemini APIベースURL
  static String get geminiApiBaseUrl {
    return _getValue(
      'GEMINI_API_BASE_URL',
      defaultValue: 'https://generativelanguage.googleapis.com',
    );
  }

  /// Nano Banana APIキー（未指定の場合はGeminiにフォールバック）
  static String get nanoBananaApiKey {
    try {
      return _getValue('NANO_BANANA_API_KEY');
    } catch (e) {
      // Nano BananaキーがなければGemini APIキーにフォールバック
      return geminiApiKey;
    }
  }

  /// Nano Banana APIベースURL
  static String get nanoBananaApiBaseUrl {
    return _getValue(
      'NANO_BANANA_API_BASE_URL',
      defaultValue: 'https://api.nanobanana.com', // プレースホルダーURL
    );
  }

  /// 必要な設定値が全て存在することを検証する
  static void validateConfiguration() {
    if (!_isInitialized) {
      throw Exception('EnvConfig not initialized. Call EnvConfig.initialize() first.');
    }

    try {
      // 必須APIキーを検証する
      geminiApiKey;
      nanoBananaApiKey; // 未指定の場合はGeminiにフォールバック

      if (kDebugMode) {
        print('✅ All required API keys are configured');
      }
    } catch (e) {
      throw Exception('Configuration validation failed: $e');
    }
  }

  /// デバッグ用に全設定値を取得する（機密データを除く）
  static Map<String, String> getDebugInfo() {
    if (!_isInitialized) {
      return {'status': 'Not initialized'};
    }

    return {
      'gemini_api_configured': _hasValue('GEMINI_API_KEY') ? 'Yes' : 'No',
      'gemini_base_url': geminiApiBaseUrl,
      'nano_banana_api_configured': _hasValue('NANO_BANANA_API_KEY') ? 'Yes' : 'No (using Gemini fallback)',
      'nano_banana_base_url': nanoBananaApiBaseUrl,
    };
  }

  /// 例外を投げずに設定値の存在を確認する
  static bool _hasValue(String key) {
    try {
      _getValue(key);
      return true;
    } catch (e) {
      return false;
    }
  }
}