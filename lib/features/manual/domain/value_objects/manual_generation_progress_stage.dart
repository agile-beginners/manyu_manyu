/// Represents the high level stages of the manual generation workflow.
enum ManualGenerationProgressStage {
  /// Gemini API is analyzing the uploaded video to extract steps.
  analyzingVideo,

  /// Images are being extracted from the video and annotated for each step.
  generatingImages,

  /// Manual generation has finished successfully.
  completed,
}

