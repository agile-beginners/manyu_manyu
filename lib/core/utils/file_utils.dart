import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// ファイル操作のユーティリティクラス
class FileUtils {
  /// アプリケーションのドキュメントディレクトリを取得する
  static Future<Directory> getAppDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      throw StorageException('Failed to get documents directory: $e');
    }
  }

  /// 一時ディレクトリを取得する
  static Future<Directory> getTempDirectory() async {
    try {
      return await getTemporaryDirectory();
    } catch (e) {
      throw StorageException('Failed to get temporary directory: $e');
    }
  }

  /// 存在しない場合はディレクトリを作成する
  static Future<Directory> createDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (e) {
      throw StorageException('Failed to create directory: $e');
    }
  }

  /// ファイルパスから拡張子を取得する
  static String getFileExtension(String filePath) {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1) return '';
    return filePath.substring(lastDotIndex + 1).toLowerCase();
  }

  /// ファイルがサポートされる動画形式かどうかを検証する
  static bool isValidVideoFormat(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.supportedVideoFormats.contains(extension);
  }

  /// ファイルサイズが制限内かどうかを検証する
  static bool isValidFileSize(File file) {
    final sizeInBytes = file.lengthSync();
    return sizeInBytes <= AppConstants.maxVideoSizeBytes;
  }

  /// ファイルサイズをバイト単位で取得する
  static int getFileSize(File file) {
    try {
      return file.lengthSync();
    } catch (e) {
      throw FileException('Failed to get file size: $e');
    }
  }

  /// 存在する場合はファイルを削除する
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileException('Failed to delete file: $e');
    }
  }

  /// ディレクトリとその全内容を削除する
  static Future<void> deleteDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      throw StorageException('Failed to delete directory: $e');
    }
  }

  /// ファイルを新しい場所にコピーする
  static Future<File> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = await sourceFile.copy(destinationPath);
      return destinationFile;
    } catch (e) {
      throw FileException('Failed to copy file: $e');
    }
  }

  /// ファイルをバイト列として読み込む
  static Future<List<int>> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsBytes();
    } catch (e) {
      throw FileException('Failed to read file: $e');
    }
  }

  /// バイト列をファイルに書き込む
  static Future<File> writeBytesToFile(String filePath, List<int> bytes) async {
    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw FileException('Failed to write file: $e');
    }
  }
}