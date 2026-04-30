/// アプリケーション内の全例外の基底クラス
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// ファイル操作の例外
class FileException extends AppException {
  const FileException(super.message, {super.code});
}

/// API関連の例外
class ApiException extends AppException {
  const ApiException(super.message, {super.code});
}

/// バリデーションの例外
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// ストレージ関連の例外
class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

/// 動画処理の例外
class VideoProcessingException extends AppException {
  const VideoProcessingException(super.message, {super.code});
}

/// PDF生成の例外
class PdfGenerationException extends AppException {
  const PdfGenerationException(super.message, {super.code});
}