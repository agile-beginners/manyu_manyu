import 'env_config.dart';

/// API configuration management
/// This class provides a clean interface to access API configuration
class ApiConfig {
  /// Gets Gemini API key
  static String get geminiApiKey => EnvConfig.geminiApiKey;
  
  /// Gets Gemini API base URL
  static String get geminiApiBaseUrl => EnvConfig.geminiApiBaseUrl;
  
  /// Validates that all required API keys are present
  static void validateApiKeys() => EnvConfig.validateConfiguration();
}