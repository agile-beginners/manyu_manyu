import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/video_repository_impl.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/entities/video_file.dart';

/// Provider for VideoRepository
final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepositoryImpl();
});

/// State class for video upload
class VideoUploadState {
  static const Object _manualInfoSentinel = Object();

  final File? selectedFile;
  final bool isUploading;
  final double uploadProgress;
  final VideoFile? uploadedVideo;
  final String? errorMessage;
  final String? manualInfo;

  const VideoUploadState({
    this.selectedFile,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadedVideo,
    this.errorMessage,
    this.manualInfo,
  });

  VideoUploadState copyWith({
    File? selectedFile,
    bool? isUploading,
    double? uploadProgress,
    VideoFile? uploadedVideo,
    String? errorMessage,
    Object? manualInfo = _manualInfoSentinel,
  }) {
    return VideoUploadState(
      selectedFile: selectedFile ?? this.selectedFile,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadedVideo: uploadedVideo ?? this.uploadedVideo,
      errorMessage: errorMessage,
      manualInfo: identical(manualInfo, _manualInfoSentinel)
          ? this.manualInfo
          : manualInfo as String?,
    );
  }

  VideoUploadState clearError() {
    return copyWith(errorMessage: null);
  }

  VideoUploadState clearUpload() {
    return copyWith(
      uploadedVideo: null,
      uploadProgress: 0.0,
      errorMessage: null,
      manualInfo: null,
    );
  }
}

/// StateNotifier for managing video upload state
class VideoUploadController extends StateNotifier<VideoUploadState> {
  final VideoRepository _repository;

  VideoUploadController(this._repository) : super(const VideoUploadState());

  /// Selects a file for upload
  void selectFile(File file) {
    state = state.copyWith(
      selectedFile: file,
    ).clearError().clearUpload();
  }

  /// Uploads the selected video file
  Future<void> uploadVideo(File videoFile) async {
    if (state.isUploading) return;

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      errorMessage: null,
      uploadedVideo: null,
      manualInfo: null,
    );

    try {
      // Simulate upload progress
      await _simulateUploadProgress();

      // Perform actual upload
      final result = await _repository.uploadVideo(videoFile);

      if (result.isSuccess) {
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 1.0,
          uploadedVideo: result.data,
        );
      } else {
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 0.0,
          errorMessage: result.failure?.message ?? 'アップロードに失敗しました',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        errorMessage: 'アップロード中にエラーが発生しました: $e',
      );
    }
  }

  /// Simulates upload progress for better UX
  Future<void> _simulateUploadProgress() async {
    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      if (!state.isUploading) break; // Stop if upload was cancelled
      
      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(
        uploadProgress: i / totalSteps * 0.9, // Go up to 90%, then complete with actual upload
      );
    }
  }

  /// Clears the current error message
  void clearError() {
    state = state.clearError();
  }

  /// Updates the manual information provided by the user
  void updateManualInfo(String? manualInfo) {
    final trimmedInfo = manualInfo?.trim();
    state = state.copyWith(
      manualInfo: (trimmedInfo == null || trimmedInfo.isEmpty) ? null : trimmedInfo,
    );
  }

  /// Resets the upload state
  void reset() {
    state = const VideoUploadState();
  }
}

/// Provider for video upload state
final videoUploadStateProvider = StateNotifierProvider<VideoUploadController, VideoUploadState>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return VideoUploadController(repository);
});

/// Provider for supported video formats
final supportedFormatsProvider = Provider<List<String>>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getSupportedFormats();
});

/// Provider for maximum file size
final maxFileSizeProvider = Provider<int>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getMaxFileSizeBytes();
});
