import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import 'video_repository.dart';
import '../../domain/entities/video_file.dart';

/// ローカルストレージを使用したVideoRepositoryの具体的な実装
class VideoRepositoryImpl implements VideoRepository {
  static const String _videoMetadataFileName = 'video_metadata.json';
  static const List<String> _supportedFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const int _maxFileSizeBytes = 500 * 1024 * 1024; // 500MB
  
  final Uuid _uuid = const Uuid();

  @override
  Future<Result<VideoFile>> uploadVideo(File videoFile) async {
    try {
      // まず動画を検証する
      final validationResult = await validateVideo(videoFile);
      if (validationResult.isFailure) {
        return Result.failure(validationResult.failure!);
      }

      // アプリのドキュメントディレクトリを取得する
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/videos');

      // 動画ディレクトリが存在しない場合は作成する
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      // 一意なファイル名を生成する
      final originalName = videoFile.path.split('/').last;
      final extension = originalName.split('.').last.toLowerCase();
      final uniqueId = _uuid.v4();
      final newFileName = '$uniqueId.$extension';
      final newPath = '${videosDir.path}/$newFileName';

      // ファイルをアプリディレクトリにコピーする
      final copiedFile = await videoFile.copy(newPath);

      // ファイルの統計情報を取得する
      final fileStat = await copiedFile.stat();

      // VideoFileのメタデータを作成する
      final videoFileMetadata = VideoFile(
        path: newPath,
        name: originalName,
        sizeInBytes: fileStat.size,
        format: extension,
        createdAt: DateTime.now(),
      );

      // メタデータを保存する
      final saveResult = await saveVideoMetadata(videoFileMetadata);
      if (saveResult.isFailure) {
        // メタデータ保存失敗時はコピーしたファイルをクリーンアップする
        try {
          await copiedFile.delete();
        } catch (e) {
          // クリーンアップエラーは無視する
        }
        return Result.failure(saveResult.failure!);
      }

      return Result.success(videoFileMetadata);
    } on FileException catch (e) {
      return Result.failure(FileFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(FileFailure('Failed to upload video: $e'));
    }
  }

  @override
  Future<Result<bool>> validateVideo(File videoFile) async {
    try {
      // ファイルの存在確認
      if (!await videoFile.exists()) {
        return Result.failure(
          const ValidationFailure('Video file does not exist'),
        );
      }

      // ファイルサイズの確認
      final fileStat = await videoFile.stat();
      if (fileStat.size > _maxFileSizeBytes) {
        return Result.failure(
          ValidationFailure(
            'Video file is too large. Maximum size is ${_maxFileSizeBytes ~/ (1024 * 1024)}MB',
          ),
        );
      }

      // ファイル形式の確認
      final fileName = videoFile.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      
      if (!_supportedFormats.contains(extension)) {
        return Result.failure(
          ValidationFailure(
            'Unsupported video format: $extension. Supported formats: ${_supportedFormats.join(', ')}',
          ),
        );
      }

      return const Result.success(true);
    } catch (e) {
      return Result.failure(ValidationFailure('Failed to validate video: $e'));
    }
  }

  @override
  Future<Result<void>> saveVideoMetadata(VideoFile videoFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      List<VideoFile> existingVideos = [];
      
      // ファイルが存在する場合は既存のメタデータを読み込む
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        existingVideos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
      }
      
      // 動画メタデータを追加または更新する
      final existingIndex = existingVideos.indexWhere((v) => v.path == videoFile.path);
      if (existingIndex != -1) {
        existingVideos[existingIndex] = videoFile;
      } else {
        existingVideos.add(videoFile);
      }
      
      // 更新されたメタデータを保存する
      final jsonList = existingVideos.map((v) => v.toJson()).toList();
      await metadataFile.writeAsString(jsonEncode(jsonList));
      
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to save video metadata: $e'));
    }
  }

  @override
  Future<Result<VideoFile?>> getVideoMetadata(String path) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      if (!await metadataFile.exists()) {
        return const Result.success(null);
      }
      
      final content = await metadataFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final videos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
      
      final video = videos.where((v) => v.path == path).firstOrNull;
      return Result.success(video);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get video metadata: $e'));
    }
  }

  @override
  Future<Result<void>> deleteVideo(String path) async {
    try {
      // 動画ファイルを削除する
      final videoFile = File(path);
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
      
      // メタデータから削除する
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final videos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
        
        final updatedVideos = videos.where((v) => v.path != path).toList();
        final updatedJsonList = updatedVideos.map((v) => v.toJson()).toList();
        
        await metadataFile.writeAsString(jsonEncode(updatedJsonList));
      }
      
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to delete video: $e'));
    }
  }

  @override
  Future<Result<List<VideoFile>>> getAllVideos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_videoMetadataFileName');
      
      if (!await metadataFile.exists()) {
        return const Result.success([]);
      }
      
      final content = await metadataFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final videos = jsonList.map((json) => VideoFile.fromJson(json)).toList();
      
      // 作成日でソートする（新しい順）
      videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Result.success(videos);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get all videos: $e'));
    }
  }

  @override
  List<String> getSupportedFormats() {
    return List.unmodifiable(_supportedFormats);
  }

  @override
  int getMaxFileSizeBytes() {
    return _maxFileSizeBytes;
  }
}
