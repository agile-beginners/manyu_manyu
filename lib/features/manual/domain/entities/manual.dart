import 'package:json_annotation/json_annotation.dart';
import 'manual_status.dart';
import 'manual_step.dart';

export 'manual_status.dart';

part 'manual.g.dart';

/// 複数のステップを持つ完全なマニュアルを表す
@JsonSerializable()
class Manual {
  /// マニュアルの一意識別子
  final String id;

  /// マニュアルのタイトル
  final String title;

  /// マニュアル内のステップ一覧
  @JsonKey(toJson: _stepsToJson, fromJson: _stepsFromJson)
  final List<ManualStep> steps;

  /// マニュアルが作成された日時
  final DateTime createdAt;

  /// マニュアルが最後に更新された日時
  final DateTime updatedAt;

  /// 元の動画ファイルのパス
  final String? videoPath;

  /// 動画の総再生時間（ミリ秒）
  final int? videoDurationMs;

  /// マニュアル生成プロセスのステータス
  final ManualStatus status;

  /// マニュアルの説明またはサマリー
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

  /// JSONからManualを生成する
  factory Manual.fromJson(Map<String, dynamic> json) => _$ManualFromJson(json);

  /// ManualをJSONに変換する
  Map<String, dynamic> toJson() => _$ManualToJson(this);

  /// 更新されたフィールドでこのManualのコピーを作成する
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

  /// このマニュアルのステップ数を返す
  int get stepCount => steps.length;

  /// このマニュアルにステップが存在するかどうかを返す
  bool get hasSteps => steps.isNotEmpty;

  /// 指定インデックスのステップを返す。範囲外の場合はnullを返す
  ManualStep? getStepAt(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  /// 指定IDのステップを返す。見つからない場合はnullを返す
  ManualStep? getStepById(String stepId) {
    try {
      return steps.firstWhere((step) => step.id == stepId);
    } catch (e) {
      return null;
    }
  }

  /// 指定インデックスのステップを更新した新しいManualを返す
  Manual updateStepAt(int index, ManualStep updatedStep) {
    if (index < 0 || index >= steps.length) return this;

    final updatedSteps = List<ManualStep>.from(steps);
    updatedSteps[index] = updatedStep;

    return copyWith(
      steps: updatedSteps,
      updatedAt: DateTime.now(),
    );
  }

  /// 指定IDのステップを更新した新しいManualを返す
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

// JSONシリアライゼーション用のヘルパー関数
List<Map<String, dynamic>> _stepsToJson(List<ManualStep> steps) {
  return steps.map((step) => step.toJson()).toList();
}

List<ManualStep> _stepsFromJson(List<dynamic> json) {
  return json.map((stepJson) => ManualStep.fromJson(stepJson as Map<String, dynamic>)).toList();
}
