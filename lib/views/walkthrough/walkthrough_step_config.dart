import 'package:flutter/material.dart';

/// ウォークスルーの各ステップ
enum WalkthroughStep {
  none,
  tapMapTab,
  tapMarker,
  tapClosePanel,
  tapHomeTab,
  tapMissionFab,
  claimMission,
  tapCoinExchange,
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
  final IconData? icon;
  final MessagePosition messagePosition;

  const WalkthroughStepConfig({
    required this.step,
    required this.message,
    this.icon,
    this.messagePosition = MessagePosition.center,
  });
}

const Map<WalkthroughStep, WalkthroughStepConfig> walkthroughStepConfigs = {
  WalkthroughStep.tapMapTab: WalkthroughStepConfig(
    step: WalkthroughStep.tapMapTab,
    message: 'マップ画面を開いてみよう！',
    icon: Icons.map,
    messagePosition: MessagePosition.center,
  ),
  WalkthroughStep.tapMarker: WalkthroughStepConfig(
    step: WalkthroughStep.tapMarker,
    message: '気になるお店をタップしてみよう！',
    icon: Icons.touch_app,
    messagePosition: MessagePosition.top,
  ),
  WalkthroughStep.tapClosePanel: WalkthroughStepConfig(
    step: WalkthroughStep.tapClosePanel,
    message: 'お店の情報を確認したら\n閉じてみよう！',
    icon: Icons.close,
    messagePosition: MessagePosition.top,
  ),
  WalkthroughStep.tapHomeTab: WalkthroughStepConfig(
    step: WalkthroughStep.tapHomeTab,
    message: 'ホーム画面に戻ろう！',
    icon: Icons.home,
    messagePosition: MessagePosition.center,
  ),
  WalkthroughStep.tapMissionFab: WalkthroughStepConfig(
    step: WalkthroughStep.tapMissionFab,
    message: 'ミッションを確認して\nコインを受け取ろう！',
    icon: Icons.monetization_on,
    messagePosition: MessagePosition.center,
  ),
  WalkthroughStep.claimMission: WalkthroughStepConfig(
    step: WalkthroughStep.claimMission,
    message: 'タップして10コインを受け取ろう！',
    icon: Icons.card_giftcard,
    messagePosition: MessagePosition.top,
  ),
  WalkthroughStep.tapCoinExchange: WalkthroughStepConfig(
    step: WalkthroughStep.tapCoinExchange,
    message: '10コインで100円引きクーポンと\n交換しよう！',
    icon: Icons.swap_horiz,
    messagePosition: MessagePosition.center,
  ),
};
