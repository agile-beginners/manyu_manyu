# Video Manual Generator

動画から自動的にAIがマニュアルを生成するFlutterアプリケーション。

## セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. 環境変数の設定

1. `.env.example`を`.env`にコピー:
```bash
cp .env.example .env
```

2. `.env`ファイルを編集してAPI Keyを設定:
```env
# Gemini API Key (Get from: https://makersuite.google.com/app/apikey)
# This key is used for both video analysis and image generation/editing
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### 3. API Keyの取得

#### Gemini API Key
1. [Google AI Studio](https://makersuite.google.com/app/apikey)にアクセス
2. Googleアカウントでログイン
3. "Create API Key"をクリック
4. 生成されたAPI Keyを`.env`ファイルに設定

**注意**: このAPI Keyは動画解析と画像生成・編集の両方に使用されます。

### 4. アプリの実行

```bash
flutter run
```

## 機能

- 動画アップロード
- AI による動画解析（Gemini API）
- 自動ステップ抽出
- 動画からの画像抽出
- 画像注釈・編集（Gemini API）
- マニュアル編集
- プレビューモード
- PDF出力

## 開発

### デバッグモード

デバッグモードでは、設定確認画面にアクセスできます：
1. アプリを起動
2. "Configuration Debug"ボタンをタップ
3. API Keyの設定状況を確認

### テスト実行

```bash
flutter test
```

## 注意事項

- `.env`ファイルはGitに含まれません（セキュリティのため）
- API Keyは絶対にソースコードに直接書かないでください
- 本番環境では適切なシークレット管理サービスを使用してください