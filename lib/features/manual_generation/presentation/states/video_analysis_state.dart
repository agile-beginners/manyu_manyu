import '../../domain/entities/manual.dart';
import '../../domain/value_objects/manual_generation_progress_stage.dart';

/// Represents high-level phases while running the manual generation flow.
enum VideoAnalysisPhase {
  idle,
  analyzingVideo,
  generatingImages,
  completed,
  error,
}

/// UI facing state for the video analysis progress dialog.
class VideoAnalysisState {
  final VideoAnalysisPhase phase;
  final bool isProcessing;
  final Manual? manual;
  final String? errorMessage;
  final VideoAnalysisPhase latestNonErrorPhase;

  const VideoAnalysisState({
    required this.phase,
    required this.isProcessing,
    this.manual,
    this.errorMessage,
    this.latestNonErrorPhase = VideoAnalysisPhase.idle,
  });

  const VideoAnalysisState.initial()
      : this(
          phase: VideoAnalysisPhase.idle,
          isProcessing: false,
          manual: null,
          errorMessage: null,
          latestNonErrorPhase: VideoAnalysisPhase.idle,
        );

  VideoAnalysisState copyWith({
    VideoAnalysisPhase? phase,
    bool? isProcessing,
    Manual? manual,
    bool clearManual = false,
    String? errorMessage,
    bool clearError = false,
    VideoAnalysisPhase? latestNonErrorPhase,
    bool resetLatestNonErrorPhase = false,
  }) {
    return VideoAnalysisState(
      phase: phase ?? this.phase,
      isProcessing: isProcessing ?? this.isProcessing,
      manual: clearManual ? null : (manual ?? this.manual),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      latestNonErrorPhase: resetLatestNonErrorPhase
          ? VideoAnalysisPhase.idle
          : (latestNonErrorPhase ?? this.latestNonErrorPhase),
    );
  }

  /// Convenience factory for creating a state based on progress callback events.
  factory VideoAnalysisState.fromProgress(
    ManualGenerationProgressStage stage,
  ) {
    switch (stage) {
      case ManualGenerationProgressStage.analyzingVideo:
        return const VideoAnalysisState(
          phase: VideoAnalysisPhase.analyzingVideo,
          isProcessing: true,
          latestNonErrorPhase: VideoAnalysisPhase.analyzingVideo,
        );
      case ManualGenerationProgressStage.generatingImages:
        return const VideoAnalysisState(
          phase: VideoAnalysisPhase.generatingImages,
          isProcessing: true,
          latestNonErrorPhase: VideoAnalysisPhase.generatingImages,
        );
      case ManualGenerationProgressStage.completed:
        return const VideoAnalysisState(
          phase: VideoAnalysisPhase.completed,
          isProcessing: false,
          latestNonErrorPhase: VideoAnalysisPhase.completed,
        );
    }
  }

  bool get hasError => errorMessage != null;

  bool get hasCompleted => phase == VideoAnalysisPhase.completed && manual != null;

  /// Phase to show on the progress indicator (ignores the error sentinel).
  VideoAnalysisPhase get displayPhase =>
      phase == VideoAnalysisPhase.error ? latestNonErrorPhase : phase;
}

