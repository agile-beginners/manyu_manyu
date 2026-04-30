import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/manual_step.dart';
import '../providers/manual_edit_controller.dart';
import '../widgets/manual_header_widget.dart';
import '../widgets/step_list_widget.dart';
import '../widgets/step_edit_dialog.dart';

/// マニュアルコンテンツを編集する画面
class ManualEditScreen extends ConsumerStatefulWidget {
  final String manualId;

  const ManualEditScreen({super.key, required this.manualId});

  @override
  ConsumerState<ManualEditScreen> createState() => _ManualEditScreenState();
}

class _ManualEditScreenState extends ConsumerState<ManualEditScreen> {
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    // 画面初期化時にマニュアルを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manualEditControllerProvider.notifier).loadManual(widget.manualId);
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _showStepEditDialog(ManualStep step) {
    showDialog(
      context: context,
      builder: (context) => StepEditDialog(
        manualId: widget.manualId,
        step: step,
        onSave: (updatedStep) {
          ref
              .read(manualEditControllerProvider.notifier)
              .updateStep(widget.manualId, updatedStep);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manualState = ref.watch(manualEditControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マニュアル編集'),
      ),
      body: manualState.when(
        data: (manual) {
          if (manual == null) {
            return const Center(child: Text('マニュアルが見つかりません'));
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: ManualHeaderWidget(
                  manual: manual,
                  onTitleChanged: (newTitle) {
                    ref
                        .read(manualEditControllerProvider.notifier)
                        .updateManualTitle(widget.manualId, newTitle);
                  },
                  onDescriptionChanged: (newDescription) {
                    ref
                        .read(manualEditControllerProvider.notifier)
                        .updateManualDescription(
                          widget.manualId,
                          newDescription,
                        );
                  },
                  onDownloadPdf: () {
                    final notifier = ref.read(manualEditControllerProvider.notifier);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDFを生成しています...'),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    notifier.exportManual(widget.manualId).then((result) {
                      result.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('PDF出力に失敗しました: ${failure.message}'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        (path) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('PDF生成完了'),
                              content: const Text('マニュアルのPDF化が完了しました。'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('閉じる'),
                                ),
                                Builder(
                                  builder: (context) {
                                    return FilledButton.icon(
                                      onPressed: () {
                                        // ダイアログを閉じる前にボタンの位置を計算する
                                        final box = context.findRenderObject() as RenderBox?;
                                        Rect? sharePositionOrigin;
                                        if (box != null) {
                                          sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
                                        }

                                        Navigator.of(context).pop();
                                        Share.shareXFiles(
                                          [XFile(path)],
                                          text: manual.title,
                                          sharePositionOrigin: sharePositionOrigin,
                                        );
                                      },
                                      icon: const Icon(Icons.save_alt),
                                      label: const Text('保存する'),
                                    );
                                  }
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    });
                  },
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
            ],
            body: StepListWidget(
              manual: manual,
              onStepTap: _showStepEditDialog,
            ),
          );
        },

        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(manualEditControllerProvider.notifier)
                      .loadManual(widget.manualId);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
