import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../../application/manual_edit_service.dart';
import '../../../application/manual_export_service.dart';
import '../../../domain/entities/manual.dart';
import '../../../domain/entities/manual_step.dart';

/// マニュアル編集の状態を管理するコントローラー
class ManualEditController extends StateNotifier<AsyncValue<Manual?>> {
  final Ref _ref;

  ManualEditController(this._ref) : super(const AsyncValue.data(null));

  ManualEditService get _editService => _ref.read(manualEditServiceProvider);
  ManualExportService get _exportService =>
      _ref.read(manualExportServiceProvider);

  /// IDでマニュアルを読み込む
  Future<void> loadManual(String manualId) async {
    state = const AsyncValue.loading();
    try {
      final manual = await _ref.read(manualProvider(manualId).future);
      state = AsyncValue.data(manual);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// マニュアルのタイトルを更新する
  Future<void> updateManualTitle(String manualId, String newTitle) async {
    if (state.value == null) return;
    try {
      final result = await _editService.updateManualTitle(manualId, newTitle);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(
            result.failure!.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// マニュアルの説明を更新する
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
            result.failure!.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ステップのタイトルを更新する
  Future<void> updateStepTitle(
      String manualId, String stepId, String newTitle) async {
    if (state.value == null) return;
    try {
      final result =
          await _editService.updateStepTitle(manualId, stepId, newTitle);
      if (result.isSuccess) {
        final currentManual = state.value;
        if (currentManual != null) {
          final updatedManual = currentManual.updateStepById(stepId, result.data!);
          state = AsyncValue.data(updatedManual);
        }
      } else {
        state = AsyncValue.error(
            result.failure!.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ステップの説明を更新する
  Future<void> updateStepDescription(
      String manualId, String stepId, String newDescription) async {
    if (state.value == null) return;
    try {
      final result = await _editService.updateStepDescription(
          manualId, stepId, newDescription);
      if (result.isSuccess) {
        final currentManual = state.value;
        if (currentManual != null) {
          final updatedManual = currentManual.updateStepById(stepId, result.data!);
          state = AsyncValue.data(updatedManual);
        }
      } else {
        state = AsyncValue.error(
            result.failure!.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ステップ全体を更新する
  Future<void> updateStep(String manualId, ManualStep updatedStep) async {
    if (state.value == null) return;
    try {
      final result = await _editService.updateStep(manualId, updatedStep);
      if (result.isSuccess) {
        final currentManual = state.value;
        if (currentManual != null) {
          final updatedManual = currentManual.updateStepById(updatedStep.id, result.data!);
          state = AsyncValue.data(updatedManual);
        }
      } else {
        state = AsyncValue.error(
            result.failure!.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// マニュアル内のステップを並び替える
  Future<void> reorderSteps(String manualId, List<String> stepIds) async {
    if (state.value == null) return;
    try {
      final result = await _editService.reorderSteps(manualId, stepIds);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data);
      } else {
        state = AsyncValue.error(
            result.failure!.toString(), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 現在読み込まれているマニュアルを検証する
  Result<bool> validateManual() {
    if (state.value == null) {
      return const Result.failure(ValidationFailure('No manual loaded'));
    }
    return _editService.validateManual(state.value!);
  }

  /// 特定のステップを検証する
  Result<bool> validateStep(ManualStep step) {
    return _editService.validateStep(step);
  }

  /// マニュアルをPDFにエクスポートして保存ファイルパスを返す
  Future<Result<String>> exportManual(String manualId) async {
    try {
      return await _exportService.exportManual(manualId);
    } catch (e) {
      return Result.failure(
          PdfGenerationFailure('Failed to export: $e'));
    }
  }
}

/// [ManualEditController]のプロバイダー
final manualEditControllerProvider =
    StateNotifierProvider<ManualEditController, AsyncValue<Manual?>>((ref) {
  return ManualEditController(ref);
});
