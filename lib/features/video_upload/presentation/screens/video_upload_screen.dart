import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../manual_editing/presentation/screens/manual_edit_screen.dart';
import '../../../manual_generation/domain/entities/manual.dart';
import '../../../manual_generation/presentation/providers/video_analysis_providers.dart';
import '../../../manual_generation/presentation/states/video_analysis_state.dart';
import '../providers/video_upload_providers.dart';
import '../widgets/file_selection_widget.dart';
import '../widgets/upload_progress_widget.dart';
import '../widgets/upload_status_widget.dart';

/// Screen for uploading video files
class VideoUploadScreen extends ConsumerWidget {
  const VideoUploadScreen({super.key});

  void _startVideoAnalysis(
    BuildContext context,
    WidgetRef ref,
    dynamic uploadedVideo,
  ) {
    ref.read(videoAnalysisNotifierProvider.notifier).analyzeVideo(uploadedVideo);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('動画解析を開始しました'),
        duration: Duration(seconds: 2),
      ),
    );

    _showAnalysisProgressDialog(context, ref);
  }

  void _showAnalysisProgressDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final analysisState = ref.watch(videoAnalysisNotifierProvider);
          final notifier = ref.read(videoAnalysisNotifierProvider.notifier);
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          Widget buildProcessingBody({
            required Widget indicator,
            required String message,
          }) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AnalysisProgressSteps(state: analysisState),
                const SizedBox(height: 24),
                Center(child: indicator),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            );
          }

          if (analysisState.hasCompleted && analysisState.manual != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pop();
              _navigateToManualEdit(context, ref, analysisState.manual!);
            });
          }

          String titleText;
          Widget content;
          List<Widget> actions = [];

          switch (analysisState.phase) {
            case VideoAnalysisPhase.analyzingVideo:
              titleText = '動画の解析中';
              content = buildProcessingBody(
                indicator: const CircularProgressIndicator(),
                message: 'Geminiが動画のステップを解析しています...',
              );
              break;
            case VideoAnalysisPhase.generatingImages:
              titleText = '説明画像の生成中';
              content = buildProcessingBody(
                indicator: const CircularProgressIndicator(),
                message: 'ステップごとの説明画像を作成しています...',
              );
              break;
            case VideoAnalysisPhase.completed:
              titleText = 'マニュアル生成完了';
              content = buildProcessingBody(
                indicator: Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 48,
                ),
                message: 'マニュアルの生成が完了しました。画面遷移中です。',
              );
              break;
            case VideoAnalysisPhase.error:
              titleText = '解析エラー';
              content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AnalysisProgressSteps(state: analysisState),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '解析エラー: ${analysisState.errorMessage ?? "不明なエラーが発生しました"}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              );
              actions = [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    notifier.reset();
                  },
                  child: const Text('閉じる'),
                ),
              ];
              break;
            case VideoAnalysisPhase.idle:
              titleText = 'マニュアル生成の準備中';
              content = buildProcessingBody(
                indicator: const CircularProgressIndicator(),
                message: 'マニュアル生成を準備しています...',
              );
              break;
          }

          return AlertDialog(
            title: Text(titleText),
            content: content,
            actions: actions,
          );
        },
      ),
    );
  }

  void _navigateToManualEdit(
    BuildContext context,
    WidgetRef ref,
    Manual manual,
  ) {
    // Reset analysis state before leaving the progress flow
    ref.read(videoAnalysisNotifierProvider.notifier).reset();

    // Show a brief confirmation toast/snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('解析が完了しました。「${manual.title}」を編集します。'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate on the next microtask to avoid Navigator conflicts
    Future.microtask(() {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ManualEditScreen(manualId: manual.id),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(videoUploadStateProvider);
    final uploadNotifier = ref.read(videoUploadStateProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('動画アップロード'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.largePadding,
              vertical: AppConstants.largePadding * 1.5,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(colorScheme: colorScheme),
                  const SizedBox(height: AppConstants.largePadding * 1.1),
                  _UploadCard(
                    colorScheme: colorScheme,
                    uploadState: uploadState,
                    uploadNotifier: uploadNotifier,
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  if (uploadState.isUploading ||
                      (uploadState.uploadProgress > 0 &&
                          uploadState.uploadProgress < 1.0))
                    _ProgressCard(uploadState: uploadState),
                  if (uploadState.errorMessage != null ||
                      uploadState.uploadedVideo != null) ...[
                    const SizedBox(height: AppConstants.largePadding),
                    _StatusCard(
                      colorScheme: colorScheme,
                      uploadState: uploadState,
                      onRetry: () {
                        if (uploadState.selectedFile != null) {
                          uploadNotifier.uploadVideo(uploadState.selectedFile!);
                        }
                      },
                      onStartAnalysis: uploadState.uploadedVideo != null
                          ? () {
                              _startVideoAnalysis(
                                context,
                                ref,
                                uploadState.uploadedVideo!,
                              );
                            }
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisProgressSteps extends StatelessWidget {
  const _AnalysisProgressSteps({required this.state});

  final VideoAnalysisState state;

  int _phaseToIndex(VideoAnalysisPhase phase) {
    switch (phase) {
      case VideoAnalysisPhase.analyzingVideo:
        return 0;
      case VideoAnalysisPhase.generatingImages:
        return 1;
      case VideoAnalysisPhase.completed:
        return 2;
      case VideoAnalysisPhase.idle:
      case VideoAnalysisPhase.error:
        return -1;
    }
  }

  bool _isStepCompleted({
    required int stepIndex,
    required bool isFullyCompleted,
    required int activeIndex,
  }) {
    if (activeIndex < 0) return false;
    if (isFullyCompleted) {
      return activeIndex >= stepIndex;
    }
    return activeIndex > stepIndex;
  }

  bool _isStepActive({
    required int stepIndex,
    required bool isFullyCompleted,
    required int activeIndex,
  }) {
    if (isFullyCompleted || activeIndex < 0) {
      return false;
    }
    return activeIndex == stepIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final steps = <VideoAnalysisPhase>[
      VideoAnalysisPhase.analyzingVideo,
      VideoAnalysisPhase.generatingImages,
      VideoAnalysisPhase.completed,
    ];

    final labels = <VideoAnalysisPhase, String>{
      VideoAnalysisPhase.analyzingVideo: '動画の解析中',
      VideoAnalysisPhase.generatingImages: '説明画像の生成中',
      VideoAnalysisPhase.completed: 'マニュアル生成完了',
    };

    final activeIndex = _phaseToIndex(state.displayPhase);
    final bool isFullyCompleted = state.phase == VideoAnalysisPhase.completed;
    final disabledColor = theme.disabledColor;

    final timelineSegments = <Widget>[];
    final labelSegments = <Widget>[];

    for (var i = 0; i < steps.length; i++) {
      final stepPhase = steps[i];
      final stepCompleted = _isStepCompleted(
        stepIndex: i,
        isFullyCompleted: isFullyCompleted,
        activeIndex: activeIndex,
      );
      final stepActive = _isStepActive(
        stepIndex: i,
        isFullyCompleted: isFullyCompleted,
        activeIndex: activeIndex,
      );

      final Widget circle = AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: stepCompleted
              ? colorScheme.primary
              : stepActive
                  ? colorScheme.primaryContainer
                  : colorScheme.surface,
          border: Border.all(
            color: stepCompleted || stepActive
                ? colorScheme.primary
                : disabledColor.withOpacity(0.5),
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: stepCompleted
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: colorScheme.onPrimary,
                )
              : Text(
                  '${i + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                        color: stepActive
                            ? colorScheme.onPrimaryContainer
                            : disabledColor,
                        fontWeight:
                            stepActive ? FontWeight.w700 : FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: stepActive
                            ? colorScheme.onPrimaryContainer
                            : disabledColor,
                        fontSize: 16,
                        fontWeight:
                            stepActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
        ),
      );

      timelineSegments.add(circle);

      if (i < steps.length - 1) {
        final connectorCompleted = _isStepCompleted(
          stepIndex: i,
          isFullyCompleted: isFullyCompleted,
          activeIndex: activeIndex,
        );

        timelineSegments.add(
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: connectorCompleted
                    ? colorScheme.primary
                    : disabledColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      }

      final labelStyle = theme.textTheme.labelMedium?.copyWith(
            color: stepCompleted || stepActive
                ? colorScheme.primary
                : disabledColor.withOpacity(0.9),
            fontWeight: stepActive ? FontWeight.w700 : FontWeight.w500,
          ) ??
          TextStyle(
            color: stepCompleted || stepActive
                ? colorScheme.primary
                : disabledColor.withOpacity(0.9),
            fontSize: 12,
            fontWeight: stepActive ? FontWeight.w700 : FontWeight.w500,
          );

      labelSegments.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              labels[stepPhase]!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: timelineSegments,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: labelSegments,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.largePadding * 1.5,
        vertical: AppConstants.largePadding * 1.1,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.16),
                  colorScheme.primary.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.upload_file_outlined,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppConstants.largePadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '動画をアップロードしてAI解析を開始',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'マニュマニュがステップ抽出・注釈付け・PDF出力まで自動でサポート。動画を選択してアップロードを開始してください。',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _InfoChip(label: 'Geminiでステップ抽出'),
                    _InfoChip(label: 'Nano Bananaで注釈付け'),
                    _InfoChip(label: '最大20ステップ'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.colorScheme,
    required this.uploadState,
    required this.uploadNotifier,
  });

  final ColorScheme colorScheme;
  final VideoUploadState uploadState;
  final VideoUploadStateNotifier uploadNotifier;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.video_library_outlined, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  '動画ファイルを選択',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Text(
              'MP4/MOV/AVI/MKV 形式に対応。最大 500MB までアップロードできます。',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            FileSelectionWidget(
              selectedFile: uploadState.selectedFile,
              onFileSelected: (file) {
                uploadNotifier.selectFile(file);
              },
              isEnabled: !uploadState.isUploading,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _InfoChip(label: '対応形式: MP4 / MOV / AVI / MKV'),
                _InfoChip(label: '上限: 500MB'),
                _InfoChip(label: 'アップロード後にAI解析を開始'),
              ],
            ),
            const SizedBox(height: AppConstants.largePadding * 0.8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: uploadState.selectedFile != null &&
                        !uploadState.isUploading
                    ? () {
                        uploadNotifier.uploadVideo(uploadState.selectedFile!);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.defaultPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: uploadState.isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('アップロード中...'),
                        ],
                      )
                    : const Text(
                        'アップロードを開始',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.uploadState});

  final VideoUploadState uploadState;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: UploadProgressWidget(
          progress: uploadState.uploadProgress,
          isUploading: uploadState.isUploading,
        ),
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({
    required this.colorScheme,
    required this.uploadState,
    required this.onRetry,
    this.onStartAnalysis,
  });

  final ColorScheme colorScheme;
  final VideoUploadState uploadState;
  final VoidCallback onRetry;
  final VoidCallback? onStartAnalysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnalysisInProgress = ref.watch(isAnalysisInProgressProvider);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: UploadStatusWidget(
          uploadedVideo: uploadState.uploadedVideo,
          errorMessage: uploadState.errorMessage,
          onRetry: onRetry,
          onStartAnalysis:
              uploadState.uploadedVideo != null && !isAnalysisInProgress
                  ? onStartAnalysis
                  : null,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4B5563),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
