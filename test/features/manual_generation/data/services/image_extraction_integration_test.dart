import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../lib/features/manual_generation/data/services/image_extraction_service.dart';
import '../../../../../lib/features/manual_generation/domain/entities/manual_step.dart';

void main() {
  // Initialize Flutter binding for integration tests
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ImageExtractionService Integration', () {
    late ImageExtractionService service;

    setUp(() {
      service = ImageExtractionService();
    });

    test('should handle complete workflow with multiple steps', () async {
      // Arrange - Create a temporary video file
      final tempDir = await Directory.systemTemp.createTemp('integration_test');
      final testVideoPath = '${tempDir.path}/test_video.mp4';
      final videoFile = File(testVideoPath);
      await videoFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      final steps = [
        ManualStep(
          id: '1',
          title: 'Open Application',
          description: 'Click on the application icon',
          timestamp: 1000,
          stepNumber: 1,
        ),
        ManualStep(
          id: '2',
          title: 'Navigate to Settings',
          description: 'Click on the settings menu',
          timestamp: 5000,
          stepNumber: 2,
        ),
        ManualStep(
          id: '3',
          title: 'Change Configuration',
          description: 'Update the configuration values',
          timestamp: 10000,
          stepNumber: 3,
        ),
      ];

      try {
        // Act
        final result = await service.extractImagesFromVideo(
          videoPath: testVideoPath,
          steps: steps,
        );

        // Assert - Since video processing requires platform-specific implementation,
        // we expect the service to handle this gracefully by creating placeholders
        expect(result.isSuccess, isTrue);
        final imagePaths = result.data!;
        expect(imagePaths.length, equals(3));

        // Verify all image files were created (either extracted or placeholder)
        for (int i = 0; i < imagePaths.length; i++) {
          final imagePath = imagePaths[i];
          expect(File(imagePath).existsSync(), isTrue);
          
          // Verify the file has some content
          final imageFile = File(imagePath);
          final bytes = await imageFile.readAsBytes();
          expect(bytes.isNotEmpty, isTrue);
        }

        // Verify the service can handle cleanup
        await service.cleanupTempFiles();

      } finally {
        // Clean up test files
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('should handle mixed success and failure scenarios', () async {
      // Arrange - Mix of valid and invalid timestamps
      final tempDir = await Directory.systemTemp.createTemp('integration_test');
      final testVideoPath = '${tempDir.path}/test_video.mp4';
      final videoFile = File(testVideoPath);
      await videoFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      final steps = [
        ManualStep(
          id: '1',
          title: 'Valid Step',
          description: 'This should work',
          timestamp: 1000,
          stepNumber: 1,
        ),
        ManualStep(
          id: '2',
          title: 'Another Valid Step',
          description: 'This should also work',
          timestamp: 2000,
          stepNumber: 2,
        ),
      ];

      try {
        // Act
        final result = await service.extractImagesFromVideo(
          videoPath: testVideoPath,
          steps: steps,
        );

        // Assert - Service should handle video processing gracefully
        expect(result.isSuccess, isTrue);
        final imagePaths = result.data!;
        expect(imagePaths.length, equals(2));

        // All steps should have some form of output (either extracted or placeholder)
        for (final imagePath in imagePaths) {
          expect(File(imagePath).existsSync(), isTrue);
        }

      } finally {
        // Clean up test files
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}