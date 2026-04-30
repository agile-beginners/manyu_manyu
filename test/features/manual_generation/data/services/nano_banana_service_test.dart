import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokyo_flutter_hackathon_2025/core/errors/failures.dart';
import 'package:tokyo_flutter_hackathon_2025/core/network/api_client.dart';
import 'package:tokyo_flutter_hackathon_2025/core/utils/result.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual/data/services/gemini_image_service.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual/data/services/nano_banana_service.dart';

// Simple mock implementation for testing
class MockGeminiImageService extends GeminiImageService {
  final String? _mockResult;
  final bool _shouldFail;

  MockGeminiImageService({
    String? mockResult,
    bool shouldFail = false,
  }) : _mockResult = mockResult,
       _shouldFail = shouldFail,
       super(
         apiClient: ApiClient(),
         apiKey: 'test_key',
       );

  @override
  Future<Result<String>> generateAnnotatedImage({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  }) async {
    if (_shouldFail) {
      return Result.failure(const ApiFailure('Mock failure'));
    }
    return Result.success(_mockResult ?? originalImagePath);
  }
}

void main() {
  group('NanoBananaService', () {
    late NanoBananaService service;
    late MockGeminiImageService mockFallbackService;
    
    const testApiKey = 'test_api_key';
    const testBaseUrl = 'https://api.nanobanana.com';
    const testImagePath = '/test/image.jpg';
    const testStepTitle = 'Test Step';
    const testStepDescription = 'Test step description';
    const testStepNumber = 1;

    setUp(() {
      mockFallbackService = MockGeminiImageService();
      
      service = NanoBananaService(
        apiClient: ApiClient(),
        apiKey: testApiKey,
        baseUrl: testBaseUrl,
        fallbackService: mockFallbackService,
      );
    });

    group('generateAnnotatedImage', () {
      test('should return original path when image file does not exist', () async {
        // Act
        final result = await service.generateAnnotatedImage(
          originalImagePath: '/nonexistent/image.jpg',
          stepTitle: testStepTitle,
          stepDescription: testStepDescription,
          stepNumber: testStepNumber,
        );

        // Assert - Should fallback to original path as per requirement 4.4
        expect(result.isSuccess, true);
        expect(result.data, '/nonexistent/image.jpg');
      });

      test('should return original path when step number is invalid', () async {
        // Arrange - Create a temporary test image file
        final tempDir = await Directory.systemTemp.createTemp('test_images');
        final testFile = File('${tempDir.path}/test.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Minimal file content

        // Act
        final result = await service.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: testStepTitle,
          stepDescription: testStepDescription,
          stepNumber: 0, // Invalid step number
        );

        // Assert - Should fallback to original path as per requirement 4.4
        expect(result.isSuccess, true);
        expect(result.data, testFile.path);

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should return original path when step title is empty', () async {
        // Arrange - Create a temporary test image file
        final tempDir = await Directory.systemTemp.createTemp('test_images');
        final testFile = File('${tempDir.path}/test.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        // Act
        final result = await service.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: '', // Empty title
          stepDescription: testStepDescription,
          stepNumber: testStepNumber,
        );

        // Assert - Should fallback to original path as per requirement 4.4
        expect(result.isSuccess, true);
        expect(result.data, testFile.path);

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should use fallback service when Nano Banana API fails', () async {
        // Arrange - Create a temporary test image file
        final tempDir = await Directory.systemTemp.createTemp('test_images');
        final testFile = File('${tempDir.path}/test.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        const expectedAnnotatedPath = '/fallback/annotated.jpg';
        
        final fallbackService = MockGeminiImageService(mockResult: expectedAnnotatedPath);
        final testService = NanoBananaService(
          apiClient: ApiClient(),
          apiKey: testApiKey,
          baseUrl: testBaseUrl,
          fallbackService: fallbackService,
        );

        // Act
        final result = await testService.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: testStepTitle,
          stepDescription: testStepDescription,
          stepNumber: testStepNumber,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, expectedAnnotatedPath);

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should return original image path when both API and fallback fail', () async {
        // Arrange - Create a temporary test image file
        final tempDir = await Directory.systemTemp.createTemp('test_images');
        final testFile = File('${tempDir.path}/test.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final failingFallbackService = MockGeminiImageService(shouldFail: true);
        final testService = NanoBananaService(
          apiClient: ApiClient(),
          apiKey: testApiKey,
          baseUrl: testBaseUrl,
          fallbackService: failingFallbackService,
        );

        // Act
        final result = await testService.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: testStepTitle,
          stepDescription: testStepDescription,
          stepNumber: testStepNumber,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, testFile.path); // Should return original path as ultimate fallback

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle exceptions gracefully and return original image path', () async {
        // Arrange - Create a temporary test image file
        final tempDir = await Directory.systemTemp.createTemp('test_images');
        final testFile = File('${tempDir.path}/test.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final failingFallbackService = MockGeminiImageService(shouldFail: true);
        final testService = NanoBananaService(
          apiClient: ApiClient(),
          apiKey: testApiKey,
          baseUrl: testBaseUrl,
          fallbackService: failingFallbackService,
        );

        // Act
        final result = await testService.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: testStepTitle,
          stepDescription: testStepDescription,
          stepNumber: testStepNumber,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, testFile.path); // Should return original path as ultimate fallback

        // Cleanup
        await tempDir.delete(recursive: true);
      });
    });

    group('validation', () {
      test('should validate step number range correctly', () async {
        // Arrange - Create a temporary test image file
        final tempDir = await Directory.systemTemp.createTemp('test_images');
        final testFile = File('${tempDir.path}/test.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        // Test valid step numbers
        final successFallbackService = MockGeminiImageService(mockResult: '/annotated/path.jpg');
        final testService = NanoBananaService(
          apiClient: ApiClient(),
          apiKey: testApiKey,
          baseUrl: testBaseUrl,
          fallbackService: successFallbackService,
        );

        for (int stepNumber in [1, 10, 20]) {
          final result = await testService.generateAnnotatedImage(
            originalImagePath: testFile.path,
            stepTitle: testStepTitle,
            stepDescription: testStepDescription,
            stepNumber: stepNumber,
          );

          expect(result.isSuccess, true, reason: 'Step number $stepNumber should be valid');
        }

        // Test invalid step numbers - should fallback to original path
        final fallbackService = MockGeminiImageService(shouldFail: true);
        final fallbackTestService = NanoBananaService(
          apiClient: ApiClient(),
          apiKey: testApiKey,
          baseUrl: testBaseUrl,
          fallbackService: fallbackService,
        );

        for (int stepNumber in [0, -1, 21, 100]) {
          final result = await fallbackTestService.generateAnnotatedImage(
            originalImagePath: testFile.path,
            stepTitle: testStepTitle,
            stepDescription: testStepDescription,
            stepNumber: stepNumber,
          );

          expect(result.isSuccess, true, reason: 'Should fallback to original path for invalid step number $stepNumber');
          expect(result.data, testFile.path);
        }

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should validate text fields correctly', () async {
        // Arrange - Create a temporary test image file
        final tempDir = await Directory.systemTemp.createTemp('test_images');
        final testFile = File('${tempDir.path}/test.jpg');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        // Test empty title
        final result1 = await service.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: '',
          stepDescription: testStepDescription,
          stepNumber: testStepNumber,
        );
        expect(result1.isSuccess, true); // Should fallback to original path
        expect(result1.data, testFile.path);

        // Test whitespace-only title
        final result2 = await service.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: '   ',
          stepDescription: testStepDescription,
          stepNumber: testStepNumber,
        );
        expect(result2.isSuccess, true); // Should fallback to original path
        expect(result2.data, testFile.path);

        // Test empty description
        final result3 = await service.generateAnnotatedImage(
          originalImagePath: testFile.path,
          stepTitle: testStepTitle,
          stepDescription: '',
          stepNumber: testStepNumber,
        );
        expect(result3.isSuccess, true); // Should fallback to original path
        expect(result3.data, testFile.path);

        // Cleanup
        await tempDir.delete(recursive: true);
      });
    });
  });
}