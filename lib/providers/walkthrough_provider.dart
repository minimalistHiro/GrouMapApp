import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../views/walkthrough/walkthrough_step_config.dart';

/// ウォークスルーの状態
class WalkthroughState {
  final WalkthroughStep step;
  final bool isActive;
  final String? userId;

  const WalkthroughState({
    this.step = WalkthroughStep.none,
    this.isActive = false,
    this.userId,
  });

  WalkthroughState copyWith({
    WalkthroughStep? step,
    bool? isActive,
    String? userId,
  }) {
    return WalkthroughState(
      step: step ?? this.step,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
    );
  }
}

/// ウォークスルーの状態管理
class WalkthroughNotifier extends StateNotifier<WalkthroughState> {
  WalkthroughNotifier() : super(const WalkthroughState());

  /// ウォークスルーを開始
  void startWalkthrough(String userId) {
    state = WalkthroughState(
      step: WalkthroughStep.concept,
      isActive: true,
      userId: userId,
    );
  }

  /// 次のステップへ進む
  void nextStep() {
    const steps = WalkthroughStep.values;
    final currentIndex = steps.indexOf(state.step);
    final nextIndex = currentIndex + 1;
    if (nextIndex >= steps.length) {
      completeWalkthrough();
      return;
    }
    state = state.copyWith(step: steps[nextIndex]);
  }

  /// 特定のステップに設定
  void setStep(WalkthroughStep step) {
    state = state.copyWith(step: step);
  }

  /// ウォークスルーを完了
  Future<void> completeWalkthrough() async {
    final userId = state.userId;
    state = const WalkthroughState();
    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'walkthroughCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('ウォークスルー完了フラグ更新エラー: $e');
      }
    }
  }

  /// スキップ
  Future<void> skipWalkthrough() async {
    await completeWalkthrough();
  }

  /// プロバイダーの状態のみリセット（Firestoreは更新しない）
  /// pushAndRemoveUntilで新しいMainNavigationViewが作成された時に、
  /// 前インスタンスのゴースト状態をクリアするために使用
  void resetState() {
    state = const WalkthroughState();
  }
}

final walkthroughProvider =
    StateNotifierProvider<WalkthroughNotifier, WalkthroughState>((ref) {
  return WalkthroughNotifier();
});
