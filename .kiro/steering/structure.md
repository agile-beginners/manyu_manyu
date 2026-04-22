# Structure Steering

## 基本構造

プロジェクトは feature-first を基本とし、`lib/features/` 配下を主要な構造単位とする。

想定する基本形:

```text
lib/
  core/
  features/
    <feature>/
      application/
      data/
        repositories/
        services/
      domain/
        entities/
        value_objects/
      presentation/
```

## feature の切り方

- feature は UI 画面単位ではなく、**同じ集約を扱う機能群** として切る
- 同じ集約に対する生成・編集・確認・出力は、原則 1 つの feature にまとめる
- 画面フローが複数ある場合は、`presentation/` 配下でサブフォルダを切る

例:

- `manual/presentation/generation`
- `manual/presentation/editing`
- `manual/presentation/preview`
- `manual/presentation/export`

## 各層の配置ルール

### domain

- `domain/` には純粋なモデルを置く
- 基本的に置いてよいのは以下のみ
  - `entities/`
  - `value_objects/`
- repository interface や外部 service interface は `domain/` に置かない

### data

- `data/repositories/` には repository interface とその実装を置く
- `data/services/` には外部 API / ファイル操作などの interface と実装を置く
- concrete 実装はこの層に集約する

### application

- `application/` には use case 単位の concrete service を置く
- 1 ユースケース 1 クラスに機械的に分割するのではなく、依存先・変更理由・処理フローが近いものをまとめる
- service ファイルには、その service provider や関連 query provider を近接配置してよい

### presentation

- `presentation/` には screen / widget / controller / state など UI 関連を置く
- query provider の共通定義は `presentation` ではなく `application` 側に置く
- 画面固有 provider や一時 state は `presentation` に置いてよい

## 現在の主要 feature

- `home`
  - UI 中心の軽量 feature
- `video`
  - 動画選択、検証、保存、`VideoFile` 返却までを担当
- `manual`
  - Manual 集約に対する生成、編集、プレビュー、出力を担当

## 命名方針

- 画面状態を管理するファイルは `xxx_controller.dart` を基本とする
- application service は `xxx_service.dart` を基本とする
- barrel file は極力増やさず、必要な import を明示する

## 実装時の注意

- feature をまたいで domain model を参照し続ける構造を残さない
- 新しい feature を追加する際は、まず既存集約に統合すべきかを検討する
- 一時的な移行期間を除き、旧 feature と新 feature を長期間並存させない
