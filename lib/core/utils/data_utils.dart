import 'dart:io';
import 'package:uuid/uuid.dart';

/// データ操作のユーティリティ関数
class DataUtils {
  static const Uuid _uuid = Uuid();

  /// 一意のIDを生成する
  static String generateId() => _uuid.v4();

  /// ファイルパスから拡張子を取得する
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  /// ファイルパスからファイル名を取得する
  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  /// 拡張子なしのファイル名を取得する
  static String getFileNameWithoutExtension(String filePath) {
    final fileName = getFileName(filePath);
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return fileName;
    return fileName.substring(0, lastDotIndex);
  }

  /// バイト単位のファイルサイズを人間が読みやすい形式に変換する
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// ミリ秒単位の時間を人間が読みやすい形式に変換する
  static String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// 文字列が有効なUUIDかどうかを検証する
  static bool isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }

  /// 文字列をファイル名として使えるようサニタイズする
  static String sanitizeFileName(String fileName) {
    // 無効な文字を削除または置換する
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// 安全なディレクトリパスを作成する
  static Future<Directory> createSafeDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// ファイルが存在して読み取り可能かどうかを確認する
  static Future<bool> isFileAccessible(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists() && await file.stat().then((_) => true);
    } catch (e) {
      return false;
    }
  }

  /// 動画ファイル拡張子のMIMEタイプを取得する
  static String getVideoMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'video/*';
    }
  }
}