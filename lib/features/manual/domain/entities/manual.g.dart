// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manual _$ManualFromJson(Map<String, dynamic> json) => Manual(
      id: json['id'] as String,
      title: json['title'] as String,
      steps: _stepsFromJson(json['steps'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      videoPath: json['videoPath'] as String?,
      videoDurationMs: (json['videoDurationMs'] as num?)?.toInt(),
      status: $enumDecodeNullable(_$ManualStatusEnumMap, json['status']) ??
          ManualStatus.draft,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ManualToJson(Manual instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'steps': _stepsToJson(instance.steps),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'videoPath': instance.videoPath,
      'videoDurationMs': instance.videoDurationMs,
      'status': _$ManualStatusEnumMap[instance.status]!,
      'description': instance.description,
    };

const _$ManualStatusEnumMap = {
  ManualStatus.generating: 'generating',
  ManualStatus.draft: 'draft',
  ManualStatus.completed: 'completed',
  ManualStatus.failed: 'failed',
};
