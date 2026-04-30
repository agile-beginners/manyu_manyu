# フィーチャーファースト再構成 マッピング

## 目的

この文書は、`2026-04-21-feature-first-restructure-design.md` の実装補助として、既存ファイルの移動先・削除対象・リネーム対象を一覧化したものである。

## 基本ルール

| 元の場所 | 移動先 | 備考 |
|---|---|---|
| `manual_editing/data/**` | `manual/data/**` | サービス実装 |
| `manual_editing/domain/**` | `manual/domain/**` / `manual/application/**` | entities/value_objects は domain、編集ロジックは application へ |
| `manual_editing/presentation/{providers,screens,widgets}/**` | `manual/presentation/editing/{providers,screens,widgets}/**` | 編集画面関連 |
| `manual_generation/data/**` | `manual/data/**` | リポジトリ実装、各種サービス実装 |
| `manual_generation/domain/**` | `manual/domain/**` / `manual/data/**` | entities/value_objects は domain、repository/service interface は data へ |
| `manual_generation/presentation/{providers,states}/**` | `manual/presentation/generation/{providers,states}/**` | 生成プロセスの状態管理 |
| `video_upload/**` | `video/**` | 構造はそのまま、フォルダ名のみ改名 |
| `home/**` | `home/**` | 変更なし |

## manual 統合後の構造

### domain

```text
manual/domain/
  entities/
    manual.dart               ← manual_generation/domain/entities/manual.dart
    manual.g.dart             ← manual_generation/domain/entities/manual.g.dart
    manual_status.dart        ← manual.dart から抽出
    manual_step.dart          ← manual_generation/domain/entities/manual_step.dart
    manual_step.g.dart        ← manual_generation/domain/entities/manual_step.g.dart
  value_objects/
    manual_generation_progress_stage.dart ← manual_generation/domain/value_objects/
```

> `repositories/` と `services/` は domain には置かない。

### data

```text
manual/data/
  repositories/
    manual_repository.dart      ← manual_generation/domain/repositories/manual_repository.dart
    manual_repository_impl.dart ← manual_generation/data/repositories/manual_repository_impl.dart
  services/
    video_analysis_service.dart        ← manual_generation/domain/services/gemini_service.dart
    gemini_video_analysis_service.dart ← manual_generation/data/services/gemini_service.dart
    gemini_image_service.dart          ← manual_generation/data/services/gemini_image_service.dart
    image_annotation_service.dart      ← manual_generation/domain/services/image_annotation_service.dart
    image_extraction_service.dart      ← manual_generation/data/services/image_extraction_service.dart
    nano_banana_service.dart           ← manual_generation/data/services/nano_banana_service.dart
    pdf_export_service.dart            ← manual_generation/domain/services/pdf_export_service.dart
    pdf_export_service_impl.dart       ← manual_generation/data/services/pdf_export_service_impl.dart
```

### application

```text
manual/application/
  manual_creation_service.dart   ← manual_generation/data/services/video_analysis_service.dart
  manual_edit_service.dart       ← manual_editing/data/services/manual_edit_service_impl.dart
  manual_export_service.dart     ← 新規作成
```

### presentation

```text
manual/presentation/
  generation/
    providers/
      video_analysis_controller.dart  ← manual_generation/presentation/providers/video_analysis_providers.dart
    states/
      video_analysis_state.dart       ← manual_generation/presentation/states/
    screens/
    widgets/
  editing/
    providers/
      manual_edit_controller.dart     ← manual_editing/presentation/providers/manual_edit_providers.dart
    screens/
      manual_edit_screen.dart         ← manual_editing/presentation/screens/
    widgets/
      step_list_widget.dart           ← manual_editing/presentation/widgets/
      step_edit_dialog.dart           ← manual_editing/presentation/widgets/
      manual_header_widget.dart       ← manual_editing/presentation/widgets/
  preview/
    screens/
    widgets/
  export/
    providers/
    widgets/
```

## video 統合後の構造

```text
video/
  data/
    repositories/
      video_repository.dart      ← video_upload/domain/repositories/video_repository.dart
      video_repository_impl.dart ← video_upload/data/repositories/video_repository_impl.dart
    services/
      video_upload_service.dart  ← video_upload/data/services/
  domain/
    entities/
      video_file.dart            ← video_upload/domain/entities/
      video_file.g.dart          ← video_upload/domain/entities/
  presentation/
    providers/
      video_upload_controller.dart ← video_upload/presentation/providers/video_upload_providers.dart
    screens/
      video_upload_screen.dart     ← video_upload/presentation/screens/
    widgets/
      file_selection_widget.dart   ← video_upload/presentation/widgets/
      upload_progress_widget.dart  ← video_upload/presentation/widgets/
      upload_status_widget.dart    ← video_upload/presentation/widgets/
```

> `video/domain/repositories/` は作らない。

## 特殊ケース

- `video_analysis_service.dart` は名前に `video` を含むが、実態は Manual 生成プロセスの一部なので `manual/data/services/` に置く
- `manual_export_service.dart` は PDF 出力の application 層の窓口として新規作成する
- `gemini_providers.dart` は責務混在のため廃止し、controller / query / DI に分離する

## 削除対象

- `manual_editing/` フォルダ
- `manual_generation/` フォルダ
- `manual_preview/` フォルダ
- `pdf_export/` フォルダ
- `video_upload/` フォルダ
- `manual_editing/domain/services/manual_edit_service.dart`
- `manual_generation/presentation/providers/gemini_providers.dart`
- すべての barrel ファイル
  - `manual_editing/data/data.dart`
  - `manual_editing/domain/domain.dart`
  - `manual_editing/presentation/presentation.dart`
  - `manual_generation/data/data.dart`
  - `manual_generation/domain/domain.dart`
  - `video_upload/data/data.dart`
  - `video_upload/domain/domain.dart`

## リネーム対象

| 変更前 | 変更後 | 備考 |
|---|---|---|
| `manual_edit_providers.dart` | `manual_edit_controller.dart` | presentation controller |
| `video_upload_providers.dart` | `video_upload_controller.dart` | presentation controller |
| `video_analysis_providers.dart` | `video_analysis_controller.dart` | presentation controller |
| `GeminiService` | `VideoAnalysisService` | abstract interface |
| `GeminiServiceImpl` | `GeminiVideoAnalysisService` | concrete data service |
| `VideoAnalysisService` | `ManualCreationService` | application service |
| `ManualEditServiceDataImpl` | `ManualEditService` | application service |

