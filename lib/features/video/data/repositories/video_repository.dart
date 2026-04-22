import 'dart:io';
import '../../../../core/utils/result.dart';
import '../../domain/entities/video_file.dart';

/// Repository interface for video file operations
abstract class VideoRepository {
  /// Uploads a video file and returns the VideoFile metadata
  Future<Result<VideoFile>> uploadVideo(File videoFile);
  
  /// Validates a video file format and size
  Future<Result<bool>> validateVideo(File videoFile);
  
  /// Saves video file metadata to local storage
  Future<Result<void>> saveVideoMetadata(VideoFile videoFile);
  
  /// Retrieves video file metadata by path
  Future<Result<VideoFile?>> getVideoMetadata(String path);
  
  /// Deletes a video file and its metadata
  Future<Result<void>> deleteVideo(String path);
  
  /// Lists all uploaded video files
  Future<Result<List<VideoFile>>> getAllVideos();
  
  /// Gets the supported video formats
  List<String> getSupportedFormats();
  
  /// Gets the maximum allowed file size in bytes
  int getMaxFileSizeBytes();
}
