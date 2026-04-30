import 'package:json_annotation/json_annotation.dart';

part 'video_file.g.dart';

/// メタデータを持つ動画ファイルを表す
@JsonSerializable()
class VideoFile {
  /// 動画ファイルのパス
  final String path;

  /// 動画ファイルの元のファイル名
  final String name;

  /// 動画ファイルのサイズ（バイト）
  final int sizeInBytes;

  /// 動画ファイルの形式・拡張子（例: 'mp4', 'mov', 'avi'）
  final String format;

  /// 動画の長さ（ミリ秒）
  final int? durationMs;

  /// ファイルが作成・アップロードされたタイムスタンプ
  final DateTime createdAt;

  const VideoFile({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.format,
    this.durationMs,
    required this.createdAt,
  });

  /// JSONからVideoFileを生成する
  factory VideoFile.fromJson(Map<String, dynamic> json) => _$VideoFileFromJson(json);

  /// VideoFileをJSONに変換する
  Map<String, dynamic> toJson() => _$VideoFileToJson(this);

  /// フィールドを更新したVideoFileのコピーを生成する
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