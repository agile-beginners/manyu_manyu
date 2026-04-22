import 'package:flutter/material.dart';

import '../../domain/entities/video_file.dart';

/// Widget for displaying upload status (success or error)
class UploadStatusWidget extends StatelessWidget {
  final VideoFile? uploadedVideo;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onStartAnalysis;
  final String? manualInfo;
  final ValueChanged<String>? onManualInfoChanged;

  const UploadStatusWidget({
    super.key,
    this.uploadedVideo,
    this.errorMessage,
    this.onRetry,
    this.onStartAnalysis,
    this.manualInfo,
    this.onManualInfoChanged,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アップロード完了',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '動画の解析を開始できます',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Video file details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildVideoDetails(context),
          ),
          
          const SizedBox(height: 20),

          if (onManualInfoChanged != null) ...[
            TextFormField(
              key: ValueKey(uploadedVideo?.path ?? 'no-video'),
              initialValue: manualInfo,
              onChanged: onManualInfoChanged,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                labelText: '生成したいマニュアルの情報 (任意)',
                hintText: '例: 操作対象や目的、重点的に説明したいポイントなど',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Analysis start button
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: onStartAnalysis,
              icon: onStartAnalysis == null 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                onStartAnalysis == null ? '解析中...' : '動画解析を開始',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アップロードエラー',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'もう一度お試しください',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Retry button
          if (onRetry != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
      children: [
        _buildDetailRow(context, Icons.description_outlined, 'ファイル名', uploadedVideo!.name),
        const SizedBox(height: 8),
        _buildDetailRow(
          context, 
          Icons.data_usage_outlined,
          'サイズ', 
          '${(uploadedVideo!.sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        ),
        const SizedBox(height: 8),
        _buildDetailRow(context, Icons.video_file_outlined, '形式', uploadedVideo!.format.toUpperCase()),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}