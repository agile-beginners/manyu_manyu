import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_flutter_hackathon_2025/features/video/domain/entities/video_file.dart';

void main() {
  group('VideoFile', () {
    test('should create VideoFile with required fields', () {
      // Arrange
      final createdAt = DateTime.now();
      
      // Act
      final videoFile = VideoFile(
        path: '/path/to/video.mp4',
        name: 'video.mp4',
        sizeInBytes: 1024000,
        format: 'mp4',
        createdAt: createdAt,
      );
      
      // Assert
      expect(videoFile.path, '/path/to/video.mp4');
      expect(videoFile.name, 'video.mp4');
      expect(videoFile.sizeInBytes, 1024000);
      expect(videoFile.format, 'mp4');
      expect(videoFile.createdAt, createdAt);
      expect(videoFile.durationMs, null);
    });

    test('should create VideoFile with optional duration', () {
      // Arrange & Act
      final videoFile = VideoFile(
        path: '/path/to/video.mp4',
        name: 'video.mp4',
        sizeInBytes: 1024000,
        format: 'mp4',
        durationMs: 60000,
        createdAt: DateTime.now(),
      );
      
      // Assert
      expect(videoFile.durationMs, 60000);
    });

    test('should serialize to and from JSON correctly', () {
      // Arrange
      final createdAt = DateTime.now();
      final originalVideoFile = VideoFile(
        path: '/path/to/video.mp4',
        name: 'video.mp4',
        sizeInBytes: 1024000,
        format: 'mp4',
        durationMs: 60000,
        createdAt: createdAt,
      );
      
      // Act
      final json = originalVideoFile.toJson();
      final deserializedVideoFile = VideoFile.fromJson(json);
      
      // Assert
      expect(deserializedVideoFile.path, originalVideoFile.path);
      expect(deserializedVideoFile.name, originalVideoFile.name);
      expect(deserializedVideoFile.sizeInBytes, originalVideoFile.sizeInBytes);
      expect(deserializedVideoFile.format, originalVideoFile.format);
      expect(deserializedVideoFile.durationMs, originalVideoFile.durationMs);
      expect(deserializedVideoFile.createdAt, originalVideoFile.createdAt);
    });

    test('should create copy with updated fields', () {
      // Arrange
      final originalVideoFile = VideoFile(
        path: '/path/to/video.mp4',
        name: 'video.mp4',
        sizeInBytes: 1024000,
        format: 'mp4',
        createdAt: DateTime.now(),
      );
      
      // Act
      final updatedVideoFile = originalVideoFile.copyWith(
        name: 'updated_video.mp4',
        durationMs: 120000,
      );
      
      // Assert
      expect(updatedVideoFile.path, originalVideoFile.path);
      expect(updatedVideoFile.name, 'updated_video.mp4');
      expect(updatedVideoFile.sizeInBytes, originalVideoFile.sizeInBytes);
      expect(updatedVideoFile.format, originalVideoFile.format);
      expect(updatedVideoFile.durationMs, 120000);
      expect(updatedVideoFile.createdAt, originalVideoFile.createdAt);
    });

    test('should implement equality correctly', () {
      // Arrange
      final createdAt = DateTime.now();
      final videoFile1 = VideoFile(
        path: '/path/to/video.mp4',
        name: 'video.mp4',
        sizeInBytes: 1024000,
        format: 'mp4',
        createdAt: createdAt,
      );
      
      final videoFile2 = VideoFile(
        path: '/path/to/video.mp4',
        name: 'video.mp4',
        sizeInBytes: 1024000,
        format: 'mp4',
        createdAt: createdAt,
      );
      
      final videoFile3 = VideoFile(
        path: '/different/path/video.mp4',
        name: 'video.mp4',
        sizeInBytes: 1024000,
        format: 'mp4',
        createdAt: createdAt,
      );
      
      // Assert
      expect(videoFile1, equals(videoFile2));
      expect(videoFile1, isNot(equals(videoFile3)));
      expect(videoFile1.hashCode, equals(videoFile2.hashCode));
    });
  });
}