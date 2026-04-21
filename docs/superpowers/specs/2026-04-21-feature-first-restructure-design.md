# フィーチャーファースト再構成 設計ドキュメント

**作成日:** 2026-04-21
**参考:** [Flutter Project Structure: Feature-first or Layer-first? (Code with Andrea)](https://codewithandrea.com/articles/flutter-project-structure/) / [Flutter App Architecture: The Application Layer (Code with Andrea)](https://codewithandrea.com/articles/flutter-app-architecture-application-layer/)

## 背景と目的

### 現状の問題

現状 `lib/features/` 配下は表面的には feature-first 構成になっているが、(記事)[https://codewithandrea.com/articles/flutter-project-structure/]が提唱する「feature」の概念（＝ユーザーが達成したいタスクに対応するドメイン単位）を取り入れられていない。

具体的には、`manual_editing` / `manual_generation` / `manual_preview` / `pdf_export` はいずれも **同じ Manual（マニュアル）ドメイン** を触る機能であるにもかかわらず、画面単位で別 feature として切られている。結果として:

- `manual_generation/data/services/pdf_export_service_impl.dart` のように、`pdf_export/` フィーチャーと別の場所に PDF 出力ロジックが存在する
- `manual_editing` の widget が `manual_generation/domain/entities/manual.dart` を参照する（Manual エンティティの所有者が曖昧）
- `manual_preview`, `pdf_export` は `.gitkeep` のみで空

### 目的

記事が示す "feature = ユーザーが達成したいタスク ＝ ドメイン集約" の定義に沿って、同じドメインを扱う複数の機能を 1 つの feature に統合し、ユーザーストーリーマップのエピックを presentation 配下のサブフォルダで表現する。

---

## 指針となる概念整理

### feature とは何か

- **誤解**: feature ＝ ユーザーストーリーマップのエピック（テキスト編集、画像編集、PDF書き出しなど）と 1:1
- **正しい理解**: feature ＝ **同じ "モノ"（ドメイン集約）を扱う機能群**
  - 複数のエピックが同じモノを扱う場合、それらは 1 つの feature に統合される（N:1）
  - 記事の `products` feature が「一覧・詳細・管理画面」など複数のエピックを束ねているのと同じ

### 集約とは何か

「一緒に扱う "モノ" のかたまり」と理解すれば十分。このプロジェクトにおいては:

- **Manual 集約** ＝ `Manual` と `ManualStep` のセット。生成・編集・プレビュー・PDF 出力すべてがこの集約を触る
- **Video 集約** ＝ `VideoFile`。アップロードと管理を担当

### ユーザーストーリーマップとの対応

| 階層 | 例 | フォルダ構成との対応 |
|---|---|---|
| ユーザー行動 | 動画を準備する / マニュアルを生成する / 編集する / 出力する | 複数がドメインに対応する場合は 1 feature に集約 |
| エピック | AI解析、テキスト編集、画像編集、PDF書き出し | `presentation/` 配下のサブフォルダ |
| ストーリー | ステップのテキストを修正する、など | 個別の Widget / 画面 |

### feature-first の開発順序

記事の "How to do feature-first, the right way" が示す手順は以下の通り:

1. **ユーザー行動（ユーザーが達成したいタスク）を洗い出す**
2. その行動で扱う **モデル（モノ／集約）** と、それを操作する **ビジネスロジック** を特定する
3. 関連するモデル群ごとに 1 つのフォルダ（＝ feature）を作る
4. その中に `data / domain / application / presentation` を **必要に応じて** 作る

記事の手順そのものはステップ 2〜4（"start from the domain layer..."）を明示しているが、記事冒頭で "feature とは what the user does" と定義しているため、ステップ 1 が暗黙の起点になっている。

**モデルとビジネスロジックを識別する際のポイント:**

- **モデル（モノ）**: 「Manual と ManualStep は常にセットで扱う」のように、一貫性を保って扱うべきデータのかたまり ＝ 集約
- **ビジネスロジック**: そのモノに対する操作（生成する、編集する、並び替える、PDF化する など）

この 2 つを束ねた単位が feature になる。

**新規開発と既存コード改善の違い:**

- 新規開発: 上記ステップ 1 → 4 を順方向に進める
- 既存コードからの改善（今回のリファクタリング）: 逆方向に辿る
  1. 既存コードからモデル（`Manual`, `ManualStep`, `VideoFile`）を発見する
  2. その "モノ" を触っているロジック群を集める
  3. 1 つの feature フォルダに統合する

方向は違うが「モデルとロジックがまとまる単位 ＝ feature」という本質は同じ。

---

## スコープ

今回のリファクタリングは **`lib/features/` 配下のみ** を対象とする:

- ✅ `lib/features/` 配下の feature 統合・再配置
- ❌ `lib/src/` を挟む構造への変更（行わない）
- ❌ `lib/core/` の解体・再編（行わない）

小さく始めて効果を確認してから、将来的に `core/` の再編や `lib/src/` 導入を検討する方針。

---

## 設計

### 全体フォルダ構造

```
lib/
  core/                       (現状維持、今回は触らない)
  features/
    home/                     (UI のみの feature、現状維持)
      presentation/
        screens/
        widgets/
    video/                    (旧 video_upload、改名)
      data/
        repositories/
        services/
      domain/
        entities/
        repositories/
      presentation/
        providers/
        screens/
        widgets/
    manual/                   (旧 manual_editing + manual_generation + manual_preview + pdf_export を統合)
      application/            (オプション／必要になったら service を追加、初期は空)
      data/
        repositories/
        services/
      domain/
        entities/
        repositories/
        services/
        value_objects/
      presentation/
        generation/           ← エピック: マニュアルを生成する
          providers/
          screens/
          states/
          widgets/
        editing/              ← エピック: マニュアルを編集する
          providers/
          screens/
          widgets/
        preview/              ← エピック: プレビュー確認
          screens/
          widgets/
        export/               ← エピック: PDF書き出し
          widgets/
  main.dart
```

### 主な設計判断

1. `features/` 直下は **`home` / `video` / `manual` の 3 feature に集約**
2. `manual/presentation/` 配下は **ユーザーストーリーマップのエピック単位** でサブフォルダを切る（`generation`, `editing`, `preview`, `export`）
3. 各エピックサブフォルダ内は従来どおり **型別フォルダ**（`providers/screens/widgets/states`）で整理
4. `manual/application/` は**用意だけしておき、必要になってから中身を追加**（記事が示す application 層のオプショナル方針に従う）
5. `video/presentation/` はサブ機能が 1 つ（アップロード）しかないため、エピックサブフォルダは切らず型別のみ
6. `home/` は UI のみ（domain / data なし）の軽い feature として維持。記事の `address` feature が同様の扱い

---

## ファイル移動マッピング

### 基本ルール

| 元の場所 | 移動先 | 備考 |
|---|---|---|
| `manual_editing/data/**` | `manual/data/**` | サービス実装 |
| `manual_editing/domain/**` | `manual/domain/**` | サービスインターフェース |
| `manual_editing/presentation/{providers,screens,widgets}/**` | `manual/presentation/editing/{providers,screens,widgets}/**` | 編集画面関連 |
| `manual_generation/data/**` | `manual/data/**` | リポジトリ実装、各種サービス実装 |
| `manual_generation/domain/**` | `manual/domain/**` | Manual 集約本体、リポジトリインターフェース、値オブジェクト |
| `manual_generation/presentation/{providers,states}/**` | `manual/presentation/generation/{providers,states}/**` | 生成プロセスの状態管理 |
| `video_upload/**` | `video/**` | 構造はそのまま、フォルダ名のみ改名 |
| `home/**` | `home/**` | 変更なし |

### 詳細マッピング

**manual 統合後の `domain/`**:
```
manual/domain/
  entities/
    manual.dart               ← manual_generation/domain/entities/manual.dart
    manual.g.dart             ← manual_generation/domain/entities/manual.g.dart
    manual_step.dart          ← manual_generation/domain/entities/manual_step.dart
    manual_step.g.dart        ← manual_generation/domain/entities/manual_step.g.dart
  repositories/
    manual_repository.dart    ← manual_generation/domain/repositories/manual_repository.dart
  services/
    manual_edit_service.dart  ← manual_editing/domain/services/manual_edit_service.dart
    gemini_service.dart       ← manual_generation/domain/services/gemini_service.dart
    image_annotation_service.dart ← manual_generation/domain/services/image_annotation_service.dart
    pdf_export_service.dart   ← manual_generation/domain/services/pdf_export_service.dart
  value_objects/
    manual_generation_progress_stage.dart ← manual_generation/domain/value_objects/
```

**manual 統合後の `data/`**:
```
manual/data/
  repositories/
    manual_repository_impl.dart ← manual_generation/data/repositories/
  services/
    manual_edit_service_impl.dart ← manual_editing/data/services/
    gemini_service.dart          ← manual_generation/data/services/gemini_service.dart
    gemini_image_service.dart    ← manual_generation/data/services/gemini_image_service.dart
    image_extraction_service.dart ← manual_generation/data/services/
    nano_banana_service.dart     ← manual_generation/data/services/
    pdf_export_service_impl.dart ← manual_generation/data/services/
    video_analysis_service.dart  ← manual_generation/data/services/
```

**manual 統合後の `presentation/`**:
```
manual/presentation/
  generation/
    providers/
      video_analysis_controller.dart  ← manual_generation/presentation/providers/video_analysis_providers.dart (リネーム)
      gemini_providers.dart           ← manual_generation/presentation/providers/gemini_providers.dart (リネームしない)
    states/
      video_analysis_state.dart       ← manual_generation/presentation/states/
    screens/                          (今は空、将来の進捗画面などが入る)
    widgets/                          (今は空)
  editing/
    providers/
      manual_edit_controller.dart     ← manual_editing/presentation/providers/manual_edit_providers.dart (リネーム)
    screens/
      manual_edit_screen.dart         ← manual_editing/presentation/screens/
    widgets/
      step_list_widget.dart           ← manual_editing/presentation/widgets/
      step_edit_dialog.dart           ← manual_editing/presentation/widgets/
      manual_header_widget.dart       ← manual_editing/presentation/widgets/
  preview/
    screens/                          (今は空、将来のプレビュー画面が入る)
    widgets/                          (今は空)
  export/
    widgets/                          (今は空、将来の PDF 出力ダイアログなどが入る)
```

**video（旧 video_upload）**:
```
video/
  data/
    repositories/
      video_repository_impl.dart      ← video_upload/data/repositories/
    services/
      video_upload_service.dart       ← video_upload/data/services/
  domain/
    entities/
      video_file.dart                 ← video_upload/domain/entities/
      video_file.g.dart               ← video_upload/domain/entities/
    repositories/
      video_repository.dart           ← video_upload/domain/repositories/
  presentation/
    providers/
      video_upload_controller.dart    ← video_upload/presentation/providers/video_upload_providers.dart (リネーム)
    screens/
      video_upload_screen.dart        ← video_upload/presentation/screens/
    widgets/
      file_selection_widget.dart      ← video_upload/presentation/widgets/
      upload_progress_widget.dart     ← video_upload/presentation/widgets/
      upload_status_widget.dart       ← video_upload/presentation/widgets/
```

### 特殊ケースの判断

**① `video_analysis_service.dart` は `manual/` へ**

「動画を受け取ってAIで解析し、マニュアルのステップを抽出する」サービス。名前に `video` が入っているが、**実態はマニュアル生成プロセスの一部**（動画は入力でしかない）。`manual/data/services/` が正しい配置。

**② `gemini_providers.dart` はリネームせず `manual/presentation/generation/providers/` に配置**

中身は Gemini サービスの Riverpod DI 用 provider（Controller ではない）。本来なら `application/` 層の service DI として配置するのが記事的には正しいが、今回は「application はオプション、必要になってから追加」方針に沿って、いったん `generation/providers/` に置く。必要性が見えた段階で `application/` に引き上げる、インクリメンタルな方針。

### 削除対象

- `manual_editing/` フォルダ（移動完了後、空になるため削除）
- `manual_generation/` フォルダ（移動完了後、空になるため削除）
- `manual_preview/` フォルダ（中身 `.gitkeep` のみ、削除。新しい `manual/presentation/preview/` に役割が引き継がれる）
- `pdf_export/` フォルダ（中身 `.gitkeep` のみ、削除。新しい `manual/presentation/export/` に役割が引き継がれる）
- `video_upload/` フォルダ（移動完了後、空になるため削除）
- すべての barrel ファイル:
  - `manual_editing/data/data.dart`
  - `manual_editing/domain/domain.dart`
  - `manual_editing/presentation/presentation.dart`
  - `manual_generation/data/data.dart`
  - `manual_generation/domain/domain.dart`
  - `video_upload/data/data.dart`
  - `video_upload/domain/domain.dart`

---

## 命名変更

### Controller へのリネーム

`ecommerce_app` の命名に合わせて、画面状態を管理する Notifier ファイルを `xxx_controller.dart` 名に統一する:

| 変更前 | 変更後 |
|---|---|
| `manual_edit_providers.dart` | `manual_edit_controller.dart` |
| `video_upload_providers.dart` | `video_upload_controller.dart` |
| `video_analysis_providers.dart` | `video_analysis_controller.dart` |
| `gemini_providers.dart` | 変更なし（Controller ではなく DI 用 provider のため） |

**付随作業:**
- 対応する `.g.dart`（Riverpod code gen）もリネーム
- ファイル内のクラス名の変更（例: `ManualEditNotifier` → `ManualEditController`）は実装時にファイル内容を確認した上で判断
- 移動・リネーム後に `dart run build_runner build --delete-conflicting-outputs` を実行して `.g.dart` を再生成

### barrel ファイル削除と import の書き換え

全 import 文を移動後のパスに合わせて更新する。対象は以下の 2 種類:

**① barrel 経由の import を直接 import に置き換える**

```dart
// Before
import 'package:manyu_manyu/features/manual_editing/domain/domain.dart';

// After
import 'package:manyu_manyu/features/manual/domain/services/manual_edit_service.dart';
```

**② ファイル直接 import のパスを更新する**

移動・リネームに伴い、barrel を経由していない import もすべて新しいパスに書き換える。例えば `home/presentation/widgets/primary_actions.dart` の以下の import を更新する:

```dart
// Before
import '../../../video_upload/presentation/screens/video_upload_screen.dart';

// After
import '../../../video/presentation/screens/video_upload_screen.dart';
```

相対 import / 絶対 import のどちらを使うかは既存コードのスタイルを踏襲する。

---

## 検証手順

再構成完了後、以下のコマンドで検証:

1. `dart run build_runner build --delete-conflicting-outputs` — `.g.dart` の再生成
2. `fvm flutter analyze` — import エラー、未使用参照がないことを確認
3. `fvm flutter test` — 既存テストがあれば通ることを確認
4. `fvm flutter run` — アプリ起動と主要フロー（ホーム画面 → 動画アップロード → マニュアル生成 → 編集）が動作することを確認

---

## スコープ外（将来の検討事項）

以下は今回のリファクタリングには含めず、必要性が見えた時点で別途スコープとして扱う:

- `lib/src/` を挟む構造への変更
- `lib/core/` の解体（記事の `common_widgets / constants / exceptions / routing / utils` スタイルへの再編）
- `application/` 層の実体追加（複数リポジトリをまたぐサービスが必要になった場合）
- `gemini_providers.dart` の `application/` への引き上げ
- Riverpod Notifier のクラス命名変更（`XxxNotifier` → `XxxController`）
