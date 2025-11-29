import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Utility class for file operations
class FileUtils {
  /// Gets the application documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      throw StorageException('Failed to get documents directory: $e');
    }
  }
  
  /// Gets the temporary directory
  static Future<Directory> getTempDirectory() async {
    try {
      return await getTemporaryDirectory();
    } catch (e) {
      throw StorageException('Failed to get temporary directory: $e');
    }
  }
  
  /// Creates a directory if it doesn't exist
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
  
  /// Gets the file extension from a file path
  static String getFileExtension(String filePath) {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1) return '';
    return filePath.substring(lastDotIndex + 1).toLowerCase();
  }
  
  /// Validates if a file is a supported video format
  static bool isValidVideoFormat(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.supportedVideoFormats.contains(extension);
  }
  
  /// Validates if a file size is within limits
  static bool isValidFileSize(File file) {
    final sizeInBytes = file.lengthSync();
    return sizeInBytes <= AppConstants.maxVideoSizeBytes;
  }
  
  /// Gets the file size in bytes
  static int getFileSize(File file) {
    try {
      return file.lengthSync();
    } catch (e) {
      throw FileException('Failed to get file size: $e');
    }
  }
  
  /// Deletes a file if it exists
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
  
  /// Deletes a directory and all its contents
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
  
  /// Copies a file to a new location
  static Future<File> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = await sourceFile.copy(destinationPath);
      return destinationFile;
    } catch (e) {
      throw FileException('Failed to copy file: $e');
    }
  }
  
  /// Reads file as bytes
  static Future<List<int>> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsBytes();
    } catch (e) {
      throw FileException('Failed to read file: $e');
    }
  }
  
  /// Writes bytes to file
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