import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../../application/manual_edit_service.dart';
import '../../../application/manual_export_service.dart';
import '../../../domain/entities/manual.dart';
import '../../../domain/entities/manual_step.dart';

/// Controller for managing manual editing state.
class ManualEditController extends StateNotifier<AsyncValue<Manual?>> {
  final Ref _ref;

  ManualEditController(this._ref) : super(const AsyncValue.data(null));

  ManualEditService get _editService => _ref.read(manualEditServiceProvider);
  ManualExportService get _exportService =>
      _ref.read(manualExportServiceProvider);

  /// Loads a manual by ID.
  Future<void> loadManual(String manualId) async {
    state = const AsyncValue.loading();
    try {
      final manual = await _ref.read(manualProvider(manualId).future);
      state = AsyncValue.data(manual);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates the manual title.
  Future<void> updateManualTitle(String manualId, String newTitle) async {
    if (state.value == null) return;
    try {
      final result = await _editService.updateManualTitle(manualId, newTitle);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(
            result.failure.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates the manual description.
  Future<void> updateManualDescription(
      String manualId, String? newDescription) async {
    if (state.value == null) return;
    try {
      final result =
          await _editService.updateManualDescription(manualId, newDescription);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(
            result.failure.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates a step's title.
  Future<void> updateStepTitle(
      String manualId, String stepId, String newTitle) async {
    if (state.value == null) return;
    try {
      final result =
          await _editService.updateStepTitle(manualId, stepId, newTitle);
      if (result.isSuccess) {
        await loadManual(manualId);
      } else {
        state = AsyncValue.error(
            result.failure.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates a step's description.
  Future<void> updateStepDescription(
      String manualId, String stepId, String newDescription) async {
    if (state.value == null) return;
    try {
      final result = await _editService.updateStepDescription(
          manualId, stepId, newDescription);
      if (result.isSuccess) {
        await loadManual(manualId);
      } else {
        state = AsyncValue.error(
            result.failure.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates a complete step.
  Future<void> updateStep(String manualId, ManualStep updatedStep) async {
    if (state.value == null) return;
    try {
      final result = await _editService.updateStep(manualId, updatedStep);
      if (result.isSuccess) {
        await loadManual(manualId);
      } else {
        state = AsyncValue.error(
            result.failure.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reorders the steps in the manual.
  Future<void> reorderSteps(String manualId, List<String> stepIds) async {
    if (state.value == null) return;
    try {
      final result = await _editService.reorderSteps(manualId, stepIds);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(
            result.failure.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Validates the currently loaded manual.
  Result<bool> validateManual() {
    if (state.value == null) {
      return const Result.failure(ValidationFailure('No manual loaded'));
    }
    return _editService.validateManual(state.value!);
  }

  /// Validates a specific step.
  Result<bool> validateStep(ManualStep step) {
    return _editService.validateStep(step);
  }

  /// Exports the manual to PDF and returns the saved file path.
  Future<Result<String>> exportManual(String manualId) async {
    try {
      return await _exportService.exportManual(manualId);
    } catch (e) {
      return Result.failure(
          PdfGenerationFailure('Failed to export: $e'));
    }
  }
}

/// Provider for [ManualEditController].
final manualEditControllerProvider =
    StateNotifierProvider<ManualEditController, AsyncValue<Manual?>>((ref) {
  return ManualEditController(ref);
});

/// Provider for tracking editing state of individual fields.
final editingStateProvider = StateProvider<Map<String, bool>>((ref) {
  return {};
});

/// Provider for tracking unsaved changes.
final unsavedChangesProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider for auto-save functionality.
final autoSaveProvider = Provider<AutoSaveService>((ref) {
  final editService = ref.watch(manualEditServiceProvider);
  return AutoSaveService(editService);
});

/// Service for handling auto-save functionality.
class AutoSaveService {
  final ManualEditService _editService;

  AutoSaveService(this._editService);

  /// Auto-saves a manual title change.
  Future<Result<Manual>> autoSaveManualTitle(
      String manualId, String newTitle) async {
    return _editService.updateManualTitle(manualId, newTitle);
  }

  /// Auto-saves a manual description change.
  Future<Result<Manual>> autoSaveManualDescription(
      String manualId, String? newDescription) async {
    return _editService.updateManualDescription(manualId, newDescription);
  }

  /// Auto-saves a step title change.
  Future<Result<ManualStep>> autoSaveStepTitle(
      String manualId, String stepId, String newTitle) async {
    return _editService.updateStepTitle(manualId, stepId, newTitle);
  }

  /// Auto-saves a step description change.
  Future<Result<ManualStep>> autoSaveStepDescription(
      String manualId, String stepId, String newDescription) async {
    return _editService.updateStepDescription(manualId, stepId, newDescription);
  }
}
