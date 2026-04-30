import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/manual.dart';
import '../../domain/entities/manual_step.dart';
import 'manual_repository.dart';

/// Concrete implementation of ManualRepository using local storage
class ManualRepositoryImpl implements ManualRepository {
  static const String _manualsFileName = 'manuals.json';

  @override
  Future<Result<void>> saveManual(Manual manual) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final manualsFile = File('${appDir.path}/$_manualsFileName');
      
      List<Manual> existingManuals = [];
      
      // Load existing manuals if file exists
      if (await manualsFile.exists()) {
        final content = await manualsFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        existingManuals = jsonList.map((json) => Manual.fromJson(json)).toList();
      }
      
      // Add or update the manual
      final existingIndex = existingManuals.indexWhere((m) => m.id == manual.id);
      if (existingIndex != -1) {
        existingManuals[existingIndex] = manual;
      } else {
        existingManuals.add(manual);
      }
      
      // Save updated manuals
      final jsonList = existingManuals.map((m) => m.toJson()).toList();
      await manualsFile.writeAsString(jsonEncode(jsonList));
      
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to save manual: $e'));
    }
  }

  @override
  Future<Result<Manual?>> getManual(String id) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final manualsFile = File('${appDir.path}/$_manualsFileName');
      
      if (!await manualsFile.exists()) {
        return const Result.success(null);
      }
      
      final content = await manualsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final manuals = jsonList.map((json) => Manual.fromJson(json)).toList();
      
      final manual = manuals.where((m) => m.id == id).firstOrNull;
      return Result.success(manual);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get manual: $e'));
    }
  }

  @override
  Future<Result<void>> updateManual(Manual manual) async {
    // Update is the same as save for this implementation
    return saveManual(manual);
  }

  @override
  Future<Result<void>> deleteManual(String id) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final manualsFile = File('${appDir.path}/$_manualsFileName');
      
      if (!await manualsFile.exists()) {
        return const Result.success(null);
      }
      
      final content = await manualsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final manuals = jsonList.map((json) => Manual.fromJson(json)).toList();
      
      final updatedManuals = manuals.where((m) => m.id != id).toList();
      final updatedJsonList = updatedManuals.map((m) => m.toJson()).toList();
      
      await manualsFile.writeAsString(jsonEncode(updatedJsonList));
      
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to delete manual: $e'));
    }
  }

  @override
  Future<Result<List<Manual>>> getAllManuals() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final manualsFile = File('${appDir.path}/$_manualsFileName');
      
      if (!await manualsFile.exists()) {
        return const Result.success([]);
      }
      
      final content = await manualsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final manuals = jsonList.map((json) => Manual.fromJson(json)).toList();
      
      // Sort by updated date (newest first)
      manuals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return Result.success(manuals);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get all manuals: $e'));
    }
  }

  @override
  Future<Result<void>> saveManualStep(String manualId, ManualStep step) async {
    try {
      final manualResult = await getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return Result.failure(
          const StorageFailure('Manual not found'),
        );
      }
      
      // Add or update the step
      final existingSteps = List<ManualStep>.from(manual.steps);
      final existingIndex = existingSteps.indexWhere((s) => s.id == step.id);
      
      if (existingIndex != -1) {
        existingSteps[existingIndex] = step;
      } else {
        existingSteps.add(step);
      }
      
      // Sort steps by step number
      existingSteps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
      
      final updatedManual = manual.copyWith(
        steps: existingSteps,
        updatedAt: DateTime.now(),
      );
      
      return saveManual(updatedManual);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to save manual step: $e'));
    }
  }

  @override
  Future<Result<void>> updateManualStep(String manualId, ManualStep step) async {
    // Update is the same as save for this implementation
    return saveManualStep(manualId, step);
  }

  @override
  Future<Result<void>> deleteManualStep(String manualId, String stepId) async {
    try {
      final manualResult = await getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return Result.failure(
          const StorageFailure('Manual not found'),
        );
      }
      
      final updatedSteps = manual.steps.where((s) => s.id != stepId).toList();
      
      final updatedManual = manual.copyWith(
        steps: updatedSteps,
        updatedAt: DateTime.now(),
      );
      
      return saveManual(updatedManual);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to delete manual step: $e'));
    }
  }

  @override
  Future<Result<List<ManualStep>>> getManualSteps(String manualId) async {
    try {
      final manualResult = await getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return const Result.success([]);
      }
      
      // Return steps sorted by step number
      final sortedSteps = List<ManualStep>.from(manual.steps);
      sortedSteps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
      
      return Result.success(sortedSteps);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get manual steps: $e'));
    }
  }

  @override
  Future<Result<List<Manual>>> searchManuals(String query) async {
    try {
      final allManualsResult = await getAllManuals();
      if (allManualsResult.isFailure) {
        return Result.failure(allManualsResult.failure!);
      }
      
      final allManuals = allManualsResult.data!;
      final queryLower = query.toLowerCase();
      
      final filteredManuals = allManuals.where((manual) {
        return manual.title.toLowerCase().contains(queryLower) ||
               (manual.description?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
      
      return Result.success(filteredManuals);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to search manuals: $e'));
    }
  }

  @override
  Future<Result<List<Manual>>> getManualsByStatus(ManualStatus status) async {
    try {
      final allManualsResult = await getAllManuals();
      if (allManualsResult.isFailure) {
        return Result.failure(allManualsResult.failure!);
      }
      
      final allManuals = allManualsResult.data!;
      final filteredManuals = allManuals.where((manual) => manual.status == status).toList();
      
      return Result.success(filteredManuals);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to get manuals by status: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> exportManualAsJson(String manualId) async {
    try {
      final manualResult = await getManual(manualId);
      if (manualResult.isFailure) {
        return Result.failure(manualResult.failure!);
      }
      
      final manual = manualResult.data;
      if (manual == null) {
        return Result.failure(
          const StorageFailure('Manual not found'),
        );
      }
      
      return Result.success(manual.toJson());
    } catch (e) {
      return Result.failure(StorageFailure('Failed to export manual: $e'));
    }
  }

  @override
  Future<Result<Manual>> importManualFromJson(Map<String, dynamic> json) async {
    try {
      final manual = Manual.fromJson(json);
      final saveResult = await saveManual(manual);
      
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure!);
      }
      
      return Result.success(manual);
    } catch (e) {
      return Result.failure(StorageFailure('Failed to import manual: $e'));
    }
  }
}