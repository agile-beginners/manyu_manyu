import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/entities/manual_step.dart';

void main() {
  group('ManualStep', () {
    test('should create ManualStep with required fields', () {
      // Act
      final step = ManualStep(
        id: 'step-1',
        title: 'Step 1',
        description: 'This is the first step',
        timestamp: 5000,
        stepNumber: 1,
      );
      
      // Assert
      expect(step.id, 'step-1');
      expect(step.title, 'Step 1');
      expect(step.description, 'This is the first step');
      expect(step.timestamp, 5000);
      expect(step.stepNumber, 1);
      expect(step.imagePath, null);
      expect(step.annotatedImagePath, null);
      expect(step.isProcessed, false);
    });

    test('should create ManualStep with optional fields', () {
      // Act
      final step = ManualStep(
        id: 'step-1',
        title: 'Step 1',
        description: 'This is the first step',
        timestamp: 5000,
        imagePath: '/path/to/image.jpg',
        annotatedImagePath: '/path/to/annotated.jpg',
        stepNumber: 1,
        isProcessed: true,
      );
      
      // Assert
      expect(step.imagePath, '/path/to/image.jpg');
      expect(step.annotatedImagePath, '/path/to/annotated.jpg');
      expect(step.isProcessed, true);
    });

    test('should serialize to and from JSON correctly', () {
      // Arrange
      final originalStep = ManualStep(
        id: 'step-1',
        title: 'Step 1',
        description: 'This is the first step',
        timestamp: 5000,
        imagePath: '/path/to/image.jpg',
        annotatedImagePath: '/path/to/annotated.jpg',
        stepNumber: 1,
        isProcessed: true,
      );
      
      // Act
      final json = originalStep.toJson();
      final deserializedStep = ManualStep.fromJson(json);
      
      // Assert
      expect(deserializedStep.id, originalStep.id);
      expect(deserializedStep.title, originalStep.title);
      expect(deserializedStep.description, originalStep.description);
      expect(deserializedStep.timestamp, originalStep.timestamp);
      expect(deserializedStep.imagePath, originalStep.imagePath);
      expect(deserializedStep.annotatedImagePath, originalStep.annotatedImagePath);
      expect(deserializedStep.stepNumber, originalStep.stepNumber);
      expect(deserializedStep.isProcessed, originalStep.isProcessed);
    });

    test('should create copy with updated fields', () {
      // Arrange
      final originalStep = ManualStep(
        id: 'step-1',
        title: 'Step 1',
        description: 'This is the first step',
        timestamp: 5000,
        stepNumber: 1,
      );
      
      // Act
      final updatedStep = originalStep.copyWith(
        title: 'Updated Step 1',
        imagePath: '/path/to/image.jpg',
        isProcessed: true,
      );
      
      // Assert
      expect(updatedStep.id, originalStep.id);
      expect(updatedStep.title, 'Updated Step 1');
      expect(updatedStep.description, originalStep.description);
      expect(updatedStep.timestamp, originalStep.timestamp);
      expect(updatedStep.imagePath, '/path/to/image.jpg');
      expect(updatedStep.stepNumber, originalStep.stepNumber);
      expect(updatedStep.isProcessed, true);
    });

    test('should implement equality correctly', () {
      // Arrange
      final step1 = ManualStep(
        id: 'step-1',
        title: 'Step 1',
        description: 'This is the first step',
        timestamp: 5000,
        stepNumber: 1,
      );
      
      final step2 = ManualStep(
        id: 'step-1',
        title: 'Step 1',
        description: 'This is the first step',
        timestamp: 5000,
        stepNumber: 1,
      );
      
      final step3 = ManualStep(
        id: 'step-2',
        title: 'Step 1',
        description: 'This is the first step',
        timestamp: 5000,
        stepNumber: 1,
      );
      
      // Assert
      expect(step1, equals(step2));
      expect(step1, isNot(equals(step3)));
      expect(step1.hashCode, equals(step2.hashCode));
    });
  });
}