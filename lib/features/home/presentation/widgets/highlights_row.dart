import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'highlight_card.dart';

class HighlightsRow extends StatelessWidget {
  const HighlightsRow({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cards = [
      HighlightCard(
        icon: Icons.flash_on,
        title: 'ステップ自動抽出',
        body: 'Gemini解析で最大20ステップを抽出',
        colorScheme: colorScheme,
      ),
      HighlightCard(
        icon: Icons.brush_rounded,
        title: '注釈付きビジュアル',
        body: '矢印・テキスト・丸囲みを自動付与',
        colorScheme: colorScheme,
      ),
      HighlightCard(
        icon: Icons.picture_as_pdf_outlined,
        title: 'すぐに共有',
        body: 'PDF出力で共有や印刷に即対応',
        colorScheme: colorScheme,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        final spacing = AppConstants.defaultPadding;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: cards
              .map(
                (card) => SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - spacing * 2) / 3
                      : math.min(constraints.maxWidth, 360),
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
