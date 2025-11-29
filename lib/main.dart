import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_constants.dart';
import 'core/debug/config_debug_screen.dart';
import 'features/video_upload/presentation/screens/video_upload_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvConfig.initialize();

  runApp(
    const ProviderScope(
      child: VideoManualGeneratorApp(),
    ),
  );
}

class VideoManualGeneratorApp extends ConsumerWidget {
  const VideoManualGeneratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const seedColor = Color(0xFF2563EB);
    const surfaceTint = Color(0xFFF4F6FB);

    return MaterialApp(
      title: 'マニュマニュ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
          surface: surfaceTint,
          background: surfaceTint,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.largePadding,
              vertical: AppConstants.defaultPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF4A5568),
            height: 1.4,
          ),
        ),
        scaffoldBackgroundColor: surfaceTint,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                colorScheme.primary.withOpacity(0.12),
                colorScheme.primary.withOpacity(0.04),
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Badge(colorScheme: colorScheme),
          const SizedBox(height: AppConstants.largePadding * 1.2),
          _HeroIcon(colorScheme: colorScheme),
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
          _HighlightsRow(colorScheme: colorScheme),
          const SizedBox(height: AppConstants.largePadding * 1.3),
          _PrimaryActions(colorScheme: colorScheme),
          if (kDebugMode) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ConfigDebugScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('設定デバッグ'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.largePadding,
        vertical: AppConstants.defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'AIアシストでマニュアル生成',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      width: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.14),
            colorScheme.primary.withOpacity(0.32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 62,
          width: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.smart_display_outlined,
            size: 40,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _HighlightsRow extends StatelessWidget {
  const _HighlightsRow({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Highlight(
        icon: Icons.flash_on,
        title: 'ステップ自動抽出',
        body: 'Gemini解析で最大20ステップを抽出',
        colorScheme: colorScheme,
      ),
      _Highlight(
        icon: Icons.brush_rounded,
        title: '注釈付きビジュアル',
        body: '矢印・テキスト・丸囲みを自動付与',
        colorScheme: colorScheme,
      ),
      _Highlight(
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

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.title,
    required this.body,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String body;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.colorScheme});

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
            icon: const Icon(Icons.upload_file_outlined, size: 22),
            label: const Text(
              '動画をアップロード',
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
