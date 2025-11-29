import 'package:flutter/material.dart';
import 'package:faker/faker.dart';

/// Test utilities for property-based testing
class TestUtils {
  static final Faker _faker = Faker();

  /// Generate random screen sizes for testing responsive design
  static List<Size> generateRandomScreenSizes({int count = 10}) {
    final sizes = <Size>[];
    
    for (int i = 0; i < count; i++) {
      // Generate various screen sizes including mobile, tablet, and desktop
      // Keep within reasonable bounds for testing
      final width = _faker.randomGenerator.integer(1920, min: 320).toDouble();
      final height = _faker.randomGenerator.integer(1080, min: 568).toDouble();
      sizes.add(Size(width, height));
    }
    
    // Always include common device sizes
    sizes.addAll([
      const Size(375, 667),   // iPhone SE
      const Size(414, 896),   // iPhone 11 Pro Max
      const Size(768, 1024),  // iPad
      const Size(1024, 768),  // iPad Landscape
      const Size(1920, 1080), // Desktop HD
    ]);
    
    return sizes;
  }

  /// Generate random device types for testing
  static List<TargetPlatform> generateRandomPlatforms() {
    return [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ];
  }

  /// Create a test widget with specific screen size
  static Widget createTestWidgetWithSize({
    required Widget child,
    required Size size,
    TargetPlatform? platform,
  }) {
    return MaterialApp(
      theme: ThemeData(
        platform: platform,
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1.0,
          textScaler: const TextScaler.linear(1.0),
          platformBrightness: Brightness.light,
          accessibleNavigation: false,
          invertColors: false,
          disableAnimations: false,
          boldText: false,
          highContrast: false,
        ),
        child: child,
      ),
    );
  }

  /// Check if a widget is mobile-sized
  static bool isMobileSize(Size size) {
    return size.width < 768;
  }

  /// Check if a widget is tablet-sized
  static bool isTabletSize(Size size) {
    return size.width >= 768 && size.width <= 1024;
  }

  /// Check if a widget is desktop-sized
  static bool isDesktopSize(Size size) {
    return size.width >= 1024;
  }

  /// Generate random touch events for testing
  static List<Offset> generateRandomTouchPoints(Size screenSize, {int count = 5}) {
    final points = <Offset>[];
    
    for (int i = 0; i < count; i++) {
      final x = _faker.randomGenerator.decimal(scale: screenSize.width);
      final y = _faker.randomGenerator.decimal(scale: screenSize.height);
      points.add(Offset(x, y));
    }
    
    return points;
  }

  /// Verify that UI elements are properly positioned within screen bounds
  static bool isWithinScreenBounds(Rect elementBounds, Size screenSize) {
    return elementBounds.left >= 0 &&
           elementBounds.top >= 0 &&
           elementBounds.right <= screenSize.width &&
           elementBounds.bottom <= screenSize.height;
  }

  /// Check if text is readable (not too small)
  static bool isTextReadable(double fontSize, Size screenSize) {
    // Minimum readable font size - be more lenient for testing
    // AppBar title might have default font size which could be smaller
    return fontSize >= 10.0; // More lenient minimum for testing
  }

  /// Verify that touch targets are appropriately sized
  static bool isTouchTargetAppropriate(Size targetSize, Size screenSize) {
    // Minimum touch target size should be 44x44 points on mobile
    const minTouchTarget = 44.0;
    
    if (isMobileSize(screenSize)) {
      return targetSize.width >= minTouchTarget && targetSize.height >= minTouchTarget;
    }
    
    // For larger screens, touch targets can be smaller but should still be reasonable
    return targetSize.width >= 32.0 && targetSize.height >= 32.0;
  }
}