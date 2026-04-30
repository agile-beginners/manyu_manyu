import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/result.dart';
import '../../video/domain/entities/video_file.dart';
import '../data/repositories/manual_repository.dart';
import '../data/repositories/manual_repository_impl.dart';
import '../data/services/gemini_image_service.dart';
import '../data/services/gemini_video_analysis_service.dart';
import '../data/services/image_annotation_service.dart';
import '../data/services/image_extraction_service.dart';
import '../data/services/nano_banana_service.dart';
import '../data/services/video_analysis_service.dart';
import '../domain/entities/manual.dart';
import '../domain/entities/manual_step.dart';
import '../domain/value_objects/manual_generation_progress_stage.dart';
import 'manual_edit_service.dart'; // for allManualsProvider, manualProvider, manualRepositoryProvider

/// Service that orchestrates the complete video analysis process
class ManualCreationService {
  final VideoAnalysisService _videoAnalysisService;
  final ManualRepository _manualRepository;
  final ImageExtractionService _imageExtractionService;
  final ImageAnnotationService _imageAnnotationService;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  ManualCreationService({
    required VideoAnalysisService videoAnalysisService,
    required ManualRepository manualRepository,
    required ImageExtractionService imageExtractionService,
    required ImageAnnotationService imageAnnotationService,
    required Ref ref,
  })  : _videoAnalysisService = videoAnalysisService,
        _manualRepository = manualRepository,
        _imageExtractionService = imageExtractionService,
        _imageAnnotationService = imageAnnotationService,
        _ref = ref;

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
    String? manualInfo,
    void Function(ManualGenerationProgressStage stage)? onProgress,
  }) async {
    try {
      final sanitizedManualInfo = manualInfo?.trim();

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
        description:
            (sanitizedManualInfo == null || sanitizedManualInfo.isEmpty)
                ? null
                : sanitizedManualInfo,
      );

      // Save initial manual
      final saveResult = await _manualRepository.saveManual(manual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      try {
        // Step 1: Analyze video with Gemini API (Requirements 2.1, 2.2, 2.3)
        onProgress?.call(ManualGenerationProgressStage.analyzingVideo);

        final analysisResult = await _videoAnalysisService.analyzeVideo(
          videoFile,
          manualInfo: sanitizedManualInfo,
        );
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

        // Step 2: Extract images from video at timestamps (Requirements 3.1, 3.2)
        onProgress?.call(ManualGenerationProgressStage.generatingImages);

        final imageExtractionResult =
            await _imageExtractionService.extractImagesFromVideo(
          videoPath: videoFile.path,
          steps: steps,
        );

        List<String> extractedImagePaths = [];
        if (imageExtractionResult.isSuccess) {
          extractedImagePaths = imageExtractionResult.data!;
        } else {
          // Continue with empty image paths if extraction fails (Requirement 3.4)
          print(
              'Image extraction failed: ${imageExtractionResult.failure!.message}');
        }

        // Step 3: Update steps with extracted image paths and annotate images
        final imagePathsForSteps = List<String?>.generate(
          steps.length,
          (index) => index < extractedImagePaths.length
              ? extractedImagePaths[index]
              : null,
        );

        // Step 4: Annotate images in parallel (Requirements 4.1, 4.2, 4.3)
        final annotationFutures = <Future<String?>>[];
        for (int i = 0; i < steps.length; i++) {
          final step = steps[i];
          final imagePath = imagePathsForSteps[i];

          if (imagePath == null) {
            annotationFutures.add(Future.value(null));
            continue;
          }

          annotationFutures.add(() async {
            try {
              final annotationResult =
                  await _imageAnnotationService.generateAnnotatedImage(
                originalImagePath: imagePath,
                stepTitle: step.title,
                stepDescription: step.description,
                stepNumber: step.stepNumber,
              );

              if (annotationResult.isSuccess &&
                  annotationResult.data != null) {
                return annotationResult.data!;
              }

              final failureMessage =
                  annotationResult.failure?.message ?? 'Unknown error';
              print(
                'Image annotation failed for step ${step.stepNumber}: $failureMessage',
              );
              // Fallback: use original image if annotation fails (Requirement 4.4)
              return imagePath;
            } catch (e) {
              // Fallback: use original image on any error (Requirement 4.4)
              print('Image annotation error for step ${step.stepNumber}: $e');
              return imagePath;
            }
          }());
        }

        final annotatedImagePaths = await Future.wait(annotationFutures);

        final processedSteps = <ManualStep>[];
        for (int i = 0; i < steps.length; i++) {
          final step = steps[i];

          // Create updated step with image paths
          final processedStep = step.copyWith(
            imagePath: imagePathsForSteps[i],
            annotatedImagePath: annotatedImagePaths[i],
            isProcessed: true,
          );

          processedSteps.add(processedStep);
        }

        // Update manual with processed steps
        final completedManual = manual.copyWith(
          steps: processedSteps,
          status: ManualStatus.draft,
          updatedAt: DateTime.now(),
        );

        // Save completed manual
        final updateResult =
            await _manualRepository.updateManual(completedManual);
        if (updateResult.isFailure) {
          return Result.failure(updateResult.failure!);
        }

        // Invalidate providers so UI sees the new manual
        _ref.invalidate(allManualsProvider);
        _ref.invalidate(manualProvider(completedManual.id));

        onProgress?.call(ManualGenerationProgressStage.completed);

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
  Future<Result<Manual>> retryAnalysis(
    String manualId, {
    void Function(ManualGenerationProgressStage stage)? onProgress,
  }) async {
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
      return analyzeVideoAndCreateManual(
        videoFile,
        customTitle: manual.title,
        manualInfo: manual.description,
        onProgress: onProgress,
      );
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

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final _geminiVideoAnalysisServiceProvider =
    Provider<VideoAnalysisService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeminiVideoAnalysisService(
    apiClient: apiClient,
    apiKey: EnvConfig.geminiApiKey,
  );
});

final _imageExtractionServiceProvider =
    Provider<ImageExtractionService>((ref) {
  return ImageExtractionService();
});

final _geminiImageServiceProvider = Provider<GeminiImageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeminiImageService(
    apiClient: apiClient,
    apiKey: EnvConfig.geminiApiKey,
  );
});

final _nanoBananaServiceProvider = Provider<NanoBananaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NanoBananaService(
    apiClient: apiClient,
    apiKey: EnvConfig.nanoBananaApiKey,
    baseUrl: EnvConfig.nanoBananaApiBaseUrl,
    fallbackService: ref.watch(_geminiImageServiceProvider),
  );
});

final _imageAnnotationServiceProvider = Provider<ImageAnnotationService>((ref) {
  return ref.watch(_nanoBananaServiceProvider);
});

/// Provider for ManualCreationService
final manualCreationServiceProvider = Provider<ManualCreationService>((ref) {
  return ManualCreationService(
    videoAnalysisService: ref.watch(_geminiVideoAnalysisServiceProvider),
    manualRepository: ref.watch(manualRepositoryProvider),
    imageExtractionService: ref.watch(_imageExtractionServiceProvider),
    imageAnnotationService: ref.watch(_imageAnnotationServiceProvider),
    ref: ref,
  );
});
