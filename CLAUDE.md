# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language Preference

**重要**: このプロジェクトでは日本語で応答してください。ユーザーとのコミュニケーションは日本語で行い、コメントや説明も日本語で記述してください。

## Project Overview

This is a Flutter mobile application called "groumapapp" - a standard Flutter project initialized with the default counter app template. The project supports multiple platforms (iOS, Android, macOS, Linux, Windows, and Web).

## Architecture

- **Framework**: Flutter with Dart SDK ^3.5.0
- **Main Entry Point**: `lib/main.dart` contains the standard Flutter counter app with MaterialApp
- **Project Structure**:
  - `lib/` - Main Dart source code (currently only contains `main.dart`)
  - `test/` - Widget and unit tests
  - Platform-specific directories: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`

## Common Development Commands

### Dependencies
- **Install dependencies**: `flutter pub get`
- **Update dependencies**: `flutter pub upgrade`

### Development
- **Run app (debug mode)**: `flutter run`
- **Run on specific device**: `flutter run -d <device_id>`
- **Hot reload**: Press `r` in terminal while app is running
- **Hot restart**: Press `R` in terminal while app is running

### Code Quality
- **Static analysis/linting**: `flutter analyze`
- **Format code**: `flutter format .`

### Testing
- **Run all tests**: `flutter test`
- **Run specific test file**: `flutter test test/widget_test.dart`

### Build
- **Build APK (Android)**: `flutter build apk`
- **Build iOS**: `flutter build ios`
- **Build for web**: `flutter build web`

## Code Style

The project uses `flutter_lints ^4.0.0` for linting rules, configured in `analysis_options.yaml`. The linter follows Flutter's recommended practices and includes the standard Flutter lint set.