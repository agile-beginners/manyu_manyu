# 要件定義書

## 概要

動画から自動的にAIがマニュアルを生成するFlutterアプリケーション。ユーザーが操作手順を録画した動画をアップロードすると、Gemini APIが動画を解析してステップを抽出し、Nano Banana APIが各ステップの説明画像を生成する。最終的にPDF出力も可能な、スマートフォンとWeb対応のマニュアル作成システム。

## 用語集

- **Video_Manual_Generator**: 動画解析による自動マニュアル生成システム
- **Gemini_API**: 動画解析を行い、操作ステップを抽出するGoogle AI API
- **Nano_Banana_API**: 画像に注釈や図形を追加する画像編集API
- **ステップ**: マニュアルの個別の操作手順項目（最大20ステップ）
- **プレビューモード**: 生成されたマニュアルを1ステップずつ大画面で閲覧するモード
- **タイムスタンプ**: 動画中の特定操作が行われている時刻（ミリ秒単位）

## 要件

### 要件 1

**ユーザーストーリー:** ユーザーとして、操作手順を録画した動画をアップロードしたい。そうすることで、AIによる自動マニュアル生成を開始したい。

#### 受入基準

1. WHEN ユーザーが動画ファイルを選択する THEN Video_Manual_Generator SHALL 対応する動画形式を受け入れる
2. WHEN 動画ファイルがアップロードされる THEN Video_Manual_Generator SHALL ファイルサイズと形式を検証する
3. WHEN 無効な動画ファイルがアップロードされる THEN Video_Manual_Generator SHALL エラーメッセージを表示し、アップロードを拒否する
4. WHEN 動画アップロードが完了する THEN Video_Manual_Generator SHALL アップロード進捗を表示し、完了通知を行う

### 要件 2

**ユーザーストーリー:** システムとして、アップロードされた動画をGemini APIで解析したい。そうすることで、操作ステップを自動抽出したい。

#### 受入基準

1. WHEN 動画アップロードが完了する THEN Video_Manual_Generator SHALL 動画をGemini_API に送信する
2. WHEN Gemini_API が動画を解析する THEN Video_Manual_Generator SHALL 最大20ステップの操作手順を抽出する
3. WHEN ステップ抽出が完了する THEN Video_Manual_Generator SHALL タイトル、説明、タイムスタンプを含むJSONデータを受信する
4. WHEN API通信でエラーが発生する THEN Video_Manual_Generator SHALL エラー詳細を表示し、再試行オプションを提供する

### 要件 3

**ユーザーストーリー:** システムとして、抽出されたタイムスタンプから動画の画像を切り出したい。そうすることで、各ステップの説明画像を準備したい。

#### 受入基準

1. WHEN ステップ抽出が完了する THEN Video_Manual_Generator SHALL 各タイムスタンプで動画から画像を抽出する
2. WHEN 画像抽出が実行される THEN Video_Manual_Generator SHALL 抽出した画像をローカルに一時保存する
3. WHEN 画像抽出が完了する THEN Video_Manual_Generator SHALL 抽出された全画像をNano_Banana_API に送信する
4. WHEN 画像抽出でエラーが発生する THEN Video_Manual_Generator SHALL エラーを記録し、該当ステップをスキップする

### 要件 4

**ユーザーストーリー:** システムとして、抽出した画像にNano Banana APIで注釈を追加したい。そうすることで、わかりやすいマニュアル画像を生成したい。

#### 受入基準

1. WHEN 画像がNano_Banana_API に送信される THEN Video_Manual_Generator SHALL 各画像に赤色の矢印、文字、丸囲みを追加させる
2. WHEN 注釈付き画像が生成される THEN Video_Manual_Generator SHALL 編集済み画像をローカルに保存する
3. WHEN 画像編集が完了する THEN Video_Manual_Generator SHALL ステップJSONに画像パスを追加する
4. WHEN API通信でエラーが発生する THEN Video_Manual_Generator SHALL 元画像を使用してステップを継続する

### 要件 5

**ユーザーストーリー:** ユーザーとして、生成されたマニュアルを確認・編集したい。そうすることで、より正確で分かりやすいマニュアルに仕上げたい。

#### 受入基準

1. WHEN マニュアル生成が完了する THEN Video_Manual_Generator SHALL 全ステップを一覧表示する
2. WHEN ユーザーがステップを選択する THEN Video_Manual_Generator SHALL タイトルと説明の編集機能を提供する
3. WHEN ステップの説明文を編集する THEN Video_Manual_Generator SHALL リアルタイムで変更を保存する
4. WHEN 編集が完了する THEN Video_Manual_Generator SHALL 更新されたマニュアルデータを保持する

### 要件 6

**ユーザーストーリー:** ユーザーとして、生成されたマニュアルをプレビューモードで閲覧したい。そうすることで、実際のマニュアルとしての使いやすさを確認したい。

#### 受入基準

1. WHEN ユーザーがプレビューモードを選択する THEN Video_Manual_Generator SHALL 1ステップずつ大画面で表示する
2. WHEN プレビューモードで画面右側をタップする THEN Video_Manual_Generator SHALL 次のステップを表示する
3. WHEN プレビューモードで画面左側をタップする THEN Video_Manual_Generator SHALL 前のステップを表示する
4. WHEN 最初または最後のステップに到達する THEN Video_Manual_Generator SHALL 適切な境界処理を行う

### 要件 7

**ユーザーストーリー:** ユーザーとして、完成したマニュアルをPDFとして出力したい。そうすることで、他のユーザーと共有したり、印刷して利用したい。

#### 受入基準

1. WHEN ユーザーがPDF出力ボタンを押下する THEN Video_Manual_Generator SHALL マニュアルをPDF形式で生成する
2. WHEN PDF生成が実行される THEN Video_Manual_Generator SHALL 各ステップの画像と説明を含む整形されたドキュメントを作成する
3. WHEN PDF生成が完了する THEN Video_Manual_Generator SHALL ファイルのダウンロードを開始する
4. WHEN PDF生成でエラーが発生する THEN Video_Manual_Generator SHALL エラーメッセージを表示し、再試行オプションを提供する

### 要件 8

**ユーザーストーリー:** システムとして、スマートフォンとWebの両方で動作したい。そうすることで、様々なデバイスでマニュアル作成を可能にしたい。

#### 受入基準

1. WHEN アプリケーションがスマートフォンで起動される THEN Video_Manual_Generator SHALL モバイル向けUIを表示する
2. WHEN アプリケーションがWebブラウザで起動される THEN Video_Manual_Generator SHALL Web向けUIを表示する
3. WHEN 異なるデバイスでアクセスされる THEN Video_Manual_Generator SHALL レスポンシブデザインで適切に表示する
4. WHEN タッチ操作が行われる THEN Video_Manual_Generator SHALL タッチイベントを適切に処理する