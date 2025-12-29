// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManualStep _$ManualStepFromJson(Map<String, dynamic> json) => ManualStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      imagePath: json['imagePath'] as String?,
      annotatedImagePath: json['annotatedImagePath'] as String?,
      stepNumber: (json['stepNumber'] as num).toInt(),
      isProcessed: json['isProcessed'] as bool? ?? false,
    );

Map<String, dynamic> _$ManualStepToJson(ManualStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'timestamp': instance.timestamp,
      'imagePath': instance.imagePath,
      'annotatedImagePath': instance.annotatedImagePath,
      'stepNumber': instance.stepNumber,
      'isProcessed': instance.isProcessed,
    };
