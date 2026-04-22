import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../video/presentation/screens/video_upload_screen.dart';

class PrimaryActions extends StatelessWidget {
  const PrimaryActions({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.largePadding * 0.75,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const VideoUploadScreen(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 22),
            label: const Text(
              'はじめる',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          'AIがステップ抽出と画像注釈を自動で実行し、編集・PDF出力まで1つのフローで完結します。',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
