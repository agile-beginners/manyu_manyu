/// Base class for all exceptions in the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, {this.code});
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// File operation exceptions
class FileException extends AppException {
  const FileException(super.message, {super.code});
}

/// API-related exceptions
class ApiException extends AppException {
  const ApiException(super.message, {super.code});
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

/// Video processing exceptions
class VideoProcessingException extends AppException {
  const VideoProcessingException(super.message, {super.code});
}

/// PDF generation exceptions
class PdfGenerationException extends AppException {
  const PdfGenerationException(super.message, {super.code});
}