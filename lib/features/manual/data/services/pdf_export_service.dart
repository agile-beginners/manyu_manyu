import '../../../../core/utils/result.dart';
import '../../domain/entities/manual.dart';

/// マニュアルをPDFにエクスポートするサービス。
///
/// 要件: 7.1, 7.2, 7.3, 7.4
/// - 7.1: PDFファイルを生成できる
/// - 7.2: 画像・テキストを含める
/// - 7.3: ファイル保存（ダウンロード）できる
/// - 7.4: 生成時のエラーハンドリング
abstract class PdfExportService {
  /// [manual]をPDFファイルにエクスポートし、成功時に保存されたファイルパスを返す。
  Future<Result<String>> exportManual(Manual manual);
}
