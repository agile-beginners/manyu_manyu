import '../../../../core/utils/result.dart';
import '../../../video/domain/entities/video_file.dart';
import '../../domain/entities/manual_step.dart';

/// Interface for video analysis service
abstract class VideoAnalysisService {
  /// Analyzes a video file and extracts manual steps
  ///
  /// Requirements: 2.1, 2.2, 2.3, 2.4
  /// - 2.1: Video is sent to Gemini API when upload completes
  /// - 2.2: Maximum 20 steps are extracted
  /// - 2.3: JSON data with title, description, timestamp is received
  /// - 2.4: Error handling and retry options are provided
  Future<Result<List<ManualStep>>> analyzeVideo(
    VideoFile videoFile, {
    String? manualInfo,
  });
}
