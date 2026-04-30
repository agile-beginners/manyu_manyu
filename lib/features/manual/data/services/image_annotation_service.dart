import '../../../../core/utils/result.dart';

/// 画像アノテーションサービスのインターフェース
abstract class ImageAnnotationService {
  /// 矢印、テキスト、ハイライトを含むアノテーション付き画像を生成する
  ///
  /// 要件: 4.1, 4.2, 4.3, 4.4
  /// - 4.1: 赤い矢印・テキスト・円を含む画像をアノテーションAPIに送信する
  /// - 4.2: アノテーション付き画像を生成してローカルに保存する
  /// - 4.3: 編集完了時にステップJSONへ画像パスを追加する
  /// - 4.4: API通信失敗時は元画像を使用する
  Future<Result<String>> generateAnnotatedImage({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  });
}