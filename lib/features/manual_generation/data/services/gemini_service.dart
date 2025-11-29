import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../video_upload/domain/entities/video_file.dart';
import '../../domain/entities/manual_step.dart';

/// Service for interacting with Gemini API for video analysis
class GeminiService {
  final ApiClient _apiClient;
  final String _apiKey;
  
  GeminiService({
    required ApiClient apiClient,
    required String apiKey,
  }) : _apiClient = apiClient, _apiKey = apiKey;

  /// Analyzes a video file and extracts manual steps
  /// 
  /// Requirements: 2.1, 2.2, 2.3, 2.4
  Future<Result<List<ManualStep>>> analyzeVideo(VideoFile videoFile) async {
    try {
      // Validate video file
      final validationResult = _validateVideoFile(videoFile);
      if (validationResult.isFailure) {
        return Result.failure(validationResult.failure!);
      }

      // Prepare video for upload
      final videoBytes = await _readVideoFile(videoFile.path);
      if (videoBytes == null) {
        return Result.failure(
          const ApiFailure('Failed to read video file'),
        );
      }

      // Call Gemini API with retry mechanism
      final analysisResult = await _callGeminiApiWithRetry(videoBytes, videoFile);
      if (analysisResult.isFailure) {
        return Result.failure(analysisResult.failure!);
      }

      // Parse API response
      final steps = _parseGeminiResponse(analysisResult.data!);
      
      // Validate step count (max 20 steps as per requirement 2.2)
      if (steps.length > AppConstants.maxManualSteps) {
        return Result.failure(
          ApiFailure('Too many steps extracted: ${steps.length}. Maximum allowed: ${AppConstants.maxManualSteps}'),
        );
      }

      return Result.success(steps);
    } catch (e) {
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
    if (!AppConstants.supportedVideoFormats.contains(videoFile.format.toLowerCase())) {
      return Result.failure(
        ValidationFailure('Unsupported video format: ${videoFile.format}'),
      );
    }

    // Check file size
    if (videoFile.sizeInBytes > AppConstants.maxVideoSizeBytes) {
      return Result.failure(
        ValidationFailure('Video file too large: ${videoFile.sizeInBytes} bytes. Maximum: ${AppConstants.maxVideoSizeBytes} bytes'),
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
  ) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < AppConstants.maxRetryAttempts) {
      attempts++;
      
      try {
        final result = await _callGeminiApi(videoBytes, videoFile);
        if (result.isSuccess) {
          return result;
        }
        
        lastException = Exception(result.failure!.message);
        
        // Wait before retry (exponential backoff)
        if (attempts < AppConstants.maxRetryAttempts) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Wait before retry
        if (attempts < AppConstants.maxRetryAttempts) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }
    }

    return Result.failure(
      ApiFailure(
        'Failed to analyze video after $attempts attempts: ${lastException?.toString() ?? "Unknown error"}',
      ),
    );
  }

  /// Makes the actual API call to Gemini
  Future<Result<Map<String, dynamic>>> _callGeminiApi(
    List<int> videoBytes,
    VideoFile videoFile,
  ) async {
    try {
      final url = '${AppConstants.geminiApiBaseUrl}/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey';
      
      // Encode video as base64
      final base64Video = base64Encode(videoBytes);
      
      // Prepare request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': _buildAnalysisPrompt(),
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

      // Make API call
      final response = await _apiClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      return Result.success(response);
    } catch (e) {
      if (e is ApiException) {
        return Result.failure(ApiFailure(e.message, code: e.code));
      }
      return Result.failure(ApiFailure('API call failed: $e'));
    }
  }

  /// Builds the analysis prompt for Gemini
  String _buildAnalysisPrompt() {
    return '''
Analyze this video and extract step-by-step instructions for creating a manual. 

Please provide a JSON response with the following structure:
{
  "title": "Brief title for the manual",
  "steps": [
    {
      "title": "Step title",
      "description": "Detailed description of what to do in this step",
      "timestamp": 1500
    }
  ]
}

Requirements:
- Extract maximum ${AppConstants.maxManualSteps} steps
- Each step should have a clear title and detailed description
- Timestamp should be in milliseconds indicating when this action occurs in the video
- Focus on actionable steps that a user can follow
- Descriptions should be clear and concise
- Order steps chronologically based on the video timeline

Return only the JSON response, no additional text.
''';
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

      // Parse JSON from text response
      final jsonResponse = jsonDecode(textPart) as Map<String, dynamic>;
      
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
}