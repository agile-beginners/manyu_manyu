import '../../../../core/utils/result.dart';
import '../entities/manual.dart';

/// Service that exports a manual to PDF.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4
/// - 7.1: PDFファイルを生成できる
/// - 7.2: 画像・テキストを含める
/// - 7.3: ファイル保存（ダウンロード）できる
/// - 7.4: 生成時のエラーハンドリング
abstract class PdfExportService {
  /// Exports [manual] to a PDF file and returns the saved file path on success.
  Future<Result<String>> exportManual(Manual manual);
}
