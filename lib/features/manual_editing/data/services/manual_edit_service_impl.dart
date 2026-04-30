import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../manual/domain/entities/manual.dart';
import '../../../manual/domain/entities/manual_step.dart';
import '../../../manual/data/repositories/manual_repository.dart';

class ManualEditServiceDataImpl {
  final ManualRepository _repository;
  
  const ManualEditServiceDataImpl(this._repository);

  Future<Result<Manual>> updateManualTitle(String manualId, String newTitle) async {
    try {
      // Validate title
      if (newTitle.trim().isEmpty) {
        return const Result.failure(ValidationFailure('Title cannot be empty'));
      }
      
      // Get existing manual
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }
      
      // Update manual with new title
      final updatedManual = manual.copyWith(
        title: newTitle.trim(),
        updatedAt: DateTime.now(),
      );
      
      // Save updated manual
      final saveResult = await _repository.updateManual(updatedManual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }
      
      return Result.success(updatedManual);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to update manual title: $e'));
    }
  }
  
  Future<Result<Manual>> updateManualDescription(String manualId, String? newDescription) async {
    try {
      // Get existing manual
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }
      
      // Update manual with new description
      final updatedManual = manual.copyWith(
        description: newDescription?.trim(),
        updatedAt: DateTime.now(),
      );
      
      // Save updated manual
      final saveResult = await _repository.updateManual(updatedManual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }
      
      return Result.success(updatedManual);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to update manual description: $e'));
    }
  }
  
  Future<Result<ManualStep>> updateStepTitle(String manualId, String stepId, String newTitle) async {
    try {
      // Validate title
      if (newTitle.trim().isEmpty) {
        return const Result.failure(ValidationFailure('Step title cannot be empty'));
      }
      
      // Get existing manual
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }
      
      // Find the step to update
      final step = manual.getStepById(stepId);
      if (step == null) {
        return const Result.failure(StorageFailure('Step not found'));
      }
      
      // Update step with new title
      final updatedStep = step.copyWith(title: newTitle.trim());
      
      // Save updated step
      final saveResult = await _repository.updateManualStep(manualId, updatedStep);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }
      
      return Result.success(updatedStep);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to update step title: $e'));
    }
  }
  
  Future<Result<ManualStep>> updateStepDescription(String manualId, String stepId, String newDescription) async {
    try {
      // Validate description
      if (newDescription.trim().isEmpty) {
        return const Result.failure(ValidationFailure('Step description cannot be empty'));
      }
      
      // Get existing manual
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }
      
      // Find the step to update
      final step = manual.getStepById(stepId);
      if (step == null) {
        return const Result.failure(StorageFailure('Step not found'));
      }
      
      // Update step with new description
      final updatedStep = step.copyWith(description: newDescription.trim());
      
      // Save updated step
      final saveResult = await _repository.updateManualStep(manualId, updatedStep);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }
      
      return Result.success(updatedStep);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to update step description: $e'));
    }
  }
  
  Future<Result<ManualStep>> updateStep(String manualId, ManualStep updatedStep) async {
    try {
      // Validate step
      final validationResult = validateStep(updatedStep);
      if (validationResult.isFailure) {
        return Result.failure(validationResult.failure!);
      }
      
      // Save updated step
      final saveResult = await _repository.updateManualStep(manualId, updatedStep);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }
      
      return Result.success(updatedStep);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to update step: $e'));
    }
  }
  
  Future<Result<Manual>> reorderSteps(String manualId, List<String> stepIds) async {
    try {
      // Get existing manual
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }
      
      // Validate that all step IDs exist
      if (stepIds.length != manual.steps.length) {
        return const Result.failure(ValidationFailure('Step count mismatch'));
      }
      
      // Reorder steps according to the provided order
      final reorderedSteps = <ManualStep>[];
      for (int i = 0; i < stepIds.length; i++) {
        final step = manual.getStepById(stepIds[i]);
        if (step == null) {
          return Result.failure(StorageFailure('Step with ID ${stepIds[i]} not found'));
        }
        // Update step number to match new order
        reorderedSteps.add(step.copyWith(stepNumber: i + 1));
      }
      
      // Update manual with reordered steps
      final updatedManual = manual.copyWith(
        steps: reorderedSteps,
        updatedAt: DateTime.now(),
      );
      
      // Save updated manual
      final saveResult = await _repository.updateManual(updatedManual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }
      
      return Result.success(updatedManual);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to reorder steps: $e'));
    }
  }
  
  Result<bool> validateManual(Manual manual) {
    try {
      // Check title
      if (manual.title.trim().isEmpty) {
        return const Result.failure(ValidationFailure('Manual title cannot be empty'));
      }
      
      // Check steps
      if (manual.steps.isEmpty) {
        return const Result.failure(ValidationFailure('Manual must have at least one step'));
      }
      
      // Validate each step
      for (final step in manual.steps) {
        final stepValidation = validateStep(step);
        if (stepValidation.isFailure) {
          return stepValidation;
        }
      }
      
      return const Result.success(true);
    } catch (e) {
      return Result.failure(ValidationFailure('Manual validation failed: $e'));
    }
  }
  
  Result<bool> validateStep(ManualStep step) {
    try {
      // Check title
      if (step.title.trim().isEmpty) {
        return const Result.failure(ValidationFailure('Step title cannot be empty'));
      }
      
      // Check description
      if (step.description.trim().isEmpty) {
        return const Result.failure(ValidationFailure('Step description cannot be empty'));
      }
      
      // Check timestamp
      if (step.timestamp < 0) {
        return const Result.failure(ValidationFailure('Step timestamp must be non-negative'));
      }
      
      // Check step number
      if (step.stepNumber <= 0) {
        return const Result.failure(ValidationFailure('Step number must be positive'));
      }
      
      return const Result.success(true);
    } catch (e) {
      return Result.failure(ValidationFailure('Step validation failed: $e'));
    }
  }
}