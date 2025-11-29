import 'package:json_annotation/json_annotation.dart';

part 'video_file.g.dart';

/// Represents a video file with metadata
@JsonSerializable()
class VideoFile {
  /// Path to the video file
  final String path;
  
  /// Original name of the video file
  final String name;
  
  /// Size of the video file in bytes
  final int sizeInBytes;
  
  /// Format/extension of the video file (e.g., 'mp4', 'mov', 'avi')
  final String format;
  
  /// Duration of the video in milliseconds
  final int? durationMs;
  
  /// Timestamp when the file was created/uploaded
  final DateTime createdAt;

  const VideoFile({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.format,
    this.durationMs,
    required this.createdAt,
  });

  /// Creates a VideoFile from JSON
  factory VideoFile.fromJson(Map<String, dynamic> json) => _$VideoFileFromJson(json);

  /// Converts VideoFile to JSON
  Map<String, dynamic> toJson() => _$VideoFileToJson(this);

  /// Creates a copy of this VideoFile with updated fields
  VideoFile copyWith({
    String? path,
    String? name,
    int? sizeInBytes,
    String? format,
    int? durationMs,
    DateTime? createdAt,
  }) {
    return VideoFile(
      path: path ?? this.path,
      name: name ?? this.name,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      format: format ?? this.format,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoFile &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name &&
          sizeInBytes == other.sizeInBytes &&
          format == other.format &&
          durationMs == other.durationMs &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      path.hashCode ^
      name.hashCode ^
      sizeInBytes.hashCode ^
      format.hashCode ^
      durationMs.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'VideoFile(path: $path, name: $name, sizeInBytes: $sizeInBytes, '
           'format: $format, durationMs: $durationMs, createdAt: $createdAt)';
  }
}