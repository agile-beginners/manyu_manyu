import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../manual_generation/data/repositories/manual_repository_impl.dart';
import '../../../manual_generation/domain/entities/manual.dart';
import '../../../manual_generation/domain/entities/manual_step.dart';
import '../../../manual_generation/domain/repositories/manual_repository.dart';
import '../../data/services/manual_edit_service_impl.dart';
import '../../domain/services/manual_edit_service.dart';

/// Provider for ManualRepository
final manualRepositoryProvider = Provider<ManualRepository>((ref) {
  return ManualRepositoryImpl();
});

/// Provider for ManualEditService
final manualEditServiceProvider = Provider<ManualEditService>((ref) {
  final repository = ref.watch(manualRepositoryProvider);
  return ManualEditServiceDataImpl(repository);
});

/// Provider for getting a specific manual by ID
final manualProvider = FutureProvider.family<Manual?, String>((ref, manualId) async {
  final repository = ref.watch(manualRepositoryProvider);
  final result = await repository.getManual(manualId);
  
  if (result.isSuccess) {
    return result.data;
  } else {
    throw Exception(result.failure.toString());
  }
});

/// Provider for getting all manuals
final allManualsProvider = FutureProvider<List<Manual>>((ref) async {
  final repository = ref.watch(manualRepositoryProvider);
  final result = await repository.getAllManuals();
  
  if (result.isSuccess) {
    return result.data!;
  } else {
    throw Exception(result.failure.toString());
  }
});

/// State notifier for managing manual editing state
class ManualEditNotifier extends StateNotifier<AsyncValue<Manual?>> {
  final ManualEditService _editService;
  final ManualRepository _repository;
  
  ManualEditNotifier(this._editService, this._repository) : super(const AsyncValue.data(null));
  
  /// Loads a manual by ID
  Future<void> loadManual(String manualId) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _repository.getManual(manualId);
      
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(result.failure.toString(), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Updates the manual title
  Future<void> updateManualTitle(String manualId, String newTitle) async {
    if (state.value == null) return;
    
    try {
      final result = await _editService.updateManualTitle(manualId, newTitle);
      
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(result.failure.toString(), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Updates the manual description
  Future<void> updateManualDescription(String manualId, String? newDescription) async {
    if (state.value == null) return;
    
    try {
      final result = await _editService.updateManualDescription(manualId, newDescription);
      
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(result.failure.toString(), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Updates a step's title
  Future<void> updateStepTitle(String manualId, String stepId, String newTitle) async {
    if (state.value == null) return;
    
    try {
      final result = await _editService.updateStepTitle(manualId, stepId, newTitle);
      
      if (result.isSuccess) {
        // Reload the manual to get the updated state
        await loadManual(manualId);
      } else {
        state = AsyncValue.error(result.failure.toString(), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Updates a step's description
  Future<void> updateStepDescription(String manualId, String stepId, String newDescription) async {
    if (state.value == null) return;
    
    try {
      final result = await _editService.updateStepDescription(manualId, stepId, newDescription);
      
      if (result.isSuccess) {
        // Reload the manual to get the updated state
        await loadManual(manualId);
      } else {
        state = AsyncValue.error(result.failure.toString(), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Updates a complete step
  Future<void> updateStep(String manualId, ManualStep updatedStep) async {
    if (state.value == null) return;
    
    try {
      final result = await _editService.updateStep(manualId, updatedStep);
      
      if (result.isSuccess) {
        // Reload the manual to get the updated state
        await loadManual(manualId);
      } else {
        state = AsyncValue.error(result.failure.toString(), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Reorders the steps in the manual
  Future<void> reorderSteps(String manualId, List<String> stepIds) async {
    if (state.value == null) return;
    
    try {
      final result = await _editService.reorderSteps(manualId, stepIds);
      
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(result.failure.toString(), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Validates the current manual
  Result<bool> validateManual() {
    if (state.value == null) {
      return const Result.failure(ValidationFailure('No manual loaded'));
    }
    
    return _editService.validateManual(state.value!);
  }
  
  /// Validates a specific step
  Result<bool> validateStep(ManualStep step) {
    return _editService.validateStep(step);
  }
}

/// Provider for ManualEditNotifier
final manualEditNotifierProvider = StateNotifierProvider<ManualEditNotifier, AsyncValue<Manual?>>((ref) {
  final editService = ref.watch(manualEditServiceProvider);
  final repository = ref.watch(manualRepositoryProvider);
  return ManualEditNotifier(editService, repository);
});

/// Provider for tracking editing state of individual fields
final editingStateProvider = StateProvider<Map<String, bool>>((ref) {
  return {};
});

/// Provider for tracking unsaved changes
final unsavedChangesProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider for auto-save functionality
final autoSaveProvider = Provider<AutoSaveService>((ref) {
  final editService = ref.watch(manualEditServiceProvider);
  return AutoSaveService(editService);
});

/// Service for handling auto-save functionality
class AutoSaveService {
  final ManualEditService _editService;
  
  AutoSaveService(this._editService);
  
  /// Auto-saves a manual title change
  Future<Result<Manual>> autoSaveManualTitle(String manualId, String newTitle) async {
    // Add debouncing logic here if needed
    return await _editService.updateManualTitle(manualId, newTitle);
  }
  
  /// Auto-saves a manual description change
  Future<Result<Manual>> autoSaveManualDescription(String manualId, String? newDescription) async {
    // Add debouncing logic here if needed
    return await _editService.updateManualDescription(manualId, newDescription);
  }
  
  /// Auto-saves a step title change
  Future<Result<ManualStep>> autoSaveStepTitle(String manualId, String stepId, String newTitle) async {
    // Add debouncing logic here if needed
    return await _editService.updateStepTitle(manualId, stepId, newTitle);
  }
  
  /// Auto-saves a step description change
  Future<Result<ManualStep>> autoSaveStepDescription(String manualId, String stepId, String newDescription) async {
    // Add debouncing logic here if needed
    return await _editService.updateStepDescription(manualId, stepId, newDescription);
  }
}