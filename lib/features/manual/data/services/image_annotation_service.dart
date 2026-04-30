import '../../../../core/utils/result.dart';

/// Interface for image annotation service
abstract class ImageAnnotationService {
  /// Generates an annotated image with arrows, text, and highlights
  /// 
  /// Requirements: 4.1, 4.2, 4.3, 4.4
  /// - 4.1: Images are sent to annotation API with red arrows, text, circles
  /// - 4.2: Annotated images are generated and saved locally
  /// - 4.3: Image paths are added to step JSON when editing completes
  /// - 4.4: Original images are used when API communication fails
  Future<Result<String>> generateAnnotatedImage({
    required String originalImagePath,
    required String stepTitle,
    required String stepDescription,
    required int stepNumber,
  });
}