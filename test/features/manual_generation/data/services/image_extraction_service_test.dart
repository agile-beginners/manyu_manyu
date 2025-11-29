import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../lib/core/errors/failures.dart';
import '../../../../../lib/features/manual_generation/data/services/image_extraction_service.dart';
import '../../../../../lib/features/manual_generation/domain/entities/manual_step.dart';

void main() {
  group('ImageExtractionService', () {
    late ImageExtractionService service;

    setUp(() {
      service = ImageExtractionService();
    });

    group('extractImagesFromVideo', () {
      test('should handle non-existent video file', () async {
        // Arrange
        final steps = [
          ManualStep(
            id: '1',
            title: 'Step 1',
            description: 'First step',
            timestamp: 1000,
            stepNumber: 1,
          ),
        ];

        // Act
        final result = await service.extractImagesFromVideo(
          videoPath: '/non/existent/path.mp4',
          steps: steps,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failure, isA<VideoProcessingFailure>());
      });

      test('should handle empty steps list', () async {
        // Arrange
        final tempDir = await Directory.systemTemp.createTemp('test');
        final testVideoPath = '${tempDir.path}/test_video.mp4';
        final videoFile = File(testVideoPath);
        await videoFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

        try {
          // Act
          final result = await service.extractImagesFromVideo(
            videoPath: testVideoPath,
            steps: [],
          );

          // Assert
          expect(result.isSuccess, isTrue);
          expect(result.data!.isEmpty, isTrue);
        } finally {
          // Clean up
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      });

      test('should create service instance', () {
        // Assert
        expect(service, isNotNull);
        expect(service, isA<ImageExtractionService>());
      });
    });

    group('validation', () {
      test('should validate video file existence', () async {
        // Create a temporary file
        final tempDir = await Directory.systemTemp.createTemp('test');
        final testVideoPath = '${tempDir.path}/test_video.mp4';
        final videoFile = File(testVideoPath);
        await videoFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

        try {
          // Test with existing file - should not throw
          final result = await service.extractImagesFromVideo(
            videoPath: testVideoPath,
            steps: [],
          );
          expect(result.isSuccess, isTrue);

          // Test with non-existing file
          final result2 = await service.extractImagesFromVideo(
            videoPath: '/non/existent/path.mp4',
            steps: [],
          );
          expect(result2.isFailure, isTrue);
        } finally {
          // Clean up
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      });
    });
  });
}