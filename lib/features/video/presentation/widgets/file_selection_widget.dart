import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/video_upload_controller.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // File selection area
        if (selectedFile == null)
          InkWell(
            onTap: isEnabled ? _selectFile : null,
            borderRadius: BorderRadius.circular(16),
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              dashPattern: const [8, 4],
              color: isEnabled
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.onSurface.withValues(alpha: 0.2),
              strokeWidth: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? colorScheme.primary.withValues(alpha: 0.04)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: isEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '動画ファイルをここにドロップ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'または',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ファイルを選択',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.video_file_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFileName(selectedFile!.path),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<FileStat>(
                        future: selectedFile!.stat(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final sizeInMB =
                                snapshot.data!.size / (1024 * 1024);
                            return Text(
                              '${sizeInMB.toStringAsFixed(1)} MB',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          }
                          return const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (isEnabled)
                  IconButton(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.change_circle_outlined),
                    tooltip: 'ファイルを変更',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Format and size info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '対応形式: ${supportedFormats.join(', ').toUpperCase()}  •  最大: ${(maxFileSize / (1024 * 1024)).round()}MB',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
