import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/ai_assist_badge.dart';
import '../widgets/hero_icon.dart';
import '../widgets/highlights_row.dart';
import '../widgets/primary_actions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxContentWidth =
        math.min(MediaQuery.of(context).size.width * 0.9, 860.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マニュマニュ'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.12),
                colorScheme.primary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.largePadding,
              vertical: AppConstants.largePadding * 1.5,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: _HomeContent(colorScheme: colorScheme),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 28,
          color: const Color(0xFF1F2937),
        );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.largePadding * 1.5,
        vertical: AppConstants.largePadding * 1.2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AiAssistBadge(colorScheme: colorScheme),
          const SizedBox(height: AppConstants.largePadding * 1.2),
          HeroIcon(colorScheme: colorScheme),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'マニュマニュ',
            style: headlineStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          const Text(
            '動画をアップロードすると、AIがステップを抽出し、注釈付きビジュアルを自動生成するマニュアル作成アプリです。',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.largePadding * 1.3),
          HighlightsRow(colorScheme: colorScheme),
          const SizedBox(height: AppConstants.largePadding * 1.3),
          PrimaryActions(colorScheme: colorScheme),
        ],
      ),
    );
  }
}
