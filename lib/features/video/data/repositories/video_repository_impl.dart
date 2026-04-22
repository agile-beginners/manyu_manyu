import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import 'video_repository.dart';
import '../../domain/entities/video_file.dart';

/// Concrete implementation of VideoRepository using local storage
class VideoRepositoryImpl implements VideoRepository {
  static const String _videoMetadataFileName = 'video_metadata.json';
  static const List<String> _supportedFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const int _maxFileSizeBytes = 500 * 1024 * 1024; // 500MB
  
  final Uuid _uuid = const Uuid();

  @override
  Future<Result<VideoFile>> uploadVideo(File videoFile) async {
    try {
      // Validate the video first
      final validationResult = await validateVideo(videoFile);
      if (validationResult.isFailure) {
        return Result.failure(validationResult.failure!);
      }

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/videos');
      
      // Create videos directory if it doesn't exist
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      // Generate unique filename
      final originalName = videoFile.path.split('/').last;
      final extension = originalName.split('.').last.toLowerCase();
      final uniqueId = _uuid.v4();
      final newFileName = '$uniqueId.$extension';
      final newPath = '${videosDir.path}/$newFileName';

      // Copy the file to app directory
      final copiedFile = await videoFile.copy(newPath);
      
      // Get file stats
      final fileStat = await copiedFile.stat();
      
      // Create VideoFile metadata
      final videoFileMetadata = VideoFile(
        path: newPath,
        name: originalName,
        sizeInBytes: fileStat.size,
        format: extension,
        createdAt: DateTime.now(),
      );

      // Save metadata
      final saveResult = await saveVideoMetadata(videoFileMetadata);
      if (saveResult.isFailure) {
        // Clean up the copied file if metadata save fails
        try {
          await copiedFile.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
        return Result.failure(saveResult.failure!);
      }

      return Result.success(videoFileMetadata);
    } on FileException catch (e) {
      return Result.failure(FileFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(FileFailure('Failed to upload video: $e'));
    }
  }

  @override
  Future<Result<bool>> validateVideo(File videoFile) async {
    try {
      // Check if file exists
      if (!await videoFile.exists()) {
        return Result.failure(
          const ValidationFailure('Video file does not exist'),
        );
      }

      // Check file size
      final fileStat = await videoFile.stat();
      if (fileStat.size > _maxFileSizeBytes) {
        return Result.failure(
          ValidationFailure(
            'Video file is too large. Maximum size is ${_maxFileSizeBytes ~/ (1024 * 1024)}MB',
          ),
        );
      }

      // Check file format
      final fileName = videoFile.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      
      if (!_supportedFormats.contains(extension)) {
        return Result.failure(
          ValidationFailure(
            'Unsupported video format: $extension. Supported formats: ${_supportedFormats.join(', ')}',
          ),
        );
      }

      return const Result.success(true);
    } catch (e) {
      return Result.failure(ValidationFailure('Failed to validate video: $e'));
    }
  }

  @override
  Future<Result<void>> saveVideoMetadata(VideoFile videoFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      List<VideoFile> existingVideos = [];
      
      // Load existing metadata if file exists
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        existingVideos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
      }
      
      // Add or update the video metadata
      final existingIndex = existingVideos.indexWhere((v) => v.path == videoFile.path);
      if (existingIndex != -1) {
        existingVideos[existingIndex] = videoFile;
      } else {
        existingVideos.add(videoFile);
      }
      
      // Save updated metadata
      final jsonList = existingVideos.map((v) => v.toJson()).toList();
      await metadataFile.writeAsString(jsonEncode(jsonList));
      
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to save video metadata: $e'));
    }
  }

  @override
  Future<Result<VideoFile?>> getVideoMetadata(String path) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      if (!await metadataFile.exists()) {
        return const Result.success(null);
      }
      
      final content = await metadataFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final videos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
      
      final video = videos.where((v) => v.path == path).firstOrNull;
      return Result.success(video);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get video metadata: $e'));
    }
  }

  @override
  Future<Result<void>> deleteVideo(String path) async {
    try {
      // Delete the video file
      final videoFile = File(path);
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
      
      // Remove from metadata
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final videos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
        
        final updatedVideos = videos.where((v) => v.path != path).toList();
        final updatedJsonList = updatedVideos.map((v) => v.toJson()).toList();
        
        await metadataFile.writeAsString(jsonEncode(updatedJsonList));
      }
      
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to delete video: $e'));
    }
  }

  @override
  Future<Result<List<VideoFile>>> getAllVideos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      if (!await metadataFile.exists()) {
        return const Result.success([]);
      }
      
      final content = await metadataFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final videos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
      
      // Sort by creation date (newest first)
      videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Result.success(videos);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get all videos: $e'));
    }
  }

  @override
  List<String> getSupportedFormats() {
    return List.unmodifiable(_supportedFormats);
  }

  @override
  int getMaxFileSizeBytes() {
    return _maxFileSizeBytes;
  }
}
