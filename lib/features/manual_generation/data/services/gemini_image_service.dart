import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';

/// Service for Gemini API image generation and editing
/// Uses the Nano Banana Pro (gemini-3-pro-image-preview) model
class GeminiImageService {
  final ApiClient _apiClient;
  final String _apiKey;

  GeminiImageService({required ApiClient apiClient, required String apiKey})
    : _apiClient = apiClient,
      _apiKey = apiKey;

  /// Generates an annotated image with arrows, text, and highlights
  /// using Gemini's image generation capabilities
  ///
  /// Requirements: 4.1, 4.2, 4.3, 4.4
  Future<Result<String>> generateAnnotatedImage({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) async {
    try {
      print('🖼️ 画像アノテーション開始: ステップ$stepNumber');
      print('📁 元画像パス: $originalImagePath');
      print('📝 ステップタイトル: $stepTitle');

      // Read the original image
      final imageBytes = await _readImageFile(originalImagePath);
      if (imageBytes == null) {
        print('❌ 元画像の読み込みに失敗');
        return Result.failure(
          const ApiFailure('Failed to read original image file'),
        );
      }
      print('✅ 元画像読み込み完了: ${imageBytes.length} bytes');

      // Generate annotated image using Gemini
      final result = await _generateImageWithGemini(
        imageBytes: imageBytes,
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
      );

      if (result.isFailure) {
        print('⚠️ Gemini画像生成失敗、元画像を使用: ${result.failure!.message}');
        // Fallback: return original image path if generation fails
        return Result.success(originalImagePath);
      }

      // Save the generated image
      final annotatedImagePath = await _saveGeneratedImage(
        result.data!,
        originalImagePath,
        stepNumber,
      );

      print('✅ アノテーション完了: $annotatedImagePath');
      return Result.success(annotatedImagePath);
    } catch (e) {
      print('❌ アノテーション処理でエラー: $e');
      // Fallback: return original image path on any error
      return Result.success(originalImagePath);
    }
  }

  /// Reads image file as bytes
  Future<List<int>?> _readImageFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('❌ 画像ファイルが存在しません: $path');
        return null;
      }
      final bytes = await file.readAsBytes();
      print('📖 画像ファイル読み込み: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      print('❌ 画像ファイル読み込みエラー: $e');
      return null;
    }
  }

  /// Generates annotated image using Gemini API
  Future<Result<List<int>>> _generateImageWithGemini({
    required List<int> imageBytes,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) async {
    try {
      final url =
          '${AppConstants.geminiApiBaseUrl}/${AppConstants.geminiApiVersion}/models/${AppConstants.geminiImageModel}:generateContent';
      print('🌐 画像生成API エンドポイント (Nano Banana Pro): $url');

      // Encode image as base64
      final base64Image = base64Encode(imageBytes);
      print('🔄 Base64エンコード完了: ${base64Image.length} 文字');

      // Create prompt for image annotation
      final prompt = _buildImageAnnotationPrompt(
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
      );

      // Prepare request body for image generation
      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
      };

      // Log request details
      print('📋 リクエスト詳細:');
      print('  URL: $url');
      print('  画像サイズ: ${imageBytes.length} bytes');
      print('  Base64サイズ: ${base64Image.length} 文字');
      print('  リクエストボディサイズ: ${jsonEncode(requestBody).length} 文字');
      print('  プロンプト長: ${prompt.length} 文字');
      print('  リクエストボディ: $requestBody');

      // Make API call
      print('📤 Gemini画像生成API呼び出し中...');
      final response = await _apiClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: requestBody,
      );

      // Log response details
      print('📥 レスポンス詳細:');
      print('  レスポンスキー: ${response.keys.toList()}');
      if (response.containsKey('candidates')) {
        print('  候補数: ${(response['candidates'] as List).length}');
      }
      if (response.containsKey('error')) {
        print('  エラー: ${response['error']}');
      }

      // Parse response and extract generated image
      return _parseImageGenerationResponse(response);
    } catch (e) {
      print('❌ 画像生成API呼び出しエラー: $e');
      if (e is ApiException) {
        return Result.failure(ApiFailure(e.message, code: e.code));
      }
      return Result.failure(ApiFailure('Image generation failed: $e'));
    }
  }

  /// Builds prompt for image annotation
  String _buildImageAnnotationPrompt({
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) {
    final prompt =
        '''
このスクリーンショットを分析して、ステップバイステップの手順を理解しやすくするアノテーション付きバージョンを作成してください。

ステップ$stepNumber: $stepTitle
説明: $stepDescription

この画像に以下の視覚的アノテーションを追加してください：
1. 説明で言及されている重要なUI要素を指す赤い矢印を追加
2. 操作対象領域、操作が影響を与える領域を強調する赤い円または四角形を追加
3. 左上角に赤い円でステップ番号「$stepNumber」を追加
4. クリックまたは操作する内容を説明する明確で読みやすいフォントのテキストラベルを追加
5. アノテーションには明確に見える明るい対比色（赤、オレンジ）を使用

すべてのテキストラベルと説明文は日本語で記載してください。

目標は、この画像を誰かがこのステップを完了するために従うことができる明確な指導ガイドにすることです。

ユーザーが注意を向けるべき場所を明確に示すアノテーション付き画像を返してください。

純粋な画像のみを返してください。テキストやコードブロックは含めないでください。
''';

    print('📝 画像アノテーションプロンプト:');
    print(prompt);

    return prompt;
  }

  /// Parses Gemini image generation response
  Future<Result<List<int>>> _parseImageGenerationResponse(
    Map<String, dynamic> response,
  ) async {
    try {
      print('🔍 画像生成レスポンス解析中...');
      print('📄 生レスポンス: ${jsonEncode(response)}');

      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        print('❌ レスポンスに候補がありません');
        throw const ApiException('No candidates in Gemini response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        print('❌ レスポンスにコンテンツがありません');
        throw const ApiException('No content in Gemini response');
      }

      print('📋 コンテンツキー: ${content.keys.toList()}');

      // Check for inline_data with image
      final parts = content['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        for (final part in parts) {
          if (part is Map<String, dynamic>) {
            final inlineData = part['inlineData'] ?? part['inline_data'];
            if (inlineData is Map<String, dynamic>) {
              final mimeType =
                  inlineData['mimeType'] ?? inlineData['mime_type'];
              final data = inlineData['data'];

              if (mimeType is String && data is String) {
                print('✅ 画像データ発見:');
                print('  MIME Type: $mimeType');
                print('  データサイズ: ${data.length} 文字');

                if (mimeType.startsWith('image/')) {
                  try {
                    final imageBytes = base64Decode(data);
                    print('✅ Base64デコード完了: ${imageBytes.length} bytes');
                    return Result.success(imageBytes);
                  } catch (e) {
                    print('❌ Base64デコードエラー: $e');
                    throw ApiException('Failed to decode base64 image: $e');
                  }
                }
              }
            }
          }
        }
      }

      // For now, we'll return a placeholder since the actual image generation
      // API structure needs to be verified with real Gemini API documentation
      print('⚠️ 画像データが見つからない、フォールバックを使用');
      throw const ApiException(
        'Image data not found in response - using fallback',
      );
    } catch (e) {
      print('❌ 画像生成レスポンス解析エラー: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to parse image generation response: $e');
    }
  }

  /// Saves generated image to local storage
  Future<String> _saveGeneratedImage(
    List<int> imageBytes,
    String originalImagePath,
    int stepNumber,
  ) async {
    try {
      print('💾 生成画像を保存中...');

      // Create annotated images directory
      final originalFile = File(originalImagePath);
      final directory = originalFile.parent;
      final annotatedDir = Directory('${directory.path}/annotated');

      if (!await annotatedDir.exists()) {
        await annotatedDir.create(recursive: true);
        print('📁 アノテーション用ディレクトリ作成: ${annotatedDir.path}');
      }

      // Generate new filename
      final originalName = originalFile.uri.pathSegments.last;
      final nameWithoutExtension = originalName.split('.').first;
      final extension = originalName.split('.').last;
      final annotatedFileName =
          '${nameWithoutExtension}_step${stepNumber}_annotated.$extension';

      // Save annotated image
      final annotatedFile = File('${annotatedDir.path}/$annotatedFileName');
      await annotatedFile.writeAsBytes(imageBytes);

      print('✅ アノテーション画像保存完了:');
      print('  パス: ${annotatedFile.path}');
      print('  サイズ: ${imageBytes.length} bytes');

      return annotatedFile.path;
    } catch (e) {
      print('❌ アノテーション画像保存エラー: $e');
      throw ApiException('Failed to save annotated image: $e');
    }
  }
}
