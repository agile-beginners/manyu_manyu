import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/result.dart';
import '../../video/domain/entities/video_file.dart';
import '../data/repositories/manual_repository.dart';
import '../data/services/gemini_image_service.dart';
import '../data/services/gemini_video_analysis_service.dart';
import '../data/services/image_annotation_service.dart';
import '../data/services/image_extraction_service.dart';
import '../data/services/nano_banana_service.dart';
import '../data/services/video_analysis_service.dart';
import '../domain/entities/manual.dart';
import '../domain/entities/manual_step.dart';
import '../domain/value_objects/manual_generation_progress_stage.dart';
import 'manual_edit_service.dart';

/// 動画解析の完全なプロセスを調整するサービス
class ManualCreationService {
  final VideoAnalysisService _videoAnalysisService;
  final ManualRepository _manualRepository;
  final ImageExtractionService _imageExtractionService;
  final ImageAnnotationService _imageAnnotationService;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  ManualCreationService({
    required VideoAnalysisService videoAnalysisService,
    required ManualRepository manualRepository,
    required ImageExtractionService imageExtractionService,
    required ImageAnnotationService imageAnnotationService,
    required Ref ref,
  })  : _videoAnalysisService = videoAnalysisService,
        _manualRepository = manualRepository,
        _imageExtractionService = imageExtractionService,
        _imageAnnotationService = imageAnnotationService,
        _ref = ref;

  /// 動画を解析して完全なマニュアルを作成する
  ///
  /// マニュアル作成のシナリオを調整する:
  /// 1. Gemini APIを呼び出して動画を解析する
  /// 2. 抽出したステップでManualエンティティを作成する
  /// 3. マニュアルをリポジトリに保存する
  Future<Result<Manual>> analyzeVideoAndCreateManual(
    VideoFile videoFile, {
    String? customTitle,
    String? manualInfo,
    void Function(ManualGenerationProgressStage stage)? onProgress,
  }) async {
    try {
      final sanitizedManualInfo = manualInfo?.trim();

      // 生成中ステータスで初期マニュアルを作成する
      final manual = Manual(
        id: _uuid.v4(),
        title: customTitle ?? 'Manual from ${videoFile.name}',
        steps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoPath: videoFile.path,
        videoDurationMs: videoFile.durationMs,
        status: ManualStatus.generating,
        description:
            (sanitizedManualInfo == null || sanitizedManualInfo.isEmpty)
                ? null
                : sanitizedManualInfo,
      );

      // 初期マニュアルを保存する
      final saveResult = await _manualRepository.saveManual(manual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      return _runAnalysis(manual, videoFile,
          manualInfo: sanitizedManualInfo, onProgress: onProgress);
    } catch (e) {
      return Result.failure(
        ApiFailure('Failed to create manual: $e'),
      );
    }
  }

  /// 解析ワークフローのコア処理。[initialManual]のidを再利用することで
  /// [analyzeVideoAndCreateManual]と[retryAnalysis]が同じレコードに書き込む。
  Future<Result<Manual>> _runAnalysis(
    Manual initialManual,
    VideoFile videoFile, {
    String? manualInfo,
    void Function(ManualGenerationProgressStage stage)? onProgress,
  }) async {
    try {
      // ステップ1: Gemini APIで動画を解析する（要件2.1, 2.2, 2.3）
      onProgress?.call(ManualGenerationProgressStage.analyzingVideo);

      final analysisResult = await _videoAnalysisService.analyzeVideo(
        videoFile,
        manualInfo: manualInfo,
      );
      if (analysisResult.isFailure) {
        // マニュアルのステータスを失敗に更新する
        final failedManual = initialManual.copyWith(
          status: ManualStatus.failed,
          updatedAt: DateTime.now(),
        );
        await _manualRepository.updateManual(failedManual);
        _ref.invalidate(allManualsProvider);
        _ref.invalidate(manualProvider(initialManual.id));

        return Result.failure(analysisResult.failure!);
      }

      final steps = analysisResult.data!;

      // ステップ2: タイムスタンプで動画から画像を抽出する（要件3.1, 3.2）
      onProgress?.call(ManualGenerationProgressStage.generatingImages);

      final imageExtractionResult =
          await _imageExtractionService.extractImagesFromVideo(
        videoPath: videoFile.path,
        steps: steps,
      );

      List<String> extractedImagePaths = [];
      if (imageExtractionResult.isSuccess) {
        extractedImagePaths = imageExtractionResult.data!;
      } else {
        // 抽出失敗時は空の画像パスで続行する（要件3.4）
        print(
            'Image extraction failed: ${imageExtractionResult.failure!.message}');
      }

      // ステップ3: 抽出した画像パスでステップを更新し画像にアノテーションを付与する
      final imagePathsForSteps = List<String?>.generate(
        steps.length,
        (index) => index < extractedImagePaths.length
            ? extractedImagePaths[index]
            : null,
      );

      // ステップ4: 並列で画像にアノテーションを付与する（要件4.1, 4.2, 4.3）
      final annotationFutures = <Future<String?>>[];
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        final imagePath = imagePathsForSteps[i];

        if (imagePath == null) {
          annotationFutures.add(Future.value(null));
          continue;
        }

        annotationFutures.add(() async {
          try {
            final annotationResult =
                await _imageAnnotationService.generateAnnotatedImage(
              originalImagePath: imagePath,
              stepTitle: step.title,
              stepDescription: step.description,
              stepNumber: step.stepNumber,
            );

            if (annotationResult.isSuccess && annotationResult.data != null) {
              return annotationResult.data!;
            }

            final failureMessage =
                annotationResult.failure?.message ?? 'Unknown error';
            print(
              'Image annotation failed for step ${step.stepNumber}: $failureMessage',
            );
            // フォールバック: アノテーション失敗時は元画像を使用する（要件4.4）
            return imagePath;
          } catch (e) {
            // フォールバック: エラー発生時は元画像を使用する（要件4.4）
            print('Image annotation error for step ${step.stepNumber}: $e');
            return imagePath;
          }
        }());
      }

      final annotatedImagePaths = await Future.wait(annotationFutures);

      final processedSteps = <ManualStep>[];
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];

        // 画像パスで更新したステップを作成する
        final processedStep = step.copyWith(
          imagePath: imagePathsForSteps[i],
          annotatedImagePath: annotatedImagePaths[i],
          isProcessed: true,
        );

        processedSteps.add(processedStep);
      }

      // 処理済みステップでマニュアルを更新する（既存のidを再利用）
      final completedManual = initialManual.copyWith(
        steps: processedSteps,
        status: ManualStatus.draft,
        updatedAt: DateTime.now(),
      );

      // 完成したマニュアルを保存する
      final updateResult =
          await _manualRepository.updateManual(completedManual);
      if (updateResult.isFailure) {
        return Result.failure(updateResult.failure!);
      }

      // UIが更新されたマニュアルを表示できるようプロバイダーを無効化する
      _ref.invalidate(allManualsProvider);
      _ref.invalidate(manualProvider(completedManual.id));

      onProgress?.call(ManualGenerationProgressStage.completed);

      return Result.success(completedManual);
    } catch (e) {
      // エラー発生時はマニュアルのステータスを失敗に更新する
      final failedManual = initialManual.copyWith(
        status: ManualStatus.failed,
        updatedAt: DateTime.now(),
      );
      await _manualRepository.updateManual(failedManual);
      _ref.invalidate(allManualsProvider);
      _ref.invalidate(manualProvider(initialManual.id));

      return Result.failure(
        ApiFailure('Video analysis failed: $e'),
      );
    }
  }

  /// 失敗したマニュアルの解析をリトライする
  ///
  /// 要件: 2.4 - APIコール失敗時のリトライオプション
  Future<Result<Manual>> retryAnalysis(
    String manualId, {
    void Function(ManualGenerationProgressStage stage)? onProgress,
  }) async {
    try {
      // 既存のマニュアルを取得する
      final manualResult = await _manualRepository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }

      final manual = manualResult.data;
      if (manual == null) {
        return Result.failure(
          const ValidationFailure('Manual not found'),
        );
      }

      if (manual.videoPath == null) {
        return Result.failure(
          const ValidationFailure('No video path found for manual'),
        );
      }

      // マニュアルデータからVideoFileを作成する
      final videoFile = VideoFile(
        path: manual.videoPath!,
        name: manual.title,
        sizeInBytes: 0, // この情報は持っていないが、リトライには必須でない
        format: _extractFormatFromPath(manual.videoPath!),
        durationMs: manual.videoDurationMs,
        createdAt: manual.createdAt,
      );

      // 既存のマニュアルを生成中ステータスにリセットする（同じidを再利用）
      final generatingManual = manual.copyWith(
        status: ManualStatus.generating,
        updatedAt: DateTime.now(),
      );
      await _manualRepository.updateManual(generatingManual);
      _ref.invalidate(allManualsProvider);
      _ref.invalidate(manualProvider(manual.id));

      // 既存のマニュアルidを再利用してインラインで解析を実行する
      return _runAnalysis(generatingManual, videoFile,
          manualInfo: manual.description, onProgress: onProgress);
    } catch (e) {
      return Result.failure(
        ApiFailure('Failed to retry analysis: $e'),
      );
    }
  }

  /// ファイルパスからファイル形式を抽出する
  String _extractFormatFromPath(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'mp4'; // デフォルトのフォールバック
  }
}

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final _geminiVideoAnalysisServiceProvider =
    Provider<VideoAnalysisService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeminiVideoAnalysisService(
    apiClient: apiClient,
    apiKey: EnvConfig.geminiApiKey,
  );
});

final _imageExtractionServiceProvider = Provider<ImageExtractionService>((ref) {
  return ImageExtractionService();
});

final _geminiImageServiceProvider = Provider<GeminiImageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeminiImageService(
    apiClient: apiClient,
    apiKey: EnvConfig.geminiApiKey,
  );
});

final _nanoBananaServiceProvider = Provider<NanoBananaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NanoBananaService(
    apiClient: apiClient,
    apiKey: EnvConfig.nanoBananaApiKey,
    baseUrl: EnvConfig.nanoBananaApiBaseUrl,
    fallbackService: ref.watch(_geminiImageServiceProvider),
  );
});

final _imageAnnotationServiceProvider = Provider<ImageAnnotationService>((ref) {
  return ref.watch(_nanoBananaServiceProvider);
});

/// ManualCreationServiceのプロバイダー
final manualCreationServiceProvider = Provider<ManualCreationService>((ref) {
  return ManualCreationService(
    videoAnalysisService: ref.watch(_geminiVideoAnalysisServiceProvider),
    manualRepository: ref.watch(manualRepositoryProvider),
    imageExtractionService: ref.watch(_imageExtractionServiceProvider),
    imageAnnotationService: ref.watch(_imageAnnotationServiceProvider),
    ref: ref,
  );
});
