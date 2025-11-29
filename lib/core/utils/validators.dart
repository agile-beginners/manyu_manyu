import 'dart:io';
import '../constants/app_constants.dart';
import 'file_utils.dart';

/// Utility class for validation functions
class Validators {
  /// Validates a video file
  static ValidationResult validateVideoFile(File file) {
    // Check if file exists
    if (!file.existsSync()) {
      return ValidationResult.invalid('File does not exist');
    }
    
    // Check file format
    if (!FileUtils.isValidVideoFormat(file.path)) {
      return ValidationResult.invalid(
        'Unsupported video format. Supported formats: ${AppConstants.supportedVideoFormats.join(', ')}',
      );
    }
    
    // Check file size
    if (!FileUtils.isValidFileSize(file)) {
      final sizeInMB = (FileUtils.getFileSize(file) / (1024 * 1024)).toStringAsFixed(1);
      final maxSizeInMB = (AppConstants.maxVideoSizeBytes / (1024 * 1024)).toStringAsFixed(0);
      return ValidationResult.invalid(
        'File size ($sizeInMB MB) exceeds maximum allowed size ($maxSizeInMB MB)',
      );
    }
    
    return ValidationResult.valid();
  }
  
  /// Validates manual step count
  static ValidationResult validateStepCount(int stepCount) {
    if (stepCount < 1) {
      return ValidationResult.invalid('Manual must have at least 1 step');
    }
    
    if (stepCount > AppConstants.maxManualSteps) {
      return ValidationResult.invalid(
        'Manual cannot have more than ${AppConstants.maxManualSteps} steps',
      );
    }
    
    return ValidationResult.valid();
  }
  
  /// Validates step title
  static ValidationResult validateStepTitle(String title) {
    if (title.trim().isEmpty) {
      return ValidationResult.invalid('Step title cannot be empty');
    }
    
    if (title.length > 100) {
      return ValidationResult.invalid('Step title cannot exceed 100 characters');
    }
    
    return ValidationResult.valid();
  }
  
  /// Validates step description
  static ValidationResult validateStepDescription(String description) {
    if (description.trim().isEmpty) {
      return ValidationResult.invalid('Step description cannot be empty');
    }
    
    if (description.length > 500) {
      return ValidationResult.invalid('Step description cannot exceed 500 characters');
    }
    
    return ValidationResult.valid();
  }
  
  /// Validates timestamp
  static ValidationResult validateTimestamp(int timestamp) {
    if (timestamp < 0) {
      return ValidationResult.invalid('Timestamp cannot be negative');
    }
    
    return ValidationResult.valid();
  }
  
  /// Validates manual title
  static ValidationResult validateManualTitle(String title) {
    if (title.trim().isEmpty) {
      return ValidationResult.invalid('Manual title cannot be empty');
    }
    
    if (title.length > 200) {
      return ValidationResult.invalid('Manual title cannot exceed 200 characters');
    }
    
    return ValidationResult.valid();
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult._(this.isValid, this.errorMessage);
  
  /// Creates a valid result
  const ValidationResult.valid() : this._(true, null);
  
  /// Creates an invalid result with an error message
  const ValidationResult.invalid(String errorMessage) : this._(false, errorMessage);
  
  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $errorMessage';
  }
}