import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tokyo_flutter_hackathon_2025/core/constants/app_constants.dart';
import 'package:tokyo_flutter_hackathon_2025/core/errors/failures.dart';
import 'package:tokyo_flutter_hackathon_2025/core/network/api_client.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual/data/services/gemini_video_analysis_service.dart';
import 'package:tokyo_flutter_hackathon_2025/features/video/domain/entities/video_file.dart';

import 'gemini_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('GeminiVideoAnalysisService', () {
    late GeminiVideoAnalysisService geminiService;
    late MockApiClient mockApiClient;
    const testApiKey = 'test-api-key';

    setUp(() {
      mockApiClient = MockApiClient();
      geminiService = GeminiVideoAnalysisService(
        apiClient: mockApiClient,
        apiKey: testApiKey,
      );
    });

    group('analyzeVideo', () {
      late VideoFile testVideoFile;

      setUp(() {
        testVideoFile = VideoFile(
          path: 'test/fixtures/test_video.mp4',
          name: 'test_video.mp4',
          sizeInBytes: 1024 * 1024, // 1MB
          format: 'mp4',
          durationMs: 30000,
          createdAt: DateTime.now(),
        );
      });

      test('should return failure when video file does not exist', () async {
        // Arrange
        final nonExistentVideoFile = VideoFile(
          path: 'non_existent_file.mp4',
          name: 'non_existent_file.mp4',
          sizeInBytes: 1024,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        // Act
        final result = await geminiService.analyzeVideo(nonExistentVideoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, contains('Video file does not exist'));
      });

      test('should return failure for unsupported video format', () async {
        // Arrange
        // Create a temporary test file with unsupported format
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mkv');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Dummy video data

        final unsupportedVideoFile = VideoFile(
          path: testFile.path,
          name: 'test_video.mkv',
          sizeInBytes: 1024,
          format: 'mkv',
          createdAt: DateTime.now(),
        );

        // Act
        final result = await geminiService.analyzeVideo(unsupportedVideoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, contains('Unsupported video format'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should return failure for oversized video file', () async {
        // Arrange
        // Create a temporary test file
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/large_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Dummy video data

        final oversizedVideoFile = VideoFile(
          path: testFile.path,
          name: 'large_video.mp4',
          sizeInBytes: AppConstants.maxVideoSizeBytes + 1,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        // Act
        final result = await geminiService.analyzeVideo(oversizedVideoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, contains('Video file too large'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should return failure when too many steps are extracted', () async {
        // Arrange
        // Create a temporary test file
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Dummy video data

        final videoFile = testVideoFile.copyWith(path: testFile.path);

        // Mock API response with too many steps
        final steps = List.generate(AppConstants.maxManualSteps + 1, (index) => {
          'title': 'Step ${index + 1}',
          'description': 'Description for step ${index + 1}',
          'timestamp': (index + 1) * 1000,
        });

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'title': 'Test Manual',
                      'steps': steps,
                    }),
                  }
                ]
              }
            }
          ]
        };

        when(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await geminiService.analyzeVideo(videoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ApiFailure>());
        expect(result.failure!.message, contains('Too many steps extracted'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should successfully analyze video and return manual steps', () async {
        // Arrange
        // Create a temporary test file
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Dummy video data

        final videoFile = testVideoFile.copyWith(path: testFile.path);

        // Mock successful API response
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'title': 'Test Manual',
                      'steps': [
                        {
                          'title': 'Step 1',
                          'description': 'First step description',
                          'timestamp': 1000,
                        },
                        {
                          'title': 'Step 2',
                          'description': 'Second step description',
                          'timestamp': 2000,
                        },
                      ],
                    }),
                  }
                ]
              }
            }
          ]
        };

        when(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await geminiService.analyzeVideo(videoFile);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.length, 2);
        
        final firstStep = result.data![0];
        expect(firstStep.title, 'Step 1');
        expect(firstStep.description, 'First step description');
        expect(firstStep.timestamp, 1000);
        expect(firstStep.stepNumber, 1);
        expect(firstStep.isProcessed, false);

        final secondStep = result.data![1];
        expect(secondStep.title, 'Step 2');
        expect(secondStep.description, 'Second step description');
        expect(secondStep.timestamp, 2000);
        expect(secondStep.stepNumber, 2);

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle API errors gracefully', () async {
        // Arrange
        // Create a temporary test file
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Dummy video data

        final videoFile = testVideoFile.copyWith(path: testFile.path);

        when(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenThrow(Exception('Network error'));

        // Act
        final result = await geminiService.analyzeVideo(videoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ApiFailure>());
        expect(result.failure!.message, contains('Failed after'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle malformed API response', () async {
        // Arrange
        // Create a temporary test file
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]); // Dummy video data

        final videoFile = testVideoFile.copyWith(path: testFile.path);

        // Mock malformed API response
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Invalid JSON response',
                  }
                ]
              }
            }
          ]
        };

        when(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await geminiService.analyzeVideo(videoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ApiFailure>());

        // Cleanup
        await tempDir.delete(recursive: true);
      });
    });
  });
}