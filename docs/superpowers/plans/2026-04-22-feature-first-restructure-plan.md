# フィーチャーファースト再構成 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Note:** この計画はユーザーが手動で実装する想定です。各ステップに具体的なコマンドと期待される結果を記載しています。

**Goal:** `lib/features/` 配下を feature-first の原則に沿って再構成し、`manual_editing` / `manual_generation` / `manual_preview` / `pdf_export` を `manual/` に統合、`video_upload` を `video/` に改名する。

**Architecture:** 段階的フェーズで進める。各フェーズで `fvm flutter analyze` が通る状態を保ち、フェーズ単位でコミットする。フェーズ 1 → 7 の順で依存関係があるため、順番に実行する。

**Tech Stack:** Flutter 3.38.5 (fvm)、Dart、Riverpod (手書き `StateNotifier`)、build_runner (freezed / json_serializable)、git

**関連ドキュメント:** [設計ドキュメント](../specs/2026-04-21-feature-first-restructure-design.md)

---

## 前提条件

- プロジェクトルートは `/Users/8mitsuboy/workspaces/manyu_manyu`
- 以降のコマンドは全てプロジェクトルートで実行する想定
- Flutter は `fvm flutter ...` で実行する
- 現在のブランチは `feature/update-riverpod`。ワーキングツリーに未コミットの変更（`macos/Podfile.lock`, `pubspec.lock`）がある

---

## Phase 0: 準備

### Task 0.1: ワーキングツリーを整える

- [x] **Step 0.1.1: 現在のブランチとステータスを確認**

```bash
git status
git branch --show-current
```

期待: 現在のブランチと、未コミットの変更が見える。

- [x] **Step 0.1.2: リファクタリング用のブランチを作成**

現在のブランチ `feature/update-riverpod` と混ぜないために、新しいブランチを切る:

```bash
git checkout -b refactor/feature-first-restructure
```

期待: `Switched to a new branch 'refactor/feature-first-restructure'`

- [x] **Step 0.1.3: 未コミットの変更を一旦コミット or stash**

`macos/Podfile.lock`, `pubspec.lock` は環境依存の自動生成物。リファクタリングとは無関係なのでまずコミット（or stash）して、以降の作業を綺麗に進める:

```bash
# コミットする場合:
git add macos/Podfile.lock pubspec.lock
git commit -m "chore: update generated lock files"

# or stash する場合:
git stash push -m "wip: lock files"
```

期待: `git status` で clean な状態になる。

---

## Phase 1: 空フォルダの削除

`manual_preview/` と `pdf_export/` は中身が `.gitkeep` のみの空フォルダ。先に削除しておく。

### Task 1.1: 空フォルダを削除してコミット

- [ ] **Step 1.1.1: 削除対象フォルダの中身を確認**

```bash
ls -la lib/features/manual_preview/*/
ls -la lib/features/pdf_export/*/
```

期待: 各フォルダに `.gitkeep` しかないことを確認する。

- [ ] **Step 1.1.2: `manual_preview/`, `pdf_export/` を削除**

```bash
git rm -r lib/features/manual_preview
git rm -r lib/features/pdf_export
```

期待: 対象ファイル（.gitkeep）が削除済みとしてステージされる。

- [ ] **Step 1.1.3: analyze で問題ないことを確認**

```bash
fvm flutter analyze
```

期待: エラーなし。空フォルダ削除では import 破損は起きない。

- [ ] **Step 1.1.4: コミット**

```bash
git commit -m "refactor: remove empty manual_preview and pdf_export feature folders"
```

---

## Phase 2: `manual/` ディレクトリ構造を作成

リファクタ先のフォルダを先に作っておく（`.gitkeep` 付き）。これで以降のフェーズで段階的にファイルを移動できる。

### Task 2.1: `manual/` 配下のディレクトリを作成

- [ ] **Step 2.1.1: ディレクトリを mkdir で作成**

```bash
mkdir -p lib/features/manual/application
mkdir -p lib/features/manual/data/repositories
mkdir -p lib/features/manual/data/services
mkdir -p lib/features/manual/domain/entities
mkdir -p lib/features/manual/domain/repositories
mkdir -p lib/features/manual/domain/services
mkdir -p lib/features/manual/domain/value_objects
mkdir -p lib/features/manual/presentation/generation/providers
mkdir -p lib/features/manual/presentation/generation/screens
mkdir -p lib/features/manual/presentation/generation/states
mkdir -p lib/features/manual/presentation/generation/widgets
mkdir -p lib/features/manual/presentation/editing/providers
mkdir -p lib/features/manual/presentation/editing/screens
mkdir -p lib/features/manual/presentation/editing/widgets
mkdir -p lib/features/manual/presentation/preview/screens
mkdir -p lib/features/manual/presentation/preview/widgets
mkdir -p lib/features/manual/presentation/export/widgets
```

期待: 全ディレクトリが作成される。`ls lib/features/manual/` で確認。

- [ ] **Step 2.1.2: 各ディレクトリに `.gitkeep` を配置**

```bash
find lib/features/manual -type d -empty -exec touch {}/.gitkeep \;
```

期待: 全ての空ディレクトリに `.gitkeep` ができる。`find lib/features/manual -name '.gitkeep'` で確認。

- [ ] **Step 2.1.3: analyze で問題ないことを確認**

```bash
fvm flutter analyze
```

期待: エラーなし。

- [ ] **Step 2.1.4: コミット**

```bash
git add lib/features/manual
git commit -m "refactor: scaffold manual/ feature directory structure"
```

---

## Phase 3: `video_upload` → `video` へのリネーム

Manual 側より先に video 側をリネームする（依存関係が少ないため）。

### Task 3.1: フォルダ全体を `video/` にリネーム

- [ ] **Step 3.1.1: フォルダ rename**

```bash
git mv lib/features/video_upload lib/features/video
```

期待: `lib/features/video/` が出現し、`lib/features/video_upload/` は消える。

- [ ] **Step 3.1.2: analyze で破損確認**

```bash
fvm flutter analyze
```

期待: **多数のエラー** が出る（`video_upload` を import している箇所が壊れる）。どのファイルが壊れているかを把握する。

### Task 3.2: barrel ファイルを削除

- [ ] **Step 3.2.1: barrel ファイルを削除**

```bash
git rm lib/features/video/data/data.dart
git rm lib/features/video/domain/domain.dart
```

期待: 2 ファイル削除。

### Task 3.3: Provider ファイルを Controller にリネーム

ファイル `lib/features/video/presentation/providers/video_upload_providers.dart` をリネーム。

- [ ] **Step 3.3.1: ファイル rename**

```bash
git mv lib/features/video/presentation/providers/video_upload_providers.dart lib/features/video/presentation/providers/video_upload_controller.dart
```

- [ ] **Step 3.3.2: ファイル内部のクラス名を変更**

`lib/features/video/presentation/providers/video_upload_controller.dart` を開いて、以下を置換:

- `class VideoUploadStateNotifier` → `class VideoUploadController`
- `VideoUploadStateNotifier(...)` コンストラクタの自己参照 → `VideoUploadController(...)`
- `StateNotifierProvider<VideoUploadStateNotifier, ...>` → `StateNotifierProvider<VideoUploadController, ...>`

具体的には下記の行を置換:

```dart
// Before (68行目)
class VideoUploadStateNotifier extends StateNotifier<VideoUploadState> {
  final VideoRepository _repository;

  VideoUploadStateNotifier(this._repository) : super(const VideoUploadState());

// After
class VideoUploadController extends StateNotifier<VideoUploadState> {
  final VideoRepository _repository;

  VideoUploadController(this._repository) : super(const VideoUploadState());
```

```dart
// Before (154行目あたり)
final videoUploadStateProvider = StateNotifierProvider<VideoUploadStateNotifier, VideoUploadState>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return VideoUploadStateNotifier(repository);
});

// After
final videoUploadStateProvider = StateNotifierProvider<VideoUploadController, VideoUploadState>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return VideoUploadController(repository);
});
```

### Task 3.4: import 文の全置換

他のファイルから `video_upload` を参照しているコードを `video` に置き換える。

- [ ] **Step 3.4.1: 参照元ファイルを洗い出す**

```bash
rg -l "features/video_upload" lib/
```

期待される出力例:
```
lib/features/home/presentation/widgets/primary_actions.dart
lib/features/manual_generation/presentation/providers/gemini_providers.dart
lib/features/manual_generation/presentation/providers/video_analysis_providers.dart
lib/features/video/presentation/screens/video_upload_screen.dart
lib/features/video/presentation/widgets/file_selection_widget.dart
lib/features/video/presentation/widgets/upload_progress_widget.dart
lib/features/video/presentation/widgets/upload_status_widget.dart
```

- [ ] **Step 3.4.2: 各ファイルで `video_upload/` を `video/` に置換**

`sed` で一括置換する（macOS の sed は `-i ''` が必要）:

```bash
rg -l "features/video_upload" lib/ | xargs sed -i '' 's|features/video_upload|features/video|g'
```

期待: `rg "features/video_upload" lib/` で何もマッチしない状態になる。

- [ ] **Step 3.4.3: barrel 経由の import を直接 import に置換**

`data/data.dart` や `domain/domain.dart` を import しているコードがあれば個別に修正する:

```bash
rg "features/video/data/data\\.dart|features/video/domain/domain\\.dart" lib/
```

ヒットしたファイルを開き、例えば以下のように直接 import に変更:

```dart
// Before
import 'package:manyu_manyu/features/video/domain/domain.dart';

// After（必要なファイルを個別に指定）
import 'package:manyu_manyu/features/video/domain/entities/video_file.dart';
import 'package:manyu_manyu/features/video/domain/repositories/video_repository.dart';
```

- [ ] **Step 3.4.4: Provider 名の参照も追随（必要なら）**

`VideoUploadStateNotifier` を直接参照しているコードがあれば `VideoUploadController` に変更:

```bash
rg "VideoUploadStateNotifier" lib/
```

ヒットした場合、各ファイルで `VideoUploadStateNotifier` → `VideoUploadController` に置換。ヒットしなければスキップ。

### Task 3.5: analyze と動作確認

- [ ] **Step 3.5.1: analyze で全エラー解消を確認**

```bash
fvm flutter analyze
```

期待: `No issues found!`（または元々あった warning のみ）。

- [ ] **Step 3.5.2: build_runner 実行（必要な場合のみ）**

`.g.dart` が影響を受ける変更はないはずだが、念のため:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

期待: 成功メッセージ。

- [ ] **Step 3.5.3: コミット**

```bash
git add -A
git commit -m "refactor: rename video_upload feature to video and rename providers to controller"
```

---

## Phase 4: `manual/` への domain / data 統合

Manual 集約の中核（`manual.dart`, `manual_step.dart`）を含むため、このフェーズで Manual の所有権が確立される。

### Task 4.1: `manual_generation/domain/` を `manual/domain/` へ統合

- [ ] **Step 4.1.1: entities を移動**

```bash
git mv lib/features/manual_generation/domain/entities/manual.dart lib/features/manual/domain/entities/manual.dart
git mv lib/features/manual_generation/domain/entities/manual.g.dart lib/features/manual/domain/entities/manual.g.dart
git mv lib/features/manual_generation/domain/entities/manual_step.dart lib/features/manual/domain/entities/manual_step.dart
git mv lib/features/manual_generation/domain/entities/manual_step.g.dart lib/features/manual/domain/entities/manual_step.g.dart
```

- [ ] **Step 4.1.2: repositories を移動**

```bash
git mv lib/features/manual_generation/domain/repositories/manual_repository.dart lib/features/manual/domain/repositories/manual_repository.dart
```

- [ ] **Step 4.1.3: services を移動**

```bash
git mv lib/features/manual_generation/domain/services/gemini_service.dart lib/features/manual/domain/services/gemini_service.dart
git mv lib/features/manual_generation/domain/services/image_annotation_service.dart lib/features/manual/domain/services/image_annotation_service.dart
git mv lib/features/manual_generation/domain/services/pdf_export_service.dart lib/features/manual/domain/services/pdf_export_service.dart
```

- [ ] **Step 4.1.4: value_objects を移動**

```bash
git mv lib/features/manual_generation/domain/value_objects/manual_generation_progress_stage.dart lib/features/manual/domain/value_objects/manual_generation_progress_stage.dart
```

- [ ] **Step 4.1.5: barrel ファイルを削除**

```bash
git rm lib/features/manual_generation/domain/domain.dart
```

### Task 4.2: `manual_editing/domain/` を `manual/domain/` へ統合

- [ ] **Step 4.2.1: service を移動**

```bash
git mv lib/features/manual_editing/domain/services/manual_edit_service.dart lib/features/manual/domain/services/manual_edit_service.dart
```

- [ ] **Step 4.2.2: barrel ファイルを削除**

```bash
git rm lib/features/manual_editing/domain/domain.dart
```

### Task 4.3: `manual_generation/data/` を `manual/data/` へ統合

- [ ] **Step 4.3.1: repositories を移動**

```bash
git mv lib/features/manual_generation/data/repositories/manual_repository_impl.dart lib/features/manual/data/repositories/manual_repository_impl.dart
```

- [ ] **Step 4.3.2: services を移動**

```bash
git mv lib/features/manual_generation/data/services/gemini_image_service.dart lib/features/manual/data/services/gemini_image_service.dart
git mv lib/features/manual_generation/data/services/gemini_service.dart lib/features/manual/data/services/gemini_service.dart
git mv lib/features/manual_generation/data/services/image_extraction_service.dart lib/features/manual/data/services/image_extraction_service.dart
git mv lib/features/manual_generation/data/services/nano_banana_service.dart lib/features/manual/data/services/nano_banana_service.dart
git mv lib/features/manual_generation/data/services/pdf_export_service_impl.dart lib/features/manual/data/services/pdf_export_service_impl.dart
git mv lib/features/manual_generation/data/services/video_analysis_service.dart lib/features/manual/data/services/video_analysis_service.dart
```

- [ ] **Step 4.3.3: barrel ファイルを削除**

```bash
git rm lib/features/manual_generation/data/data.dart
```

### Task 4.4: `manual_editing/data/` を `manual/data/` へ統合

- [ ] **Step 4.4.1: service を移動**

```bash
git mv lib/features/manual_editing/data/services/manual_edit_service_impl.dart lib/features/manual/data/services/manual_edit_service_impl.dart
```

- [ ] **Step 4.4.2: barrel ファイルを削除**

```bash
git rm lib/features/manual_editing/data/data.dart
```

### Task 4.5: import パスの一括更新

この時点で `manual/presentation/generation/` と `manual/presentation/editing/` 配下は**まだ空**（Phase 5 で移動）。しかし Phase 5 で参照する `manual/domain/` と `manual/data/` は既に所定の位置にあるので、以下を**実行しておく**:

1. `manual_generation/domain/*` → `manual/domain/*` の参照更新
2. `manual_generation/data/*` → `manual/data/*` の参照更新
3. `manual_editing/domain/*` → `manual/domain/*` の参照更新
4. `manual_editing/data/*` → `manual/data/*` の参照更新

この参照更新をすることで、Phase 5 でファイルを移動した後の analyze 失敗を最小化できる。

- [ ] **Step 4.5.1: 参照元ファイルを洗い出す**

```bash
rg -l "features/manual_generation/(domain|data)" lib/
rg -l "features/manual_editing/(domain|data)" lib/
```

- [ ] **Step 4.5.2: `manual_generation/domain` への参照を更新**

```bash
rg -l "features/manual_generation/domain" lib/ | xargs sed -i '' 's|features/manual_generation/domain|features/manual/domain|g'
```

- [ ] **Step 4.5.3: `manual_generation/data` への参照を更新**

```bash
rg -l "features/manual_generation/data" lib/ | xargs sed -i '' 's|features/manual_generation/data|features/manual/data|g'
```

- [ ] **Step 4.5.4: `manual_editing/domain` への参照を更新**

```bash
rg -l "features/manual_editing/domain" lib/ | xargs sed -i '' 's|features/manual_editing/domain|features/manual/domain|g'
```

- [ ] **Step 4.5.5: `manual_editing/data` への参照を更新**

```bash
rg -l "features/manual_editing/data" lib/ | xargs sed -i '' 's|features/manual_editing/data|features/manual/data|g'
```

- [ ] **Step 4.5.6: barrel 経由の import を直接 import に置換**

barrel ファイル（`data.dart`, `domain.dart`）を参照しているコードがあれば個別修正:

```bash
rg "features/manual/(data/data|domain/domain)\\.dart" lib/
```

ヒットしたファイルを開き、具体的なファイルへの import に書き換える。例:

```dart
// Before
import 'package:manyu_manyu/features/manual/data/data.dart';

// After
import 'package:manyu_manyu/features/manual/data/services/manual_edit_service_impl.dart';
```

### Task 4.6: `.gitkeep` の削除

実ファイルが入ったディレクトリの `.gitkeep` は不要:

- [ ] **Step 4.6.1: 実ファイルが入った階層の .gitkeep を削除**

```bash
find lib/features/manual/data -name '.gitkeep' -delete
find lib/features/manual/domain -name '.gitkeep' -delete
```

期待: `manual/data/` と `manual/domain/` 配下の `.gitkeep` が消える。

### Task 4.7: analyze 確認とコミット

- [ ] **Step 4.7.1: analyze 実行**

```bash
fvm flutter analyze
```

期待: **エラーが残っている可能性あり**（Phase 5 で解決）。この時点ではエラーが残っていても、「内容が `manual_editing/presentation/` または `manual_generation/presentation/` 配下のファイルから発生している」ことのみ確認する。他の場所からのエラーは修正する。

- [ ] **Step 4.7.2: manual_editing/presentation/ と manual_generation/presentation/ 由来以外のエラーを修正**

`fvm flutter analyze` の出力から、これら 2 フォルダ以外のエラーがあれば個別対応。典型例:
- home から manual を参照している箇所
- video から manual を参照している箇所
- core から manual を参照している箇所（あれば）

- [ ] **Step 4.7.3: build_runner 実行**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

期待: 成功。`manual.g.dart`, `manual_step.g.dart` が新しい位置で再生成される。

- [ ] **Step 4.7.4: コミット**

```bash
git add -A
git commit -m "refactor: consolidate manual_generation and manual_editing domain/data into manual/"
```

---

## Phase 5: `manual/presentation/` への統合 + Controller リネーム

最も作業量が多いフェーズ。manual_generation と manual_editing の presentation を移動し、Provider ファイルを Controller にリネームする。

### Task 5.1: `manual_generation/presentation/` を `manual/presentation/generation/` へ移動

- [ ] **Step 5.1.1: providers を移動（Controller リネームも同時に）**

```bash
git mv lib/features/manual_generation/presentation/providers/gemini_providers.dart lib/features/manual/presentation/generation/providers/gemini_providers.dart
git mv lib/features/manual_generation/presentation/providers/video_analysis_providers.dart lib/features/manual/presentation/generation/providers/video_analysis_controller.dart
```

**注意:** `gemini_providers.dart` はリネームせず、ファイル名そのまま。`video_analysis_providers.dart` は `video_analysis_controller.dart` にリネーム。

- [ ] **Step 5.1.2: states を移動**

```bash
git mv lib/features/manual_generation/presentation/states/video_analysis_state.dart lib/features/manual/presentation/generation/states/video_analysis_state.dart
```

### Task 5.2: `manual_editing/presentation/` を `manual/presentation/editing/` へ移動

- [ ] **Step 5.2.1: providers を移動（Controller リネームも同時に）**

```bash
git mv lib/features/manual_editing/presentation/providers/manual_edit_providers.dart lib/features/manual/presentation/editing/providers/manual_edit_controller.dart
```

- [ ] **Step 5.2.2: screens を移動**

```bash
git mv lib/features/manual_editing/presentation/screens/manual_edit_screen.dart lib/features/manual/presentation/editing/screens/manual_edit_screen.dart
```

- [ ] **Step 5.2.3: widgets を移動**

```bash
git mv lib/features/manual_editing/presentation/widgets/manual_header_widget.dart lib/features/manual/presentation/editing/widgets/manual_header_widget.dart
git mv lib/features/manual_editing/presentation/widgets/step_edit_dialog.dart lib/features/manual/presentation/editing/widgets/step_edit_dialog.dart
git mv lib/features/manual_editing/presentation/widgets/step_list_widget.dart lib/features/manual/presentation/editing/widgets/step_list_widget.dart
```

- [ ] **Step 5.2.4: barrel ファイル削除**

```bash
git rm lib/features/manual_editing/presentation/presentation.dart
```

（`manual_generation/presentation/presentation.dart` は存在しないが、もし存在する場合は同様に削除）

### Task 5.3: `video_analysis_controller.dart` 内のクラス名変更

ファイル `lib/features/manual/presentation/generation/providers/video_analysis_controller.dart` を開く。

- [ ] **Step 5.3.1: `VideoAnalysisNotifier` を `VideoAnalysisController` に置換**

エディタで以下を一括置換（ファイル全体で約 3 箇所）:

- `class VideoAnalysisNotifier` → `class VideoAnalysisController`
- `VideoAnalysisNotifier(` → `VideoAnalysisController(`
- `StateNotifierProvider<VideoAnalysisNotifier,` → `StateNotifierProvider<VideoAnalysisController,`

または sed:

```bash
sed -i '' 's/VideoAnalysisNotifier/VideoAnalysisController/g' lib/features/manual/presentation/generation/providers/video_analysis_controller.dart
```

### Task 5.4: `manual_edit_controller.dart` 内のクラス名変更

ファイル `lib/features/manual/presentation/editing/providers/manual_edit_controller.dart` を開く。

- [ ] **Step 5.4.1: `ManualEditNotifier` を `ManualEditController` に置換**

```bash
sed -i '' 's/ManualEditNotifier/ManualEditController/g' lib/features/manual/presentation/editing/providers/manual_edit_controller.dart
```

期待: `class ManualEditNotifier`, `ManualEditNotifier(`, `StateNotifierProvider<ManualEditNotifier, ...>` が全て `ManualEditController` に置換される。

### Task 5.5: 新しいパスに合わせて import を更新

前フェーズで `manual_generation/` や `manual_editing/` の domain/data は既に `manual/domain`, `manual/data` に書き換え済み。ここでは **presentation 配下**の参照を更新する。

- [ ] **Step 5.5.1: 他ファイルからの参照を更新**

```bash
rg -l "features/manual_generation/presentation" lib/
rg -l "features/manual_editing/presentation" lib/
```

ヒットしたファイルで:
- `features/manual_generation/presentation` → `features/manual/presentation/generation`
- `features/manual_editing/presentation` → `features/manual/presentation/editing`

sed で一括:

```bash
rg -l "features/manual_generation/presentation" lib/ | xargs sed -i '' 's|features/manual_generation/presentation|features/manual/presentation/generation|g'
rg -l "features/manual_editing/presentation" lib/ | xargs sed -i '' 's|features/manual_editing/presentation|features/manual/presentation/editing|g'
```

- [ ] **Step 5.5.2: ファイル名リネームに伴う参照を更新**

`video_upload_providers.dart` → `video_upload_controller.dart`
`manual_edit_providers.dart` → `manual_edit_controller.dart`
`video_analysis_providers.dart` → `video_analysis_controller.dart`

他ファイルから旧ファイル名を import している箇所を確認:

```bash
rg "video_upload_providers\\.dart|manual_edit_providers\\.dart|video_analysis_providers\\.dart" lib/
```

ヒットしたら sed で一括更新:

```bash
rg -l "video_upload_providers\\.dart" lib/ | xargs sed -i '' 's|video_upload_providers\.dart|video_upload_controller.dart|g'
rg -l "manual_edit_providers\\.dart" lib/ | xargs sed -i '' 's|manual_edit_providers\.dart|manual_edit_controller.dart|g'
rg -l "video_analysis_providers\\.dart" lib/ | xargs sed -i '' 's|video_analysis_providers\.dart|video_analysis_controller.dart|g'
```

- [ ] **Step 5.5.3: Controller クラス名参照を更新**

```bash
rg -l "ManualEditNotifier" lib/ | xargs sed -i '' 's/ManualEditNotifier/ManualEditController/g' 2>/dev/null || true
rg -l "VideoAnalysisNotifier" lib/ | xargs sed -i '' 's/VideoAnalysisNotifier/VideoAnalysisController/g' 2>/dev/null || true
```

（既に対象ファイル自体は置換済みなので、他参照があれば追加置換）

- [ ] **Step 5.5.4: manual/ 内の相対 import を検証**

移動したファイル内の相対 import が壊れている可能性。各ファイルの `import '../../...';` パスを確認する。

例えば `manual/presentation/editing/screens/manual_edit_screen.dart` が元々 `manual_editing/presentation/screens/` にあったなら、相対パスは `../../../../core/...` だったはず。新しい位置は `manual/presentation/editing/screens/` なので、`../../../../core/...` は 4 段上がって `lib/` 直下を想定するが、新しい位置では 5 段上がることになる、ような破綻が起きうる。

**手順:**

```bash
rg "import '\\.\\./" lib/features/manual/
rg "import '\\.\\./" lib/features/video/
```

ヒットした各ファイルを開き、相対 import のパスの階層数が正しいか確認。必要なら `package:manyu_manyu/...` 形式の絶対 import に書き換える（メンテ性も上がる）。

### Task 5.6: `.gitkeep` の削除

- [ ] **Step 5.6.1: 実ファイルが入った階層の .gitkeep を削除**

```bash
find lib/features/manual/presentation/generation -name '.gitkeep' -delete
find lib/features/manual/presentation/editing -name '.gitkeep' -delete
```

ただし `manual/presentation/preview/` と `manual/presentation/export/` はまだ空なので `.gitkeep` を残す。

### Task 5.7: build_runner & analyze

- [ ] **Step 5.7.1: build_runner で再生成**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

期待: 成功。`.g.dart` ファイルが新しい位置で正しく生成される。

- [ ] **Step 5.7.2: analyze で全エラー解消を確認**

```bash
fvm flutter analyze
```

期待: `No issues found!`（または元々あった warning のみ）。

エラーが残る場合は、出力を見て:
- import パスの間違い → 該当箇所を修正
- クラス名の参照漏れ → 該当箇所を修正

までを繰り返す。

- [ ] **Step 5.7.3: コミット**

```bash
git add -A
git commit -m "refactor: move manual_editing and manual_generation presentation into manual/presentation with epic sub-folders"
```

---

## Phase 6: 古い空フォルダのクリーンアップ

### Task 6.1: 空になったフォルダを削除

- [ ] **Step 6.1.1: 空フォルダの確認**

```bash
find lib/features/manual_editing -type f
find lib/features/manual_generation -type f
```

期待: **出力なし**（全ファイルが manual/ に移動済みのため）。

もし残っているファイルがあれば、Phase 4 / 5 の移動漏れ。該当ファイルを適切な場所に移動する。

- [ ] **Step 6.1.2: 空フォルダを削除**

```bash
rm -rf lib/features/manual_editing
rm -rf lib/features/manual_generation
```

期待: これらのフォルダが消える。git は空フォルダを追跡しないので `git rm` は不要（ファイルが既に移動済みで git 側では削除として追跡済み）。

- [ ] **Step 6.1.3: analyze で最終確認**

```bash
fvm flutter analyze
```

期待: `No issues found!`

- [ ] **Step 6.1.4: コミット**

```bash
git add -A
git commit -m "refactor: remove emptied manual_editing and manual_generation directories"
```

---

## Phase 7: 最終検証

### Task 7.1: クリーンビルドと動作確認

- [ ] **Step 7.1.1: クリーンビルド**

```bash
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

期待: 全て成功。

- [ ] **Step 7.1.2: analyze**

```bash
fvm flutter analyze
```

期待: `No issues found!`

- [ ] **Step 7.1.3: test 実行（テストがあれば）**

```bash
fvm flutter test
```

期待: 既存テストがあれば通る。なければ `No tests found` で OK。

- [ ] **Step 7.1.4: アプリを起動して手動動作確認**

```bash
fvm flutter run
```

確認項目:
- アプリが起動する
- ホーム画面が表示される
- 「はじめる」ボタンで動画アップロード画面に遷移する
- （もし既存データがあれば）マニュアル編集画面が正常に開く
- （もし Gemini API キーが設定されていれば）マニュアル生成フローが動く

エラーが出る場合は該当箇所を修正してコミットを追加する。

- [ ] **Step 7.1.5: フォルダ構造の最終確認**

```bash
tree lib/features -L 3
```

期待される構造（抜粋）:
```
lib/features
├── home
│   └── presentation
│       ├── screens
│       └── widgets
├── manual
│   ├── application
│   ├── data
│   │   ├── repositories
│   │   └── services
│   ├── domain
│   │   ├── entities
│   │   ├── repositories
│   │   ├── services
│   │   └── value_objects
│   └── presentation
│       ├── editing
│       ├── export
│       ├── generation
│       └── preview
└── video
    ├── data
    │   ├── repositories
    │   └── services
    ├── domain
    │   ├── entities
    │   └── repositories
    └── presentation
        ├── providers
        ├── screens
        └── widgets
```

`manual_editing`, `manual_generation`, `manual_preview`, `pdf_export`, `video_upload` が全て消えていること、`manual/`, `video/` の構造が設計通りであることを確認。

### Task 7.2: PR の準備（任意）

- [ ] **Step 7.2.1: ログとコミット履歴の確認**

```bash
git log --oneline refactor/feature-first-restructure ^feature/update-riverpod
```

期待: Phase ごとのコミットが綺麗に並んでいる。

- [ ] **Step 7.2.2: develop への PR を作成（任意）**

必要に応じて PR を作成。タイトル例:

```
refactor: consolidate manual_* features into manual/ (feature-first restructure)
```

---

## 参考: 変更ファイル一覧（事後確認用）

Phase 7 完了時点で以下の状態になる:

### 新規作成
- `lib/features/manual/application/.gitkeep`
- `lib/features/manual/presentation/preview/.gitkeep`（または screens/, widgets/ に .gitkeep）
- `lib/features/manual/presentation/export/.gitkeep`

### リネーム
- `lib/features/video_upload/` → `lib/features/video/`
- `lib/features/video/presentation/providers/video_upload_providers.dart` → `.../video_upload_controller.dart`
- `lib/features/manual_generation/presentation/providers/video_analysis_providers.dart` → `.../manual/presentation/generation/providers/video_analysis_controller.dart`
- `lib/features/manual_editing/presentation/providers/manual_edit_providers.dart` → `.../manual/presentation/editing/providers/manual_edit_controller.dart`

### 移動
- `manual_editing/*` → `manual/**`（詳細は設計ドキュメント参照）
- `manual_generation/*` → `manual/**`
- `video_upload/*` → `video/*`

### 削除
- `manual_preview/`, `pdf_export/`（空フォルダ）
- `manual_editing/`, `manual_generation/`, `video_upload/`（移動後、空になったもの）
- 全 barrel ファイル（`data.dart`, `domain.dart`, `presentation.dart`）

### クラスリネーム
- `VideoUploadStateNotifier` → `VideoUploadController`
- `VideoAnalysisNotifier` → `VideoAnalysisController`
- `ManualEditNotifier` → `ManualEditController`

---

## スコープ外の既知の問題（将来対応）

以下の既存の問題は今回のリファクタリングでは **そのまま保持**する。別 PR で対応:

1. **Provider の重複定義**: `manualRepositoryProvider`, `geminiServiceProvider` など複数の Provider が `manual_edit_controller.dart`, `video_analysis_controller.dart`, `gemini_providers.dart` に重複している
2. **`gemini_providers.dart` の `application/` への移動検討**: DI 専用ファイルなので `application/` 層に移すのが本来の形
3. **1 ファイルに複数の Provider+Notifier+Service クラスが混在**: ファイル分割が有益
4. **`ManualEditServiceDataImpl` という命名**: `ManualEditServiceImpl` に揃える余地あり

---

## 自己レビューチェックリスト

- [x] **Spec coverage**: 設計ドキュメントの各セクションが Phase として対応している（feature 統合、video 改名、barrel 削除、Controller リネーム、検証手順）
- [x] **Placeholder scan**: TBD / TODO / 「適切にハンドリング」系の曖昧表現なし。各ステップに具体的コマンドを記載
- [x] **Type consistency**: Controller リネームは全 Phase で一貫（`VideoUploadStateNotifier` / `VideoAnalysisNotifier` / `ManualEditNotifier` → `VideoUploadController` / `VideoAnalysisController` / `ManualEditController`）
