import 'dart:io';
import '../../../../core/utils/result.dart';
import '../repositories/video_repository.dart';
import '../../domain/entities/video_file.dart';

/// 動画アップロード操作を処理するサービスクラス
class VideoUploadService {
  final VideoRepository _repository;

  VideoUploadService(this._repository);

  /// 動画ファイルを検証してアップロードする
  Future<Result<VideoFile>> uploadVideo(File videoFile) async {
    // まず動画を検証する
    final validationResult = await _repository.validateVideo(videoFile);
    if (validationResult.isFailure) {
      return Result.failure(validationResult.failure!);
    }

    // 次に動画をアップロードする
    return await _repository.uploadVideo(videoFile);
  }

  /// 対応している動画形式を取得する
  List<String> getSupportedFormats() {
    return _repository.getSupportedFormats();
  }

  /// 最大ファイルサイズ（バイト）を取得する
  int getMaxFileSizeBytes() {
    return _repository.getMaxFileSizeBytes();
  }

  /// 表示用の最大ファイルサイズ（MB）を取得する
  int getMaxFileSizeMB() {
    return (_repository.getMaxFileSizeBytes() / (1024 * 1024)).round();
  }

  /// アップロードせずに動画ファイルを検証する
  Future<Result<bool>> validateVideo(File videoFile) async {
    return await _repository.validateVideo(videoFile);
  }

  /// アップロードされた全動画を取得する
  Future<Result<List<VideoFile>>> getAllVideos() async {
    return await _repository.getAllVideos();
  }

  /// 動画ファイルを削除する
  Future<Result<void>> deleteVideo(String path) async {
    return await _repository.deleteVideo(path);
  }
}
