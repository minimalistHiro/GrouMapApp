import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // リトライ設定
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Googleサインイン
  Future<UserCredential?> signInWithGoogle() async {
    return await _retryOperation(() async {
      try {
        UserCredential userCredential;
        if (kIsWeb) {
          final provider = GoogleAuthProvider();
          userCredential = await _auth.signInWithPopup(provider);
        } else {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw Exception('Googleサインインがキャンセルされました');
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          userCredential = await _auth.signInWithCredential(credential);
        }
        
        // 新規ユーザーの場合、基本情報を保存
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          try {
            await _saveUserToFirestore(
              user: userCredential.user!,
              displayName: userCredential.user?.displayName ?? '',
              authProvider: 'google',
              additionalInfo: {
                'level': 1,
                'experience': 0,
                'createdAt': DateTime.now(),
              },
            );
          } catch (e) {
            debugPrint('Firestore save failed during Google sign in: $e');
          }
        }
        
        return userCredential;
      } catch (e) {
        debugPrint('Google sign in error: $e');
        throw _handleAuthError(e, 'Googleサインイン');
      }
    });
  }

  // Appleサインイン
  Future<UserCredential?> signInWithApple() async {
    return await _retryOperation(() async {
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        final userCredential = await _auth.signInWithCredential(oauthCredential);
        
        // 新規ユーザーの場合、基本情報を保存
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          try {
            await _saveUserToFirestore(
              user: userCredential.user!,
              displayName: userCredential.user?.displayName ?? '',
              authProvider: 'apple',
              additionalInfo: {
                'level': 1,
                'experience': 0,
                'createdAt': DateTime.now(),
              },
            );
          } catch (e) {
            debugPrint('Firestore save failed during Apple sign in: $e');
          }
        }
        
        return userCredential;
      } catch (e) {
        debugPrint('Apple sign in error: $e');
        throw _handleAuthError(e, 'Appleサインイン');
      }
    });
  }

  // メールアドレス・パスワードでサインイン
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _retryOperation(() async {
      try {
        debugPrint('AuthService: Attempting email sign in for $email');
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('AuthService: Email sign in successful: ${credential.user?.uid}');
        return credential;
      } catch (e) {
        debugPrint('AuthService: Email sign in error: $e');
        throw _handleAuthError(e, 'メールアドレス・パスワードサインイン');
      }
    });
  }

  // メールアドレス・パスワードでアカウント作成
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    Map<String, dynamic>? additionalUserInfo,
  }) async {
    return await _retryOperation(() async {
      try {
        debugPrint('Creating user with email: $email');
        final UserCredential userCredential = 
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint('User created successfully: ${userCredential.user?.uid}');
        
        // 表示名を設定
        await userCredential.user?.updateDisplayName(displayName);
        debugPrint('Display name updated: $displayName');

        // Firestoreにユーザー情報を保存（失敗しても認証は成功させる）
        try {
          await _saveUserToFirestore(
            user: userCredential.user!,
            displayName: displayName,
            authProvider: 'email',
            additionalInfo: additionalUserInfo,
          );
        } catch (e) {
          debugPrint('Firestore save failed but continuing with auth: $e');
          // Firestore保存に失敗しても認証は成功させる
        }

        return userCredential;
      } catch (e) {
        debugPrint('User creation error: $e');
        throw _handleAuthError(e, 'アカウント作成');
      }
    });
  }

  // 匿名サインイン
  Future<UserCredential?> signInAnonymously() async {
    return await _retryOperation(() async {
      try {
        return await _auth.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous sign in error: $e');
        throw _handleAuthError(e, '匿名サインイン');
      }
    });
  }

  // パスワードリセット
  Future<void> sendPasswordResetEmail(String email) async {
    return await _retryOperation(() async {
      try {
        await _auth.sendPasswordResetEmail(email: email);
      } catch (e) {
        debugPrint('Password reset error: $e');
        throw _handleAuthError(e, 'パスワードリセット');
      }
    });
  }

  // メール認証コードを送信
  Future<void> sendEmailVerification() async {
    return await _retryOperation(() async {
      try {
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('ユーザーがログインしていません');
        }

        final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
        final callable = functions.httpsCallable('requestEmailOtp');
        await callable();
      } catch (e) {
        debugPrint('Send email OTP error: $e');
        throw _handleAuthError(e, 'メール認証コード送信');
      }
    });
  }

  // メール認証コードを検証
  Future<void> verifyEmailOtp(String code) async {
    return await _retryOperation(() async {
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
        final callable = functions.httpsCallable('verifyEmailOtp');
        await callable.call({'code': code});
      } catch (e) {
        debugPrint('Verify email OTP error: $e');
        throw _handleAuthError(e, 'メール認証コード確認');
      }
    });
  }

  // メール認証状態を確認
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      return data?['emailVerified'] == true;
    } catch (e) {
      debugPrint('Check email verified error: $e');
      return false;
    }
  }

  // メール認証状態のストリーム
  Stream<bool> emailVerificationStatusStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return data?['emailVerified'] == true;
    });
  }

  // Firestore上のメール認証状態を更新
  Future<void> updateEmailVerificationStatus(bool isVerified) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('users').doc(user.uid).set({
        'emailVerified': isVerified,
        'emailVerifiedAt': isVerified ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Update email verification status error: $e');
      // 非致命的
    }
  }

  // アカウント削除
  Future<void> deleteAccount() async {
    return await _retryOperation(() async {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).delete();
          await user.delete();
        }
      } catch (e) {
        debugPrint('Account deletion error: $e');
        throw _handleAuthError(e, 'アカウント削除');
      }
    });
  }

  // サインアウト
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw _handleAuthError(e, 'サインアウト');
    }
  }

  // Firestoreにユーザー情報を保存
  Future<void> _saveUserToFirestore({
    required User user,
    required String displayName,
    Map<String, dynamic>? additionalInfo,
    String? authProvider, // 認証プロバイダー情報を追加
  }) async {
    try {
      debugPrint('Saving user to Firestore: ${user.uid}');
      debugPrint('User email: ${user.email}');
      debugPrint('Display name: $displayName');
      debugPrint('Auth provider: $authProvider');
      
      // 紹介コードを生成
      final referralCode = _generateReferralCode(user.uid);
      final storeReferralCode = _generateStoreReferralCode(user.uid);
      
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'emailVerified': user.emailVerified,
        'authProvider': authProvider ?? 'email', // 認証プロバイダー情報
        'isOwner': false, // デフォルトで一般ユーザー
        'points': 0, // 初期ポイント
        'totalPoints': 0, // 総ポイント（ランキング用）
        'pointReturnRate': 1.0, // ポイント還元率（初期値 1.0%）
        'paid': 0, // 初期支払額
        'rank': 'ブロンズ', // 初期ランク
        'currentLevel': 1, // 現在のレベル
        'badgeCount': 0, // 獲得バッジ数
        'earnedBadges': <String>[], // 獲得したバッジIDのリスト
        'referralCode': referralCode, // 友達紹介コード
        'referralCount': 0, // 招待した友達数
        'referralEarnings': 0, // 友達紹介で獲得したポイント数
        'storeReferralCode': storeReferralCode, // 店舗紹介コード
        'storeReferralCount': 0, // 紹介した店舗数
        'storeReferralEarnings': 0, // 店舗紹介で獲得したポイント数
        'favoriteStoreIds': <String>[], // お気に入り店舗IDリスト
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(), // ランキング更新用
        'isActive': true,
        'showTutorial': true, // 初回ログイン時にチュートリアルを表示
        'readNotifications': <String>[], // 既読通知IDリスト
      };

      // 追加のユーザー情報がある場合はマージ
      if (additionalInfo != null) {
        debugPrint('Additional user info: $additionalInfo');
        userData.addAll(additionalInfo);
      }

      debugPrint('User data to save: $userData');
      
      await _firestore.collection('users').doc(user.uid).set(userData);
      debugPrint('User data saved to Firestore successfully');
      
      // 保存確認のため、すぐに読み取りを試行
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        debugPrint('User document confirmed in Firestore: ${doc.data()}');
      } else {
        debugPrint('WARNING: User document not found after saving');
      }
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception details: ${e.toString()}');
      }
      // Firestore保存エラーは認証成功を妨げないようにする
      // 必要に応じて後で再試行できるようにログに記録
    }
  }

  // ユーザー情報を更新
  Future<void> updateUserInfo(Map<String, dynamic> userData) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        userData['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).update(userData);
        debugPrint('User info updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating user info: $e');
      throw _handleAuthError(e, 'ユーザー情報更新');
    }
  }

  Future<void> updateAuthProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();
    } catch (e) {
      debugPrint('Error updating auth profile: $e');
      throw _handleAuthError(e, 'プロフィール更新');
    }
  }

  // ユーザー情報を取得
  Future<DocumentSnapshot?> getUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await _firestore.collection('users').doc(user.uid).get();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }

  // 既存ユーザーデータのクリーンアップ（goldStampsとfriendcodeを削除）
  Future<void> cleanupUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        
        // 削除するフィールドを指定
        final fieldsToDelete = {
          'goldStamps': FieldValue.delete(),
          'friendcode': FieldValue.delete(),
        };
        
        await userDoc.update(fieldsToDelete);
        debugPrint('User data cleaned up successfully');
      }
    } catch (e) {
      debugPrint('Error cleaning up user data: $e');
      // クリーンアップエラーは認証を妨げない
    }
  }

  // リトライ機能付きの操作実行
  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempts++;

        // リトライしないエラーの場合は即座に例外を投げる
        if (_shouldNotRetry(e)) {
          rethrow;
        }

        // 最後の試行でない場合は待機
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay * attempts);
        }
      }
    }

    throw lastException ?? Exception('操作が失敗しました');
  }

  // リトライしないエラーかどうかを判定
  bool _shouldNotRetry(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
        case 'user-disabled':
        case 'user-not-found':
        case 'wrong-password':
        case 'email-already-in-use':
        case 'weak-password':
        case 'invalid-credential':
        case 'account-exists-with-different-credential':
        case 'invalid-verification-code':
        case 'invalid-verification-id':
        case 'missing-verification-code':
        case 'missing-verification-id':
          return true;
        default:
          return false;
      }
    }
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'invalid-argument':
        case 'not-found':
        case 'failed-precondition':
        case 'resource-exhausted':
        case 'unauthenticated':
          return true;
        default:
          return false;
      }
    }
    return false;
  }

  // 友達紹介コードを生成
  String _generateReferralCode(String userId) {
    // ユーザーIDの最初の8文字を大文字に変換して友達紹介コードとして使用
    return userId.substring(0, 8).toUpperCase();
  }

  // 店舗紹介コードを生成
  String _generateStoreReferralCode(String userId) {
    // ユーザーIDの最後の8文字を大文字に変換して店舗紹介コードとして使用
    return userId.substring(userId.length - 8).toUpperCase();
  }

  // 認証エラーのハンドリング
  Exception _handleAuthError(dynamic error, String operation) {
    if (error is FirebaseAuthException) {
      return AuthException(
        message: _getJapaneseErrorMessage(error.code),
        code: error.code,
        operation: operation,
      );
    } else if (error is FirebaseFunctionsException) {
      return AuthException(
        message: _getFunctionsErrorMessage(error.code, error.message),
        code: error.code,
        operation: operation,
      );
    } else if (error is SocketException) {
      return AuthException(
        message: 'ネットワーク接続を確認してください',
        code: 'network_error',
        operation: operation,
      );
    } else if (error is HttpException) {
      return AuthException(
        message: 'サーバーとの通信に失敗しました',
        code: 'http_error',
        operation: operation,
      );
    } else if (error is TimeoutException) {
      return AuthException(
        message: 'タイムアウトが発生しました。しばらくしてから再試行してください',
        code: 'timeout_error',
        operation: operation,
      );
    } else {
      return AuthException(
        message: '$operation中にエラーが発生しました: ${error.toString()}',
        code: 'unknown_error',
        operation: operation,
      );
    }
  }

  // Firebase Auth エラーコードを日本語メッセージに変換
  String _getJapaneseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'user-not-found':
        return 'このメールアドレスは登録されていません';
      case 'wrong-password':
        return 'パスワードが正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードが弱すぎます。6文字以上で設定してください';
      case 'invalid-credential':
        return '認証情報が無効です';
      case 'account-exists-with-different-credential':
        return 'このメールアドレスは別の認証方法で既に登録されています';
      case 'invalid-verification-code':
        return '認証コードが無効です';
      case 'invalid-verification-id':
        return '認証IDが無効です';
      case 'missing-verification-code':
        return '認証コードが入力されていません';
      case 'missing-verification-id':
        return '認証IDが見つかりません';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらくしてから再試行してください';
      case 'operation-not-allowed':
        return 'この操作は許可されていません';
      case 'requires-recent-login':
        return 'セキュリティのため、再度ログインしてください';
      default:
        return '認証エラーが発生しました: $errorCode';
    }
  }

  String _getFunctionsErrorMessage(String errorCode, String? message) {
    if (message != null && message.isNotEmpty) {
      return message;
    }

    switch (errorCode) {
      case 'invalid-argument':
        return '入力内容に誤りがあります';
      case 'not-found':
        return '認証コードが見つかりません';
      case 'failed-precondition':
        return '認証コードの有効期限が切れています';
      case 'resource-exhausted':
        return 'リクエストが多すぎます。しばらくしてから再試行してください';
      case 'unauthenticated':
        return 'ログインが必要です';
      default:
        return '処理中にエラーが発生しました: $errorCode';
    }
  }
}

// カスタム認証例外クラス
class AuthException implements Exception {
  final String message;
  final String code;
  final String operation;

  AuthException({
    required this.message,
    required this.code,
    required this.operation,
  });

  @override
  String toString() => 'AuthException: $message (Code: $code, Operation: $operation)';
}
