import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/manual_step.dart';

/// 特定のタイムスタンプで動画から画像を抽出するサービス
class ImageExtractionService {
  /// 指定されたタイムスタンプで動画から画像を抽出する
  ///
  /// 要件: 3.1, 3.2, 3.3, 3.4
  Future<Result<List<String>>> extractImagesFromVideo({
    required String videoPath,
    required List<ManualStep> steps,
  }) async {
    try {
      // 動画ファイルの存在確認（要件3.4）
      if (!await _validateVideoFile(videoPath)) {
        return Result.failure(
          VideoProcessingFailure('Video file not found or inaccessible: $videoPath'),
        );
      }

      // 抽出画像用ディレクトリを作成する（要件3.2）
      final extractedImagesDir = await _createExtractedImagesDirectory();

      final extractedImagePaths = <String>[];

      // 各ステップの画像を抽出する（要件3.1）
      for (final step in steps) {
        try {
          // タイムスタンプで画像を抽出する
          final imagePath = await _extractImageAtTimestamp(
            videoPath: videoPath,
            timestamp: step.timestamp,
            stepNumber: step.stepNumber,
            outputDirectory: extractedImagesDir.path,
          );

          if (imagePath != null) {
            extractedImagePaths.add(imagePath);
          } else {
            // 抽出失敗時はプレースホルダー画像を作成する（要件3.4）
            final placeholderPath = await _createPlaceholderImage(
              stepNumber: step.stepNumber,
              outputDirectory: extractedImagesDir.path,
              reason: 'Frame extraction failed',
            );
            extractedImagePaths.add(placeholderPath);
          }
        } catch (e) {
          // エラー時はこのステップをスキップしてプレースホルダーを作成する（要件3.4）
          print('Error extracting image for step ${step.stepNumber}: $e');
          final placeholderPath = await _createPlaceholderImage(
            stepNumber: step.stepNumber,
            outputDirectory: extractedImagesDir.path,
            reason: 'Error: $e',
          );
          extractedImagePaths.add(placeholderPath);
        }
      }
      
      return Result.success(extractedImagePaths);
    } catch (e) {
      return Result.failure(
        VideoProcessingFailure('Failed to extract images from video: $e'),
      );
    }
  }

  /// 抽出画像用ディレクトリを作成する
  Future<Directory> _createExtractedImagesDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final extractedImagesDir = Directory(
        '${appDir.path}/${AppConstants.extractedImagesDirectory}',
      );
      
      if (!await extractedImagesDir.exists()) {
        await extractedImagesDir.create(recursive: true);
      }
      
      return extractedImagesDir;
    } catch (e) {
      // テスト用にシステム一時ディレクトリにフォールバック
      final tempDir = await Directory.systemTemp.createTemp('extracted_images');
      return tempDir;
    }
  }

  /// VideoPlayerControllerを使用して特定のタイムスタンプで動画から画像を抽出する
  ///
  /// 要件: 3.1 - 各タイムスタンプで動画から画像を抽出する
  Future<String?> _extractImageAtTimestamp({
    required String videoPath,
    required int timestamp,
    required int stepNumber,
    required String outputDirectory,
  }) async {
    try {
      final outputPath = '$outputDirectory/step_${stepNumber}_${timestamp}ms.jpg';

      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: timestamp,
        maxHeight: 720,
        quality: 90,
      );

      if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
        print('Thumbnail generation returned empty for timestamp $timestamp ms.');
        return null;
      }

      final file = File(outputPath);
      await file.writeAsBytes(thumbnailBytes, flush: true);
      print('Extracted frame for step $stepNumber at $timestamp ms -> $outputPath');

      return outputPath;
    } catch (e) {
      print('Error extracting frame at timestamp $timestamp: $e');
      return null;
    }
  }

  /// 1x1の透明ピクセルのための最小限のPNGバイト列を作成する
  Uint8List _createMinimalPngBytes() {
    // 最小限のPNGファイル（1x1の透明ピクセル）
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNGシグネチャ
      0x00, 0x00, 0x00, 0x0D, // IHDRチャンク長
      0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x01, // 幅: 1
      0x00, 0x00, 0x00, 0x01, // 高さ: 1
      0x08, 0x06, 0x00, 0x00, 0x00, // ビット深度: 8, カラータイプ: 6 (RGBA), 圧縮: 0, フィルタ: 0, インタレース: 0
      0x1F, 0x15, 0xC4, 0x89, // CRC
      0x00, 0x00, 0x00, 0x0A, // IDAT chunk length
      0x49, 0x44, 0x41, 0x54, // IDAT
      0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // Compressed data
      0xE2, 0x21, 0xBC, 0x33, // CRC
      0x00, 0x00, 0x00, 0x00, // IEND chunk length
      0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82, // CRC
    ]);
  }

  /// 動画抽出失敗時にプレースホルダー画像を作成する
  ///
  /// 要件: 3.4 - エラーをログに記録して失敗したステップをスキップして処理する
  Future<String> _createPlaceholderImage({
    required int stepNumber,
    required String outputDirectory,
    required String reason,
  }) async {
    try {
      // プレースホルダー画像ファイルを作成する
      final placeholderPath = '$outputDirectory/step_${stepNumber}_placeholder.jpg';
      final placeholderFile = File(placeholderPath);
      
      // プレースホルダー用の最小PNGバイト列を作成する
      final imageBytes = _createMinimalPngBytes();
      await placeholderFile.writeAsBytes(imageBytes);
      
      // デバッグ用のメタデータファイルも作成する
      final metadataPath = '$outputDirectory/step_${stepNumber}_metadata.txt';
      final metadataFile = File(metadataPath);
      
      await metadataFile.writeAsString(
        'Placeholder for Step $stepNumber\n'
        'Reason: $reason\n'
        'Created: ${DateTime.now().toIso8601String()}\n'
        'Note: This is a placeholder image due to extraction failure.',
      );
      
      return placeholderPath;
    } catch (e) {
      throw VideoProcessingFailure('Failed to create placeholder image: $e');
    }
  }

  /// 動画ファイルが存在してアクセス可能かどうかを検証する
  ///
  /// 要件: 3.4 - エラーを適切に処理する
  Future<bool> _validateVideoFile(String videoPath) async {
    try {
      final file = File(videoPath);
      final exists = await file.exists();
      
      if (!exists) {
        print('Video file does not exist: $videoPath');
        return false;
      }
      
      // ファイルが読み取り可能かどうかを確認する
      final stat = await file.stat();
      if (stat.size == 0) {
        print('Video file is empty: $videoPath');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error validating video file: $e');
      return false;
    }
  }

  /// 一時ファイルとディレクトリをクリーンアップする
  Future<void> cleanupTempFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final extractedImagesDir = Directory(
        '${appDir.path}/${AppConstants.extractedImagesDirectory}',
      );
      
      if (await extractedImagesDir.exists()) {
        await extractedImagesDir.delete(recursive: true);
        print('Cleaned up extracted images directory');
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
      // テスト環境では失敗が予想される
    }
  }

  /// 抽出可能なフレームの総数を取得する
  Future<int> getEstimatedFrameCount(String videoPath) async {
    VideoPlayerController? controller;
    
    try {
      controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      
      final duration = controller.value.duration;
      // 一般的なフレームレート（30fps）を基に推定する
      return (duration.inMilliseconds / 1000 * 30).round();
    } catch (e) {
      print('Error getting frame count: $e');
      return 0;
    } finally {
      await controller?.dispose();
    }
  }

}