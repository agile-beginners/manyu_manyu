import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../data/services/pdf_export_service.dart';
import '../data/services/pdf_export_service_impl.dart';
import 'manual_edit_service.dart';

class ManualExportService {
  final Ref _ref;

  ManualExportService(this._ref);

  Future<Result<String>> exportManual(String manualId) async {
    final manualResult =
        await _ref.read(manualRepositoryProvider).getManual(manualId);
    if (manualResult.isFailure) return Result.failure(manualResult.failure!);
    final manual = manualResult.data;
    if (manual == null) {
      return const Result.failure(ValidationFailure('Manual not found'));
    }
    final exportResult =
        await _ref.read(_pdfExportServiceProvider).exportManual(manual);
    if (exportResult.isSuccess) {
      _ref.invalidate(manualProvider(manualId));
      _ref.invalidate(allManualsProvider);
    }
    return exportResult;
  }
}

final _pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportServiceImpl();
});

final manualExportServiceProvider = Provider<ManualExportService>((ref) {
  return ManualExportService(ref);
});
