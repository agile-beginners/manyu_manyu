import 'package:json_annotation/json_annotation.dart';

part 'manual_step.g.dart';

/// Represents a single step in a manual
@JsonSerializable()
class ManualStep {
  /// Unique identifier for the step
  final String id;
  
  /// Title of the step
  final String title;
  
  /// Detailed description of the step
  final String description;
  
  /// Timestamp in the video where this step occurs (in milliseconds)
  final int timestamp;
  
  /// Path to the image associated with this step (optional)
  final String? imagePath;
  
  /// Path to the annotated image (processed by Nano Banana API)
  final String? annotatedImagePath;
  
  /// Order/sequence number of this step in the manual
  final int stepNumber;
  
  /// Whether this step has been processed by AI
  final bool isProcessed;

  const ManualStep({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.imagePath,
    this.annotatedImagePath,
    required this.stepNumber,
    this.isProcessed = false,
  });

  /// Creates a ManualStep from JSON
  factory ManualStep.fromJson(Map<String, dynamic> json) => _$ManualStepFromJson(json);

  /// Converts ManualStep to JSON
  Map<String, dynamic> toJson() => _$ManualStepToJson(this);

  /// Creates a copy of this ManualStep with updated fields
  ManualStep copyWith({
    String? id,
    String? title,
    String? description,
    int? timestamp,
    String? imagePath,
    String? annotatedImagePath,
    int? stepNumber,
    bool? isProcessed,
  }) {
    return ManualStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      annotatedImagePath: annotatedImagePath ?? this.annotatedImagePath,
      stepNumber: stepNumber ?? this.stepNumber,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualStep &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          timestamp == other.timestamp &&
          imagePath == other.imagePath &&
          annotatedImagePath == other.annotatedImagePath &&
          stepNumber == other.stepNumber &&
          isProcessed == other.isProcessed;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      timestamp.hashCode ^
      imagePath.hashCode ^
      annotatedImagePath.hashCode ^
      stepNumber.hashCode ^
      isProcessed.hashCode;

  @override
  String toString() {
    return 'ManualStep(id: $id, title: $title, description: $description, '
           'timestamp: $timestamp, imagePath: $imagePath, '
           'annotatedImagePath: $annotatedImagePath, stepNumber: $stepNumber, '
           'isProcessed: $isProcessed)';
  }
}