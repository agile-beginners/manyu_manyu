import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../video_upload/domain/entities/video_file.dart';
import '../../domain/entities/manual_step.dart';
import '../../domain/services/gemini_service.dart' as domain;

/// Service for interacting with Gemini API for video analysis
class GeminiService implements domain.GeminiService {
  final ApiClient _apiClient;
  final String _apiKey;

  GeminiService({
    required ApiClient apiClient,
    required String apiKey,
  })  : _apiClient = apiClient,
        _apiKey = apiKey;

  /// Analyzes a video file and extracts manual steps
  ///
  /// Requirements: 2.1, 2.2, 2.3, 2.4
  Future<Result<List<ManualStep>>> analyzeVideo(
    VideoFile videoFile, {
    String? manualInfo,
  }) async {
    try {
      print(
          '🎬 Analyzing video: ${videoFile.name} (${videoFile.sizeInBytes} bytes)');
      final sanitizedManualInfo = manualInfo?.trim();
      if (sanitizedManualInfo != null && sanitizedManualInfo.isNotEmpty) {
        print(
            '📝 Manual info provided (length: ${sanitizedManualInfo.length})');
      }

      // Temporary: Use mock data for testing while API issues are resolved
      const bool useMockData = false; // Set to false when API is working

      if (useMockData) {
        print('🧪 Using mock data');
        return _generateMockSteps(videoFile);
      }

      // Validate video file
      final validationResult = _validateVideoFile(videoFile);
      if (validationResult.isFailure) {
        print('❌ Validation failed: ${validationResult.failure!.message}');
        return Result.failure(validationResult.failure!);
      }

      // Prepare video for upload
      final videoBytes = await _readVideoFile(videoFile.path);
      if (videoBytes == null) {
        print('❌ Failed to read video file');
        return Result.failure(
          const ApiFailure('Failed to read video file'),
        );
      }

      // Call Gemini API with retry mechanism
      final analysisResult = await _callGeminiApiWithRetry(
          videoBytes, videoFile, sanitizedManualInfo);
      if (analysisResult.isFailure) {
        print('❌ API call failed: ${analysisResult.failure!.message}');
        return Result.failure(analysisResult.failure!);
      }

      // Parse API response
      final steps = _parseGeminiResponse(analysisResult.data!);

      // Validate step count (max 20 steps as per requirement 2.2)
      if (steps.length > AppConstants.maxManualSteps) {
        print(
            '❌ Too many steps: ${steps.length} > ${AppConstants.maxManualSteps}');
        return Result.failure(
          ApiFailure(
              'Too many steps extracted: ${steps.length}. Maximum allowed: ${AppConstants.maxManualSteps}'),
        );
      }

      print('✅ Analysis completed: ${steps.length} steps');
      return Result.success(steps);
    } catch (e) {
      print('❌ Analysis failed: $e');
      return Result.failure(
        ApiFailure('Video analysis failed: $e'),
      );
    }
  }

  /// Validates the video file before processing
  Result<void> _validateVideoFile(VideoFile videoFile) {
    // Check if file exists
    final file = File(videoFile.path);
    if (!file.existsSync()) {
      return Result.failure(
        const ValidationFailure('Video file does not exist'),
      );
    }

    // Check file format
    if (!AppConstants.supportedVideoFormats
        .contains(videoFile.format.toLowerCase())) {
      return Result.failure(
        ValidationFailure('Unsupported video format: ${videoFile.format}'),
      );
    }

    // Check file size
    if (videoFile.sizeInBytes > AppConstants.maxVideoSizeBytes) {
      return Result.failure(
        ValidationFailure(
            'Video file too large: ${videoFile.sizeInBytes} bytes. Maximum: ${AppConstants.maxVideoSizeBytes} bytes'),
      );
    }

    return const Result.success(null);
  }

  /// Reads video file as bytes
  Future<List<int>?> _readVideoFile(String path) async {
    try {
      final file = File(path);
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Calls Gemini API with retry mechanism
  Future<Result<Map<String, dynamic>>> _callGeminiApiWithRetry(
    List<int> videoBytes,
    VideoFile videoFile,
    String? manualInfo,
  ) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < AppConstants.maxRetryAttempts) {
      attempts++;
      print('🔄 Attempt $attempts/${AppConstants.maxRetryAttempts}');

      try {
        final result = await _callGeminiApi(
          videoBytes,
          videoFile,
          manualInfo,
        );
        if (result.isSuccess) {
          print('✅ API call successful');
          return result;
        }

        print('❌ API call failed: ${result.failure!.message}');
        lastException = Exception(result.failure!.message);

        // Wait before retry (exponential backoff)
        if (attempts < AppConstants.maxRetryAttempts) {
          final waitTime = attempts * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
        }
      } catch (e) {
        print('❌ Exception on attempt $attempts: $e');
        lastException = e is Exception ? e : Exception(e.toString());

        // Wait before retry
        if (attempts < AppConstants.maxRetryAttempts) {
          final waitTime = attempts * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
        }
      }
    }

    final errorMessage =
        'Failed after $attempts attempts: ${lastException?.toString() ?? "Unknown error"}';
    print('❌ Final failure: $errorMessage');
    return Result.failure(ApiFailure(errorMessage));
  }

  /// Makes the actual API call to Gemini
  Future<Result<Map<String, dynamic>>> _callGeminiApi(
    List<int> videoBytes,
    VideoFile videoFile,
    String? manualInfo,
  ) async {
    try {
      final url =
          '${AppConstants.geminiApiBaseUrl}/${AppConstants.geminiApiVersion}/models/${AppConstants.geminiModel}:generateContent';
      print('🌐 API Endpoint: $url');

      return await _makeApiRequest(
        url,
        videoBytes,
        videoFile,
        manualInfo,
      );
    } catch (e) {
      if (e is ApiException) {
        return Result.failure(ApiFailure(e.message, code: e.code));
      }
      return Result.failure(ApiFailure('API call failed: $e'));
    }
  }

  /// Makes the actual HTTP request to a specific endpoint
  Future<Result<Map<String, dynamic>>> _makeApiRequest(
    String url,
    List<int> videoBytes,
    VideoFile videoFile,
    String? manualInfo,
  ) async {
    print('📤 Making API request...');

    // Encode video as base64
    final base64Video = base64Encode(videoBytes);

    // Prepare request body
    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': _buildAnalysisPrompt(manualInfo: manualInfo),
            },
            {
              'inline_data': {
                'mime_type': _getMimeType(videoFile.format),
                'data': base64Video,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 32,
        'topP': 1,
        'maxOutputTokens': 4096,
      }
    };

    // Log request details
    print('📋 Request Details:');
    print('  URL: $url');
    print('  MIME Type: ${_getMimeType(videoFile.format)}');
    print('  Video Size: ${videoBytes.length} bytes');
    print('  Base64 Size: ${base64Video.length} characters');
    print('  Request Body Size: ${jsonEncode(requestBody).length} characters');
    if (manualInfo != null && manualInfo.isNotEmpty) {
      print(
          '  Manual Info Preview: ${manualInfo.substring(0, manualInfo.length > 120 ? 120 : manualInfo.length)}${manualInfo.length > 120 ? '...' : ''}');
    }

    // Make API call
    final response = await _apiClient.post(
      url,
      headers: {
        'X-Goog-Api-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    // Log response details
    print('📥 Response Details:');
    print('  Response Keys: ${response.keys.toList()}');
    if (response.containsKey('candidates')) {
      print('  Candidates Count: ${(response['candidates'] as List).length}');
    }
    if (response.containsKey('error')) {
      print('  Error: ${response['error']}');
    }

    return Result.success(response);
  }

  /// Builds the analysis prompt for Gemini
  String _buildAnalysisPrompt({String? manualInfo}) {
    final buffer = StringBuffer('''
この動画を分析して、マニュアル作成のためのステップバイステップの手順を抽出してください。

以下の構造でJSONレスポンスを提供してください：
{
  "title": "マニュアルの簡潔なタイトル",
  "steps": [
    {
      "title": "ステップのタイトル",
      "description": "このステップで何をするかの詳細な説明",
      "timestamp": 1500
    }
  ]
}

要件：
- 最大${AppConstants.maxManualSteps}ステップまで抽出
- 各ステップには明確なタイトルと詳細な説明を含める
- タイムスタンプは動画内でそのアクションが発生する時間をミリ秒で表示
  - ここで、タイムスタンプはできる限り詳細に指定するようにしてください。(出来れば1/10秒レベルまで指定)
- ユーザーが実行可能なアクションに焦点を当てる
- 説明は明確で簡潔にする
- 動画のタイムラインに基づいて時系列順に並べる
- すべてのテキストは日本語で記述する

純粋なJSONのみを返してください。コードブロック（```json）や追加のテキストは含めないでください。
''');

    if (manualInfo != null && manualInfo.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('追加コンテキスト:');
      buffer.writeln(manualInfo);
    }

    return buffer.toString();
  }

  /// Gets MIME type for video format
  String _getMimeType(String format) {
    switch (format.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'video/mp4'; // Default fallback
    }
  }

  /// Parses Gemini API response and converts to ManualStep objects
  List<ManualStep> _parseGeminiResponse(Map<String, dynamic> response) {
    try {
      // Extract content from Gemini response
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const ApiException('No candidates in Gemini response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw const ApiException('No content in Gemini response');
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw const ApiException('No parts in Gemini response');
      }

      final textPart = parts[0]['text'] as String?;
      if (textPart == null) {
        throw const ApiException('No text in Gemini response');
      }

      print('📄 Raw Response Text:');
      print(textPart);

      // Clean the response text (remove code blocks if present)
      String cleanedText = textPart.trim();

      // Remove markdown code blocks if present
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.replaceFirst('```json', '').trim();
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.replaceFirst('```', '').trim();
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3).trim();
      }

      print('📄 Cleaned Response Text:');
      print(cleanedText);

      // Parse JSON from cleaned text response
      final jsonResponse = jsonDecode(cleanedText) as Map<String, dynamic>;

      // Validate required fields
      if (!jsonResponse.containsKey('steps')) {
        throw const ApiException('Missing steps in Gemini response');
      }

      final stepsJson = jsonResponse['steps'] as List<dynamic>;
      final steps = <ManualStep>[];
      const uuid = Uuid();

      for (int i = 0; i < stepsJson.length; i++) {
        final stepJson = stepsJson[i] as Map<String, dynamic>;

        // Validate required fields for each step
        if (!stepJson.containsKey('title') ||
            !stepJson.containsKey('description') ||
            !stepJson.containsKey('timestamp')) {
          throw ApiException('Missing required fields in step $i');
        }

        final step = ManualStep(
          id: uuid.v4(),
          title: stepJson['title'] as String,
          description: stepJson['description'] as String,
          timestamp: stepJson['timestamp'] as int,
          stepNumber: i + 1,
          isProcessed: false,
        );

        steps.add(step);
      }

      return steps;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to parse Gemini response: $e');
    }
  }

  /// Generates mock steps for testing purposes
  Result<List<ManualStep>> _generateMockSteps(VideoFile videoFile) {
    print('🎭 モックデータを生成中...');

    const uuid = Uuid();
    final steps = <ManualStep>[
      ManualStep(
        id: uuid.v4(),
        title: 'アプリケーションを起動する',
        description: '対象のアプリケーションをダブルクリックして起動し、メイン画面が表示されるまで待ちます。',
        timestamp: 1000,
        stepNumber: 1,
        isProcessed: false,
      ),
      ManualStep(
        id: uuid.v4(),
        title: 'メニューから機能を選択する',
        description: '画面上部のメニューバーから「ファイル」→「新規作成」を選択します。',
        timestamp: 5000,
        stepNumber: 2,
        isProcessed: false,
      ),
      ManualStep(
        id: uuid.v4(),
        title: '設定を変更する',
        description: '設定ダイアログで必要なオプションを変更し、「適用」ボタンをクリックして保存します。',
        timestamp: 10000,
        stepNumber: 3,
        isProcessed: false,
      ),
      ManualStep(
        id: uuid.v4(),
        title: '操作を完了する',
        description: '変更内容を確認し、「OK」ボタンをクリックして操作を完了します。',
        timestamp: 15000,
        stepNumber: 4,
        isProcessed: false,
      ),
    ];

    print('✅ ${steps.length}個のモックステップを生成しました');
    return Result.success(steps);
  }
}
