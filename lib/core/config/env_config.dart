import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration service
/// Loads API keys and other configuration from .env file
class EnvConfig {
  static bool _isInitialized = false;

  /// Initialize the environment configuration
  /// This should be called in main() before runApp()
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load .env file
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
      
      // In production or when .env file is missing, we can still try to use
      // environment variables or dart-define values
      _isInitialized = true;
    }
  }

  /// Gets a configuration value with fallback options
  /// 1. First tries .env file
  /// 2. Then tries system environment variables
  /// 3. Then tries dart-define values
  /// 4. Finally uses default value if provided
  static String _getValue(String key, {String? defaultValue}) {
    // Try .env file first
    String? value = dotenv.env[key];
    
    // Fallback to system environment variables
    value ??= Platform.environment[key];
    
    // Fallback to dart-define (compile-time constants)
    value ??= String.fromEnvironment(key);
    
    // Use default value if provided
    value = value.isEmpty ? defaultValue : value;
    
    if (value == null || value.isEmpty) {
      throw Exception(
        'Configuration value for "$key" not found. '
        'Please set it in .env file, environment variables, or dart-define.',
      );
    }
    
    return value;
  }

  /// Gemini API Key
  static String get geminiApiKey {
    return _getValue('GEMINI_API_KEY');
  }

  /// Gemini API Base URL
  static String get geminiApiBaseUrl {
    return _getValue(
      'GEMINI_API_BASE_URL',
      defaultValue: 'https://generativelanguage.googleapis.com',
    );
  }

  /// Validates that all required configuration values are present
  static void validateConfiguration() {
    if (!_isInitialized) {
      throw Exception('EnvConfig not initialized. Call EnvConfig.initialize() first.');
    }

    try {
      // Validate required API keys
      geminiApiKey;
      
      if (kDebugMode) {
        print('✅ All required API keys are configured');
      }
    } catch (e) {
      throw Exception('Configuration validation failed: $e');
    }
  }

  /// Gets all configuration values for debugging (without sensitive data)
  static Map<String, String> getDebugInfo() {
    if (!_isInitialized) {
      return {'status': 'Not initialized'};
    }

    return {
      'gemini_api_configured': _hasValue('GEMINI_API_KEY') ? 'Yes' : 'No',
      'gemini_base_url': geminiApiBaseUrl,
    };
  }

  /// Checks if a configuration value exists without throwing an exception
  static bool _hasValue(String key) {
    try {
      _getValue(key);
      return true;
    } catch (e) {
      return false;
    }
  }
}