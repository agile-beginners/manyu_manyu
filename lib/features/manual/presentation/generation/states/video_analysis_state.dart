import '../../../domain/entities/manual.dart';
import '../../../domain/value_objects/manual_generation_progress_stage.dart';

/// マニュアル生成フロー実行中の高レベルなフェーズを表す
enum VideoAnalysisPhase {
  idle,
  analyzingVideo,
  generatingImages,
  completed,
  error,
}

/// 動画解析の進行状況ダイアログ向けのUI状態
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

  /// 進行状況コールバックのイベントをもとに状態を生成する便利ファクトリー
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

  /// 進行状況インジケーターに表示するフェーズ（エラー状態を無視する）
  VideoAnalysisPhase get displayPhase =>
      phase == VideoAnalysisPhase.error ? latestNonErrorPhase : phase;
}

