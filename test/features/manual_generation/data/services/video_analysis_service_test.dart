import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tokyo_flutter_hackathon_2025/core/errors/failures.dart';
import 'package:tokyo_flutter_hackathon_2025/core/utils/result.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/data/services/video_analysis_service.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/entities/manual.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/entities/manual_step.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/repositories/manual_repository.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/services/gemini_service.dart';
import 'package:tokyo_flutter_hackathon_2025/features/video_upload/domain/entities/video_file.dart';

import 'video_analysis_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GeminiService>(), MockSpec<ManualRepository>()])
void main() {
  // Provide dummy values for Result types
  provideDummy<Result<void>>(const Result.success(null));
  provideDummy<Result<Manual?>>(const Result.success(null));
  provideDummy<Result<List<ManualStep>>>(const Result.success([]));

  group('VideoAnalysisService', () {
    late VideoAnalysisService videoAnalysisService;
    late MockGeminiService mockGeminiService;
    late MockManualRepository mockManualRepository;

    setUp(() {
      mockGeminiService = MockGeminiService();
      mockManualRepository = MockManualRepository();
      videoAnalysisService = VideoAnalysisService(
        geminiService: mockGeminiService,
        manualRepository: mockManualRepository,
      );
    });

    group('analyzeVideoAndCreateManual', () {
      late VideoFile testVideoFile;
      late List<ManualStep> testSteps;

      setUp(() {
        testVideoFile = VideoFile(
          path: 'test_video.mp4',
          name: 'test_video.mp4',
          sizeInBytes: 1024 * 1024,
          format: 'mp4',
          durationMs: 30000,
          createdAt: DateTime.now(),
        );

        testSteps = [
          const ManualStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            timestamp: 1000,
            stepNumber: 1,
          ),
          const ManualStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Second step',
            timestamp: 2000,
            stepNumber: 2,
          ),
        ];
      });

      test('should successfully create manual when analysis succeeds', () async {
        // Arrange
        when(mockManualRepository.saveManual(any))
            .thenAnswer((_) async => const Result.success(null));
        when(mockGeminiService.analyzeVideo(any))
            .thenAnswer((_) async => Result.success(testSteps));
        when(mockManualRepository.updateManual(any))
            .thenAnswer((_) async => const Result.success(null));

        // Act
        final result = await videoAnalysisService.analyzeVideoAndCreateManual(testVideoFile);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.steps.length, 2);
        expect(result.data!.status, ManualStatus.draft);
        expect(result.data!.videoPath, testVideoFile.path);

        // Verify interactions
        verify(mockManualRepository.saveManual(any)).called(1);
        verify(mockGeminiService.analyzeVideo(testVideoFile)).called(1);
        verify(mockManualRepository.updateManual(any)).called(1);
      });

      test('should handle Gemini service failure', () async {
        // Arrange
        when(mockManualRepository.saveManual(any))
            .thenAnswer((_) async => const Result.success(null));
        when(mockGeminiService.analyzeVideo(any))
            .thenAnswer((_) async => Result.failure(const ApiFailure('Analysis failed')));
        when(mockManualRepository.updateManual(any))
            .thenAnswer((_) async => const Result.success(null));

        // Act
        final result = await videoAnalysisService.analyzeVideoAndCreateManual(testVideoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ApiFailure>());
        expect(result.failure!.message, 'Analysis failed');

        // Verify that manual status was updated to failed
        verify(mockManualRepository.updateManual(argThat(
          predicate<Manual>((manual) => manual.status == ManualStatus.failed),
        ))).called(1);
      });

      test('should handle repository save failure', () async {
        // Arrange
        when(mockManualRepository.saveManual(any))
            .thenAnswer((_) async => Result.failure(const StorageFailure('Save failed')));

        // Act
        final result = await videoAnalysisService.analyzeVideoAndCreateManual(testVideoFile);

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<StorageFailure>());
        expect(result.failure!.message, 'Save failed');

        // Verify that Gemini service was not called
        verifyNever(mockGeminiService.analyzeVideo(any));
      });

      test('should use custom title when provided', () async {
        // Arrange
        const customTitle = 'Custom Manual Title';
        when(mockManualRepository.saveManual(any))
            .thenAnswer((_) async => const Result.success(null));
        when(mockGeminiService.analyzeVideo(any))
            .thenAnswer((_) async => Result.success(testSteps));
        when(mockManualRepository.updateManual(any))
            .thenAnswer((_) async => const Result.success(null));

        // Act
        final result = await videoAnalysisService.analyzeVideoAndCreateManual(
          testVideoFile,
          customTitle: customTitle,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.title, customTitle);
      });
    });

    group('retryAnalysis', () {
      late Manual testManual;

      setUp(() {
        testManual = Manual(
          id: 'manual1',
          title: 'Test Manual',
          steps: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          videoPath: 'test_video.mp4',
          videoDurationMs: 30000,
          status: ManualStatus.failed,
        );
      });

      test('should successfully retry analysis', () async {
        // Arrange
        when(mockManualRepository.getManual('manual1'))
            .thenAnswer((_) async => Result.success(testManual));
        when(mockManualRepository.updateManual(any))
            .thenAnswer((_) async => const Result.success(null));
        when(mockManualRepository.saveManual(any))
            .thenAnswer((_) async => const Result.success(null));
        when(mockGeminiService.analyzeVideo(any))
            .thenAnswer((_) async => Result.success([
              const ManualStep(
                id: 'step1',
                title: 'Retry Step',
                description: 'Retry description',
                timestamp: 1000,
                stepNumber: 1,
              ),
            ]));

        // Act
        final result = await videoAnalysisService.retryAnalysis('manual1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.steps.length, 1);
        expect(result.data!.status, ManualStatus.draft);

        // Verify interactions
        verify(mockManualRepository.getManual('manual1')).called(1);
        verify(mockManualRepository.updateManual(argThat(
          predicate<Manual>((manual) => manual.status == ManualStatus.generating),
        ))).called(1);
      });

      test('should handle manual not found', () async {
        // Arrange
        when(mockManualRepository.getManual('manual1'))
            .thenAnswer((_) async => const Result.success(null));

        // Act
        final result = await videoAnalysisService.retryAnalysis('manual1');

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, 'Manual not found');
      });

      test('should handle manual without video path', () async {
        // Arrange
        final manualWithoutVideo = Manual(
          id: testManual.id,
          title: testManual.title,
          steps: testManual.steps,
          createdAt: testManual.createdAt,
          updatedAt: testManual.updatedAt,
          videoPath: null, // Explicitly set to null
          videoDurationMs: testManual.videoDurationMs,
          status: testManual.status,
        );
        when(mockManualRepository.getManual('manual1'))
            .thenAnswer((_) async => Result.success(manualWithoutVideo));

        // Act
        final result = await videoAnalysisService.retryAnalysis('manual1');

        // Assert
        expect(result.isFailure, true);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, 'No video path found for manual');
      });
    });
  });
}