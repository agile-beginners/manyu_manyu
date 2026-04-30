import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import 'gemini_image_service.dart';
import 'image_annotation_service.dart';

/// Nano Banana APIを使用した画像アノテーションサービス
/// 矢印、テキスト、ハイライトによる画像アノテーションを実装する
///
/// 要件: 4.1, 4.2, 4.3, 4.4
/// - 4.1: 赤い矢印・テキスト・円を含む画像をアノテーションAPIに送信する
/// - 4.2: アノテーション付き画像を生成してローカルに保存する
/// - 4.3: 編集完了時にステップJSONへ画像パスを追加する
/// - 4.4: API通信失敗時は元画像を使用する
class NanoBananaService implements ImageAnnotationService {
  final ApiClient _apiClient;
  final String _apiKey;
  final String _baseUrl;
  final GeminiImageService _fallbackService;
  
  NanoBananaService({
    required ApiClient apiClient,
    required String apiKey,
    required String baseUrl,
    required GeminiImageService fallbackService,
  }) : _apiClient = apiClient,
       _apiKey = apiKey,
       _baseUrl = baseUrl,
       _fallbackService = fallbackService;

  @override
  Future<Result<String>> generateAnnotatedImage({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) async {
    try {
      // 入力パラメータを検証する
      final validationResult = _validateInputs(
        originalImagePath: originalImagePath,
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
      );
      
      if (validationResult.isFailure) {
        return _handleFallback(
          originalImagePath: originalImagePath,
          stepTitle: stepTitle,
          stepDescription: stepDescription,
          stepNumber: stepNumber,
          error: validationResult.failure!.message,
        );
      }

      // まずNano Banana APIを試みる
      final nanoBananaResult = await _callNanoBananaApi(
        originalImagePath: originalImagePath,
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
      );

      if (nanoBananaResult.isSuccess) {
        return nanoBananaResult;
      }

      // Nano Banana失敗時はGeminiサービスにフォールバックする
      return await _handleFallback(
        originalImagePath: originalImagePath,
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
        error: nanoBananaResult.failure!.message,
      );

    } catch (e) {
      // 最終フォールバック: 元画像パスを返す
      return await _handleFallback(
        originalImagePath: originalImagePath,
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
        error: e.toString(),
      );
    }
  }

  /// 入力パラメータを検証する
  Result<void> _validateInputs({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) {
    // 画像ファイルの存在確認
    final file = File(originalImagePath);
    if (!file.existsSync()) {
      return Result.failure(
        const ValidationFailure('Original image file does not exist'),
      );
    }

    // ステップ番号を検証する
    if (stepNumber < 1 || stepNumber > AppConstants.maxManualSteps) {
      return Result.failure(
        ValidationFailure('Invalid step number: $stepNumber'),
      );
    }

    // 必須テキストフィールドを検証する
    if (stepTitle.trim().isEmpty) {
      return Result.failure(
        const ValidationFailure('Step title cannot be empty'),
      );
    }

    if (stepDescription.trim().isEmpty) {
      return Result.failure(
        const ValidationFailure('Step description cannot be empty'),
      );
    }

    return const Result.success(null);
  }

  /// 画像アノテーションのためにNano Banana APIを呼び出す
  Future<Result<String>> _callNanoBananaApi({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) async {
    try {
      // 元画像を読み込む
      final imageBytes = await _readImageFile(originalImagePath);
      if (imageBytes == null) {
        return Result.failure(
          const ApiFailure('Failed to read original image file'),
        );
      }

      // 画像アップロード用のマルチパートリクエストを準備する
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/v1/annotate'),
      );

      // ヘッダーを追加する
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'multipart/form-data',
      });

      // 画像ファイルを追加する
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'step_$stepNumber.jpg',
        ),
      );

      // アノテーションパラメータを追加する
      request.fields.addAll({
        'step_number': stepNumber.toString(),
        'step_title': stepTitle,
        'step_description': stepDescription,
        'annotation_style': 'red_arrows_and_circles',
        'highlight_color': '#FF0000', // 赤色
        'add_step_number': 'true',
        'add_text_labels': 'true',
      });

      // タイムアウト付きでリクエストを送信する
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 成功レスポンスを解析する
        return await _parseNanoBananaResponse(response, originalImagePath, stepNumber);
      } else {
        // APIがエラーステータスを返した
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          // パース失敗時はデフォルトのエラーメッセージを使用する
        }
        
        return Result.failure(
          ApiFailure(
            'Nano Banana API error: $errorMessage',
            code: response.statusCode.toString(),
          ),
        );
      }

    } catch (e) {
      if (e is ApiException) {
        return Result.failure(ApiFailure(e.message, code: e.code));
      }
      return Result.failure(ApiFailure('Nano Banana API call failed: $e'));
    }
  }

  /// Nano Banana APIのレスポンスを解析してアノテーション付き画像を保存する
  Future<Result<String>> _parseNanoBananaResponse(
    http.Response response,
    String originalImagePath,
    int stepNumber,
  ) async {
    try {
      // レスポンスに画像データが含まれるか確認する
      if (response.headers['content-type']?.startsWith('image/') == true) {
        // レスポンスが画像の場合はそのまま保存する
        final annotatedImagePath = await _saveAnnotatedImage(
          response.bodyBytes,
          originalImagePath,
          stepNumber,
        );
        return Result.success(annotatedImagePath);
      } else {
        // レスポンスがJSONの場合は画像URLまたはbase64データを抽出する
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData.containsKey('annotated_image_url')) {
          // URLから画像をダウンロードする
          final imageUrl = responseData['annotated_image_url'] as String;
          final imageBytes = await _downloadImage(imageUrl);
          
          if (imageBytes != null) {
            final annotatedImagePath = await _saveAnnotatedImage(
              imageBytes,
              originalImagePath,
              stepNumber,
            );
            return Result.success(annotatedImagePath);
          }
        } else if (responseData.containsKey('annotated_image_base64')) {
          // base64画像データをデコードする
          final base64Data = responseData['annotated_image_base64'] as String;
          final imageBytes = base64Decode(base64Data);
          
          final annotatedImagePath = await _saveAnnotatedImage(
            imageBytes,
            originalImagePath,
            stepNumber,
          );
          return Result.success(annotatedImagePath);
        }
        
        return Result.failure(
          const ApiFailure('No image data found in Nano Banana response'),
        );
      }
    } catch (e) {
      return Result.failure(
        ApiFailure('Failed to parse Nano Banana response: $e'),
      );
    }
  }

  /// URLから画像をダウンロードする
  Future<List<int>?> _downloadImage(String imageUrl) async {
    try {
      final response = await _apiClient.get(imageUrl);
      // 注意: ApiClientはMap<String, dynamic>を返すが、画像ダウンロードには
      // バイト列が必要。現在のApiClientの制限事項。
      // 実際の実装ではバイナリダウンロード用の別メソッドが必要になる場合がある。
      return null; // プレースホルダー - バイナリダウンロードの実装が必要
    } catch (e) {
      return null;
    }
  }

  /// 画像ファイルをバイト列として読み込む
  Future<List<int>?> _readImageFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// アノテーション付き画像をローカルストレージに保存する
  Future<String> _saveAnnotatedImage(
    List<int> imageBytes,
    String originalImagePath,
    int stepNumber,
  ) async {
    try {
      // アノテーション付き画像用ディレクトリを作成する
      final originalFile = File(originalImagePath);
      final directory = originalFile.parent;
      final annotatedDir = Directory('${directory.path}/annotated');
      
      if (!await annotatedDir.exists()) {
        await annotatedDir.create(recursive: true);
      }

      // 新しいファイル名を生成する
      final originalName = originalFile.uri.pathSegments.last;
      final nameWithoutExtension = originalName.split('.').first;
      final extension = originalName.split('.').last;
      final annotatedFileName = '${nameWithoutExtension}_step${stepNumber}_nano_banana.$extension';
      
      // アノテーション付き画像を保存する
      final annotatedFile = File('${annotatedDir.path}/$annotatedFileName');
      await annotatedFile.writeAsBytes(imageBytes);
      
      return annotatedFile.path;
    } catch (e) {
      throw ApiException('Failed to save annotated image: $e');
    }
  }

  /// Geminiサービスまたは元画像へのフォールバックを処理する
  Future<Result<String>> _handleFallback({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
    required String error,
  }) async {
    try {
      // フォールバックとしてGeminiサービスを試みる
      final geminiResult = await _fallbackService.generateAnnotatedImage(
        originalImagePath: originalImagePath,
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
      );

      if (geminiResult.isSuccess) {
        return geminiResult;
      }

      // 最終フォールバック: 元画像パスを返す
      // 要件4.4を満たす: API通信失敗時は元画像を使用する
      return Result.success(originalImagePath);

    } catch (e) {
      // 最終フォールバック: 元画像パスを返す
      return Result.success(originalImagePath);
    }
  }
}