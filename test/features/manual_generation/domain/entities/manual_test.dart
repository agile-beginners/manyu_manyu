import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/entities/manual.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/entities/manual_step.dart';

void main() {
  group('Manual', () {
    late List<ManualStep> testSteps;
    
    setUp(() {
      testSteps = [
        ManualStep(
          id: 'step-1',
          title: 'Step 1',
          description: 'First step',
          timestamp: 1000,
          stepNumber: 1,
        ),
        ManualStep(
          id: 'step-2',
          title: 'Step 2',
          description: 'Second step',
          timestamp: 2000,
          stepNumber: 2,
        ),
      ];
    });

    test('should create Manual with required fields', () {
      // Arrange
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      
      // Act
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      // Assert
      expect(manual.id, 'manual-1');
      expect(manual.title, 'Test Manual');
      expect(manual.steps, testSteps);
      expect(manual.createdAt, createdAt);
      expect(manual.updatedAt, updatedAt);
      expect(manual.videoPath, null);
      expect(manual.videoDurationMs, null);
      expect(manual.status, ManualStatus.draft);
      expect(manual.description, null);
    });

    test('should create Manual with optional fields', () {
      // Act
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoPath: '/path/to/video.mp4',
        videoDurationMs: 60000,
        status: ManualStatus.completed,
        description: 'Test description',
      );
      
      // Assert
      expect(manual.videoPath, '/path/to/video.mp4');
      expect(manual.videoDurationMs, 60000);
      expect(manual.status, ManualStatus.completed);
      expect(manual.description, 'Test description');
    });

    test('should serialize to and from JSON correctly', () {
      // Arrange
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      final originalManual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: createdAt,
        updatedAt: updatedAt,
        videoPath: '/path/to/video.mp4',
        videoDurationMs: 60000,
        status: ManualStatus.completed,
        description: 'Test description',
      );
      
      // Act
      final json = originalManual.toJson();
      final deserializedManual = Manual.fromJson(json);
      
      // Assert
      expect(deserializedManual.id, originalManual.id);
      expect(deserializedManual.title, originalManual.title);
      expect(deserializedManual.steps.length, originalManual.steps.length);
      expect(deserializedManual.createdAt, originalManual.createdAt);
      expect(deserializedManual.updatedAt, originalManual.updatedAt);
      expect(deserializedManual.videoPath, originalManual.videoPath);
      expect(deserializedManual.videoDurationMs, originalManual.videoDurationMs);
      expect(deserializedManual.status, originalManual.status);
      expect(deserializedManual.description, originalManual.description);
    });

    test('should return correct step count and hasSteps', () {
      // Arrange
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final emptyManual = Manual(
        id: 'manual-2',
        title: 'Empty Manual',
        steps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Assert
      expect(manual.stepCount, 2);
      expect(manual.hasSteps, true);
      expect(emptyManual.stepCount, 0);
      expect(emptyManual.hasSteps, false);
    });

    test('should get step at index correctly', () {
      // Arrange
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(manual.getStepAt(0), testSteps[0]);
      expect(manual.getStepAt(1), testSteps[1]);
      expect(manual.getStepAt(-1), null);
      expect(manual.getStepAt(2), null);
    });

    test('should get step by ID correctly', () {
      // Arrange
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(manual.getStepById('step-1'), testSteps[0]);
      expect(manual.getStepById('step-2'), testSteps[1]);
      expect(manual.getStepById('non-existent'), null);
    });

    test('should update step at index correctly', () {
      // Arrange
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final updatedStep = testSteps[0].copyWith(title: 'Updated Step 1');
      
      // Act
      final updatedManual = manual.updateStepAt(0, updatedStep);
      
      // Assert
      expect(updatedManual.steps[0].title, 'Updated Step 1');
      expect(updatedManual.steps[1], testSteps[1]); // Other steps unchanged
      expect(updatedManual.updatedAt.isAfter(manual.updatedAt), true);
    });

    test('should update step by ID correctly', () {
      // Arrange
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final updatedStep = testSteps[0].copyWith(title: 'Updated Step 1');
      
      // Act
      final updatedManual = manual.updateStepById('step-1', updatedStep);
      
      // Assert
      expect(updatedManual.steps[0].title, 'Updated Step 1');
      expect(updatedManual.steps[1], testSteps[1]); // Other steps unchanged
    });

    test('should handle invalid update operations gracefully', () {
      // Arrange
      final manual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final updatedStep = testSteps[0].copyWith(title: 'Updated Step 1');
      
      // Act & Assert
      expect(manual.updateStepAt(-1, updatedStep), manual); // No change
      expect(manual.updateStepAt(10, updatedStep), manual); // No change
      expect(manual.updateStepById('non-existent', updatedStep), manual); // No change
    });
  });

  group('ManualStatus', () {
    test('should have correct JSON values', () {
      expect(ManualStatus.generating.name, 'generating');
      expect(ManualStatus.draft.name, 'draft');
      expect(ManualStatus.completed.name, 'completed');
      expect(ManualStatus.failed.name, 'failed');
    });
  });
}