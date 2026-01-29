---
name: app-release-build-rules
description: GrouMapプロジェクトで「アプリをリリースして」等の依頼が来たときに、Google Play/App Store向けのリリースビルド手順を実行するために使う。
---

# App Release Build Rules

## 概要

GrouMapのリリース依頼時に、AndroidのAAB作成とiOSビルド準備を順番に実行する。iOSのArchiveはXcodeで手動実行する前提で進める。

## 手順

ユーザーから「アプリをリリースして」等の依頼が来た場合は、以下を順番どおりに実施する。

1. Android向けに`flutter build appbundle`を実行し、Google Playリリース用のAABを作成する。
2. `ios`ディレクトリで`pod install`を実行する（`cd ios && pod install`）。
3. `flutter build ios`を実行し、App Storeリリース向けのビルドを行う。
4. iOSのArchiveを`xcodebuild`で実行する。
   - ワークスペース: `ios/Runner.xcworkspace`
   - Scheme: `Runner`
   - Configuration: `Release`
   - 出力先: `ios/build/Runner.xcarchive`
   - 例: `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath ios/build/Runner.xcarchive archive`

## 注意事項

- iOSのアップロードは手動で進める（Archive作成後の配布はGUIで実施）。
- 権限不足や依存エラーが出た場合は、ターミナルでコマンドを実行して確認・修正する。
