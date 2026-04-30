import '../../../../core/utils/result.dart';
import '../../domain/entities/manual.dart';
import '../../domain/entities/manual_step.dart';

/// Repository interface for manual operations
abstract class ManualRepository {
  /// Saves a manual to local storage
  Future<Result<void>> saveManual(Manual manual);
  
  /// Retrieves a manual by its ID
  Future<Result<Manual?>> getManual(String id);
  
  /// Updates an existing manual
  Future<Result<void>> updateManual(Manual manual);
  
  /// Deletes a manual by its ID
  Future<Result<void>> deleteManual(String id);
  
  /// Lists all manuals
  Future<Result<List<Manual>>> getAllManuals();
  
  /// Saves a manual step
  Future<Result<void>> saveManualStep(String manualId, ManualStep step);
  
  /// Updates a manual step
  Future<Result<void>> updateManualStep(String manualId, ManualStep step);
  
  /// Deletes a manual step
  Future<Result<void>> deleteManualStep(String manualId, String stepId);
  
  /// Gets all steps for a manual
  Future<Result<List<ManualStep>>> getManualSteps(String manualId);
  
  /// Searches manuals by title or description
  Future<Result<List<Manual>>> searchManuals(String query);
  
  /// Gets manuals by status
  Future<Result<List<Manual>>> getManualsByStatus(ManualStatus status);
  
  /// Exports manual data as JSON
  Future<Result<Map<String, dynamic>>> exportManualAsJson(String manualId);
  
  /// Imports manual data from JSON
  Future<Result<Manual>> importManualFromJson(Map<String, dynamic> json);
}