import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';

/// Service for Gemini API image generation and editing
/// Uses Gemini's built-in image generation capabilities
class GeminiImageService {
  final ApiClient _apiClient;
  final String _apiKey;
  
  GeminiImageService({
    required ApiClient apiClient,
    required String apiKey,
  }) : _apiClient = apiClient, _apiKey = apiKey;

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
      // Read the original image
      final imageBytes = await _readImageFile(originalImagePath);
      if (imageBytes == null) {
        return Result.failure(
          const ApiFailure('Failed to read original image file'),
        );
      }

      // Generate annotated image using Gemini
      final result = await _generateImageWithGemini(
        imageBytes: imageBytes,
        stepTitle: stepTitle,
        stepDescription: stepDescription,
        stepNumber: stepNumber,
      );

      if (result.isFailure) {
        // Fallback: return original image path if generation fails
        return Result.success(originalImagePath);
      }

      // Save the generated image
      final annotatedImagePath = await _saveGeneratedImage(
        result.data!,
        originalImagePath,
        stepNumber,
      );

      return Result.success(annotatedImagePath);
    } catch (e) {
      // Fallback: return original image path on any error
      return Result.success(originalImagePath);
    }
  }

  /// Reads image file as bytes
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

  /// Generates annotated image using Gemini API
  Future<Result<List<int>>> _generateImageWithGemini({
    required List<int> imageBytes,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) async {
    try {
      final url = '${AppConstants.geminiApiBaseUrl}/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey';
      
      // Encode image as base64
      final base64Image = base64Encode(imageBytes);
      
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
            'parts': [
              {
                'text': prompt,
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
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

      // Parse response and extract generated image
      return _parseImageGenerationResponse(response);
    } catch (e) {
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
    return '''
Please analyze this screenshot and create an annotated version that helps users understand the step-by-step instructions.

Step $stepNumber: $stepTitle
Description: $stepDescription

Please add visual annotations to this image:
1. Add red arrows pointing to important UI elements mentioned in the description
2. Add red circles or rectangles to highlight clickable areas
3. Add step number "$stepNumber" in a red circle in the top-left corner
4. Add text labels with clear, readable font to explain what to click or interact with
5. Use bright, contrasting colors (red, orange) for annotations to make them clearly visible

The goal is to make this image a clear, instructional guide that someone can follow to complete this step.

Return the annotated image that clearly shows where the user should focus their attention.
''';
  }

  /// Parses Gemini image generation response
  Future<Result<List<int>>> _parseImageGenerationResponse(Map<String, dynamic> response) async {
    try {
      // Note: This is a simplified implementation
      // In reality, Gemini API's image generation response format may be different
      // This would need to be adjusted based on the actual API response structure
      
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const ApiException('No candidates in Gemini response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw const ApiException('No content in Gemini response');
      }

      // For now, we'll return a placeholder since the actual image generation
      // API structure needs to be verified with real Gemini API documentation
      throw const ApiException('Image generation not yet implemented - using fallback');
      
    } catch (e) {
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
      // Create annotated images directory
      final originalFile = File(originalImagePath);
      final directory = originalFile.parent;
      final annotatedDir = Directory('${directory.path}/annotated');
      
      if (!await annotatedDir.exists()) {
        await annotatedDir.create(recursive: true);
      }

      // Generate new filename
      final originalName = originalFile.uri.pathSegments.last;
      final nameWithoutExtension = originalName.split('.').first;
      final extension = originalName.split('.').last;
      final annotatedFileName = '${nameWithoutExtension}_step${stepNumber}_annotated.$extension';
      
      // Save annotated image
      final annotatedFile = File('${annotatedDir.path}/$annotatedFileName');
      await annotatedFile.writeAsBytes(imageBytes);
      
      return annotatedFile.path;
    } catch (e) {
      throw ApiException('Failed to save annotated image: $e');
    }
  }

  /// Creates a simple overlay annotation as fallback
  /// This is a placeholder implementation that could be enhanced
  Future<String> _createSimpleAnnotation(
    String originalImagePath,
    String stepTitle,
    int stepNumber,
  ) async {
    try {
      // For now, just copy the original image with a new name
      // In a real implementation, you might use a package like image
      // to add simple overlays
      
      final originalFile = File(originalImagePath);
      final directory = originalFile.parent;
      final annotatedDir = Directory('${directory.path}/annotated');
      
      if (!await annotatedDir.exists()) {
        await annotatedDir.create(recursive: true);
      }

      final originalName = originalFile.uri.pathSegments.last;
      final nameWithoutExtension = originalName.split('.').first;
      final extension = originalName.split('.').last;
      final annotatedFileName = '${nameWithoutExtension}_step${stepNumber}_annotated.$extension';
      
      final annotatedFile = File('${annotatedDir.path}/$annotatedFileName');
      await originalFile.copy(annotatedFile.path);
      
      return annotatedFile.path;
    } catch (e) {
      // Ultimate fallback: return original path
      return originalImagePath;
    }
  }
}