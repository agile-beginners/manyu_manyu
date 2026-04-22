# フィーチャーファースト再構成 設計ドキュメント

**作成日:** 2026-04-21
**参考:** [Flutter Project Structure: Feature-first or Layer-first? (Code with Andrea)](https://codewithandrea.com/articles/flutter-project-structure/) / [Flutter App Architecture: The Application Layer (Code with Andrea)](https://codewithandrea.com/articles/flutter-app-architecture-application-layer/)

## 背景と目的

### 現状の問題

現状 `lib/features/` 配下は表面的には feature-first 構成になっているが、[参考記事](https://codewithandrea.com/articles/flutter-project-structure/)が警告している **「UI や画面単位で feature を切ってしまう状態」** に近い構造になっている。

具体的には、`manual_editing` と `manual_generation` はどちらも **同じ Manual（マニュアル）ドメイン** を扱っているにもかかわらず、ユーザー行動やドメイン集約ではなく、画面や処理フローに近い単位で別 feature として切られている。結果として、feature-first が `features/` の見た目にだけ適用され、実際には domain / data の責務が一部の feature に偏った **アンバランスな構造** になっている。

その症状として:

- `Manual` / `ManualStep`、`ManualRepository`、PDF 出力など、Manual に関する中核的なモデルやロジックが `manual_generation` 側に偏在している
- `manual_editing` の widget や provider が `manual_generation/domain/entities/manual.dart` を参照しており、feature をまたいだ依存が発生している
- Manual に関する変更を行うたびに `manual_editing` と `manual_generation` の両方を行き来する必要があり、記事で言う「1 つの feature に集中できない」状態になっている

### 目的

記事が示す「ユーザーが何をするか」を起点にしつつ、最終的には **同じドメイン集約を扱う機能群を 1 つの feature に再グルーピングする**。その上で、ユーザー行動に近い画面フローを `presentation/` 配下のサブフォルダで表現する。

---

## 指針となる概念整理

### feature とは何か

- 記事の重要な出発点は、**feature を「ユーザーが見るもの」ではなく「ユーザーがすること」から考える**ことにある
- ただし、そこからそのまま **ユーザー行動 ＝ feature フォルダ名** と 1:1 対応させるわけではない
- 実際の feature-first 設計では、**ユーザー行動を起点に、そこで扱うモデルとビジネスロジックを見つけ、最後にドメイン集約ごとに再グルーピングする**
- したがって、このドキュメントにおける feature は **ユーザー行動をそのまま写したものではなく、そこで扱うモデルとビジネスロジックをドメイン集約ごとに整理し直した機能群** を意味する
  - 複数のユーザー行動や画面フローが同じモノを扱う場合、それらは 1 つの feature に統合される
  - 記事の `products` feature が「一覧・詳細・管理画面」など複数の画面フローを束ねているのと同じ

### 集約とは何か

「一緒に扱う "モノ" のかたまり」このプロジェクトにおいては:

- **Manual 集約** ＝ `Manual` と `ManualStep` のセット。生成・編集・プレビュー・PDF 出力すべてがこの集約を触る
- **Video 集約** ＝ `VideoFile`。アップロードと管理を担当

### ユーザーストーリーマップとの対応

| 階層 | 例 | フォルダ構成との対応 |
|---|---|---|
| ユーザー行動 | 動画を準備する / マニュアルを生成する / 内容を確認する / 修正する / 出力する | feature を見つけるための**起点** |
| ドメイン集約 | `VideoFile` / `Manual` + `ManualStep` | `features/video` / `features/manual` |
| 画面フロー | `generation` / `preview` / `editing` / `export` | `presentation/` 配下のサブフォルダ |
| 個別ストーリー | ステップのテキストを修正する / PDF を出力する、など | Controller / Widget / 画面 |

> **重要:** ストーリーマップ上の列やエピックをそのまま feature フォルダに投影するのではなく、  
> **ユーザー行動からドメインを発見し、そのドメインごとに feature を切り直す** のがこの設計の基本方針である。

### feature-first の開発順序

記事の "How to do feature-first, the right way" が示す手順は以下の通り:

1. **ユーザー行動（ユーザーが達成したいタスク）を洗い出す**
2. その行動で扱う **モデル（モノ／集約）** と、それを操作する **ビジネスロジック** を特定する
3. 同じモデル群を触る行動や処理を **ドメイン集約ごとに再グルーピング** する
4. 再グルーピングした単位ごとに 1 つのフォルダ（＝ feature）を作る
5. その中に `data / domain / application / presentation` を **必要に応じて** 作る

記事の手順そのものはステップ 2〜5（"start from the domain layer..."）を明示しているが、記事冒頭で "feature とは what the user does" と定義しているため、ステップ 1 が暗黙の起点になっている。  
このため、**出発点はユーザー行動、構造化の最終単位はドメイン集約** とする。

**モデルとビジネスロジックを識別する際のポイント:**

- **モデル（モノ）**: 「Manual と ManualStep は常にセットで扱う」のように、一貫性を保って扱うべきデータのかたまり ＝ 集約
- **ビジネスロジック**: そのモノに対する操作（生成する、編集する、並び替える、PDF化する など）

この 2 つを束ね、かつ同じ集約を扱う処理群として再グルーピングした単位が feature になる。

**新規開発と既存コード改善の違い:**

- 新規開発: 上記ステップ 1 → 5 を順方向に進める
- 既存コードからの改善（今回のリファクタリング）: 逆方向に辿る
  1. 既存コードからモデル（`Manual`, `ManualStep`, `VideoFile`）を発見する
  2. その "モノ" を触っているロジック群を集める
  3. 同じ集約を扱うもの同士で再グルーピングする
  4. 1 つの feature フォルダに統合する

方向は違うが「ユーザー行動を起点にしつつ、モデルとロジックがまとまる単位に落とし込むと feature になる」という本質は同じ。

---

## スコープ

今回のリファクタリングは **`lib/features/` 配下のみ** を対象とする:

- ✅ `lib/features/` 配下の feature 統合・再配置
- ✅ `domain/` 層の整理（entities と value_objects のみ残す）
  - Repository interface → `data/repositories/`（実装の隣に置く）
  - 外部 API / ファイル操作の interface → `data/services/`（実装の隣に置く）
  - ビジネスロジック実装 → `application/`（abstract class は作らず concrete class を直接置く）
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
        repositories/         (VideoRepository interface + VideoRepositoryImpl)
        services/
      domain/
        entities/             (VideoFile)
      presentation/
        providers/
        screens/
        widgets/
    manual/                   (旧 manual_editing + manual_generation + manual_preview + pdf_export を統合)
      application/            (use case 単位の concrete service + Riverpod provider)
      data/
        repositories/         (ManualRepository interface + ManualRepositoryImpl)
        services/             (外部API interface + 実装: GeminiService, ImageAnnotationService, PdfExportService など)
      domain/
        entities/             (Manual, ManualStep, ManualStatus)
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
          providers/
          widgets/
  main.dart
```

### 主な設計判断

1. `features/` 直下は **`home` / `video` / `manual` の 3 feature に集約**
2. `video` feature の責務は **`VideoFile` を返すところまで** とする。動画解析の開始、生成進捗の表示、`Manual` の作成、編集画面への遷移は `manual/generation` が担う
3. `video` から `manual/generation` への受け渡しは **画面遷移時に `VideoFile` を引数として渡す** 方式を採用する。共有 provider に一時保存して受け渡す方式は採らない
4. `manual/presentation/` 配下は **ユーザー行動に近い画面フロー単位** でサブフォルダを切る（`generation`, `editing`, `preview`, `export`）
5. 各画面フローごとのサブフォルダ内は従来どおり **型別フォルダ**（`providers/screens/widgets/states`）で整理
6. `manual/application/` には **use case 単位の concrete service を置く**。1 ユースケース 1 クラスに機械的に分割するのではなく、**依存先・変更理由・処理フローが近いユースケースを 1 service にまとめる**。今回の対象は `ManualCreationService`（生成・再試行）、`ManualEditService`（編集・並び替え・検証）、`ManualExportService`（PDF 出力）の 3 クラスとする
7. `manual/application/` の各 service ファイルには、**service 本体・その service provider・その service と強く結びつく query provider** を同居させてよい。これにより依存関係と `invalidate` 対象を 1 ファイルで把握できるようにする
8. `domain/` には **entities と value_objects のみ**を残す。Repository interface は `data/repositories/`（実装の隣）に、外部API/ファイル操作の interface は `data/services/`（実装の隣）に置く。これにより domain は純粋なデータモデル層になる
9. `video/presentation/` は画面フローが 1 つ（アップロード）しかないため、`manual` のような画面フローごとのサブフォルダは切らず、`providers/screens/widgets` のようなファイル種類ごとの整理のみとする
10. `home/` は UI のみ（domain / data なし）の軽い feature として維持。記事の `address` feature が同様の扱い

### application と provider の責務分担

- **application service**: ユーザーのユースケースを実現するために、repository / data service / domain model / query provider 更新を組み合わせて調停する。書き込みや副作用を伴う処理の実行責務を持ち、必要に応じて `Ref` 経由で関連 query provider を `invalidate` する
- **参照系 provider**: 「現在の状態は何か」を表現する。単体取得・一覧取得・件数・派生値など、**状態変更を伴わない読み取り**を担う
- **presentation controller**: application service provider と参照系 provider を読む。ローディング、エラー表示、一時入力状態などの **画面固有の状態管理** に専念し、query provider の更新責務は持たない

参照系 provider は **presentation ではなく application 側に置く**。  
これにより、application service が `invalidate` する対象 provider を同じ層で定義でき、`application -> presentation` の逆依存を避けられる。

`invalidate` は Riverpod に対して「この provider が保持している値は古い可能性があるので、破棄して次回参照時に再取得させる」ことを伝える操作である。  
本設計では、**書き込み成功後にどの query provider を最新化すべきかの判断は application service が担う**。

### application service の分割ルール

application service は「同じドメインモデルを触るか」だけでまとめず、**依存先・変更理由・処理フローがまとまるか**で分割する。今回の設計では以下を判断基準とする:

- **同じ依存先を使うユースケース**は同じ service にまとめる
- **同じ理由で変更されるユースケース**は同じ service にまとめる
- **読み取り専用の処理**は service に入れず provider に置く
- **副作用や状態変更を伴う処理**は application service に置く
- **書き込み成功後に関連 query provider をどう更新するか** も application service の責務に含める

この基準により、`manual` feature では以下のようにまとめる:

- `ManualCreationService`: 生成・再試行
- `ManualEditService`: 編集・並び替え・検証
- `ManualExportService`: PDF 出力

### feature 間の受け渡し

- `video` は upload 完了後に `VideoFile` を生成する
- `video/presentation/screens/video_upload_screen.dart` は `VideoFile` を引数として `manual/presentation/generation/...` の screen へ遷移する
- `manual/generation` 側の controller / service が、その `VideoFile` を入力として `ManualCreationService` を呼ぶ
- `VideoFile` を feature 間共有 provider に一時保存して受け渡す構成は採用しない

---

## ファイル移動マッピング

詳細な移動先・削除対象・リネーム一覧は別紙の  
[2026-04-21-feature-first-restructure-mapping.md](/Users/8mitsuboy/workspaces/manyu_manyu/docs/superpowers/specs/2026-04-21-feature-first-restructure-mapping.md)  
を参照する。

本文では以下のルールのみを前提とする:

- `manual_editing` / `manual_generation` の domain model は `manual/domain/` に再配置する
- Repository interface と外部 service interface は `manual/data/` 配下に再配置する
- 生成・編集・出力の操作系ロジックは `manual/application/` に再配置する
- `video_upload` は `video` に改名し、既存構造を概ね維持する

---

## Provider / Service 配置パターン

記事の [The Auth and Cart Repositories](https://codewithandrea.com/articles/flutter-app-architecture-application-layer/#note-about-controllers-services-and-repositories) と `complete-flutter-course` の `CartService` 構成を参考に、**application service のファイルに service 本体・service provider・関連する query provider をまとめて置く**。  
また、application service は **書き込み後の query provider 更新も責務に含める**ため、**`Ref` を直接受け取ってよい**ものとする。

`gemini_providers.dart` のように、DI・query・controller を 1 ファイルに混在させる構成は採用しない。  
ただし、**application service とそれに紐づく query provider を同じ service ファイルに置く**構成は採用する。

### 配置ルール

- `data/` には repository / 外部 service の concrete 実装を置く
- `application/xxx_service.dart` には service 本体を置く
- `application/xxx_service.dart` にはその service provider を置く
- `application/xxx_service.dart` にはその service が参照・更新する query provider を置いてよい
- `presentation/.../xxx_controller.dart` には画面固有の controller を置く
- `presentation` 配下には画面固有の一時 state は置いてよいが、feature 横断で使う query provider は置かない

この配置により:

- `data/` は concrete 実装に集中する
- `application/` はユースケース実装と feature 共通の読み取り provider に集中する
- service と query provider の関係を近接配置できる
- `invalidate` 対象を service のすぐ近くで定義できる
- `main.dart` は feature 実装の詳細を知らずに済む

repository や外部 service の concrete 実装は `data/` に置く。  
それらを返す provider は、**複数 service から再利用するものは feature 内の共通 provider として定義してよい**。一方で、**service provider と、その service が `invalidate` する query provider は service ファイル側に置く**。例えば:

```dart
final manualRepositoryProvider = Provider<ManualRepository>((ref) {
  return ManualRepositoryImpl();
});
```

同様に `videoAnalysisServiceProvider`、`imageAnnotationServiceProvider`、`imageExtractionServiceProvider`、`pdfExportServiceProvider` なども、再利用範囲に応じて feature 内の共通 provider として定義してよい。

### application service provider の定義

application service provider は依存先 provider を読み、必要な依存を service のコンストラクタへ明示的に渡す。  
同じファイルには、その service と密接に関係する query provider も定義する。application service は `Ref` を受け取り、**書き込み成功後に関連 query provider を `invalidate` する責務**を持つ:

```dart
// manual/application/manual_edit_service.dart
final manualRepositoryProvider = Provider<ManualRepository>((ref) {
  return ManualRepositoryImpl();
});

@Riverpod(keepAlive: true)
Future<Manual?> manual(Ref ref, String manualId) async {
  final repository = ref.watch(manualRepositoryProvider);
  final result = await repository.getManual(manualId);
  if (result.isSuccess) {
    return result.data;
  }
  throw Exception(result.failure.toString());
}

@Riverpod(keepAlive: true)
Future<List<Manual>> allManuals(Ref ref) async {
  final repository = ref.watch(manualRepositoryProvider);
  final result = await repository.getAllManuals();
  if (result.isSuccess) {
    return result.data!;
  }
  throw Exception(result.failure.toString());
}

class ManualEditService {
  ManualEditService({
    required this.ref,
    required this.manualRepository,
  });

  final Ref ref;
  final ManualRepository manualRepository;

  Future<Result<Manual>> updateTitle(String manualId, String title) async {
    final result = await manualRepository.updateTitle(manualId, title);

    if (result.isSuccess) {
      ref.invalidate(manualProvider(manualId));
      ref.invalidate(allManualsProvider);
      ref.invalidate(manualStepCountProvider(manualId));
      ref.invalidate(canExportManualProvider(manualId));
    }

    return result;
  }
}

@Riverpod(keepAlive: true)
ManualEditService manualEditService(Ref ref) {
  return ManualEditService(
    ref: ref,
    manualRepository: ref.watch(manualRepositoryProvider),
  );
}
```

`ManualEditService`、`ManualExportService` も同様に `@Riverpod` で公開する。

`ManualCreationService` では Manual 生成成功後に `manualProvider(newManualId)` や `allManualsProvider` を、`ManualExportService` では export 可否や Manual 状態に影響する query provider を適宜 `invalidate` する。

---

## 命名変更

### Controller へのリネーム

`ecommerce_app` の命名に合わせて、画面状態を管理する Notifier ファイルを `xxx_controller.dart` 名に統一する:

| 変更前 | 変更後 |
|---|---|
| `manual_edit_providers.dart` | `manual_edit_controller.dart` |
| `video_upload_providers.dart` | `video_upload_controller.dart` |
| `video_analysis_providers.dart` | `video_analysis_controller.dart` |
| `gemini_providers.dart` | 削除（application service provider + query provider に整理） |

**付随作業:**
- 対応する `.g.dart`（Riverpod code gen）もリネーム
- ファイル内のクラス名の変更（例: `ManualEditNotifier` → `ManualEditController`）は実装時にファイル内容を確認した上で判断
- 移動・リネーム後に `dart run build_runner build --delete-conflicting-outputs` を実行して `.g.dart` を再生成

### クラス・ファイルのリネーム（命名抽象化 + 責務整理）

| 変更前（クラス名） | 変更後（クラス名） | ファイル |
|---|---|---|
| `GeminiService`（abstract interface） | `VideoAnalysisService` | `data/services/video_analysis_service.dart` |
| `GeminiServiceImpl`（concrete、Gemini API 呼び出し） | `GeminiVideoAnalysisService` | `data/services/gemini_video_analysis_service.dart` |
| `VideoAnalysisService`（concrete、オーケストレーション） | `ManualCreationService` | `application/manual_creation_service.dart` |
| `ManualEditServiceDataImpl` | `ManualEditService` | `application/manual_edit_service.dart` |
| `PdfExportService` を直接 presentation から呼ぶ構成 | `ManualExportService` 経由に変更 | `application/manual_export_service.dart` |

> **注意:** 旧 `VideoAnalysisService`（concrete）は abstract interface のリネーム先と名前が衝突するため `ManualCreationService` に変更する。中身はオーケストレーション（Gemini + リポジトリ + 画像処理の調整）なので `application/` が正しい配置。

### barrel ファイル削除と import の書き換え

全 import 文を移動後のパスに合わせて更新する。対象は以下の 2 種類:

**① barrel 経由の import を直接 import に置き換える**

```dart
// Before
import 'package:manyu_manyu/features/manual_editing/domain/domain.dart';

// After（abstract ManualEditService は削除済み。concrete 実装は application/ にある）
import 'package:manyu_manyu/features/manual/application/manual_edit_service.dart';
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
- query provider の配置場所の微調整（`presentation/providers/` と `application/` の責務境界）
- Riverpod Notifier のクラス命名変更（`XxxNotifier` → `XxxController`）
