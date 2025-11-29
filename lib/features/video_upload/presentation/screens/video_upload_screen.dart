import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/video_upload_providers.dart';
import '../widgets/upload_progress_widget.dart';
import '../widgets/file_selection_widget.dart';
import '../widgets/upload_status_widget.dart';

/// Screen for uploading video files
class VideoUploadScreen extends ConsumerWidget {
  const VideoUploadScreen({super.key});

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
                  child: UploadStatusWidget(
                    uploadedVideo: uploadState.uploadedVideo,
                    errorMessage: uploadState.errorMessage,
                    onRetry: () {
                      if (uploadState.selectedFile != null) {
                        uploadNotifier.uploadVideo(uploadState.selectedFile!);
                      }
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