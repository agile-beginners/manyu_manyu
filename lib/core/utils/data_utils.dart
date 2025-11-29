import 'dart:io';
import 'package:uuid/uuid.dart';

/// Utility functions for data operations
class DataUtils {
  static const Uuid _uuid = Uuid();
  
  /// Generates a unique ID
  static String generateId() => _uuid.v4();
  
  /// Extracts file extension from a file path
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }
  
  /// Gets the file name from a file path
  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }
  
  /// Gets the file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    final fileName = getFileName(filePath);
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return fileName;
    return fileName.substring(0, lastDotIndex);
  }
  
  /// Formats file size in bytes to human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Formats duration in milliseconds to human readable format
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
  
  /// Validates if a string is a valid UUID
  static bool isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }
  
  /// Sanitizes a string to be used as a filename
  static String sanitizeFileName(String fileName) {
    // Remove or replace invalid characters
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
  
  /// Creates a safe directory path
  static Future<Directory> createSafeDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
  
  /// Checks if a file exists and is readable
  static Future<bool> isFileAccessible(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists() && await file.stat().then((_) => true);
    } catch (e) {
      return false;
    }
  }
  
  /// Gets the MIME type for a video file extension
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