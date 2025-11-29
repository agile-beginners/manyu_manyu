import 'dart:io';
import 'package:flutter/material.dart';

import '../../../manual_generation/domain/entities/manual.dart';
import '../../../manual_generation/domain/entities/manual_step.dart';

/// Widget for displaying and managing the list of manual steps
class StepListWidget extends StatefulWidget {
  final Manual manual;
  final Function(ManualStep) onStepTap;
  final Function(List<String>) onStepReorder;

  const StepListWidget({
    super.key,
    required this.manual,
    required this.onStepTap,
    required this.onStepReorder,
  });

  @override
  State<StepListWidget> createState() => _StepListWidgetState();
}

class _StepListWidgetState extends State<StepListWidget> {
  bool _isReorderMode = false;

  void _toggleReorderMode() {
    setState(() {
      _isReorderMode = !_isReorderMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.manual.steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'ステップがありません',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '右下の + ボタンでステップを追加できます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with step count and reorder toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ステップ一覧 (${widget.manual.stepCount})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _toggleReorderMode,
                icon: Icon(_isReorderMode ? Icons.check : Icons.reorder),
                label: Text(_isReorderMode ? '完了' : '並び替え'),
              ),
            ],
          ),
        ),

        // Steps list
        Expanded(
          child: _isReorderMode ? _buildReorderableList() : _buildNormalList(),
        ),
      ],
    );
  }

  Widget _buildNormalList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: widget.manual.steps.length,
      itemBuilder: (context, index) {
        final step = widget.manual.steps[index];
        return _buildStepCard(step, index);
      },
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: widget.manual.steps.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        final steps = List<ManualStep>.from(widget.manual.steps);
        final item = steps.removeAt(oldIndex);
        steps.insert(newIndex, item);

        // Update step numbers and get step IDs in new order
        final reorderedStepIds = <String>[];
        for (int i = 0; i < steps.length; i++) {
          reorderedStepIds.add(steps[i].id);
        }

        widget.onStepReorder(reorderedStepIds);
      },
      itemBuilder: (context, index) {
        final step = widget.manual.steps[index];
        return _buildStepCard(step, index, key: ValueKey(step.id));
      },
    );
  }

  Widget _buildStepCard(ManualStep step, int index, {Key? key}) {
    final hasImage = step.annotatedImagePath != null || step.imagePath != null;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: _isReorderMode ? null : () => widget.onStepTap(step),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepNumber}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isReorderMode)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.drag_handle),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasImage) ...[
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.sizeOf(context).width;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildStepImage(step, maxWidth),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(step.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  if (hasImage)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '画像あり',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  if (step.isProcessed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '処理済み',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepImage(ManualStep step, double maxWidth) {
    final imagePath = step.annotatedImagePath ?? step.imagePath;
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget buildPlaceholder(IconData icon) {
      return Container(
        width: maxWidth,
        height: 200,
        color: backgroundColor,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (imagePath == null) {
      return buildPlaceholder(Icons.image_not_supported);
    }

    // Check if it's a local file
    if (File(imagePath).existsSync()) {
      return Container(
        width: maxWidth,
        color: backgroundColor,
        child: Image.file(
          File(imagePath),
          width: maxWidth,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) {
            return buildPlaceholder(Icons.broken_image);
          },
        ),
      );
    }

    // If it's a network image or asset
    return Container(
      width: maxWidth,
      color: backgroundColor,
      child: Image.network(
        imagePath,
        width: maxWidth,
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          return buildPlaceholder(Icons.broken_image);
        },
      ),
    );
  }

  String _formatTimestamp(int timestampMs) {
    final duration = Duration(milliseconds: timestampMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
