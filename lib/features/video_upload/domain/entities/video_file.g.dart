// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoFile _$VideoFileFromJson(Map<String, dynamic> json) => VideoFile(
  path: json['path'] as String,
  name: json['name'] as String,
  sizeInBytes: (json['sizeInBytes'] as num).toInt(),
  format: json['format'] as String,
  durationMs: (json['durationMs'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$VideoFileToJson(VideoFile instance) => <String, dynamic>{
  'path': instance.path,
  'name': instance.name,
  'sizeInBytes': instance.sizeInBytes,
  'format': instance.format,
  'durationMs': instance.durationMs,
  'createdAt': instance.createdAt.toIso8601String(),
};
