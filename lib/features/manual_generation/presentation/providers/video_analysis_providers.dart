import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../video_upload/domain/entities/video_file.dart';
import '../../data/repositories/manual_repository_impl.dart';
import '../../data/services/gemini_image_service.dart';
import '../../data/services/gemini_service.dart' as data_gemini;
import '../../domain/services/gemini_service.dart';
import '../../data/services/image_extraction_service.dart';
import '../../data/services/nano_banana_service.dart';
import '../../data/services/video_analysis_service.dart';
import '../../domain/entities/manual.dart';
import '../../domain/repositories/manual_repository.dart';

import '../../domain/services/image_annotation_service.dart';

/// Provider for ManualRepository
final manualRepositoryProvider = Provider<ManualRepository>((ref) {
  return ManualRepositoryImpl();
});

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final apiKey = EnvConfig.geminiApiKey;
    print('🔑 Creating GeminiService with API key: ${apiKey.isNotEmpty ? "✅ Configured (${apiKey.length} chars)" : "❌ Empty"}');
    
    return data_gemini.GeminiService(
      apiClient: apiClient,
      apiKey: apiKey,
    );
  } catch (e) {
    print('💥 Error creating GeminiService: $e');
    rethrow;
  }
});

/// Provider for ImageExtractionService
final imageExtractionServiceProvider = Provider<ImageExtractionService>((ref) {
  return ImageExtractionService();
});

/// Provider for GeminiImageService (fallback)
final geminiImageServiceProvider = Provider<GeminiImageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeminiImageService(
    apiClient: apiClient,
    apiKey: EnvConfig.geminiApiKey,
  );
});

/// Provider for ImageAnnotationService (Nano Banana)
final imageAnnotationServiceProvider = Provider<ImageAnnotationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final fallbackService = ref.watch(geminiImageServiceProvider);
  return NanoBananaService(
    apiClient: apiClient,
    apiKey: EnvConfig.nanoBananaApiKey,
    baseUrl: EnvConfig.nanoBananaApiBaseUrl,
    fallbackService: fallbackService,
  );
});

/// Provider for VideoAnalysisService
final videoAnalysisServiceProvider = Provider<VideoAnalysisService>((ref) {
  return VideoAnalysisService(
    geminiService: ref.read(geminiServiceProvider),
    manualRepository: ref.read(manualRepositoryProvider),
    imageExtractionService: ref.read(imageExtractionServiceProvider),
    imageAnnotationService: ref.read(imageAnnotationServiceProvider),
  );
});

/// State notifier for video analysis
class VideoAnalysisNotifier extends StateNotifier<AsyncValue<Manual?>> {
  final VideoAnalysisService _videoAnalysisService;
  
  VideoAnalysisNotifier(this._videoAnalysisService) : super(const AsyncValue.data(null));
  
  /// Starts video analysis
  Future<void> analyzeVideo(VideoFile videoFile, {String? customTitle}) async {
    state = const AsyncValue.loading();
    
    try {
      print('🚀 Starting video analysis for: ${videoFile.name}');
      
      // Pre-flight network check (temporarily disabled for testing)
      print('🔍 Running pre-flight network check...');
      final networkDiagnostics = await NetworkInfo.runNetworkDiagnostics();
      
      // Temporarily skip network checks to test if the issue is with the pre-flight check
      print('⚠️ Skipping network pre-flight checks for testing...');
      
      // if (!networkDiagnostics['hasInternet']) {
      //   print('❌ No internet connection detected');
      //   state = AsyncValue.error('インターネット接続がありません。ネットワーク接続を確認してください。', StackTrace.current);
      //   return;
      // }
      
      // if (!networkDiagnostics['canReachGeminiApi']) {
      //   print('❌ Cannot reach Gemini API');
      //   state = AsyncValue.error('Gemini APIに接続できません。ネットワーク設定を確認してください。', StackTrace.current);
      //   return;
      // }
      
      print('✅ Network pre-flight check bypassed for testing');
      
      final result = await _videoAnalysisService.analyzeVideoAndCreateManual(
        videoFile,
        customTitle: customTitle,
      );
      
      if (result.isSuccess) {
        print('🎉 Video analysis completed successfully');
        state = AsyncValue.data(result.data);
      } else {
        print('❌ Video analysis failed: ${result.failure!.message}');
        state = AsyncValue.error(result.failure!.message, StackTrace.current);
      }
    } catch (e, stackTrace) {
      print('💥 Video analysis exception: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Resets the analysis state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for VideoAnalysisNotifier
final videoAnalysisNotifierProvider = StateNotifierProvider<VideoAnalysisNotifier, AsyncValue<Manual?>>((ref) {
  final videoAnalysisService = ref.watch(videoAnalysisServiceProvider);
  return VideoAnalysisNotifier(videoAnalysisService);
});

/// Provider for checking if analysis is in progress
final isAnalysisInProgressProvider = Provider<bool>((ref) {
  final analysisState = ref.watch(videoAnalysisNotifierProvider);
  return analysisState.isLoading;
});