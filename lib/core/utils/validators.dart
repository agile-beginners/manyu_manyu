import 'dart:io';
import '../constants/app_constants.dart';
import 'file_utils.dart';

/// バリデーション関数のユーティリティクラス
class Validators {
  /// 動画ファイルを検証する
  static ValidationResult validateVideoFile(File file) {
    // ファイルの存在確認
    if (!file.existsSync()) {
      return ValidationResult.invalid('File does not exist');
    }

    // ファイル形式の確認
    if (!FileUtils.isValidVideoFormat(file.path)) {
      return ValidationResult.invalid(
        'Unsupported video format. Supported formats: ${AppConstants.supportedVideoFormats.join(', ')}',
      );
    }

    // ファイルサイズの確認
    if (!FileUtils.isValidFileSize(file)) {
      final sizeInMB = (FileUtils.getFileSize(file) / (1024 * 1024)).toStringAsFixed(1);
      final maxSizeInMB = (AppConstants.maxVideoSizeBytes / (1024 * 1024)).toStringAsFixed(0);
      return ValidationResult.invalid(
        'File size ($sizeInMB MB) exceeds maximum allowed size ($maxSizeInMB MB)',
      );
    }

    return ValidationResult.valid();
  }

  /// マニュアルのステップ数を検証する
  static ValidationResult validateStepCount(int stepCount) {
    if (stepCount < 1) {
      return ValidationResult.invalid('Manual must have at least 1 step');
    }

    if (stepCount > AppConstants.maxManualSteps) {
      return ValidationResult.invalid(
        'Manual cannot have more than ${AppConstants.maxManualSteps} steps',
      );
    }

    return ValidationResult.valid();
  }

  /// ステップのタイトルを検証する
  static ValidationResult validateStepTitle(String title) {
    if (title.trim().isEmpty) {
      return ValidationResult.invalid('Step title cannot be empty');
    }

    if (title.length > 100) {
      return ValidationResult.invalid('Step title cannot exceed 100 characters');
    }

    return ValidationResult.valid();
  }

  /// ステップの説明を検証する
  static ValidationResult validateStepDescription(String description) {
    if (description.trim().isEmpty) {
      return ValidationResult.invalid('Step description cannot be empty');
    }

    if (description.length > 500) {
      return ValidationResult.invalid('Step description cannot exceed 500 characters');
    }

    return ValidationResult.valid();
  }

  /// タイムスタンプを検証する
  static ValidationResult validateTimestamp(int timestamp) {
    if (timestamp < 0) {
      return ValidationResult.invalid('Timestamp cannot be negative');
    }

    return ValidationResult.valid();
  }

  /// マニュアルのタイトルを検証する
  static ValidationResult validateManualTitle(String title) {
    if (title.trim().isEmpty) {
      return ValidationResult.invalid('Manual title cannot be empty');
    }

    if (title.length > 200) {
      return ValidationResult.invalid('Manual title cannot exceed 200 characters');
    }

    return ValidationResult.valid();
  }
}

/// バリデーション操作の結果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  /// 有効な結果を生成する
  const ValidationResult.valid() : this._(true, null);

  /// エラーメッセージ付きの無効な結果を生成する
  const ValidationResult.invalid(String errorMessage) : this._(false, errorMessage);
  
  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $errorMessage';
  }
}