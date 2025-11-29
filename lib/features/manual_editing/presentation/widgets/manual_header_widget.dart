import 'dart:async';
import 'package:flutter/material.dart';

import '../../../manual_generation/domain/entities/manual.dart';

/// Widget for editing manual header information (title and description)
class ManualHeaderWidget extends StatefulWidget {
  final Manual manual;
  final Function(String) onTitleChanged;
  final Function(String?) onDescriptionChanged;
  
  const ManualHeaderWidget({
    super.key,
    required this.manual,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });
  
  @override
  State<ManualHeaderWidget> createState() => _ManualHeaderWidgetState();
}

class _ManualHeaderWidgetState extends State<ManualHeaderWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  Timer? _titleDebounceTimer;
  Timer? _descriptionDebounceTimer;
  bool _isTitleEditing = false;
  bool _isDescriptionEditing = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.manual.title);
    _descriptionController = TextEditingController(text: widget.manual.description ?? '');
    
    // Add listeners for real-time saving
    _titleController.addListener(_onTitleChanged);
    _descriptionController.addListener(_onDescriptionChanged);
  }
  
  @override
  void didUpdateWidget(ManualHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controllers if manual data changed externally
    if (oldWidget.manual.title != widget.manual.title && !_isTitleEditing) {
      _titleController.text = widget.manual.title;
    }
    
    if (oldWidget.manual.description != widget.manual.description && !_isDescriptionEditing) {
      _descriptionController.text = widget.manual.description ?? '';
    }
  }
  
  @override
  void dispose() {
    _titleDebounceTimer?.cancel();
    _descriptionDebounceTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _onTitleChanged() {
    _titleDebounceTimer?.cancel();
    _titleDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_titleController.text.trim() != widget.manual.title) {
        widget.onTitleChanged(_titleController.text.trim());
      }
    });
  }
  
  void _onDescriptionChanged() {
    _descriptionDebounceTimer?.cancel();
    _descriptionDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final newDescription = _descriptionController.text.trim();
      final currentDescription = widget.manual.description ?? '';
      
      if (newDescription != currentDescription) {
        widget.onDescriptionChanged(newDescription.isEmpty ? null : newDescription);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title editing
          Text(
            'タイトル',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: InputDecoration(
              hintText: 'マニュアルのタイトルを入力',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            maxLines: 2,
            onTap: () {
              setState(() {
                _isTitleEditing = true;
              });
            },
            onEditingComplete: () {
              setState(() {
                _isTitleEditing = false;
              });
            },
            onSubmitted: (_) {
              setState(() {
                _isTitleEditing = false;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Description editing
          Text(
            '説明',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'マニュアルの説明を入力（任意）',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            maxLines: 3,
            onTap: () {
              setState(() {
                _isDescriptionEditing = true;
              });
            },
            onEditingComplete: () {
              setState(() {
                _isDescriptionEditing = false;
              });
            },
            onSubmitted: (_) {
              setState(() {
                _isDescriptionEditing = false;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Manual metadata
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '最終更新: ${_formatDateTime(widget.manual.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.list,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.manual.stepCount} ステップ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}