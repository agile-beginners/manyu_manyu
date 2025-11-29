import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/data/repositories/manual_repository_impl.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/entities/manual.dart';
import 'package:tokyo_flutter_hackathon_2025/features/manual_generation/domain/entities/manual_step.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  group('ManualRepositoryImpl', () {
    late ManualRepositoryImpl repository;
    late Manual testManual;
    late List<ManualStep> testSteps;

    setUpAll(() {
      PathProviderPlatform.instance = MockPathProviderPlatform();
    });

    setUp(() {
      repository = ManualRepositoryImpl();
      
      testSteps = [
        ManualStep(
          id: 'step-1',
          title: 'Step 1',
          description: 'First step description',
          timestamp: 1000,
          stepNumber: 1,
        ),
        ManualStep(
          id: 'step-2',
          title: 'Step 2',
          description: 'Second step description',
          timestamp: 2000,
          stepNumber: 2,
        ),
      ];
      
      testManual = Manual(
        id: 'manual-1',
        title: 'Test Manual',
        steps: testSteps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ManualStatus.draft,
      );
    });

    tearDown(() async {
      // Clean up test files
      try {
        final tempDir = Directory.systemTemp;
        final manualsFile = File('${tempDir.path}/manuals.json');
        if (await manualsFile.exists()) {
          await manualsFile.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('should save and retrieve manual correctly', () async {
      // Act
      final saveResult = await repository.saveManual(testManual);
      final getResult = await repository.getManual(testManual.id);
      
      // Assert
      expect(saveResult.isSuccess, true);
      expect(getResult.isSuccess, true);
      expect(getResult.data, isNotNull);
      expect(getResult.data!.id, testManual.id);
      expect(getResult.data!.title, testManual.title);
      expect(getResult.data!.steps.length, testManual.steps.length);
    });

    test('should return null for non-existent manual', () async {
      // Act
      final result = await repository.getManual('non-existent-id');
      
      // Assert
      expect(result.isSuccess, true);
      expect(result.data, null);
    });

    test('should update manual correctly', () async {
      // Arrange
      await repository.saveManual(testManual);
      final updatedManual = testManual.copyWith(
        title: 'Updated Manual Title',
        status: ManualStatus.completed,
      );
      
      // Act
      final updateResult = await repository.updateManual(updatedManual);
      final getResult = await repository.getManual(testManual.id);
      
      // Assert
      expect(updateResult.isSuccess, true);
      expect(getResult.isSuccess, true);
      expect(getResult.data!.title, 'Updated Manual Title');
      expect(getResult.data!.status, ManualStatus.completed);
    });

    test('should delete manual correctly', () async {
      // Arrange
      await repository.saveManual(testManual);
      
      // Act
      final deleteResult = await repository.deleteManual(testManual.id);
      final getResult = await repository.getManual(testManual.id);
      
      // Assert
      expect(deleteResult.isSuccess, true);
      expect(getResult.isSuccess, true);
      expect(getResult.data, null);
    });

    test('should get all manuals correctly', () async {
      // Arrange
      final manual2 = testManual.copyWith(id: 'manual-2', title: 'Manual 2');
      await repository.saveManual(testManual);
      await repository.saveManual(manual2);
      
      // Act
      final result = await repository.getAllManuals();
      
      // Assert
      expect(result.isSuccess, true);
      expect(result.data!.length, 2);
      expect(result.data!.any((m) => m.id == testManual.id), true);
      expect(result.data!.any((m) => m.id == manual2.id), true);
    });

    test('should save and update manual step correctly', () async {
      // Arrange
      await repository.saveManual(testManual);
      final newStep = ManualStep(
        id: 'step-3',
        title: 'Step 3',
        description: 'Third step description',
        timestamp: 3000,
        stepNumber: 3,
      );
      
      // Act
      final saveStepResult = await repository.saveManualStep(testManual.id, newStep);
      final getResult = await repository.getManual(testManual.id);
      
      // Assert
      expect(saveStepResult.isSuccess, true);
      expect(getResult.isSuccess, true);
      expect(getResult.data!.steps.length, 3);
      expect(getResult.data!.steps.any((s) => s.id == newStep.id), true);
    });

    test('should get manual steps correctly', () async {
      // Arrange
      await repository.saveManual(testManual);
      
      // Act
      final result = await repository.getManualSteps(testManual.id);
      
      // Assert
      expect(result.isSuccess, true);
      expect(result.data!.length, 2);
      expect(result.data![0].stepNumber, 1);
      expect(result.data![1].stepNumber, 2);
    });

    test('should search manuals by title correctly', () async {
      // Arrange
      final manual2 = testManual.copyWith(
        id: 'manual-2', 
        title: 'Different Title',
      );
      await repository.saveManual(testManual);
      await repository.saveManual(manual2);
      
      // Act
      final result = await repository.searchManuals('Test');
      
      // Assert
      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data![0].id, testManual.id);
    });

    test('should get manuals by status correctly', () async {
      // Arrange
      final completedManual = testManual.copyWith(
        id: 'manual-2',
        status: ManualStatus.completed,
      );
      await repository.saveManual(testManual);
      await repository.saveManual(completedManual);
      
      // Act
      final draftResult = await repository.getManualsByStatus(ManualStatus.draft);
      final completedResult = await repository.getManualsByStatus(ManualStatus.completed);
      
      // Assert
      expect(draftResult.isSuccess, true);
      expect(draftResult.data!.length, 1);
      expect(draftResult.data![0].status, ManualStatus.draft);
      
      expect(completedResult.isSuccess, true);
      expect(completedResult.data!.length, 1);
      expect(completedResult.data![0].status, ManualStatus.completed);
    });

    test('should export and import manual as JSON correctly', () async {
      // Arrange
      await repository.saveManual(testManual);
      
      // Act
      final exportResult = await repository.exportManualAsJson(testManual.id);
      final importResult = await repository.importManualFromJson(exportResult.data!);
      
      // Assert
      expect(exportResult.isSuccess, true);
      expect(importResult.isSuccess, true);
      expect(importResult.data!.id, testManual.id);
      expect(importResult.data!.title, testManual.title);
      expect(importResult.data!.steps.length, testManual.steps.length);
    });
  });
}