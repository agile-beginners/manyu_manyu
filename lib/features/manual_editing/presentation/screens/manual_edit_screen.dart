import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../manual_generation/domain/entities/manual_step.dart';
import '../providers/manual_edit_providers.dart';
import '../widgets/manual_header_widget.dart';
import '../widgets/step_list_widget.dart';
import '../widgets/step_edit_dialog.dart';

/// Screen for editing manual content
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
    // Load the manual when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manualEditNotifierProvider.notifier).loadManual(widget.manualId);
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
              .read(manualEditNotifierProvider.notifier)
              .updateStep(widget.manualId, updatedStep);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manualState = ref.watch(manualEditNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マニュアル編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final notifier = ref.read(manualEditNotifierProvider.notifier);
              final manual = ref.read(manualEditNotifierProvider).value;
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
                    Share.shareXFiles([
                      XFile(path),
                    ], text: manual?.title ?? 'マニュアル');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDFを保存しました: $path'),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(label: 'OK', onPressed: () {}),
                      ),
                    );
                  },
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () {
              // Navigate to preview screen
              Navigator.of(
                context,
              ).pushNamed('/manual-preview', arguments: widget.manualId);
            },
          ),
        ],
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
                        .read(manualEditNotifierProvider.notifier)
                        .updateManualTitle(widget.manualId, newTitle);
                  },
                  onDescriptionChanged: (newDescription) {
                    ref
                        .read(manualEditNotifierProvider.notifier)
                        .updateManualDescription(
                          widget.manualId,
                          newDescription,
                        );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
            ],
            body: StepListWidget(
              manual: manual,
              onStepTap: _showStepEditDialog,
              onStepReorder: (stepIds) {
                ref
                    .read(manualEditNotifierProvider.notifier)
                    .reorderSteps(widget.manualId, stepIds);
              },
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
                      .read(manualEditNotifierProvider.notifier)
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
