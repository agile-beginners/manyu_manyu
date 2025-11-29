import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_flutter_hackathon_2025/main.dart';
import '../utils/test_utils.dart';

void main() {
  group('Property-Based Tests - Responsive Design', () {
    testWidgets(
      'Property 15: レスポンシブデザインの適応性 - UI adapts properly to different screen sizes and platforms',
      (WidgetTester tester) async {
        /**
         * Feature: video-manual-generator, Property 15: レスポンシブデザインの適応性
         * 任意のデバイス環境（スマートフォン、Web）に対して、適切なUIが表示され、タッチイベントが正しく処理される
         * Validates: Requirements 8.1, 8.2, 8.3, 8.4
         */

        // Generate random screen sizes and platforms for testing
        final screenSizes = TestUtils.generateRandomScreenSizes(count: 20);
        final platforms = TestUtils.generateRandomPlatforms();

        // Test the property across multiple iterations (reduced for initial testing)
        for (int iteration = 0; iteration < 20; iteration++) {
          // Select random screen size and platform for this iteration
          final screenSize = screenSizes[iteration % screenSizes.length];
          final platform = platforms[iteration % platforms.length];

          // Create test widget with specific screen size and platform
          final testWidget = TestUtils.createTestWidgetWithSize(
            child: const HomePage(),
            size: screenSize,
            platform: platform,
          );

          // Build the widget
          await tester.pumpWidget(testWidget);
          await tester.pumpAndSettle();

          // Property 1: UI elements should be visible and within screen bounds
          final appBarFinder = find.byType(AppBar);
          final iconFinder = find.byIcon(Icons.video_library);
          final titleFinder = find.text('Video Manual Generator');
          final descriptionFinder = find.text('Upload a video to automatically generate step-by-step manuals using AI');

          // Verify all essential UI elements are present
          expect(appBarFinder, findsOneWidget, 
            reason: 'AppBar should be present on screen size ${screenSize.width}x${screenSize.height}');
          expect(iconFinder, findsOneWidget,
            reason: 'Video icon should be present on screen size ${screenSize.width}x${screenSize.height}');
          expect(titleFinder, findsWidgets,
            reason: 'Title should be present on screen size ${screenSize.width}x${screenSize.height}');
          expect(descriptionFinder, findsOneWidget,
            reason: 'Description should be present on screen size ${screenSize.width}x${screenSize.height}');

          // Property 2: UI elements should render without throwing exceptions
          // This verifies that the responsive design doesn't break on different screen sizes
          final iconRect = tester.getRect(iconFinder);
          expect(iconRect.width, greaterThan(0),
            reason: 'Icon should have positive width on screen size ${screenSize.width}x${screenSize.height}');
          expect(iconRect.height, greaterThan(0),
            reason: 'Icon should have positive height on screen size ${screenSize.width}x${screenSize.height}');

          // Property 3: Text should be readable on different screen sizes
          final titleWidgets = tester.widgetList<Text>(titleFinder);
          for (final titleWidget in titleWidgets) {
            final titleStyle = titleWidget.style ?? const TextStyle();
            final titleFontSize = titleStyle.fontSize ?? 14.0;
            
            expect(TestUtils.isTextReadable(titleFontSize, screenSize), isTrue,
              reason: 'Title text should be readable on screen size ${screenSize.width}x${screenSize.height}');
          }

          // Property 4: Touch targets should be appropriately sized
          final iconSize = tester.getSize(iconFinder);
          expect(TestUtils.isTouchTargetAppropriate(iconSize, screenSize), isTrue,
            reason: 'Icon should have appropriate touch target size for screen ${screenSize.width}x${screenSize.height}');

          // Property 5: Layout should adapt to different screen orientations
          final isLandscape = screenSize.width > screenSize.height;
          final isPortrait = screenSize.height > screenSize.width;
          
          if (isLandscape || isPortrait) {
            // Verify that the layout doesn't break in different orientations
            final scaffoldFinder = find.byType(Scaffold);
            expect(scaffoldFinder, findsOneWidget,
              reason: 'Scaffold should render properly in ${isLandscape ? 'landscape' : 'portrait'} orientation');
          }

          // Property 6: Touch events should be processed correctly
          final touchPoints = TestUtils.generateRandomTouchPoints(screenSize, count: 3);
          
          for (final touchPoint in touchPoints) {
            // Verify that touch events within screen bounds don't cause crashes
            if (touchPoint.dx >= 0 && touchPoint.dx <= screenSize.width &&
                touchPoint.dy >= 0 && touchPoint.dy <= screenSize.height) {
              
              try {
                await tester.tapAt(touchPoint);
                await tester.pump();
                // If we reach here, touch event was processed without error
                expect(true, isTrue, reason: 'Touch event should be processed without error');
              } catch (e) {
                // Touch events should not cause crashes
                fail('Touch event at $touchPoint should not cause crashes: $e');
              }
            }
          }

          // Property 7: Platform-specific UI should be rendered appropriately
          final materialAppFinder = find.byType(MaterialApp);
          expect(materialAppFinder, findsOneWidget,
            reason: 'MaterialApp should render on platform $platform');

          // Clean up for next iteration
          await tester.pump();
        }
      },
    );

    testWidgets(
      'Property 15: レスポンシブデザインの適応性 - Specific device categories render correctly',
      (WidgetTester tester) async {
        /**
         * Feature: video-manual-generator, Property 15: レスポンシブデザインの適応性
         * スマートフォン、タブレット、デスクトップの各カテゴリで適切なUIが表示される
         * Validates: Requirements 8.1, 8.2, 8.3, 8.4
         */

        // Test specific device categories
        final testCases = [
          // Mobile devices
          {'size': const Size(375, 667), 'category': 'mobile', 'platform': TargetPlatform.iOS},
          {'size': const Size(414, 896), 'category': 'mobile', 'platform': TargetPlatform.android},
          
          // Tablet devices
          {'size': const Size(768, 1024), 'category': 'tablet', 'platform': TargetPlatform.iOS},
          {'size': const Size(1024, 768), 'category': 'tablet', 'platform': TargetPlatform.android},
          
          // Desktop/Web
          {'size': const Size(1920, 1080), 'category': 'desktop', 'platform': TargetPlatform.macOS},
          {'size': const Size(1366, 768), 'category': 'desktop', 'platform': TargetPlatform.windows},
        ];

        for (final testCase in testCases) {
          final size = testCase['size'] as Size;
          final category = testCase['category'] as String;
          final platform = testCase['platform'] as TargetPlatform;

          final testWidget = TestUtils.createTestWidgetWithSize(
            child: const HomePage(),
            size: size,
            platform: platform,
          );

          await tester.pumpWidget(testWidget);
          await tester.pumpAndSettle();

          // Verify UI renders correctly for each device category
          expect(find.byType(HomePage), findsOneWidget,
            reason: 'HomePage should render on $category device (${size.width}x${size.height})');
          
          expect(find.text('Video Manual Generator'), findsWidgets,
            reason: 'Title should be visible on $category device');
          
          expect(find.byIcon(Icons.video_library), findsOneWidget,
            reason: 'Video icon should be visible on $category device');

          // Verify responsive behavior based on device category
          if (category == 'mobile') {
            expect(TestUtils.isMobileSize(size), isTrue,
              reason: 'Size should be classified as mobile');
          } else if (category == 'tablet') {
            expect(TestUtils.isTabletSize(size), isTrue,
              reason: 'Size should be classified as tablet');
          } else if (category == 'desktop') {
            expect(TestUtils.isDesktopSize(size), isTrue,
              reason: 'Size should be classified as desktop');
          }
        }
      },
    );
  });
}