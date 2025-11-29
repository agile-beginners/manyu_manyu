import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../video_upload/domain/entities/video_file.dart';
import '../../domain/entities/manual.dart';
import '../../domain/entities/manual_step.dart';
import '../../domain/repositories/manual_repository.dart';
import '../../domain/services/gemini_service.dart';

/// Service that orchestrates the complete video analysis process
class VideoAnalysisService {
  final GeminiService _geminiService;
  final ManualRepository _manualRepository;
  final Uuid _uuid = const Uuid();

  VideoAnalysisService({
    required GeminiService geminiService,
    required ManualRepository manualRepository,
  }) : _geminiService = geminiService, _manualRepository = manualRepository;

  /// Analyzes a video and creates a complete manual
  /// 
  /// This method handles the complete workflow:
  /// 1. Calls Gemini API to analyze video
  /// 2. Creates a Manual entity with the extracted steps
  /// 3. Saves the manual to repository
  /// 
  /// Requirements: 2.1, 2.2, 2.3, 2.4
  Future<Result<Manual>> analyzeVideoAndCreateManual(
    VideoFile videoFile, {
    String? customTitle,
  }) async {
    try {
      // Create initial manual with generating status
      final manual = Manual(
        id: _uuid.v4(),
        title: customTitle ?? 'Manual from ${videoFile.name}',
        steps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoPath: videoFile.path,
        videoDurationMs: videoFile.durationMs,
        status: ManualStatus.generating,
      );

      // Save initial manual
      final saveResult = await _manualRepository.saveManual(manual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      try {
        // Analyze video with Gemini API
        final analysisResult = await _geminiService.analyzeVideo(videoFile);
        if (analysisResult.isFailure) {
          // Update manual status to failed
          final failedManual = manual.copyWith(
            status: ManualStatus.failed,
            updatedAt: DateTime.now(),
          );
          await _manualRepository.updateManual(failedManual);
          
          return Result.failure(analysisResult.failure!);
        }

        final steps = analysisResult.data!;

        // Update manual with extracted steps
        final completedManual = manual.copyWith(
          steps: steps,
          status: ManualStatus.draft,
          updatedAt: DateTime.now(),
        );

        // Save completed manual
        final updateResult = await _manualRepository.updateManual(completedManual);
        if (updateResult.isFailure) {
          return Result.failure(updateResult.failure!);
        }

        return Result.success(completedManual);
      } catch (e) {
        // Update manual status to failed on any error
        final failedManual = manual.copyWith(
          status: ManualStatus.failed,
          updatedAt: DateTime.now(),
        );
        await _manualRepository.updateManual(failedManual);
        
        return Result.failure(
          ApiFailure('Video analysis failed: $e'),
        );
      }
    } catch (e) {
      return Result.failure(
        ApiFailure('Failed to create manual: $e'),
      );
    }
  }

  /// Retries analysis for a failed manual
  /// 
  /// Requirements: 2.4 - Retry option for failed API calls
  Future<Result<Manual>> retryAnalysis(String manualId) async {
    try {
      // Get existing manual
      final manualResult = await _manualRepository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }

      final manual = manualResult.data;
      if (manual == null) {
        return Result.failure(
          const ValidationFailure('Manual not found'),
        );
      }

      if (manual.videoPath == null) {
        return Result.failure(
          const ValidationFailure('No video path found for manual'),
        );
      }

      // Create VideoFile from manual data
      final videoFile = VideoFile(
        path: manual.videoPath!,
        name: manual.title,
        sizeInBytes: 0, // We don't have this info, but it's not critical for retry
        format: _extractFormatFromPath(manual.videoPath!),
        durationMs: manual.videoDurationMs,
        createdAt: manual.createdAt,
      );

      // Update status to generating
      final generatingManual = manual.copyWith(
        status: ManualStatus.generating,
        updatedAt: DateTime.now(),
      );
      await _manualRepository.updateManual(generatingManual);

      // Retry analysis
      return analyzeVideoAndCreateManual(videoFile, customTitle: manual.title);
    } catch (e) {
      return Result.failure(
        ApiFailure('Failed to retry analysis: $e'),
      );
    }
  }

  /// Extracts file format from file path
  String _extractFormatFromPath(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'mp4'; // Default fallback
  }
}