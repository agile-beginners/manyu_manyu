import 'package:json_annotation/json_annotation.dart';
import 'manual_status.dart';
import 'manual_step.dart';

export 'manual_status.dart';

part 'manual.g.dart';

/// Represents a complete manual with multiple steps
@JsonSerializable()
class Manual {
  /// Unique identifier for the manual
  final String id;

  /// Title of the manual
  final String title;

  /// List of steps in the manual
  @JsonKey(toJson: _stepsToJson, fromJson: _stepsFromJson)
  final List<ManualStep> steps;

  /// Timestamp when the manual was created
  final DateTime createdAt;

  /// Timestamp when the manual was last updated
  final DateTime updatedAt;

  /// Path to the original video file
  final String? videoPath;

  /// Total duration of the video in milliseconds
  final int? videoDurationMs;

  /// Status of the manual generation process
  final ManualStatus status;

  /// Description or summary of the manual
  final String? description;

  const Manual({
    required this.id,
    required this.title,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
    this.videoPath,
    this.videoDurationMs,
    this.status = ManualStatus.draft,
    this.description,
  });

  /// Creates a Manual from JSON
  factory Manual.fromJson(Map<String, dynamic> json) => _$ManualFromJson(json);

  /// Converts Manual to JSON
  Map<String, dynamic> toJson() => _$ManualToJson(this);

  /// Creates a copy of this Manual with updated fields
  Manual copyWith({
    String? id,
    String? title,
    List<ManualStep>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? videoPath,
    int? videoDurationMs,
    ManualStatus? status,
    String? description,
  }) {
    return Manual(
      id: id ?? this.id,
      title: title ?? this.title,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      videoPath: videoPath ?? this.videoPath,
      videoDurationMs: videoDurationMs ?? this.videoDurationMs,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  /// Returns the number of steps in this manual
  int get stepCount => steps.length;

  /// Returns whether this manual has any steps
  bool get hasSteps => steps.isNotEmpty;

  /// Returns the step at the given index, or null if index is out of bounds
  ManualStep? getStepAt(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  /// Returns the step with the given ID, or null if not found
  ManualStep? getStepById(String stepId) {
    try {
      return steps.firstWhere((step) => step.id == stepId);
    } catch (e) {
      return null;
    }
  }

  /// Returns a new Manual with the step at the given index updated
  Manual updateStepAt(int index, ManualStep updatedStep) {
    if (index < 0 || index >= steps.length) return this;

    final updatedSteps = List<ManualStep>.from(steps);
    updatedSteps[index] = updatedStep;

    return copyWith(
      steps: updatedSteps,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a new Manual with the step with the given ID updated
  Manual updateStepById(String stepId, ManualStep updatedStep) {
    final index = steps.indexWhere((step) => step.id == stepId);
    if (index == -1) return this;

    return updateStepAt(index, updatedStep);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Manual &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          steps == other.steps &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          videoPath == other.videoPath &&
          videoDurationMs == other.videoDurationMs &&
          status == other.status &&
          description == other.description;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      steps.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      videoPath.hashCode ^
      videoDurationMs.hashCode ^
      status.hashCode ^
      description.hashCode;

  @override
  String toString() {
    return 'Manual(id: $id, title: $title, stepCount: ${steps.length}, '
           'createdAt: $createdAt, updatedAt: $updatedAt, '
           'videoPath: $videoPath, status: $status)';
  }
}

// Helper functions for JSON serialization
List<Map<String, dynamic>> _stepsToJson(List<ManualStep> steps) {
  return steps.map((step) => step.toJson()).toList();
}

List<ManualStep> _stepsFromJson(List<dynamic> json) {
  return json.map((stepJson) => ManualStep.fromJson(stepJson as Map<String, dynamic>)).toList();
}
