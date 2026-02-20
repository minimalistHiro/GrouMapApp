import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../providers/badge_provider.dart';

class LotteryView extends StatefulWidget {
  const LotteryView({super.key});

  @override
  State<LotteryView> createState() => _LotteryViewState();
}

class _LotteryViewState extends State<LotteryView> with TickerProviderStateMixin {
  // Firebase関連
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // スロット関連
  late AnimationController _slot1Controller;
  late AnimationController _slot2Controller;
  late AnimationController _slot3Controller;
  late Animation<double> _slot1Animation;
  late Animation<double> _slot2Animation;
  late Animation<double> _slot3Animation;
  bool _isSpinning = false;
  bool _canSpin = true;

  // 当選アニメーション関連
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late ConfettiController _confettiController;
  final bool _showWinAnimation = false;

  // 1等専用のアニメーション関連
  late AnimationController _goldenAnimationController;
  late AnimationController _backgroundDimController;
  late Animation<double> _goldenGlowAnimation;
  late Animation<double> _backgroundDimAnimation;
  late ConfettiController _goldenConfettiController;
  bool _showGoldenAnimation = false;

  // 1等専用のポップアップ関連
  bool _showCongratulationsPopup = false;
  bool _shouldLoopConfetti = false;

  // 2等専用のアニメーション関連
  late AnimationController _silverAnimationController;
  late AnimationController _silverBackgroundDimController;
  late Animation<double> _silverGlowAnimation;
  late Animation<double> _silverBackgroundDimAnimation;
  late ConfettiController _silverConfettiController;
  bool _showSilverAnimation = false;

  // 2等専用のポップアップ関連
  bool _showSilverCongratulationsPopup = false;
  bool _shouldLoopSilverConfetti = false;

  // ハズレ専用のポップアップ関連
  bool _showLosePopup = false;

  // 結果表示
  int _result1 = 0;
  int _result2 = 0;
  int _result3 = 0;
  int _finalNumber = 0;
  int _prizeResult = 0; // 0: 未実行, 1: 1等, 2: 2等, 3: ハズレ
  bool _showResult = false;

  // 事前決定済みの出目
  int _predeterminedResult1 = 0;
  int _predeterminedResult2 = 0;
  int _predeterminedResult3 = 0;

  // アニメーション状態
  bool _slot1Stopped = false;
  bool _slot2Stopped = false;
  bool _slot3Stopped = false;

  // 手動停止用の状態
  bool _showStopButtons = false;

  // コイン関連
  int _userCoins = 0;

  @override
  void initState() {
    super.initState();
    _slot1Controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slot2Controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slot3Controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _slot1Animation = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(CurvedAnimation(
      parent: _slot1Controller,
      curve: Curves.decelerate,
    ));

    _slot2Animation = Tween<double>(
      begin: 0,
      end: 25,
    ).animate(CurvedAnimation(
      parent: _slot2Controller,
      curve: Curves.decelerate,
    ));

    _slot3Animation = Tween<double>(
      begin: 0,
      end: 30,
    ).animate(CurvedAnimation(
      parent: _slot3Controller,
      curve: Curves.decelerate,
    ));

    // 当選アニメーション初期化
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1500),
    );

    // 1等専用アニメーション初期化
    _goldenAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _backgroundDimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _goldenGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _goldenAnimationController,
      curve: Curves.easeInOut,
    ));

    _backgroundDimAnimation = Tween<double>(
      begin: 0.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _backgroundDimController,
      curve: Curves.easeInOut,
    ));

    _goldenConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 2000),
    );

    // 2等専用アニメーション初期化
    _silverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _silverBackgroundDimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _silverGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _silverAnimationController,
      curve: Curves.easeInOut,
    ));

    _silverBackgroundDimAnimation = Tween<double>(
      begin: 0.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _silverBackgroundDimController,
      curve: Curves.easeInOut,
    ));

    _silverConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 2000),
    );

    _checkTodaysSpinStatus();
    _loadUserCoins();
  }

  @override
  void dispose() {
    _slot1Controller.dispose();
    _slot2Controller.dispose();
    _slot3Controller.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    _goldenAnimationController.dispose();
    _backgroundDimController.dispose();
    _goldenConfettiController.dispose();
    _silverAnimationController.dispose();
    _silverBackgroundDimController.dispose();
    _silverConfettiController.dispose();
    super.dispose();
  }

  // コイン残高を取得
  Future<void> _loadUserCoins() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _userCoins = (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('コイン残高取得エラー: $e');
    }
  }

  // 今日のスピン状況をチェック
  Future<void> _checkTodaysSpinStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('lottery_history')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateString)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _canSpin = doc.docs.isEmpty;
        });
      }
    } catch (e) {
      debugPrint('スピン状況チェックエラー: $e');
    }
  }

  // 確率ベースで当選結果を事前決定
  void _determineLotteryResult() {
    final random = Random();
    final roll = random.nextInt(100); // 0-99

    if (roll < 1) {
      // 1等: 1% (roll == 0)
      _prizeResult = 1;
      final digit = random.nextInt(10);
      _predeterminedResult1 = digit;
      _predeterminedResult2 = digit;
      _predeterminedResult3 = digit;
    } else if (roll < 6) {
      // 2等: 5% (roll == 1-5)
      _prizeResult = 2;
      final sameDigit = random.nextInt(10);
      final diffDigit = (sameDigit + 1 + random.nextInt(9)) % 10;
      final pattern = random.nextInt(3);
      switch (pattern) {
        case 0:
          _predeterminedResult1 = sameDigit;
          _predeterminedResult2 = sameDigit;
          _predeterminedResult3 = diffDigit;
          break;
        case 1:
          _predeterminedResult1 = diffDigit;
          _predeterminedResult2 = sameDigit;
          _predeterminedResult3 = sameDigit;
          break;
        case 2:
          _predeterminedResult1 = sameDigit;
          _predeterminedResult2 = diffDigit;
          _predeterminedResult3 = sameDigit;
          break;
      }
    } else {
      // ハズレ: 94% (roll == 6-99)
      _prizeResult = 3;
      _generateAllDifferentDigits(random);
    }
  }

  void _generateAllDifferentDigits(Random random) {
    _predeterminedResult1 = random.nextInt(10);
    do {
      _predeterminedResult2 = random.nextInt(10);
    } while (_predeterminedResult2 == _predeterminedResult1);
    do {
      _predeterminedResult3 = random.nextInt(10);
    } while (_predeterminedResult3 == _predeterminedResult1 ||
             _predeterminedResult3 == _predeterminedResult2);
  }

  // スロットを開始する（確認ポップアップ付き）
  Future<void> _startSlots() async {
    if (!_canSpin || _isSpinning) return;

    // コイン不足チェック
    if (_userCoins < 1) {
      _showInsufficientCoinsDialog();
      return;
    }

    // コイン消費確認ポップアップ
    final confirmed = await _showCoinConfirmDialog();
    if (confirmed != true) return;

    // 当選結果を事前決定
    _determineLotteryResult();

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _slot1Stopped = false;
      _slot2Stopped = false;
      _slot3Stopped = false;
      _showStopButtons = true;
    });

    // スロットアニメーションを無限ループで開始
    _slot1Controller.reset();
    _slot2Controller.reset();
    _slot3Controller.reset();

    _slot1Controller.repeat();
    _slot2Controller.repeat();
    _slot3Controller.repeat();
  }

  // コイン消費確認ダイアログ
  Future<bool?> _showCoinConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 28),
            const SizedBox(width: 8),
            const Text('コイン使用確認'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'スロットを回すのに1コインを使用します。',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC107), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '所持コイン: $_userCoins → ${_userCoins - 1}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'キャンセル',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('スタート'),
          ),
        ],
      ),
    );
  }

  // コイン不足ダイアログ
  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コイン不足'),
        content: const Text('スロットを回すには1コイン必要です。\nデイリーミッションや来店でコインを獲得しましょう！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 個別のスロットを停止
  void _stopSlot(int slotNumber) {
    if (!_isSpinning) return;

    setState(() {
      switch (slotNumber) {
        case 1:
          if (!_slot1Stopped) {
            _slot1Controller.stop();
            _result1 = _predeterminedResult1;
            _slot1Stopped = true;
          }
          break;
        case 2:
          if (!_slot2Stopped) {
            _slot2Controller.stop();
            _result2 = _predeterminedResult2;
            _slot2Stopped = true;
          }
          break;
        case 3:
          if (!_slot3Stopped) {
            _slot3Controller.stop();
            _result3 = _predeterminedResult3;
            _slot3Stopped = true;
          }
          break;
      }

      // 全てのスロットが停止したかチェック
      if (_slot1Stopped && _slot2Stopped && _slot3Stopped) {
        _showStopButtons = false;
        _finalizeResult();
      }
    });
  }

  // 結果を確定して表示
  Future<void> _finalizeResult() async {
    _finalNumber = _result1 * 100 + _result2 * 10 + _result3;

    // 結果を保存
    await _saveLotteryResult(_prizeResult);

    setState(() {
      _isSpinning = false;
      _showResult = true;
      _canSpin = false;
    });

    // 当選アニメーションを実行
    if (_prizeResult == 1) {
      _playGoldenAnimation();
    } else if (_prizeResult == 2) {
      _playSilverAnimation();
    } else {
      _playLoseAnimation();
    }
  }

  // スロット結果を保存
  Future<void> _saveLotteryResult(int result) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      int coinsEarned = 0;
      int couponCount = 0;
      String prize = '';
      String resultLabel = '';

      switch (result) {
        case 1:
          coinsEarned = 20;
          couponCount = 0;
          prize = 'コイン×20';
          resultLabel = '1等';
          break;
        case 2:
          coinsEarned = 10;
          couponCount = 0;
          prize = 'コイン×10';
          resultLabel = '2等';
          break;
        case 3:
          coinsEarned = 0;
          couponCount = 0;
          prize = 'コイン×0';
          resultLabel = 'ハズレ';
          break;
      }

      // 実質のコイン変動: 消費1コイン + 獲得分
      final coinsDelta = coinsEarned - 1;

      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return;

        final currentCoins = (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;

        if (currentCoins < 1) {
          throw Exception('コインが不足しています');
        }

        // コイン更新
        transaction.update(userRef, {
          'coins': currentCoins + coinsDelta,
        });

        // スロット履歴を保存
        final historyRef = _firestore.collection('lottery_history').doc();
        transaction.set(historyRef, {
          'userId': user.uid,
          'date': dateString,
          'result': resultLabel,
          'prize': prize,
          'coins': coinsEarned,
          'coinsDelta': coinsDelta,
          'couponCount': couponCount,
          'number': _finalNumber,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // ローカルのコイン残高を更新
      if (mounted) {
        setState(() {
          _userCoins = (_userCoins + coinsDelta).clamp(0, 999999);
        });
      }

      // バッジカウンター: スロットプレイ
      BadgeService().incrementBadgeCounter(user.uid, 'slotPlayed');

      // バッジカウンター: スロット当選（1等・2等）
      if (result == 1 || result == 2) {
        BadgeService().incrementBadgeCounter(user.uid, 'slotWin');
      }

      // バッジカウンター: コイン獲得
      if (coinsEarned > 0) {
        BadgeService().incrementBadgeCounter(user.uid, 'coinsEarned');
      }

      debugPrint('スロット結果保存成功: $prize');
    } catch (e) {
      debugPrint('スロット結果保存エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showCongratulationsPopup && !_showSilverCongratulationsPopup && !_showLosePopup,
      child: Scaffold(
      backgroundColor: _showGoldenAnimation
          ? Color.lerp(
              const Color(0xFFF5F5F5),
              Colors.grey[800]!,
              _backgroundDimAnimation.value,
            )
          : _showSilverAnimation
            ? Color.lerp(
                const Color(0xFFF5F5F5),
                Colors.grey[800]!,
                _silverBackgroundDimAnimation.value,
              )
            : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'スロット',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // メインコンテンツ
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              const SizedBox(height: 10),

              // タイトル画像 - トップ配置
              Container(
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/daily_slot_button.png',
                        width: 340,
                        fit: BoxFit.fitWidth,
                      ),
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Text(
                          '${DateTime.now().year}年${DateTime.now().month.toString().padLeft(2, '0')}月${DateTime.now().day.toString().padLeft(2, '0')}日まで',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.7),
                                offset: const Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 賞品テーブル
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFC107), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Column(
                  children: [
                    // 1等
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '1等',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'コイン × 20',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 2等
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC0C0C0), Color(0xFF909090)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '2等',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'コイン × 10',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // ハズレ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ハズレ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'コイン × 0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // コイン残高表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFC107), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '所持コイン: $_userCoins',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // スロットマシン
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1等時の追加の明るいリング
                      if (_showGoldenAnimation)
                        AnimatedBuilder(
                          animation: _goldenGlowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 440,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(
                                    ((sin(_goldenGlowAnimation.value * 20) + 1) / 2) * 0.8
                                  ),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(
                                      ((sin(_goldenGlowAnimation.value * 20) + 1) / 2) * 0.5
                                    ),
                                    spreadRadius: 10,
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      // 2等時の追加の明るいリング
                      if (_showSilverAnimation)
                        AnimatedBuilder(
                          animation: _silverGlowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 440,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey[400]!.withOpacity(
                                    ((sin(_silverGlowAnimation.value * 20) + 1) / 2) * 0.8
                                  ),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[400]!.withOpacity(
                                      ((sin(_silverGlowAnimation.value * 20) + 1) / 2) * 0.5
                                    ),
                                    spreadRadius: 10,
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      // メインのスロットマシン
                      Container(
                        width: 400,
                        height: 200,
                    decoration: BoxDecoration(
                      color: _showGoldenAnimation || _showSilverAnimation ? Colors.black : Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showGoldenAnimation
                          ? Color.lerp(
                              const Color(0xFFFFD700),
                              Colors.white,
                              (sin(_goldenGlowAnimation.value * 10) + 1) / 2,
                            )!
                          : _showSilverAnimation
                            ? Color.lerp(
                                const Color(0xFFC0C0C0),
                                Colors.white,
                                (sin(_silverGlowAnimation.value * 10) + 1) / 2,
                              )!
                            : _showWinAnimation
                                ? Color.lerp(
                                    const Color(0xFFFF6B35),
                                    Colors.yellow,
                                    _glowAnimation.value,
                                  )!
                                : const Color(0xFFFF6B35),
                        width: _showGoldenAnimation || _showSilverAnimation ? 6 : 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                        if (_showGoldenAnimation)
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(
                              ((sin(_goldenGlowAnimation.value * 10) + 1) / 2) * 0.9
                            ),
                            spreadRadius: _goldenGlowAnimation.value * 25,
                            blurRadius: _goldenGlowAnimation.value * 50,
                            offset: const Offset(0, 0),
                          ),
                        if (_showSilverAnimation)
                          BoxShadow(
                            color: const Color(0xFFC0C0C0).withOpacity(
                              ((sin(_silverGlowAnimation.value * 10) + 1) / 2) * 0.9
                            ),
                            spreadRadius: _silverGlowAnimation.value * 25,
                            blurRadius: _silverGlowAnimation.value * 50,
                            offset: const Offset(0, 0),
                          ),
                        if (_showWinAnimation && !_showGoldenAnimation && !_showSilverAnimation)
                          BoxShadow(
                            color: Colors.yellow.withOpacity(_glowAnimation.value * 0.8),
                            spreadRadius: _glowAnimation.value * 15,
                            blurRadius: _glowAnimation.value * 30,
                            offset: const Offset(0, 0),
                          ),
                      ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSlotReel(_slot1Animation, _result1, 1, _slot1Stopped),
                            Container(
                              width: 2,
                              height: 120,
                              color: const Color(0xFFFF6B35),
                            ),
                            _buildSlotReel(_slot2Animation, _result2, 2, _slot2Stopped),
                            Container(
                              width: 2,
                              height: 120,
                              color: const Color(0xFFFF6B35),
                            ),
                            _buildSlotReel(_slot3Animation, _result3, 3, _slot3Stopped),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // 停止ボタン
              if (_showStopButtons)
                Column(
                  children: [
                    const Text(
                      '各スロットを停止してください',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStopButton(1, _slot1Stopped),
                        _buildStopButton(2, _slot2Stopped),
                        _buildStopButton(3, _slot3Stopped),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // スピンボタン
              ElevatedButton(
                onPressed: _canSpin && !_isSpinning ? _startSlots : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSpin && !_isSpinning
                      ? const Color(0xFFFF6B35)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  _isSpinning
                      ? '各スロットを停止してください'
                      : _canSpin
                          ? 'スタート！（1コイン）'
                          : '明日また挑戦！',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 30),

              // 状態表示
              if (!_canSpin && !_showResult) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    '今日はもうスピンしました！\n明日また挑戦してください。',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
                ],
              ),
            ),
          ),

          // 紙吹雪アニメーション
          if (_showWinAnimation)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 90 * (3.14159 / 180),
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.02,
                emissionFrequency: 0.05,
                numberOfParticles: 240,
                gravity: 0.2,
                shouldLoop: false,
                maxBlastForce: 25,
                minBlastForce: 8,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                  Colors.cyan,
                  Colors.amber,
                ],
              ),
            ),

          // 1等専用: 金色の紙吹雪アニメーション
          if (_showGoldenAnimation)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _goldenConfettiController,
                blastDirection: 90 * (3.14159 / 180),
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.01,
                emissionFrequency: 0.03,
                numberOfParticles: 360,
                gravity: 0.15,
                shouldLoop: false,
                maxBlastForce: 30,
                minBlastForce: 10,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFFE55C),
                  Color(0xFFFFC72C),
                  Color(0xFFFFB347),
                  Color(0xFFDAA520),
                  Color(0xFFB8860B),
                ],
              ),
            ),

          // 2等専用: シルバーの紙吹雪アニメーション
          if (_showSilverAnimation)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _silverConfettiController,
                blastDirection: 90 * (3.14159 / 180),
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.01,
                emissionFrequency: 0.03,
                numberOfParticles: 360,
                gravity: 0.15,
                shouldLoop: false,
                maxBlastForce: 30,
                minBlastForce: 10,
                colors: const [
                  Color(0xFFC0C0C0),
                  Color(0xFFD3D3D3),
                  Color(0xFFA9A9A9),
                  Color(0xFFDCDCDC),
                  Color(0xFFB0C4DE),
                  Color(0xFF708090),
                ],
              ),
            ),

          // 1等専用: おめでとうポップアップ（モーダル）
          if (_showCongratulationsPopup) ...[
            const ModalBarrier(
              dismissible: false,
              color: Colors.transparent,
            ),
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1等当選おめでとう！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'コイン×20 獲得！',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _stopGoldenAnimation();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        '確認',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 2等専用: おめでとうポップアップ（モーダル）
          if (_showSilverCongratulationsPopup) ...[
            const ModalBarrier(
              dismissible: false,
              color: Colors.transparent,
            ),
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFC0C0C0),
                      Color(0xFF808080),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '2等当選おめでとう！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'コイン×10 獲得！',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _stopSilverAnimation();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        '確認',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ハズレ専用: ポップアップ（モーダル）
          if (_showLosePopup) ...[
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.3),
            ),
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF757575),
                      Color(0xFF424242),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '😢',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ハズレ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'コインは獲得できませんでした\nまた明日挑戦してください！',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showLosePopup = false;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        '確認',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  // スロットリールを構築（リアルなスクロールアニメーション）
  Widget _buildSlotReel(Animation<double> animation, int result, int slotNumber, bool isStopped) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        bool shouldAnimate = _isSpinning && !isStopped;

        return Container(
          width: 90,
          height: 120,
          decoration: BoxDecoration(
            color: isStopped ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isStopped ? Colors.green : const Color(0xFFFF6B35),
              width: isStopped ? 3 : 2,
            ),
            boxShadow: isStopped ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                if (shouldAnimate)
                  _buildScrollingNumbers(animation, slotNumber)
                else
                  _buildStaticNumber(result, isStopped),

                if (isStopped)
                  const Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          shouldAnimate ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          Colors.transparent,
                          shouldAnimate ? Colors.black.withOpacity(0.1) : Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // スクロールする数字列を描画
  Widget _buildScrollingNumbers(Animation<double> animation, int slotNumber) {
    double speed = 1.0;
    switch (slotNumber) {
      case 1:
        speed = 3.0;
        break;
      case 2:
        speed = 2.5;
        break;
      case 3:
        speed = 2.0;
        break;
    }

    double animationValue = animation.value * speed;
    double scrollOffset = (animationValue * 60) % 600;

    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          for (int cycle = -1; cycle <= 10; cycle++)
            for (int digit = 0; digit <= 9; digit++)
              Positioned(
                left: 0,
                right: 0,
                top: (cycle * 10 + digit) * 60.0 - scrollOffset,
                child: SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      digit.toString(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 静止した数字を表示
  Widget _buildStaticNumber(int number, bool isStopped) {
    return Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontSize: isStopped ? 52 : 48,
          fontWeight: FontWeight.bold,
          color: isStopped ? Colors.green[700] : Colors.black87,
          fontFamily: 'monospace',
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(number.toString()),
      ),
    );
  }

  // 停止ボタンを構築
  Widget _buildStopButton(int slotNumber, bool isStopped) {
    return ElevatedButton(
      onPressed: isStopped ? null : () => _stopSlot(slotNumber),
      style: ElevatedButton.styleFrom(
        backgroundColor: isStopped ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStopped ? Icons.check_circle : Icons.stop,
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            isStopped ? '停止済' : 'ストップ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 1等専用ゴールデンアニメーションを実行
  void _playGoldenAnimation() {
    setState(() {
      _showGoldenAnimation = true;
    });

    _backgroundDimController.forward();
    _goldenAnimationController.repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      _startLoopingConfetti();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showCongratulationsPopup = true;
        });
      }
    });
  }

  // 1等アニメーションを停止
  void _stopGoldenAnimation() {
    setState(() {
      _showGoldenAnimation = false;
      _showCongratulationsPopup = false;
      _shouldLoopConfetti = false;
    });
    _goldenAnimationController.stop();
    _goldenAnimationController.reset();
    _backgroundDimController.reverse();
    _goldenConfettiController.stop();
  }

  // 紙吹雪をループさせる
  void _startLoopingConfetti() {
    if (!mounted) return;

    setState(() {
      _shouldLoopConfetti = true;
    });

    _goldenConfettiController.play();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (_shouldLoopConfetti && mounted) {
        _startLoopingConfetti();
      }
    });
  }

  // 2等専用シルバーアニメーションを実行
  void _playSilverAnimation() {
    setState(() {
      _showSilverAnimation = true;
    });

    _silverBackgroundDimController.forward();
    _silverAnimationController.repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      _startLoopingSilverConfetti();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSilverCongratulationsPopup = true;
        });
      }
    });
  }

  // 2等アニメーションを停止
  void _stopSilverAnimation() {
    setState(() {
      _showSilverAnimation = false;
      _showSilverCongratulationsPopup = false;
      _shouldLoopSilverConfetti = false;
    });
    _silverAnimationController.stop();
    _silverAnimationController.reset();
    _silverBackgroundDimController.reverse();
    _silverConfettiController.stop();
  }

  // 2等用シルバー紙吹雪をループさせる
  void _startLoopingSilverConfetti() {
    if (!mounted) return;

    setState(() {
      _shouldLoopSilverConfetti = true;
    });

    _silverConfettiController.play();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (_shouldLoopSilverConfetti && mounted) {
        _startLoopingSilverConfetti();
      }
    });
  }

  // ハズレアニメーションを実行
  void _playLoseAnimation() {
    setState(() {
      _showLosePopup = true;
    });
  }
}
