import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

// QRトークンの状態を管理するクラス
class QRTokenState {
  final String? token;
  final int? expiresAt;
  final bool isLoading;
  final String? error;

  const QRTokenState({
    this.token,
    this.expiresAt,
    this.isLoading = false,
    this.error,
  });

  QRTokenState copyWith({
    String? token,
    int? expiresAt,
    bool? isLoading,
    String? error,
  }) {
    return QRTokenState(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// 残り秒数を動的に計算
  int get remainingSeconds {
    if (expiresAt == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = (expiresAt! - now) ~/ 1000;
    return remaining > 0 ? remaining : 0;
  }

  bool get isExpired => remainingSeconds <= 0;
  bool get hasToken => token != null && token!.isNotEmpty;
}

// QRトークンプロバイダー（自動破棄）
final qrTokenProvider = StateNotifierProvider.autoDispose<QRTokenNotifier, QRTokenState>((ref) {
  return QRTokenNotifier();
});

class QRTokenNotifier extends StateNotifier<QRTokenState> {
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  final Random _random = Random();

  QRTokenNotifier() : super(const QRTokenState()) {
    // 初期化時にトークンを取得
    fetchToken();
    _startTokenRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// トークンを取得
  Future<void> fetchToken() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('issueQrToken');
      
      final result = await callable.call();
      
      final token = result.data['token'] as String;
      final expiresAt = result.data['expiresAt'] as int;
      
      state = state.copyWith(
        token: token,
        expiresAt: expiresAt,
        isLoading: false,
        error: null,
      );

      _startCountdownTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'トークンの取得に失敗しました: ${e.toString()}',
      );
      
      // エラー時は3秒後にリトライ
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          fetchToken();
        }
      });
    }
  }

  /// トークンを手動で更新
  Future<void> refreshToken() async {
    await fetchToken();
  }

  /// 自動更新タイマーを開始
  void _startTokenRefresh() {
    _refreshTimer?.cancel();
    
    // 55秒 + ランダムジッター（±1秒）で更新
    final baseInterval = 55;
    final jitter = _random.nextInt(3) - 1; // -1, 0, 1
    final interval = baseInterval + jitter;
    
    _refreshTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (mounted) {
        fetchToken();
      }
    });
  }

  /// カウントダウンタイマーを開始
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && state.expiresAt != null) {
        // 残り秒数が0以下になったらタイマーを停止
        if (state.remainingSeconds <= 0) {
          timer.cancel();
        } else {
          // 状態を更新してUIを再描画
          state = state.copyWith();
        }
      } else {
        timer.cancel();
      }
    });
  }


  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 認証状態プロバイダー
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
