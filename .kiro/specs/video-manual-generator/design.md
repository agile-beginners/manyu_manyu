# 設計書

## 概要

Video Manual Generatorは、動画から自動的にマニュアルを生成するFlutterアプリケーションです。Gemini APIによる動画解析とNano Banana APIによる画像注釈機能を組み合わせ、ユーザーが操作手順を録画した動画から、わかりやすいステップバイステップのマニュアルを自動生成します。

## アーキテクチャ

### 全体アーキテクチャ

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter UI    │    │  Business Logic │    │  External APIs  │
│                 │    │                 │    │                 │
│ - Upload Screen │◄──►│ - Video Service │◄──►│ - Gemini API    │
│ - Edit Screen   │    │ - Manual Service│    │ - Nano Banana   │
│ - Preview Screen│    │ - Export Service│    │   API           │
│ - PDF Export    │    │ - Storage       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 状態管理アーキテクチャ

**Riverpod**を使用した状態管理:
- **Provider**: データの提供とビジネスロジックの管理
- **ConsumerWidget**: UIコンポーネントでの状態の購読
- **StateNotifier**: 複雑な状態変更の管理
- **AsyncValue**: 非同期処理の状態管理（loading, data, error）

### Feature-First ディレクトリ構成

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
├── features/
│   ├── video_upload/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── manual_generation/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── manual_editing/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── manual_preview/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── pdf_export/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

## コンポーネントとインターフェース

### 1. Video Upload Feature

**責任**: 動画ファイルのアップロードと検証

**主要コンポーネント**:
- `VideoUploadScreen`: 動画選択とアップロードUI
- `VideoUploadService`: ファイル検証とアップロード処理
- `VideoRepository`: 動画ファイルの一時保存

**インターフェース**:
```dart
abstract class VideoRepository {
  Future<Result<VideoFile>> uploadVideo(File videoFile);
  Future<Result<bool>> validateVideo(File videoFile);
}
```

### 2. Manual Generation Feature

**責任**: AI APIを使用したマニュアル生成

**主要コンポーネント**:
- `GeminiService`: Gemini APIとの通信
- `NanoBananaService`: Nano Banana APIとの通信
- `VideoAnalysisService`: 動画解析の統合処理
- `ImageExtractionService`: 動画からの画像切り出し

**インターフェース**:
```dart
abstract class GeminiService {
  Future<Result<List<ManualStep>>> analyzeVideo(VideoFile video);
}

abstract class NanoBananaService {
  Future<Result<String>> annotateImage(String imagePath);
}
```

### 3. Manual Editing Feature

**責任**: 生成されたマニュアルの編集機能

**主要コンポーネント**:
- `ManualEditScreen`: マニュアル編集UI
- `ManualEditService`: マニュアルデータの更新処理
- `ManualRepository`: マニュアルデータの永続化

### 4. Manual Preview Feature

**責任**: プレビューモードでのマニュアル表示

**主要コンポーネント**:
- `ManualPreviewScreen`: フルスクリーンプレビューUI
- `PreviewNavigationService`: ステップ間のナビゲーション

### 5. PDF Export Feature

**責任**: マニュアルのPDF出力

**主要コンポーネント**:
- `PdfExportService`: PDF生成処理
- `PdfTemplateService`: PDFレイアウト管理

## データモデル

### ManualStep
```dart
class ManualStep {
  final String title;
  final String description;
  final int timestamp; // ミリ秒
  final String? imagePath;
  
  ManualStep({
    required this.title,
    required this.description,
    required this.timestamp,
    this.imagePath,
  });
}
```

### Manual
```dart
class Manual {
  final String id;
  final String title;
  final List<ManualStep> steps;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Manual({
    required this.id,
    required this.title,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

### VideoFile
```dart
class VideoFile {
  final String path;
  final String name;
  final int sizeInBytes;
  final String format;
  
  VideoFile({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.format,
  });
}
```

## 正確性プロパティ

*プロパティとは、システムの全ての有効な実行において真であるべき特性や動作のことです。本質的には、システムが何をすべきかについての形式的な記述です。プロパティは、人間が読める仕様と機械で検証可能な正確性保証の橋渡しとなります。*

### プロパティ反映

全ての受入基準を分析した結果、以下のプロパティが特定されました。冗長性を排除し、各プロパティが独自の検証価値を提供することを確認しました。

**Property 1: ファイル形式検証の一貫性**
*任意の*ファイルに対して、対応する動画形式（MP4、MOV、AVI）は受け入れられ、非対応形式は拒否される
**検証対象: 要件 1.1, 1.2, 1.3**

**Property 2: アップロード完了時のUI状態遷移**
*任意の*有効な動画ファイルに対して、アップロード完了時には進捗表示が100%になり、完了通知が表示される
**検証対象: 要件 1.4**

**Property 3: API呼び出しの確実性**
*任意の*動画アップロード完了イベントに対して、Gemini APIへの呼び出しが必ず実行される
**検証対象: 要件 2.1**

**Property 4: ステップ数制限の遵守**
*任意の*動画解析結果に対して、抽出されるステップ数は1以上20以下である
**検証対象: 要件 2.2**

**Property 5: JSON構造の完全性**
*任意の*ステップ抽出結果に対して、各ステップにはtitle、description、timestampフィールドが必ず含まれる
**検証対象: 要件 2.3**

**Property 6: エラーハンドリングの一貫性**
*任意の*API通信エラーに対して、エラーメッセージの表示と再試行オプションの提供が行われる
**検証対象: 要件 2.4, 3.4, 4.4, 7.4**

**Property 7: 画像抽出とファイル保存の対応**
*任意の*タイムスタンプリストに対して、各タイムスタンプから抽出された画像がローカルに保存される
**検証対象: 要件 3.1, 3.2**

**Property 8: 画像処理パイプラインの完全性**
*任意の*抽出された画像セットに対して、全ての画像がNano Banana APIに送信され、注釈付き画像として保存される
**検証対象: 要件 3.3, 4.1, 4.2**

**Property 9: データ更新の整合性**
*任意の*画像編集完了イベントに対して、対応するステップJSONに画像パスが正しく追加される
**検証対象: 要件 4.3**

**Property 10: フォールバック処理の確実性**
*任意の*画像編集APIエラーに対して、元画像が使用されてステップ処理が継続される
**検証対象: 要件 4.4**

**Property 11: マニュアル表示の完全性**
*任意の*生成されたマニュアルに対して、全てのステップが一覧表示され、各ステップが編集可能である
**検証対象: 要件 5.1, 5.2**

**Property 12: リアルタイム保存の確実性**
*任意の*ステップ編集操作に対して、変更内容がリアルタイムで保存され、データが永続化される
**検証対象: 要件 5.3, 5.4**

**Property 13: プレビューナビゲーションの正確性**
*任意の*プレビューモードにおいて、左タップで前ステップ、右タップで次ステップに移動し、境界条件で適切な処理が行われる
**検証対象: 要件 6.1, 6.2, 6.3, 6.4**

**Property 14: PDF生成の完全性**
*任意の*マニュアルデータに対して、PDF出力時には全ステップの画像と説明が含まれた整形されたドキュメントが生成される
**検証対象: 要件 7.1, 7.2, 7.3**

**Property 15: レスポンシブデザインの適応性**
*任意の*デバイス環境（スマートフォン、Web）に対して、適切なUIが表示され、タッチイベントが正しく処理される
**検証対象: 要件 8.1, 8.2, 8.3, 8.4**

## エラーハンドリング

### エラー分類と対応策

**1. ネットワークエラー**
- API通信失敗時の再試行機構
- オフライン状態の検出と通知
- タイムアウト処理

**2. ファイル処理エラー**
- 不正な動画形式の検出
- ファイルサイズ制限の実装
- 破損ファイルの処理

**3. AI処理エラー**
- Gemini API応答エラーの処理
- Nano Banana API障害時のフォールバック
- 処理時間超過の対応

**4. ストレージエラー**
- ローカルストレージ不足の検出
- 一時ファイルのクリーンアップ
- データ破損の検出と復旧

## テスト戦略

### デュアルテストアプローチ

**ユニットテスト**:
- 各サービスクラスの個別機能テスト
- データモデルの検証テスト
- エラーハンドリングの具体例テスト
- API通信のモックテスト

**プロパティベーステスト**:
- 上記15個の正確性プロパティの検証
- Flutter Test + faker パッケージを使用
- 各プロパティテストは最低100回の反復実行
- 各テストには対応する設計書プロパティへの明示的な参照を含める

**プロパティベーステストライブラリ**: Flutter Test framework + faker パッケージ

**テスト実行設定**:
- 各プロパティテストは最低100回の反復実行
- ランダムデータ生成による幅広い入力テスト
- 失敗時の反例保存と再現機能

**テストタグ形式**:
各プロパティベーステストには以下の形式でコメントを付与:
`**Feature: video-manual-generator, Property {number}: {property_text}**`