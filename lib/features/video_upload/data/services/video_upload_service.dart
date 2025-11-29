import 'dart:io';
import '../../../../core/utils/result.dart';
import '../../domain/entities/video_file.dart';
import '../../domain/repositories/video_repository.dart';

/// Service class for handling video upload operations
class VideoUploadService {
  final VideoRepository _repository;

  VideoUploadService(this._repository);

  /// Validates and uploads a video file
  Future<Result<VideoFile>> uploadVideo(File videoFile) async {
    // First validate the video
    final validationResult = await _repository.validateVideo(videoFile);
    if (validationResult.isFailure) {
      return Result.failure(validationResult.failure!);
    }

    // Then upload the video
    return await _repository.uploadVideo(videoFile);
  }

  /// Gets supported video formats
  List<String> getSupportedFormats() {
    return _repository.getSupportedFormats();
  }

  /// Gets maximum file size in bytes
  int getMaxFileSizeBytes() {
    return _repository.getMaxFileSizeBytes();
  }

  /// Gets maximum file size in MB for display
  int getMaxFileSizeMB() {
    return (_repository.getMaxFileSizeBytes() / (1024 * 1024)).round();
  }

  /// Validates a video file without uploading
  Future<Result<bool>> validateVideo(File videoFile) async {
    return await _repository.validateVideo(videoFile);
  }

  /// Gets all uploaded videos
  Future<Result<List<VideoFile>>> getAllVideos() async {
    return await _repository.getAllVideos();
  }

  /// Deletes a video file
  Future<Result<void>> deleteVideo(String path) async {
    return await _repository.deleteVideo(path);
  }
}