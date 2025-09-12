# CLAUDE.md

## Language Preference

**重要**: このプロジェクトでは日本語で応答してください。ユーザーとのコミュニケーションは日本語で行い、コメントや説明も日本語で記述してください。

## Project Overview

「GrouMap」は、Firebase + Flutterで開発されるモバイルアプリケーション（iOS/Android対応）です。ユーザーアプリと店舗用アプリの2種類を提供し、地図を活用した店舗発見・ポイントシステム・クーポン機能を核とするプラットフォームアプリです。

### 主要な特徴
- **2つのアプリ種別**: ユーザーアプリと店舗用アプリ
- **統合バックエンド**: Firebase（Auth/Firestore/Functions/Storage/FCM）
- **リアルタイム地図連携**: Google Maps Integration
- **ポイント・スタンプシステム**: 来店促進機能
- **画像処理**: Firebase Storage + 圧縮処理
- **多階層権限管理**: 一般ユーザー・店舗オーナー・会社管理者

## Architecture

### システム構成
- **フロントエンド**: Flutter (Dart SDK ^3.5.0)
- **バックエンド**: Firebase Suite (Auth/Firestore/Functions/Storage/FCM)
- **地図サービス**: Google Maps Platform
- **タイムゾーン**: Asia/Tokyo

### プロジェクト構成
```
lib/
├── main.dart                    # エントリポイント
├── core/                        # 共通コア機能
├── models/                      # データモデル
├── repositories/                # データアクセス層
├── services/                    # サービス層
├── providers/                   # Riverpod状態管理
├── views/                       # UI画面
└── widgets/                     # 再利用可能ウィジェット
```

## Development Commands

### 開発コマンド
- **依存関係インストール**: `flutter pub get`
- **アプリ実行**: `flutter run`
- **コード解析**: `flutter analyze`
- **テスト実行**: `flutter test`
- **ビルド**: `flutter build apk` (Android) / `flutter build ios` (iOS)

## Code Style

`flutter_lints ^4.0.0` を使用し、Flutter推奨のコードスタイルに従います。

## 重要な注意事項

- 詳細設計仕様は `詳細設計.pdf` を参照
- Firebaseプロジェクト: groumapapp
- 権限管理: `isCompanyAdmin` フラグで会社管理者機能を制御
- プランシステム: Basic/Premium での機能制限実装必須

