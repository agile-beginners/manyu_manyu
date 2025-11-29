import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../video_upload/domain/entities/video_file.dart';
import '../../data/repositories/manual_repository_impl.dart';
import '../../data/services/gemini_image_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/image_extraction_service.dart';
import '../../data/services/video_analysis_service.dart';
import '../../domain/repositories/manual_repository.dart';
import '../../domain/services/gemini_service.dart' as domain;
import '../../domain/services/image_annotation_service.dart';

/// Provider for Gemini API key
final geminiApiKeyProvider = Provider<String>((ref) {
  return ApiConfig.geminiApiKey;
});

/// Provider for Gemini service implementation
final geminiServiceProvider = Provider<domain.GeminiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final apiKey = ref.watch(geminiApiKeyProvider);
  
  return GeminiService(
    apiClient: apiClient,
    apiKey: apiKey,
  );
});

/// Provider for manual repository
final manualRepositoryProvider = Provider<ManualRepository>((ref) {
  return ManualRepositoryImpl();
});

/// Provider for video analysis service
final videoAnalysisServiceProvider = Provider<VideoAnalysisService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  final manualRepository = ref.watch(manualRepositoryProvider);
  
  return VideoAnalysisService(
    geminiService: geminiService,
    manualRepository: manualRepository,
  );
});

/// State notifier for video analysis state
class VideoAnalysisNotifier extends StateNotifier<AsyncValue<String?>> {
  final VideoAnalysisService _videoAnalysisService;
  
  VideoAnalysisNotifier(this._videoAnalysisService) : super(const AsyncValue.data(null));

  /// Analyzes a video and returns the manual ID
  Future<String?> analyzeVideo(
    String videoPath,
    String videoName,
    int videoSize,
    String videoFormat, {
    int? durationMs,
    String? customTitle,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final videoFile = VideoFile(
        path: videoPath,
        name: videoName,
        sizeInBytes: videoSize,
        format: videoFormat,
        durationMs: durationMs,
        createdAt: DateTime.now(),
      );

      final result = await _videoAnalysisService.analyzeVideoAndCreateManual(
        videoFile,
        customTitle: customTitle,
      );

      if (result.isSuccess) {
        state = AsyncValue.data(result.data!.id);
        return result.data!.id;
      } else {
        state = AsyncValue.error(result.failure!.message, StackTrace.current);
        return null;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Retries analysis for a failed manual
  Future<String?> retryAnalysis(String manualId) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _videoAnalysisService.retryAnalysis(manualId);

      if (result.isSuccess) {
        state = AsyncValue.data(result.data!.id);
        return result.data!.id;
      } else {
        state = AsyncValue.error(result.failure!.message, StackTrace.current);
        return null;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Resets the state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for image annotation service (using Gemini)
final imageAnnotationServiceProvider = Provider<ImageAnnotationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final apiKey = ref.watch(geminiApiKeyProvider);
  
  return GeminiImageService(
    apiClient: apiClient,
    apiKey: apiKey,
  );
});

/// Provider for image extraction service
final imageExtractionServiceProvider = Provider<ImageExtractionService>((ref) {
  return ImageExtractionService();
});

/// Provider for video analysis state notifier
final videoAnalysisNotifierProvider = StateNotifierProvider<VideoAnalysisNotifier, AsyncValue<String?>>((ref) {
  final videoAnalysisService = ref.watch(videoAnalysisServiceProvider);
  return VideoAnalysisNotifier(videoAnalysisService);
});