import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/video_upload_providers.dart';

/// Widget for selecting video files
class FileSelectionWidget extends ConsumerWidget {
  final File? selectedFile;
  final Function(File) onFileSelected;
  final bool isEnabled;

  const FileSelectionWidget({
    super.key,
    required this.selectedFile,
    required this.onFileSelected,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportedFormats = ref.watch(supportedFormatsProvider);
    final maxFileSize = ref.watch(maxFileSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File selection button
        OutlinedButton.icon(
          onPressed: isEnabled ? _selectFile : null,
          icon: const Icon(Icons.video_file),
          label: const Text('ファイルを選択'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Selected file info
        if (selectedFile != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.video_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFileName(selectedFile!.path),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<FileStat>(
                        future: selectedFile!.stat(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final sizeInMB = snapshot.data!.size / (1024 * 1024);
                            return Text(
                              '${sizeInMB.toStringAsFixed(1)} MB',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const Text('サイズ計算中...');
                        },
                      ),
                    ],
                  ),
                ),
                if (isEnabled)
                  IconButton(
                    onPressed: () => onFileSelected(selectedFile!),
                    icon: const Icon(Icons.refresh),
                    tooltip: '別のファイルを選択',
                  ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Format and size info
        Text(
          '対応形式: ${supportedFormats.join(', ').toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '最大ファイルサイズ: ${(maxFileSize / (1024 * 1024)).round()}MB',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        onFileSelected(file);
      }
    } catch (e) {
      // Handle file picker errors
      debugPrint('Error selecting file: $e');
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }
}