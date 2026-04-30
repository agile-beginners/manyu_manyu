import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/manual.dart';
import '../../domain/entities/manual_step.dart';
import 'pdf_export_service.dart';

/// マニュアルをPDFにエクスポートするための具体的な実装。
class PdfExportServiceImpl implements PdfExportService {
  pw.Font? _fontRegular;
  pw.Font? _fontBold;
  bool _fontsLoading = false;

  @override
  Future<Result<String>> exportManual(Manual manual) async {
    try {
      _log(
          'exportManual start: title=${manual.title}, updatedAt=${manual.updatedAt}');
      await _ensureFontsLoaded();

      final theme = (_fontRegular != null && _fontBold != null)
          ? pw.ThemeData.withFont(base: _fontRegular!, bold: _fontBold!)
          : null;

      final doc = pw.Document(theme: theme);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            _buildHeader(manual),
            pw.SizedBox(height: 12),
            if ((manual.description ?? '').isNotEmpty)
              _buildDescription(manual),
            if (manual.hasSteps) ...[
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),
              ...manual.steps.map(_buildStepSection),
            ],
          ],
        ),
      );

      final exportsDir = await _prepareExportDir();
      final sanitizedTitle = _sanitizeFileName(
        manual.title.isNotEmpty ? manual.title : 'manual',
      );
      final timestamp = manual.updatedAt.toIso8601String().replaceAll(':', '-');
      final fileName = '$sanitizedTitle-$timestamp.pdf';
      final filePath = p.join(exportsDir.path, fileName);

      final file = File(filePath);
      final bytes = await doc.save();
      _log('PDF bytes length=${bytes.length}');
      await file.writeAsBytes(bytes);

      return Result.success(filePath);
    } catch (e, st) {
      _log('exportManual error: $e\n$st');
      return Result.failure(PdfGenerationFailure('Failed to export PDF: $e'));
    }
  }

  Future<void> _ensureFontsLoaded() async {
    if (_fontRegular != null && _fontBold != null) return;
    if (_fontsLoading) {
      // 別スレッドで読み込み中の場合は完了まで待つ
      while (_fontsLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return;
    }
    _fontsLoading = true;
    try {
      _log('Loading local fonts (TTF)...');
      final regularData =
          await rootBundle.load('assets/fonts/MPLUS1p-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/MPLUS1p-Bold.ttf');
      _log(
          'Font sizes: regular=${regularData.lengthInBytes}, bold=${boldData.lengthInBytes}');
      _fontRegular = pw.Font.ttf(regularData);
      _fontBold = pw.Font.ttf(boldData);
      _log('Local fonts loaded successfully');
    } catch (e, st) {
      _log('Local font load failed: $e\n$st');
      // フォント読み込みに失敗した場合はデフォルトフォントのまま続行
    } finally {
      _fontsLoading = false;
    }
  }

  void _log(String message) {
    debugPrint('[PdfExport] $message');
  }

  pw.Widget _buildHeader(Manual manual) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          manual.title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '更新日: ${manual.updatedAt}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        if (manual.videoDurationMs != null)
          pw.Text(
            '動画長: ${_formatDuration(manual.videoDurationMs!)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
      ],
    );
  }

  pw.Widget _buildDescription(Manual manual) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '概要',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          manual.description ?? '',
          style: const pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  pw.Widget _buildStepSection(ManualStep step) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'STEP ${step.stepNumber}: ${step.title}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(step.description, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(
          'タイムスタンプ: ${_formatDuration(step.timestamp)}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        if (step.annotatedImagePath != null || step.imagePath != null) ...[
          pw.SizedBox(height: 6),
          _buildStepImage(step),
        ],
        pw.SizedBox(height: 12),
        pw.Divider(),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _buildStepImage(ManualStep step) {
    final imagePath = step.annotatedImagePath ?? step.imagePath;
    if (imagePath == null) {
      return pw.SizedBox();
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      return pw.Text(
        '画像を読み込めませんでした: $imagePath',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.red),
      );
    }

    final bytes = file.readAsBytesSync();
    final image = pw.MemoryImage(bytes);
    const radius = 6.0;
    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final resolvedConstraints = constraints ?? const pw.BoxConstraints();
        final pageFormat = context.page.pageFormat;
        final availableWidth = resolvedConstraints.maxWidth.isFinite
            ? resolvedConstraints.maxWidth
            : pageFormat.availableWidth;
        final availableHeight = resolvedConstraints.maxHeight.isFinite
            ? resolvedConstraints.maxHeight
            : pageFormat.availableHeight;

        final imageWidth = image.width?.toDouble() ?? availableWidth;
        final imageHeight = image.height?.toDouble() ?? availableHeight;
        final aspectRatio = imageHeight == 0 ? 1.0 : imageWidth / imageHeight;

        double targetWidth = availableWidth;
        double targetHeight = targetWidth / aspectRatio;

        if (targetHeight > availableHeight) {
          targetHeight = availableHeight;
          targetWidth = targetHeight * aspectRatio;
        }

        return pw.Container(
          width: targetWidth,
          height: targetHeight,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.circular(radius),
          ),
          child: pw.ClipRRect(
            horizontalRadius: radius,
            verticalRadius: radius,
            child: pw.Image(
              image,
              width: targetWidth,
              height: targetHeight,
              fit: pw.BoxFit.contain,
              alignment: pw.Alignment.center,
            ),
          ),
        );
      },
    );
  }

  Future<Directory> _prepareExportDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[\\\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'manual' : sanitized;
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
