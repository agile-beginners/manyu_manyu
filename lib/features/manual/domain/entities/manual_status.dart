import 'package:json_annotation/json_annotation.dart';

/// Enum representing the status of a manual
@JsonEnum()
enum ManualStatus {
  /// Manual is being created/generated
  @JsonValue('generating')
  generating,

  /// Manual is in draft state (can be edited)
  @JsonValue('draft')
  draft,

  /// Manual is completed and ready for use
  @JsonValue('completed')
  completed,

  /// Manual generation failed
  @JsonValue('failed')
  failed,
}
