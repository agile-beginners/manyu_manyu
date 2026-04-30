import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:tokyo_flutter_hackathon_2025/core/constants/app_constants.dart';
import 'package:tokyo_flutter_hackathon_2025/core/errors/failures.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual/data/services/gemini_video_analysis_service.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual/domain/entities/manual_step.dart';
import 'package:tokyo_flutter_hackathon_2025/features/video/domain/entities/video_file.dart';

// Reuse MockApiClient generated in gemini_service_test.mocks.dart
import 'gemini_service_test.mocks.dart';

void main() {
  group('GeminiVideoAnalysisService (VideoAnalysisService contract)', () {
    late GeminiVideoAnalysisService service;
    late MockApiClient mockApiClient;
    const testApiKey = 'test-api-key';

    setUp(() {
      mockApiClient = MockApiClient();
      service = GeminiVideoAnalysisService(
        apiClient: mockApiClient,
        apiKey: testApiKey,
      );
    });

    group('analyzeVideo', () {
      test('should return failure when video file does not exist', () async {
        final videoFile = VideoFile(
          path: 'non_existent_file.mp4',
          name: 'non_existent_file.mp4',
          sizeInBytes: 1024,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        final result = await service.analyzeVideo(videoFile);

        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, contains('Video file does not exist'));
      });

      test('should return failure for unsupported video format', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mkv');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final videoFile = VideoFile(
          path: testFile.path,
          name: 'test_video.mkv',
          sizeInBytes: 1024,
          format: 'mkv',
          createdAt: DateTime.now(),
        );

        final result = await service.analyzeVideo(videoFile);

        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, contains('Unsupported video format'));

        await tempDir.delete(recursive: true);
      });

      test('should return failure for oversized video file', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/large_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final videoFile = VideoFile(
          path: testFile.path,
          name: 'large_video.mp4',
          sizeInBytes: AppConstants.maxVideoSizeBytes + 1,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        final result = await service.analyzeVideo(videoFile);

        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, contains('Video file too large'));

        await tempDir.delete(recursive: true);
      });

      test('should return failure when API returns too many steps', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final videoFile = VideoFile(
          path: testFile.path,
          name: 'test_video.mp4',
          sizeInBytes: 1024,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        final steps = List.generate(AppConstants.maxManualSteps + 1, (i) => {
          'title': 'Step ${i + 1}',
          'description': 'Description ${i + 1}',
          'timestamp': (i + 1) * 1000,
        });

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': jsonEncode({'title': 'Test Manual', 'steps': steps})}
                ]
              }
            }
          ]
        };

        when(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        final result = await service.analyzeVideo(videoFile);

        expect(result.isFailure, true);
        expect(result.failure, isA<ApiFailure>());
        expect(result.failure!.message, contains('Too many steps extracted'));

        await tempDir.delete(recursive: true);
      });

      test('should successfully analyze video and return steps', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final videoFile = VideoFile(
          path: testFile.path,
          name: 'test_video.mp4',
          sizeInBytes: 1024,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'title': 'Test Manual',
                      'steps': [
                        {'title': 'Step 1', 'description': 'First step', 'timestamp': 1000},
                        {'title': 'Step 2', 'description': 'Second step', 'timestamp': 2000},
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

        final result = await service.analyzeVideo(videoFile);

        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.length, 2);
        expect(result.data![0], isA<ManualStep>());
        expect(result.data![0].title, 'Step 1');
        expect(result.data![0].stepNumber, 1);
        expect(result.data![1].title, 'Step 2');
        expect(result.data![1].stepNumber, 2);

        await tempDir.delete(recursive: true);
      });

      test('should pass manualInfo to API call', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final videoFile = VideoFile(
          path: testFile.path,
          name: 'test_video.mp4',
          sizeInBytes: 1024,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'title': 'Test',
                      'steps': [
                        {'title': 'Step 1', 'description': 'Desc', 'timestamp': 1000},
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

        final result = await service.analyzeVideo(videoFile, manualInfo: 'Extra context');

        expect(result.isSuccess, true);
        verify(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);

        await tempDir.delete(recursive: true);
      });

      test('should return failure when API throws exception', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final videoFile = VideoFile(
          path: testFile.path,
          name: 'test_video.mp4',
          sizeInBytes: 1024,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        when(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenThrow(Exception('Network error'));

        final result = await service.analyzeVideo(videoFile);

        expect(result.isFailure, true);
        expect(result.failure, isA<ApiFailure>());
        expect(result.failure!.message, contains('Failed after'));

        await tempDir.delete(recursive: true);
      });

      test('should return failure when API response is malformed', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_video.mp4');
        await testFile.writeAsBytes([1, 2, 3, 4]);

        final videoFile = VideoFile(
          path: testFile.path,
          name: 'test_video.mp4',
          sizeInBytes: 1024,
          format: 'mp4',
          createdAt: DateTime.now(),
        );

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'not valid json at all'}
                ]
              }
            }
          ]
        };

        when(mockApiClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        final result = await service.analyzeVideo(videoFile);

        expect(result.isFailure, true);
        expect(result.failure, isA<ApiFailure>());

        await tempDir.delete(recursive: true);
      });
    });
  });
}
