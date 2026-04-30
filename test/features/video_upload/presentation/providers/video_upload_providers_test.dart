import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tokyo_flutter_hackathon_2025/features/video/presentation/providers/video_upload_controller.dart';

void main() {
  group('VideoUploadProviders', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('videoRepositoryProvider should provide VideoRepository instance', () {
      final repository = container.read(videoRepositoryProvider);
      expect(repository, isNotNull);
    });

    test('supportedFormatsProvider should return supported formats', () {
      final formats = container.read(supportedFormatsProvider);
      expect(formats, isA<List<String>>());
      expect(formats, isNotEmpty);
      expect(formats, contains('mp4'));
      expect(formats, contains('mov'));
      expect(formats, contains('avi'));
    });

    test('maxFileSizeProvider should return max file size', () {
      final maxSize = container.read(maxFileSizeProvider);
      expect(maxSize, isA<int>());
      expect(maxSize, greaterThan(0));
    });

    test('videoUploadStateProvider should have initial state', () {
      final state = container.read(videoUploadStateProvider);
      expect(state.selectedFile, isNull);
      expect(state.isUploading, isFalse);
      expect(state.uploadProgress, equals(0.0));
      expect(state.uploadedVideo, isNull);
      expect(state.errorMessage, isNull);
    });

    test('VideoUploadState copyWith should work correctly', () {
      const initialState = VideoUploadState();
      final file = File('test.mp4');
      
      final newState = initialState.copyWith(
        selectedFile: file,
        isUploading: true,
        uploadProgress: 0.5,
      );

      expect(newState.selectedFile, equals(file));
      expect(newState.isUploading, isTrue);
      expect(newState.uploadProgress, equals(0.5));
      expect(newState.uploadedVideo, isNull);
      expect(newState.errorMessage, isNull);
    });

    test('VideoUploadState clearError should clear error message', () {
      const stateWithError = VideoUploadState(errorMessage: 'Test error');
      final clearedState = stateWithError.clearError();
      
      expect(clearedState.errorMessage, isNull);
    });

    test('VideoUploadState clearUpload should clear upload data', () {
      final stateWithUpload = VideoUploadState(
        uploadProgress: 0.8,
        errorMessage: 'Test error',
      );
      final clearedState = stateWithUpload.clearUpload();
      
      expect(clearedState.uploadProgress, equals(0.0));
      expect(clearedState.uploadedVideo, isNull);
      expect(clearedState.errorMessage, isNull);
    });
  });
}