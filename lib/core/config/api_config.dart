import 'env_config.dart';

/// API configuration management
/// This class provides a clean interface to access API configuration
class ApiConfig {
  /// Gets Gemini API key
  static String get geminiApiKey => EnvConfig.geminiApiKey;
  
  /// Gets Gemini API base URL
  static String get geminiApiBaseUrl => EnvConfig.geminiApiBaseUrl;
  
  /// Gets Nano Banana API key
  static String get nanoBananaApiKey => EnvConfig.nanoBananaApiKey;
  
  /// Gets Nano Banana API base URL
  static String get nanoBananaApiBaseUrl => EnvConfig.nanoBananaApiBaseUrl;
  
  /// Validates that all required API keys are present
  static void validateApiKeys() => EnvConfig.validateConfiguration();
}