import 'package:flutter/material.dart';

import '../../domain/entities/video_file.dart';

/// Widget for displaying upload status (success or error)
class UploadStatusWidget extends StatelessWidget {
  final VideoFile? uploadedVideo;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const UploadStatusWidget({
    super.key,
    this.uploadedVideo,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (uploadedVideo != null) {
      return _buildSuccessWidget(context);
    } else if (errorMessage != null) {
      return _buildErrorWidget(context);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSuccessWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'アップロード完了',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Video file details
          _buildVideoDetails(context),
          
          const SizedBox(height: 16),
          
          // Next steps
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '動画の解析を開始できます',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'アップロードエラー',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: 16),
          
          // Retry button
          if (onRetry != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoDetails(BuildContext context) {
    if (uploadedVideo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(context, 'ファイル名', uploadedVideo!.name),
        const SizedBox(height: 4),
        _buildDetailRow(
          context, 
          'サイズ', 
          '${(uploadedVideo!.sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        ),
        const SizedBox(height: 4),
        _buildDetailRow(context, '形式', uploadedVideo!.format.toUpperCase()),
        const SizedBox(height: 4),
        _buildDetailRow(
          context, 
          'アップロード日時', 
          _formatDateTime(uploadedVideo!.createdAt)
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}