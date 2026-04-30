import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../video/domain/entities/video_file.dart';
import '../../../application/manual_creation_service.dart';
import '../../../domain/value_objects/manual_generation_progress_stage.dart';
import '../states/video_analysis_state.dart';

/// Controller for video analysis — delegates to [ManualCreationService].
class VideoAnalysisController extends StateNotifier<VideoAnalysisState> {
  final ManualCreationService _creationService;

  VideoAnalysisController(this._creationService)
      : super(const VideoAnalysisState.initial());

  /// Starts video analysis and manual creation.
  Future<void> analyzeVideo(
    VideoFile videoFile, {
    String? customTitle,
    String? manualInfo,
  }) async {
    state = const VideoAnalysisState(
      phase: VideoAnalysisPhase.analyzingVideo,
      isProcessing: true,
      latestNonErrorPhase: VideoAnalysisPhase.analyzingVideo,
    );

    try {
      final result = await _creationService.analyzeVideoAndCreateManual(
        videoFile,
        customTitle: customTitle,
        manualInfo: manualInfo,
        onProgress: (progressStage) {
          final progressState = VideoAnalysisState.fromProgress(progressStage);
          state = state.copyWith(
            phase: progressState.phase,
            isProcessing: progressState.isProcessing,
            clearManual:
                progressStage == ManualGenerationProgressStage.analyzingVideo,
            clearError: true,
            latestNonErrorPhase: progressState.latestNonErrorPhase,
          );
        },
      );

      if (result.isSuccess) {
        state = state.copyWith(
          phase: VideoAnalysisPhase.completed,
          isProcessing: false,
          manual: result.data,
          clearError: true,
          latestNonErrorPhase: VideoAnalysisPhase.completed,
        );
      } else {
        state = state.copyWith(
          phase: VideoAnalysisPhase.error,
          isProcessing: false,
          errorMessage: result.failure!.message,
          clearManual: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        phase: VideoAnalysisPhase.error,
        isProcessing: false,
        errorMessage: e.toString(),
        clearManual: true,
      );
    }
  }

  /// Resets the analysis state.
  void reset() {
    state = const VideoAnalysisState.initial();
  }
}

/// Provider for [VideoAnalysisController].
final videoAnalysisControllerProvider =
    StateNotifierProvider<VideoAnalysisController, VideoAnalysisState>((ref) {
  return VideoAnalysisController(ref.watch(manualCreationServiceProvider));
});

/// Convenience provider: true while analysis is running.
final isAnalysisInProgressProvider = Provider<bool>((ref) {
  return ref.watch(videoAnalysisControllerProvider).isProcessing;
});
