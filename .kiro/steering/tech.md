# Tech Steering

## 技術スタック

- Flutter
- Riverpod / Riverpod Generator
- Feature-first 構成

## 参照優先度

設計に迷ったときは、以下を優先的な参考資料とする。

- Code with Andrea の Riverpod アーキテクチャ記事  
  https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/
- `bizz84/complete-flutter-course` リポジトリ  
  https://github.com/bizz84/complete-flutter-course

特に、レイヤ分割、Riverpod における controller / service / repository の責務分担、provider の置き方、feature-first 構成の判断に迷った場合は、この 2 つの考え方を優先して整合を取る。

## Riverpod の責務分担

### application service

- `application` 層の service は、ユースケース実行の調停役とする
- repository、外部 service、domain model、query provider 更新を組み合わせて処理する
- application service は `Ref` を直接受け取ってよい
- 書き込み成功後にどの query provider を最新化すべきかの判断は application service が担う
- `BuildContext`、画面遷移、Snackbar 表示などの UI 操作は持たない

### query provider

- query provider は、単体取得・一覧取得・件数・派生値などの **読み取り専用** の状態を表現する
- query provider は `presentation` ではなく **`application` 側** に置く
- application service が `invalidate` する対象 provider は、できるだけ service の近くに置く

### presentation controller

- controller は画面固有の状態管理に専念する
- 役割はローディング、エラー表示、一時入力状態、画面固有の UI 操作の調停
- query provider の更新責務は持たず、application service に委譲する

## provider 配置方針

- `application/xxx_service.dart` には以下を同居させてよい
  - service 本体
  - service provider
  - その service と強く結びつく query provider
- 複数 service から再利用する provider は、feature 内の共通 provider として切り出してよい
- `gemini_providers.dart` のように、DI・query・controller を 1 ファイルに混在させる構成は避ける

## インターフェース方針

- Repository interface は `data/repositories/` に置く
- 外部 API / ファイル操作などの service interface は `data/services/` に置く
- application service は abstract class を前提にせず、**concrete class を直接 `application/` に置く**

## 更新系処理の原則

- 書き込みや副作用を伴う処理は application service に置く
- 読み取り専用の処理は service に押し込まず query provider で表現する
- `invalidate` は「古い provider の値を破棄して、次回参照時に再取得させる」ために使う

## main.dart の役割

- `main.dart` はアプリ全体の初期化と `ProviderScope` の起動に留める
- feature ごとの実装詳細や配線ロジックを `main.dart` に集中させない
