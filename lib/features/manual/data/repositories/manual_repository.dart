import '../../../../core/utils/result.dart';
import '../../domain/entities/manual.dart';
import '../../domain/entities/manual_step.dart';

/// マニュアル操作のリポジトリインターフェース
abstract class ManualRepository {
  /// マニュアルをローカルストレージに保存する
  Future<Result<void>> saveManual(Manual manual);

  /// IDでマニュアルを取得する
  Future<Result<Manual?>> getManual(String id);

  /// 既存のマニュアルを更新する
  Future<Result<void>> updateManual(Manual manual);

  /// IDでマニュアルを削除する
  Future<Result<void>> deleteManual(String id);

  /// 全マニュアルを一覧取得する
  Future<Result<List<Manual>>> getAllManuals();

  /// マニュアルのステップを保存する
  Future<Result<void>> saveManualStep(String manualId, ManualStep step);

  /// マニュアルのステップを更新する
  Future<Result<void>> updateManualStep(String manualId, ManualStep step);

  /// マニュアルのステップを削除する
  Future<Result<void>> deleteManualStep(String manualId, String stepId);

  /// マニュアルの全ステップを取得する
  Future<Result<List<ManualStep>>> getManualSteps(String manualId);

  /// タイトルまたは説明でマニュアルを検索する
  Future<Result<List<Manual>>> searchManuals(String query);

  /// ステータスでマニュアルを取得する
  Future<Result<List<Manual>>> getManualsByStatus(ManualStatus status);

  /// マニュアルデータをJSONとしてエクスポートする
  Future<Result<Map<String, dynamic>>> exportManualAsJson(String manualId);

  /// JSONからマニュアルデータをインポートする
  Future<Result<Manual>> importManualFromJson(Map<String, dynamic> json);
}