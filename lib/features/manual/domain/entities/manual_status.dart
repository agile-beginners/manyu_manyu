import 'package:json_annotation/json_annotation.dart';

/// マニュアルのステータスを表す列挙型
@JsonEnum()
enum ManualStatus {
  /// マニュアルが作成・生成中
  @JsonValue('generating')
  generating,

  /// マニュアルが下書き状態（編集可能）
  @JsonValue('draft')
  draft,

  /// マニュアルが完成済みで使用可能
  @JsonValue('completed')
  completed,

  /// マニュアルの生成が失敗した
  @JsonValue('failed')
  failed,
}
