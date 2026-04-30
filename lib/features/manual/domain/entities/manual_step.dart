import 'package:json_annotation/json_annotation.dart';

part 'manual_step.g.dart';

/// マニュアル内の1つのステップを表す
@JsonSerializable()
class ManualStep {
  /// ステップの一意識別子
  final String id;

  /// ステップのタイトル
  final String title;

  /// ステップの詳細説明
  final String description;

  /// このステップが発生する動画内のタイムスタンプ（ミリ秒）
  final int timestamp;

  /// このステップに関連する画像のパス（省略可）
  final String? imagePath;

  /// アノテーション済み画像のパス（Nano Banana APIで処理済み）
  final String? annotatedImagePath;

  /// マニュアル内のこのステップの順序番号
  final int stepNumber;

  /// このステップがAIによって処理済みかどうか
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

  /// JSONからManualStepを生成する
  factory ManualStep.fromJson(Map<String, dynamic> json) => _$ManualStepFromJson(json);

  /// ManualStepをJSONに変換する
  Map<String, dynamic> toJson() => _$ManualStepToJson(this);

  /// 更新されたフィールドでこのManualStepのコピーを作成する
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