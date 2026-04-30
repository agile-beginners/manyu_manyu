import 'dart:io';
import 'package:flutter/material.dart';

import '../../../domain/entities/manual_step.dart';

/// Dialog for editing individual manual steps
class StepEditDialog extends StatefulWidget {
  final String manualId;
  final ManualStep step;
  final Function(ManualStep) onSave;
  
  const StepEditDialog({
    super.key,
    required this.manualId,
    required this.step,
    required this.onSave,
  });
  
  @override
  State<StepEditDialog> createState() => _StepEditDialogState();
}

class _StepEditDialogState extends State<StepEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.step.title);
    _descriptionController = TextEditingController(text: widget.step.description);
    
    // Add listeners to track changes
    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    final hasChanges = _titleController.text != widget.step.title ||
                      _descriptionController.text != widget.step.description;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }
  
  void _saveChanges() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    
    // Validate input
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('説明を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Create updated step
    final updatedStep = widget.step.copyWith(
      title: title,
      description: description,
    );
    
    // Call the save callback
    widget.onSave(updatedStep);
    
    // Close dialog
    Navigator.of(context).pop();
  }
  
  void _discardChanges() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('変更を破棄'),
          content: const Text('変更内容が失われますが、よろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close edit dialog
              },
              child: const Text('破棄'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ステップ ${widget.step.stepNumber} を編集',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: _discardChanges,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Step image (if available)
            if (widget.step.annotatedImagePath != null || widget.step.imagePath != null)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _buildStepImage(),
                ),
              ),
            
            // Title editing
            Text(
              'タイトル',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: InputDecoration(
                hintText: 'ステップのタイトルを入力',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Description editing
            Text(
              '説明',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'ステップの詳細な説明を入力',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Step metadata
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'タイムスタンプ: ${_formatTimestamp(widget.step.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (widget.step.isProcessed)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
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
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _discardChanges,
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _hasChanges ? _saveChanges : null,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepImage() {
    final imagePath = widget.step.annotatedImagePath ?? widget.step.imagePath;
    
    if (imagePath == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                '画像なし',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Check if it's a local file
    if (File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '画像の読み込みに失敗しました',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    
    // If it's a network image or asset
    return Image.network(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  '画像の読み込みに失敗しました',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatTimestamp(int timestampMs) {
    final duration = Duration(milliseconds: timestampMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}