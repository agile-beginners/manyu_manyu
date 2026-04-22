import 'package:flutter/material.dart';

/// Widget for displaying upload progress
class UploadProgressWidget extends StatelessWidget {
  final double progress;
  final bool isUploading;

  const UploadProgressWidget({
    super.key,
    required this.progress,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'アップロード進捗',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            isUploading 
                ? Theme.of(context).colorScheme.primary
                : progress >= 1.0 
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Status text
        Text(
          _getStatusText(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (isUploading) {
      if (progress < 0.9) {
        return 'ファイルを処理中...';
      } else {
        return 'アップロード中...';
      }
    } else if (progress >= 1.0) {
      return 'アップロード完了';
    } else if (progress > 0) {
      return 'アップロード中断';
    } else {
      return '待機中';
    }
  }
}