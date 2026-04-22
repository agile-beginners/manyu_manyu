# フィーチャーファースト再構成 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Note:** この計画はユーザーが手動で実装する想定で、設計書の最新方針に合わせて更新している。

**Goal:** `lib/features/` 配下を feature-first の原則に沿って再構成し、`manual_editing` / `manual_generation` / `manual_preview` / `pdf_export` を `manual/` に統合、`video_upload` を `video/` に改名する。

**Implementation Principles:**
- `video` の責務は `VideoFile` を返すところまでとする
- `video` から `manual/generation` への受け渡しは、画面遷移時に `VideoFile` を引数として渡す
- `domain/` には `entities` と `value_objects` のみ残す
- Repository interface は `data/repositories/`、外部 service interface は `data/services/` に置く
- `application` の service は concrete class を直接置き、`Ref` を受け取ってよい
- query provider は `presentation` ではなく `application` 側に置く
- service ファイルには service 本体・service provider・関連 query provider を近接配置してよい
- controller は画面固有状態に専念し、query provider 更新は service に委譲する

**Tech Stack:** Flutter (fvm), Dart, Riverpod / Riverpod Generator, build_runner, json_serializable, git

**関連ドキュメント:**
- [設計ドキュメント](../specs/2026-04-21-feature-first-restructure-design.md)
- [移動マッピング](../specs/2026-04-21-feature-first-restructure-mapping.md)

---

## 前提条件

- プロジェクトルートは `/Users/8mitsuboy/workspaces/manyu_manyu`
- 以降のコマンドは全てプロジェクトルートで実行する想定
- Flutter は `fvm flutter ...` で実行する
- 実装前に `git status` でワーキングツリーを確認する
- 未コミット変更がある場合は、このリファクタリングと無関係な差分を混ぜない

---

## Phase 0: 準備

### Task 0.1: 現状確認

- [ ] **Step 0.1.1: ブランチと差分を確認**

```bash
git status
git branch --show-current
```

- [ ] **Step 0.1.2: リファクタリング用ブランチを切る**

```bash
git checkout -b refactor/feature-first-restructure
```

- [ ] **Step 0.1.3: `fvm flutter analyze` を実行し、現状エラーの有無を記録**

```bash
fvm flutter analyze
```

期待: 現状の基準点を把握できる。

---

## Phase 1: 空 feature と `video` の整備

このフェーズでは依存の少ない箇所から片付ける。

### Task 1.1: 空 feature を削除

- [ ] **Step 1.1.1: `manual_preview/`, `pdf_export/` が空であることを確認**

```bash
find lib/features/manual_preview -type f
find lib/features/pdf_export -type f
```

- [ ] **Step 1.1.2: 空 feature を削除**

```bash
git rm -r lib/features/manual_preview
git rm -r lib/features/pdf_export
```

### Task 1.2: `video_upload` を `video` に改名

- [ ] **Step 1.2.1: フォルダをリネーム**

```bash
git mv lib/features/video_upload lib/features/video
```

- [ ] **Step 1.2.2: `VideoRepository` interface を `data/repositories/` に寄せる**

```bash
git mv lib/features/video/domain/repositories/video_repository.dart lib/features/video/data/repositories/video_repository.dart
```

- [ ] **Step 1.2.3: 空になった `domain/repositories/` を削除**

```bash
rm -rf lib/features/video/domain/repositories
```

- [ ] **Step 1.2.4: barrel ファイルを削除**

```bash
git rm lib/features/video/data/data.dart
git rm lib/features/video/domain/domain.dart
```

### Task 1.3: `video` 側の controller 名を整理

- [ ] **Step 1.3.1: provider ファイルを controller 名に変更**

```bash
git mv lib/features/video/presentation/providers/video_upload_providers.dart lib/features/video/presentation/providers/video_upload_controller.dart
```

- [ ] **Step 1.3.2: `VideoUploadStateNotifier` を `VideoUploadController` にリネーム**

対象:
- クラス名
- コンストラクタ名
- `StateNotifierProvider<...>` の型引数

### Task 1.4: `video_upload` 参照の import を更新

- [ ] **Step 1.4.1: 参照元を洗い出す**

```bash
rg -n "features/video_upload|video_upload_providers\\.dart|VideoUploadStateNotifier" lib
```

- [ ] **Step 1.4.2: パスとクラス名を更新**

方針:
- `features/video_upload` → `features/video`
- `video_upload_providers.dart` → `video_upload_controller.dart`
- `VideoUploadStateNotifier` → `VideoUploadController`

### Task 1.5: `video` の責務境界を実装で合わせる準備

- [ ] **Step 1.5.1: `video/presentation/screens/video_upload_screen.dart` の現状を確認**

確認ポイント:
- `manual_generation` や `manual_editing` を直接 import していないか
- upload 完了後に解析開始まで握っていないか

- [ ] **Step 1.5.2: この時点では、`video` が最終的に `VideoFile` を渡すだけの画面になる前提をメモする**

このフェーズではまだ完全移行しなくてよいが、以降のフェーズで `manual/generation` に責務を寄せる前提を崩さない。

- [ ] **Step 1.5.3: analyze**

```bash
fvm flutter analyze
```

---

## Phase 2: `manual` の domain / data 統合

このフェーズで `Manual` 集約の所有権を `manual/` に寄せる。

### Task 2.1: `manual/` の基本構造を整える

- [ ] **Step 2.1.1: 既存の `manual/` 配下を確認**

```bash
find lib/features/manual -maxdepth 4 -type d | sort
```

- [ ] **Step 2.1.2: 不足ディレクトリがあれば補完**

必要に応じて:
- `application/`
- `data/repositories/`
- `data/services/`
- `domain/entities/`
- `domain/value_objects/`
- `presentation/generation/`
- `presentation/editing/`
- `presentation/preview/`
- `presentation/export/`

### Task 2.2: `manual_generation/domain` を `manual/domain` / `manual/data` に寄せる

- [ ] **Step 2.2.1: entities を移動**

```bash
git mv lib/features/manual_generation/domain/entities/manual.dart lib/features/manual/domain/entities/manual.dart
git mv lib/features/manual_generation/domain/entities/manual.g.dart lib/features/manual/domain/entities/manual.g.dart
git mv lib/features/manual_generation/domain/entities/manual_step.dart lib/features/manual/domain/entities/manual_step.dart
git mv lib/features/manual_generation/domain/entities/manual_step.g.dart lib/features/manual/domain/entities/manual_step.g.dart
```

- [ ] **Step 2.2.2: `ManualStatus` を `manual_status.dart` に分離**

作業内容:
- `manual.dart` から enum を切り出す
- `lib/features/manual/domain/entities/manual_status.dart` を作成
- `manual.dart` 側は import に切り替える

- [ ] **Step 2.2.3: value object を移動**

```bash
git mv lib/features/manual_generation/domain/value_objects/manual_generation_progress_stage.dart lib/features/manual/domain/value_objects/manual_generation_progress_stage.dart
```

- [ ] **Step 2.2.4: Repository interface を `data/repositories/` へ移動**

```bash
git mv lib/features/manual_generation/domain/repositories/manual_repository.dart lib/features/manual/data/repositories/manual_repository.dart
```

- [ ] **Step 2.2.5: 外部 service interface を `data/services/` へ移動**

```bash
git mv lib/features/manual_generation/domain/services/gemini_service.dart lib/features/manual/data/services/video_analysis_service.dart
git mv lib/features/manual_generation/domain/services/image_annotation_service.dart lib/features/manual/data/services/image_annotation_service.dart
git mv lib/features/manual_generation/domain/services/pdf_export_service.dart lib/features/manual/data/services/pdf_export_service.dart
```

- [ ] **Step 2.2.6: interface 名を設計に合わせて整理**

方針:
- abstract `GeminiService` → `VideoAnalysisService`
- concrete Gemini 実装は `GeminiVideoAnalysisService`

### Task 2.3: `manual_generation/data` を `manual/data` に寄せる

- [ ] **Step 2.3.1: repository 実装を移動**

```bash
git mv lib/features/manual_generation/data/repositories/manual_repository_impl.dart lib/features/manual/data/repositories/manual_repository_impl.dart
```

- [ ] **Step 2.3.2: 外部 service 実装を移動**

```bash
git mv lib/features/manual_generation/data/services/gemini_image_service.dart lib/features/manual/data/services/gemini_image_service.dart
git mv lib/features/manual_generation/data/services/image_extraction_service.dart lib/features/manual/data/services/image_extraction_service.dart
git mv lib/features/manual_generation/data/services/nano_banana_service.dart lib/features/manual/data/services/nano_banana_service.dart
git mv lib/features/manual_generation/data/services/pdf_export_service_impl.dart lib/features/manual/data/services/pdf_export_service_impl.dart
```

- [ ] **Step 2.3.3: concrete Gemini 実装を移動・改名**

```bash
git mv lib/features/manual_generation/data/services/gemini_service.dart lib/features/manual/data/services/gemini_video_analysis_service.dart
```

### Task 2.4: `manual_editing` の domain / data を整理

- [ ] **Step 2.4.1: `manual_editing/domain/services/manual_edit_service.dart` を削除**

理由: application service は abstract class を作らず concrete class を直接 `application/` に置くため。

```bash
git rm lib/features/manual_editing/domain/services/manual_edit_service.dart
```

- [ ] **Step 2.4.2: `manual_editing/data/services/manual_edit_service_impl.dart` は後続フェーズで `manual/application/manual_edit_service.dart` に移す前提で保持**

この段階では位置だけ確認し、次フェーズで application 化する。

- [ ] **Step 2.4.3: 不要 barrel を削除**

```bash
git rm lib/features/manual_generation/domain/domain.dart
git rm lib/features/manual_editing/domain/domain.dart
git rm lib/features/manual_generation/data/data.dart
git rm lib/features/manual_editing/data/data.dart
```

- [ ] **Step 2.4.4: analyze**

```bash
fvm flutter analyze
```

期待: presentation 由来のエラーは残り得るが、domain / data の移動方針自体は揃っている。

---

## Phase 3: `manual/application` への service 再配置

このフェーズで設計の中心だった application service の責務を実装に落とす。

### Task 3.1: `ManualCreationService` を作る

- [ ] **Step 3.1.1: 旧 orchestration 実装を `manual/application/manual_creation_service.dart` へ移動**

移行元:
- `lib/features/manual_generation/data/services/video_analysis_service.dart`

移行先:
- `lib/features/manual/application/manual_creation_service.dart`

- [ ] **Step 3.1.2: クラス名を `ManualCreationService` に変更**

- [ ] **Step 3.1.3: service ファイル内に関連 provider を定義**

対象例:
- `manualCreationServiceProvider`
- 生成系 query provider
- 生成完了後に invalidate 対象となる provider

### Task 3.2: `ManualEditService` を作る

- [ ] **Step 3.2.1: 旧 `manual_edit_service_impl.dart` を `manual/application/manual_edit_service.dart` へ移動**

```bash
git mv lib/features/manual_editing/data/services/manual_edit_service_impl.dart lib/features/manual/application/manual_edit_service.dart
```

- [ ] **Step 3.2.2: クラス名を `ManualEditService` に変更**

- [ ] **Step 3.2.3: service ファイルに以下を近接配置**

対象例:
- `manualEditServiceProvider`
- `manualProvider`
- `allManualsProvider`
- `manualStepCountProvider`
- `canExportManualProvider`

### Task 3.3: `ManualExportService` を作る

- [ ] **Step 3.3.1: PDF 出力の orchestration を `manual/application/manual_export_service.dart` に切り出す**

方針:
- presentation から `PdfExportService` 実装を直接呼ばない
- `ManualExportService` が repository / export service / query 更新を調停する

### Task 3.4: `Ref` と `invalidate` の責務を service 側に寄せる

- [ ] **Step 3.4.1: 各 application service が `Ref` を受け取るようにする**

- [ ] **Step 3.4.2: 書き込み成功後に関連 query provider を `invalidate` する**

例:
- Manual 生成後
  - `manualProvider(newManualId)`
  - `allManualsProvider`
- Manual 編集後
  - `manualProvider(manualId)`
  - `allManualsProvider`
  - 必要に応じて派生 provider

### Task 3.5: `main.dart` 依存の配線を増やさない

- [ ] **Step 3.5.1: `main.dart` に feature ごとの override を追加しない**

方針:
- `main.dart` は `ProviderScope` の起動と全体初期化に留める
- feature 実装の詳細は service / provider 側に閉じる

- [ ] **Step 3.5.2: analyze**

```bash
fvm flutter analyze
```

---

## Phase 4: `manual/presentation` の統合

### Task 4.1: `manual_generation/presentation` を `manual/presentation/generation` に統合

- [ ] **Step 4.1.1: state を移動**

```bash
git mv lib/features/manual_generation/presentation/states/video_analysis_state.dart lib/features/manual/presentation/generation/states/video_analysis_state.dart
```

- [ ] **Step 4.1.2: generation controller を移動・改名**

```bash
git mv lib/features/manual_generation/presentation/providers/video_analysis_providers.dart lib/features/manual/presentation/generation/providers/video_analysis_controller.dart
```

- [ ] **Step 4.1.3: `VideoAnalysisNotifier` を `VideoAnalysisController` に変更**

### Task 4.2: `manual_editing/presentation` を `manual/presentation/editing` に統合

- [ ] **Step 4.2.1: controller を移動・改名**

```bash
git mv lib/features/manual_editing/presentation/providers/manual_edit_providers.dart lib/features/manual/presentation/editing/providers/manual_edit_controller.dart
```

- [ ] **Step 4.2.2: screen を移動**

```bash
git mv lib/features/manual_editing/presentation/screens/manual_edit_screen.dart lib/features/manual/presentation/editing/screens/manual_edit_screen.dart
```

- [ ] **Step 4.2.3: widget を移動**

```bash
git mv lib/features/manual_editing/presentation/widgets/manual_header_widget.dart lib/features/manual/presentation/editing/widgets/manual_header_widget.dart
git mv lib/features/manual_editing/presentation/widgets/step_edit_dialog.dart lib/features/manual/presentation/editing/widgets/step_edit_dialog.dart
git mv lib/features/manual_editing/presentation/widgets/step_list_widget.dart lib/features/manual/presentation/editing/widgets/step_list_widget.dart
```

- [ ] **Step 4.2.4: `ManualEditNotifier` を `ManualEditController` に変更**

### Task 4.3: `video -> manual/generation` の受け渡しを実装で反映

- [ ] **Step 4.3.1: `video_upload_screen.dart` は upload 完了後に `VideoFile` を引数として generation 画面へ遷移する形に変更**

- [ ] **Step 4.3.2: generation 画面 / controller / service が `VideoFile` を入力として `ManualCreationService` を呼ぶように変更**

- [ ] **Step 4.3.3: `video` 側から manual の query provider や service ロジックを直接読まないことを確認**

### Task 4.4: import を更新

- [ ] **Step 4.4.1: 旧 feature パス参照を洗い出す**

```bash
rg -n "features/manual_generation|features/manual_editing|features/video_upload" lib
```

- [ ] **Step 4.4.2: import を新パスへ更新**

方針:
- `manual_generation` / `manual_editing` / `video_upload` を残さない
- barrel file import を直接 import に置き換える
- 相対 import が複雑な箇所は `package:manyu_manyu/...` を優先してよい

- [ ] **Step 4.4.3: build_runner**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4.4.4: analyze**

```bash
fvm flutter analyze
```

---

## Phase 5: 旧 feature の撤去と最終整合

### Task 5.1: 不要ディレクトリと `.gitkeep` を整理

- [ ] **Step 5.1.1: 実ファイルが入った新ディレクトリの `.gitkeep` を削除**

```bash
find lib/features/manual -name '.gitkeep' -delete
find lib/features/video -name '.gitkeep' -delete
```

必要なら空ディレクトリ分だけ戻す。

- [ ] **Step 5.1.2: 旧 feature の残存ファイルを確認**

```bash
find lib/features/manual_editing -type f
find lib/features/manual_generation -type f
```

- [ ] **Step 5.1.3: 空になった旧 feature を削除**

```bash
rm -rf lib/features/manual_editing
rm -rf lib/features/manual_generation
```

### Task 5.2: 参照漏れを確認

- [ ] **Step 5.2.1: 旧 feature 名が残っていないか確認**

```bash
rg -n "manual_editing|manual_generation|manual_preview|pdf_export|video_upload" lib
```

- [ ] **Step 5.2.2: 旧クラス名が残っていないか確認**

```bash
rg -n "VideoUploadStateNotifier|VideoAnalysisNotifier|ManualEditNotifier|ManualEditServiceDataImpl" lib
```

### Task 5.3: 最終検証

- [ ] **Step 5.3.1: clean build**

```bash
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5.3.2: analyze**

```bash
fvm flutter analyze
```

- [ ] **Step 5.3.3: test**

```bash
fvm flutter test
```

- [ ] **Step 5.3.4: 動作確認**

```bash
fvm flutter run
```

確認項目:
- アプリが起動する
- ホームから動画アップロード画面へ遷移できる
- upload 完了後、`VideoFile` を引数に generation 画面へ遷移できる
- generation -> editing の流れが動く
- 既存 Manual の編集が動く
- PDF 出力が動く

- [ ] **Step 5.3.5: 最終コミット**

```bash
git add -A
git commit -m "refactor: restructure features around manual and video domains"
```

---

## 補足方針

- 実装中に provider の所有者で迷ったら、まず「その provider はどの application service と最も強く結びつくか」で置き場所を決める
- 複数 service から同程度に使う provider は、feature 内の共通 provider として切り出してよい
- 設計に迷ったら以下を優先参照とする
  - https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/
  - https://github.com/bizz84/complete-flutter-course

---

## 自己レビューチェックリスト

- [x] 設計ドキュメントの最新方針と矛盾しない
- [x] `main.dart override` 前提を削除した
- [x] `video -> manual/generation` の受け渡し方法を反映した
- [x] `application service + provider + query provider` 近接配置を反映した
- [x] repository / service interface の置き場所を `data/` に統一した
