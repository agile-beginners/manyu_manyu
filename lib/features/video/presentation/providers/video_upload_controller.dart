import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/video_repository_impl.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/entities/video_file.dart';

/// VideoRepositoryのプロバイダー
final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepositoryImpl();
});

/// 動画アップロードの状態クラス
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

/// 動画アップロードの状態を管理するStateNotifier
class VideoUploadController extends StateNotifier<VideoUploadState> {
  final VideoRepository _repository;

  VideoUploadController(this._repository) : super(const VideoUploadState());

  /// アップロードするファイルを選択する
  void selectFile(File file) {
    state = state.copyWith(
      selectedFile: file,
    ).clearError().clearUpload();
  }

  /// 選択した動画ファイルをアップロードする
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
      // アップロードの進行状況をシミュレートする
      await _simulateUploadProgress();

      // 実際のアップロードを実行する
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

  /// UX向上のためアップロードの進行状況をシミュレートする
  Future<void> _simulateUploadProgress() async {
    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      if (!state.isUploading) break; // アップロードがキャンセルされた場合は停止する
      
      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(
        uploadProgress: i / totalSteps * 0.9, // 90%まで進め、その後実際のアップロードで完了する
      );
    }
  }

  /// 現在のエラーメッセージをクリアする
  void clearError() {
    state = state.clearError();
  }

  /// ユーザーが入力したマニュアル情報を更新する
  void updateManualInfo(String? manualInfo) {
    final trimmedInfo = manualInfo?.trim();
    state = state.copyWith(
      manualInfo: (trimmedInfo == null || trimmedInfo.isEmpty) ? null : trimmedInfo,
    );
  }

  /// アップロードの状態をリセットする
  void reset() {
    state = const VideoUploadState();
  }
}

/// 動画アップロード状態のプロバイダー
final videoUploadStateProvider = StateNotifierProvider<VideoUploadController, VideoUploadState>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return VideoUploadController(repository);
});

/// 対応動画形式のプロバイダー
final supportedFormatsProvider = Provider<List<String>>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getSupportedFormats();
});

/// 最大ファイルサイズのプロバイダー
final maxFileSizeProvider = Provider<int>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getMaxFileSizeBytes();
});
