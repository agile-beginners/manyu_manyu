/// マニュアル生成ワークフローの高レベルなステージを表す。
enum ManualGenerationProgressStage {
  /// Gemini APIがアップロードされた動画を解析してステップを抽出中。
  analyzingVideo,

  /// 各ステップの画像が動画から抽出されアノテーション処理中。
  generatingImages,

  /// マニュアル生成が正常に完了した。
  completed,
}

