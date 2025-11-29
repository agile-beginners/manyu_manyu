import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void _showAddStepDialog() {
    // For now, we'll show a simple dialog to add a new step
    // In a real implementation, this might involve more complex logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいステップを追加'),
        content: const Text('この機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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
              // Manual save trigger (auto-save handles most cases)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('変更は自動的に保存されています'),
                  duration: Duration(seconds: 2),
                ),
              );
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

          return Column(
            children: [
              // Manual header with title and description editing
              ManualHeaderWidget(
                manual: manual,
                onTitleChanged: (newTitle) {
                  ref
                      .read(manualEditNotifierProvider.notifier)
                      .updateManualTitle(widget.manualId, newTitle);
                },
                onDescriptionChanged: (newDescription) {
                  ref
                      .read(manualEditNotifierProvider.notifier)
                      .updateManualDescription(widget.manualId, newDescription);
                },
              ),

              const Divider(),

              // Steps list
              Expanded(
                child: StepListWidget(
                  manual: manual,
                  onStepTap: _showStepEditDialog,
                  onStepReorder: (stepIds) {
                    ref
                        .read(manualEditNotifierProvider.notifier)
                        .reorderSteps(widget.manualId, stepIds);
                  },
                ),
              ),
            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStepDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
