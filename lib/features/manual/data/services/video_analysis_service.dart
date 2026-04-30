import '../../../../core/utils/result.dart';
import '../../../video/domain/entities/video_file.dart';
import '../../domain/entities/manual_step.dart';

/// 動画解析サービスのインターフェース
abstract class VideoAnalysisService {
  /// 動画ファイルを解析してマニュアルのステップを抽出する
  ///
  /// 要件: 2.1, 2.2, 2.3, 2.4
  /// - 2.1: アップロード完了後に動画をGemini APIに送信する
  /// - 2.2: 最大20ステップを抽出する
  /// - 2.3: タイトル・説明・タイムスタンプを含むJSONデータを受け取る
  /// - 2.4: エラーハンドリングとリトライオプションを提供する
  Future<Result<List<ManualStep>>> analyzeVideo(
    VideoFile videoFile, {
    String? manualInfo,
  });
}
