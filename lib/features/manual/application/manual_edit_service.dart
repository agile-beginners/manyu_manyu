import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../data/repositories/manual_repository.dart';
import '../data/repositories/manual_repository_impl.dart';
import '../domain/entities/manual.dart';
import '../domain/entities/manual_step.dart';

class ManualEditService {
  final Ref _ref;

  ManualEditService(this._ref);

  ManualRepository get _repository => _ref.read(manualRepositoryProvider);

  Future<Result<Manual>> updateManualTitle(
      String manualId, String newTitle) async {
    try {
      // タイトルを検証する
      if (newTitle.trim().isEmpty) {
        return const Result.failure(
            ValidationFailure('Title cannot be empty'));
      }

      // 既存のマニュアルを取得する
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }

      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }

      // 新しいタイトルでマニュアルを更新する
      final updatedManual = manual.copyWith(
        title: newTitle.trim(),
        updatedAt: DateTime.now(),
      );

      // 更新されたマニュアルを保存する
      final saveResult = await _repository.updateManual(updatedManual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      _ref.invalidate(manualProvider(manualId));
      _ref.invalidate(allManualsProvider);

      return Result.success(updatedManual);
    } catch (e) {
      return Result.failure(
          StorageFailure('Failed to update manual title: $e'));
    }
  }

  Future<Result<Manual>> updateManualDescription(
      String manualId, String? newDescription) async {
    try {
      // 既存のマニュアルを取得する
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }

      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }

      // 新しい説明でマニュアルを更新する
      final updatedManual = manual.copyWith(
        description: newDescription?.trim(),
        updatedAt: DateTime.now(),
      );

      // 更新されたマニュアルを保存する
      final saveResult = await _repository.updateManual(updatedManual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      _ref.invalidate(manualProvider(manualId));
      _ref.invalidate(allManualsProvider);

      return Result.success(updatedManual);
    } catch (e) {
      return Result.failure(
          StorageFailure('Failed to update manual description: $e'));
    }
  }

  Future<Result<ManualStep>> updateStepTitle(
      String manualId, String stepId, String newTitle) async {
    try {
      // タイトルを検証する
      if (newTitle.trim().isEmpty) {
        return const Result.failure(
            ValidationFailure('Step title cannot be empty'));
      }

      // 既存のマニュアルを取得する
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }

      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }

      // 更新するステップを見つける
      final step = manual.getStepById(stepId);
      if (step == null) {
        return const Result.failure(StorageFailure('Step not found'));
      }

      // 新しいタイトルでステップを更新する
      final updatedStep = step.copyWith(title: newTitle.trim());

      // 更新されたステップを保存する
      final saveResult =
          await _repository.updateManualStep(manualId, updatedStep);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      _ref.invalidate(manualProvider(manualId));
      _ref.invalidate(allManualsProvider);

      return Result.success(updatedStep);
    } catch (e) {
      return Result.failure(
          StorageFailure('Failed to update step title: $e'));
    }
  }

  Future<Result<ManualStep>> updateStepDescription(
      String manualId, String stepId, String newDescription) async {
    try {
      // 説明を検証する
      if (newDescription.trim().isEmpty) {
        return const Result.failure(
            ValidationFailure('Step description cannot be empty'));
      }

      // 既存のマニュアルを取得する
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }

      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }

      // 更新するステップを見つける
      final step = manual.getStepById(stepId);
      if (step == null) {
        return const Result.failure(StorageFailure('Step not found'));
      }

      // 新しい説明でステップを更新する
      final updatedStep =
          step.copyWith(description: newDescription.trim());

      // 更新されたステップを保存する
      final saveResult =
          await _repository.updateManualStep(manualId, updatedStep);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      _ref.invalidate(manualProvider(manualId));
      _ref.invalidate(allManualsProvider);

      return Result.success(updatedStep);
    } catch (e) {
      return Result.failure(
          StorageFailure('Failed to update step description: $e'));
    }
  }

  Future<Result<ManualStep>> updateStep(
      String manualId, ManualStep updatedStep) async {
    try {
      // ステップを検証する
      final validationResult = validateStep(updatedStep);
      if (validationResult.isFailure) {
        return Result.failure(validationResult.failure!);
      }

      // 更新されたステップを保存する
      final saveResult =
          await _repository.updateManualStep(manualId, updatedStep);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      _ref.invalidate(manualProvider(manualId));
      _ref.invalidate(allManualsProvider);

      return Result.success(updatedStep);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to update step: $e'));
    }
  }

  Future<Result<Manual>> reorderSteps(
      String manualId, List<String> stepIds) async {
    try {
      // 既存のマニュアルを取得する
      final manualResult = await _repository.getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }

      final manual = manualResult.data;
      if (manual == null) {
        return const Result.failure(StorageFailure('Manual not found'));
      }

      // 全てのステップIDが存在することを検証する
      if (stepIds.length != manual.steps.length) {
        return const Result.failure(
            ValidationFailure('Step count mismatch'));
      }

      // 指定された順序でステップを並び替える
      final reorderedSteps = <ManualStep>[];
      for (int i = 0; i < stepIds.length; i++) {
        final step = manual.getStepById(stepIds[i]);
        if (step == null) {
          return Result.failure(
              StorageFailure('Step with ID ${stepIds[i]} not found'));
        }
        // 新しい順序に合わせてステップ番号を更新する
        reorderedSteps.add(step.copyWith(stepNumber: i + 1));
      }

      // 並び替えたステップでマニュアルを更新する
      final updatedManual = manual.copyWith(
        steps: reorderedSteps,
        updatedAt: DateTime.now(),
      );

      // 更新されたマニュアルを保存する
      final saveResult = await _repository.updateManual(updatedManual);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }

      _ref.invalidate(manualProvider(manualId));
      _ref.invalidate(allManualsProvider);

      return Result.success(updatedManual);
    } catch (e) {
      return Result.failure(
          StorageFailure('Failed to reorder steps: $e'));
    }
  }

  Result<bool> validateManual(Manual manual) {
    try {
      // タイトルを確認する
      if (manual.title.trim().isEmpty) {
        return const Result.failure(
            ValidationFailure('Manual title cannot be empty'));
      }

      // ステップを確認する
      if (manual.steps.isEmpty) {
        return const Result.failure(
            ValidationFailure('Manual must have at least one step'));
      }

      // 各ステップを検証する
      for (final step in manual.steps) {
        final stepValidation = validateStep(step);
        if (stepValidation.isFailure) {
          return stepValidation;
        }
      }

      return const Result.success(true);
    } catch (e) {
      return Result.failure(
          ValidationFailure('Manual validation failed: $e'));
    }
  }

  Result<bool> validateStep(ManualStep step) {
    try {
      // タイトルを確認する
      if (step.title.trim().isEmpty) {
        return const Result.failure(
            ValidationFailure('Step title cannot be empty'));
      }

      // 説明を確認する
      if (step.description.trim().isEmpty) {
        return const Result.failure(
            ValidationFailure('Step description cannot be empty'));
      }

      // タイムスタンプを確認する
      if (step.timestamp < 0) {
        return const Result.failure(
            ValidationFailure('Step timestamp must be non-negative'));
      }

      // ステップ番号を確認する
      if (step.stepNumber <= 0) {
        return const Result.failure(
            ValidationFailure('Step number must be positive'));
      }

      return const Result.success(true);
    } catch (e) {
      return Result.failure(
          ValidationFailure('Step validation failed: $e'));
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// ManualRepositoryのプロバイダー
final manualRepositoryProvider = Provider<ManualRepository>((ref) {
  return ManualRepositoryImpl();
});

/// ManualEditServiceのプロバイダー
final manualEditServiceProvider = Provider<ManualEditService>((ref) {
  return ManualEditService(ref);
});

/// 特定のマニュアルをidで取得するプロバイダー
final manualProvider =
    FutureProvider.family<Manual?, String>((ref, manualId) async {
  final repo = ref.watch(manualRepositoryProvider);
  final result = await repo.getManual(manualId);
  if (result.isFailure) return null;
  return result.data;
});

/// 全マニュアルを取得するプロバイダー
final allManualsProvider = FutureProvider<List<Manual>>((ref) async {
  final repo = ref.watch(manualRepositoryProvider);
  final result = await repo.getAllManuals();
  if (result.isFailure) return [];
  return result.data ?? [];
});

/// マニュアルのステップ数のプロバイダー
final manualStepCountProvider =
    Provider.family<int, String>((ref, manualId) {
  return ref.watch(manualProvider(manualId)).valueOrNull?.stepCount ?? 0;
});

/// マニュアルがエクスポート可能かどうかのプロバイダー
final canExportManualProvider =
    Provider.family<bool, String>((ref, manualId) {
  final manual = ref.watch(manualProvider(manualId)).valueOrNull;
  if (manual == null) return false;
  return manual.hasSteps && manual.status == ManualStatus.draft;
});
