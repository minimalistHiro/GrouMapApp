# CLAUDE.md

## Language Preference

**重要**: このプロジェクトでは日本語で応答してください。ユーザーとのコミュニケーションは日本語で行い、コメントや説明も日本語で記述してください。

## Project Overview

「GrouMap」は、Firebase + Flutterで開発されるモバイルアプリケーション（iOS/Android対応）です。ユーザーアプリと店舗用アプリの2種類を提供し、地図を活用した店舗発見・ポイントシステム・クーポン機能を核とするプラットフォームアプリです。

### アプリの区分
- **ユーザー用アプリ**: 本リポジトリ（/Users/kanekohiroki/Desktop/groumapapp）
- **店舗用アプリ**: /Users/kanekohiroki/Desktop/groumapapp_store

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

- Firebaseプロジェクト: groumapapp

## Firestore Rules

Firestoreのルールはユーザーアプリのリポジトリで管理します。ルールを更新する場合は
`/Users/kanekohiroki/Desktop/groumapapp/firestore.rules` を編集し、そのプロジェクトからデプロイしてください。
このリポジトリからルールの更新やデプロイは行わないでください。

### Firestoreルールの自動見直し

コードの修正・変更を行った際に、新しいFirestoreコレクションへの読み書きが発生する場合は、必ず `firestore.rules` にそのコレクションのルールが存在するか確認してください。ルールが不足している場合は追加し、`firebase deploy --only firestore:rules` でデプロイまで実行してください。

### 複合インデックスの自動見直し

コードの修正・変更を行った際に、Firestoreクエリで複数フィールドの `where` 条件や `orderBy` の組み合わせが新たに発生する場合は、必ず `firestore.indexes.json` に必要な複合インデックスが定義されているか確認してください。不足している場合はインデックスを追加し、`firebase deploy --only firestore:indexes` でデプロイまで実行してください。

### Firebase Functionsの自動デプロイ

`backend/functions` 配下のCloud Functionsコードに修正・変更を行った場合は、必ず `firebase deploy --only functions` でデプロイまで実行してください。特定の関数のみ変更した場合は `firebase deploy --only functions:関数名` で対象を絞ってデプロイしても構いません。

## Firebase関連の変更

Firebase関連の設定変更は、すべてユーザーアプリのリポジトリ内のファイルを編集してください。
- **Firestoreルール**: `/Users/kanekohiroki/Desktop/groumapapp/firestore.rules`
- **複合インデックス**: `/Users/kanekohiroki/Desktop/groumapapp/firestore.indexes.json`
- **Firebase設定**: `/Users/kanekohiroki/Desktop/groumapapp/firebase.json`
- **Cloud Functions**: `/Users/kanekohiroki/Desktop/groumapapp/backend/functions`

コード変更後、関連するFirebaseリソースに影響がある場合は、以下を自動的に確認・デプロイしてください：
1. `firebase deploy --only firestore:rules` — ルール変更時
2. `firebase deploy --only firestore:indexes` — インデックス変更時
3. `firebase deploy --only functions` — Functions変更時

## Plan Mode

### プランの保存先

プランモードで作成したプランは、以下の場所に保存してください：
- **プランファイル**: `/Users/kanekohiroki/Desktop/groumapapp/.claude/PLAN.md`

プランモードに入った際は、必ずこのファイルにプランを書き込んでください。

## Claude Code Skills

### スキルの配置

このプロジェクトでは、プロジェクト固有のスキルを使用しています。スキルは以下の場所に配置されています：
- **ユーザー用アプリ**: `/Users/kanekohiroki/Desktop/groumapapp/.claude/skills/`
- **店舗用アプリ**: `/Users/kanekohiroki/Desktop/groumapapp_store/.claude/skills/`

### スキル更新ルール

**重要**: スキルに追記・修正を行う場合は、必ず両プロジェクト（ユーザー用・店舗用）の該当するスキルに同じ内容を反映してください。

- スキルを更新する際は、ユーザー用アプリのスキルだけでなく、店舗用アプリの対応するスキルにも同じ内容を追記・修正する
- 両プロジェクトのスキルは常に同期を保つ
- 片方のみ更新すると、プロジェクト間で動作が不整合になるため注意

## Screen Configuration Reference

### 画面構成の参照

実装やプラン作成時には、必ず以下のファイルを参照してフローや画面構成を確認してください：

- **ユーザー用アプリ**: `/Users/kanekohiroki/Desktop/groumapapp/USER_APP_SCREENS.md`
- **店舗用アプリ**: `/Users/kanekohiroki/Desktop/groumapapp_store/STORE_APP_SCREENS.md`

画面の追加・変更・削除を行う際は、実装後に対応するドキュメントファイルも更新してください。
