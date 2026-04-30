/// アプリケーション内の全失敗の基底クラス
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

/// ネットワーク関連の失敗
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// ファイル操作の失敗
class FileFailure extends Failure {
  const FileFailure(super.message, {super.code});
}

/// API関連の失敗
class ApiFailure extends Failure {
  const ApiFailure(super.message, {super.code});
}

/// バリデーションの失敗
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// ストレージ関連の失敗
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

/// 動画処理の失敗
class VideoProcessingFailure extends Failure {
  const VideoProcessingFailure(super.message, {super.code});
}

/// PDF生成の失敗
class PdfGenerationFailure extends Failure {
  const PdfGenerationFailure(super.message, {super.code});
}