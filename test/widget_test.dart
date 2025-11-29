// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokyo_flutter_hackathon_2025/main.dart';

void main() {
  testWidgets('Video Manual Generator app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VideoManualGeneratorApp());

    // Verify that the app title is displayed.
    expect(find.text('Video Manual Generator'), findsWidgets);
    
    // Verify that the video icon is displayed.
    expect(find.byIcon(Icons.video_library), findsOneWidget);
    
    // Verify that the description text is displayed.
    expect(find.text('Upload a video to automatically generate step-by-step manuals using AI'), findsOneWidget);
  });
}
