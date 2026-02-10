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

## Firebase関連の変更

Firebase関連の設定変更は、このプロジェクト内のファイルを編集してください。
- `/Users/kanekohiroki/Desktop/groumapapp/firebase.json`
- `/Users/kanekohiroki/Desktop/groumapapp/firestore.indexes.json`

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
