import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../manual_generation/presentation/providers/video_analysis_providers.dart';
import '../providers/video_upload_providers.dart';
import '../widgets/upload_progress_widget.dart';
import '../widgets/file_selection_widget.dart';
import '../widgets/upload_status_widget.dart';

/// Screen for uploading video files
class VideoUploadScreen extends ConsumerWidget {
  const VideoUploadScreen({super.key});

  void _startVideoAnalysis(BuildContext context, WidgetRef ref, dynamic uploadedVideo) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画解析を開始'),
        content: const Text('動画の解析を開始しますか？\n解析には数分かかる場合があります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Start video analysis
              ref.read(videoAnalysisNotifierProvider.notifier).analyzeVideo(uploadedVideo);
              
              // Show analysis started message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('動画解析を開始しました'),
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Navigate to analysis progress screen
              _showAnalysisProgressDialog(context, ref);
            },
            child: const Text('開始'),
          ),
        ],
      ),
    );
  }
  
  void _showAnalysisProgressDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final analysisState = ref.watch(videoAnalysisNotifierProvider);
          
          return AlertDialog(
            title: const Text('動画解析中'),
            content: analysisState.when(
              loading: () => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('動画を解析しています...'),
                ],
              ),
              data: (manual) {
                if (manual != null) {
                  // Analysis completed successfully
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pop();
                    _showAnalysisCompleteDialog(context, manual);
                  });
                }
                return const SizedBox.shrink();
              },
              error: (error, stackTrace) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('解析エラー: $error'),
                ],
              ),
            ),
            actions: analysisState.when(
              loading: () => [],
              data: (_) => [],
              error: (_, __) => [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(videoAnalysisNotifierProvider.notifier).reset();
                  },
                  child: const Text('閉じる'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showAnalysisCompleteDialog(BuildContext context, dynamic manual) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解析完了'),
        content: Text('マニュアル「${manual.title}」が作成されました。\n${manual.stepCount}個のステップが抽出されました。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to manual edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('マニュアル編集画面への遷移は今後実装予定です'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(videoUploadStateProvider);
    final uploadNotifier = ref.read(videoUploadStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('動画アップロード'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File selection section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '動画ファイルを選択',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FileSelectionWidget(
                      selectedFile: uploadState.selectedFile,
                      onFileSelected: (file) {
                        uploadNotifier.selectFile(file);
                      },
                      isEnabled: !uploadState.isUploading,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload progress section
            if (uploadState.isUploading || uploadState.uploadProgress > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: UploadProgressWidget(
                    progress: uploadState.uploadProgress,
                    isUploading: uploadState.isUploading,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Upload status section
            if (uploadState.errorMessage != null || uploadState.uploadedVideo != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isAnalysisInProgress = ref.watch(isAnalysisInProgressProvider);
                      
                      return UploadStatusWidget(
                        uploadedVideo: uploadState.uploadedVideo,
                        errorMessage: uploadState.errorMessage,
                        onRetry: () {
                          if (uploadState.selectedFile != null) {
                            uploadNotifier.uploadVideo(uploadState.selectedFile!);
                          }
                        },
                        onStartAnalysis: uploadState.uploadedVideo != null && !isAnalysisInProgress
                            ? () {
                                _startVideoAnalysis(context, ref, uploadState.uploadedVideo!);
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ),
            
            const Spacer(),
            
            // Upload button
            ElevatedButton(
              onPressed: uploadState.selectedFile != null && !uploadState.isUploading
                  ? () {
                      uploadNotifier.uploadVideo(uploadState.selectedFile!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      'アップロード開始',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}