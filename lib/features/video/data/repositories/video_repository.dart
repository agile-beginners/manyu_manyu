import 'dart:io';
import '../../../../core/utils/result.dart';
import '../../domain/entities/video_file.dart';

/// 動画ファイル操作のリポジトリインターフェース
abstract class VideoRepository {
  /// 動画ファイルをアップロードしてVideoFileメタデータを返す
  Future<Result<VideoFile>> uploadVideo(File videoFile);

  /// 動画ファイルの形式とサイズを検証する
  Future<Result<bool>> validateVideo(File videoFile);

  /// 動画ファイルのメタデータをローカルストレージに保存する
  Future<Result<void>> saveVideoMetadata(VideoFile videoFile);

  /// パスで動画ファイルのメタデータを取得する
  Future<Result<VideoFile?>> getVideoMetadata(String path);

  /// 動画ファイルとそのメタデータを削除する
  Future<Result<void>> deleteVideo(String path);

  /// アップロードされた全動画ファイルの一覧を取得する
  Future<Result<List<VideoFile>>> getAllVideos();

  /// 対応している動画形式を取得する
  List<String> getSupportedFormats();

  /// 許可される最大ファイルサイズ（バイト）を取得する
  int getMaxFileSizeBytes();
}
