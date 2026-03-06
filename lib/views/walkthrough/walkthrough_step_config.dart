import 'package:flutter/material.dart';

/// ウォークスルーの各ステップ
enum WalkthroughStep {
  none,
  concept,        // 新規: フルスクリーンコンセプト説明
  tapMapTab,      // 既存
  tapMarker,      // 既存
  learnNfcTouch,  // 新規: NFCタッチ説明（操作不要）
  tapZukanTab,    // 既存
  tapProfileTab,  // 新規: アカウントタブ
}

/// メッセージの表示位置
enum MessagePosition {
  top,
  center,
  aboveTarget,
}

/// 各ステップの設定
class WalkthroughStepConfig {
  final WalkthroughStep step;
  final String message;
  final String? subMessage;
  final IconData? icon;
  final MessagePosition messagePosition;
  final bool requiresAction;

  const WalkthroughStepConfig({
    required this.step,
    required this.message,
    this.subMessage,
    this.icon,
    this.messagePosition = MessagePosition.center,
    this.requiresAction = true,
  });
}

const Map<WalkthroughStep, WalkthroughStepConfig> walkthroughStepConfigs = {
  WalkthroughStep.concept: WalkthroughStepConfig(
    step: WalkthroughStep.concept,
    message: '街を舞台にした探検ゲームへようこそ。',
    subMessage: 'ただし、実際に行かないと進まない。',
    icon: Icons.explore,
    messagePosition: MessagePosition.center,
    requiresAction: false,
  ),
  WalkthroughStep.tapMapTab: WalkthroughStepConfig(
    step: WalkthroughStep.tapMapTab,
    message: 'マップを開いてみよう！',
    subMessage: 'グレーのマーカーが"まだ誰も発見していない"お店です',
    icon: Icons.map,
    messagePosition: MessagePosition.center,
  ),
  WalkthroughStep.tapMarker: WalkthroughStepConfig(
    step: WalkthroughStep.tapMarker,
    message: '気になるお店をタップしてみよう！',
    subMessage: '★の数がレア度。少ない発見者数ほどレアなお店です',
    icon: Icons.touch_app,
    messagePosition: MessagePosition.top,
  ),
  WalkthroughStep.learnNfcTouch: WalkthroughStepConfig(
    step: WalkthroughStep.learnNfcTouch,
    message: '実際のお店でNFCタッチしてみよう！',
    subMessage: 'レジ近くのスタンドにスマホをかざすと図鑑カードが発見できます。何のレア度が出るかはお楽しみ✦',
    icon: Icons.nfc,
    messagePosition: MessagePosition.center,
    requiresAction: false,
  ),
  WalkthroughStep.tapZukanTab: WalkthroughStepConfig(
    step: WalkthroughStep.tapZukanTab,
    message: '図鑑タブを開いてみよう！',
    subMessage: '？？？のシルエットは、まだ行っていないお店。コンプリートを目指そう！',
    icon: Icons.menu_book,
    messagePosition: MessagePosition.center,
  ),
  WalkthroughStep.tapProfileTab: WalkthroughStepConfig(
    step: WalkthroughStep.tapProfileTab,
    message: 'アカウントタブもチェック！',
    subMessage: 'バッジ・ランキング・毎月の探検レポートが見られます',
    icon: Icons.person,
    messagePosition: MessagePosition.center,
  ),
};
