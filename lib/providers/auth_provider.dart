import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

// 認証サービスプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 認証状態プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// サインイン状態管理
enum SignInState {
  initial,
  loading,
  success,
  error,
}

class SignInStateNotifier extends StateNotifier<SignInState> {
  final AuthService _authService;
  String? _errorMessage;
  String? _errorDetails;
  String? _lastOperation;

  SignInStateNotifier(this._authService) : super(SignInState.initial);

  String? get errorMessage => _errorMessage;
  String? get errorDetails => _errorDetails;
  String? get lastOperation => _lastOperation;

  // エラー設定
  void _setError(String message, String? details, String operation) {
    _errorMessage = message;
    _errorDetails = details;
    _lastOperation = operation;
    state = SignInState.error;
  }

  // エラークリア
  void _clearError() {
    _errorMessage = null;
    _errorDetails = null;
    _lastOperation = null;
  }

  // Googleサインイン
  Future<void> signInWithGoogle() async {
    _clearError();
    state = SignInState.loading;
    _lastOperation = 'Googleサインイン';

    try {
      await _authService.signInWithGoogle();
      state = SignInState.success;
    } catch (e) {
      if (e is AuthException) {
        _setError(e.message, e.code, 'Googleサインイン');
      } else {
        _setError('Googleサインインに失敗しました', e.toString(), 'Googleサインイン');
      }
    }
  }

  // Appleサインイン
  Future<void> signInWithApple() async {
    _clearError();
    state = SignInState.loading;
    _lastOperation = 'Appleサインイン';

    try {
      await _authService.signInWithApple();
      state = SignInState.success;
    } catch (e) {
      if (e is AuthException) {
        _setError(e.message, e.code, 'Appleサインイン');
      } else {
        _setError('Appleサインインに失敗しました', e.toString(), 'Appleサインイン');
      }
    }
  }

  // メールアドレス・パスワードサインイン
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _clearError();
    state = SignInState.loading;
    _lastOperation = 'メールアドレス・パスワードサインイン';

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = SignInState.success;
      debugPrint('SignInStateNotifier: Sign in successful');
    } catch (e) {
      debugPrint('SignInStateNotifier: Sign in failed - $e');
      if (e is AuthException) {
        _setError(e.message, e.code, 'メールアドレス・パスワードサインイン');
      } else {
        _setError('サインインに失敗しました', e.toString(), 'メールアドレス・パスワードサインイン');
      }
    }
  }

  // アカウント作成
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    Map<String, dynamic>? additionalUserInfo,
  }) async {
    _clearError();
    state = SignInState.loading;
    _lastOperation = 'アカウント作成';

    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        additionalUserInfo: additionalUserInfo,
      );
      state = SignInState.success;
    } catch (e) {
      if (e is AuthException) {
        _setError(e.message, e.code, 'アカウント作成');
      } else {
        _setError('アカウント作成に失敗しました', e.toString(), 'アカウント作成');
      }
    }
  }

  // 匿名サインイン
  Future<void> signInAnonymously() async {
    _clearError();
    state = SignInState.loading;
    _lastOperation = '匿名サインイン';

    try {
      await _authService.signInAnonymously();
      state = SignInState.success;
    } catch (e) {
      if (e is AuthException) {
        _setError(e.message, e.code, '匿名サインイン');
      } else {
        _setError('匿名サインインに失敗しました', e.toString(), '匿名サインイン');
      }
    }
  }

  // パスワードリセット
  Future<void> sendPasswordResetEmail(String email) async {
    _clearError();
    state = SignInState.loading;
    _lastOperation = 'パスワードリセット';

    try {
      await _authService.sendPasswordResetEmail(email);
      state = SignInState.success;
    } catch (e) {
      if (e is AuthException) {
        _setError(e.message, e.code, 'パスワードリセット');
      } else {
        _setError('パスワードリセットに失敗しました', e.toString(), 'パスワードリセット');
      }
    }
  }

  // サインアウト
  Future<void> signOut() async {
    _clearError();
    state = SignInState.loading;
    _lastOperation = 'サインアウト';

    try {
      await _authService.signOut();
      state = SignInState.success;
    } catch (e) {
      if (e is AuthException) {
        _setError(e.message, e.code, 'サインアウト');
      } else {
        _setError('サインアウトに失敗しました', e.toString(), 'サインアウト');
      }
    }
  }

  // 最後の操作を再試行
  Future<void> retryLastOperation() async {
    if (_lastOperation == null) return;

    switch (_lastOperation) {
      case 'Googleサインイン':
        await signInWithGoogle();
        break;
      case 'Appleサインイン':
        await signInWithApple();
        break;
      case 'メールアドレス・パスワードサインイン':
        // メールアドレス・パスワードサインインは再試行できない
        break;
      case 'アカウント作成':
        // アカウント作成は再試行できない
        break;
      case '匿名サインイン':
        await signInAnonymously();
        break;
      case 'パスワードリセット':
        // パスワードリセットは再試行できない
        break;
      case 'サインアウト':
        await signOut();
        break;
    }
  }
}

// サインイン状態プロバイダー
final signInStateProvider = StateNotifierProvider<SignInStateNotifier, SignInState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return SignInStateNotifier(authService);
});
