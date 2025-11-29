/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final String? code;
  
  const Failure(this.message, {this.code});
  
  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;
  
  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// File operation failures
class FileFailure extends Failure {
  const FileFailure(super.message, {super.code});
}

/// API-related failures
class ApiFailure extends Failure {
  const ApiFailure(super.message, {super.code});
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Storage-related failures
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

/// Video processing failures
class VideoProcessingFailure extends Failure {
  const VideoProcessingFailure(super.message, {super.code});
}

/// PDF generation failures
class PdfGenerationFailure extends Failure {
  const PdfGenerationFailure(super.message, {super.code});
}