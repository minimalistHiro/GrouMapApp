import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'badge_awarded_view.dart';
import '../../providers/level_provider.dart';

class ExperienceGainedView extends StatefulWidget {
  final int gainedExperience;
  final int? newLevel; // 利用しないが互換のため保持
  final List<Map<String, dynamic>>? badges; // 渡された場合は確認で直接遷移
  final List<Map<String, dynamic>>? breakdown; // [{label: String, xp: int}]
  final int? paid; // 支払い額（計算のみで表示）

  const ExperienceGainedView({
    Key? key,
    required this.gainedExperience,
    this.newLevel,
    this.badges,
    this.breakdown,
    this.paid,
  }) : super(key: key);

  @override
  State<ExperienceGainedView> createState() => _ExperienceGainedViewState();
}

class _ExperienceGainedViewState extends State<ExperienceGainedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Map<String, dynamic>? _userData; // usersドキュメント
  int _startExp = 0;
  int _endExp = 0;
  bool _isLevelUp = false;
  int _startLevel = 1;
  int _endLevel = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _loadUserAndAnimate();
  }

  Future<void> _loadUserAndAnimate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      // 支払い額のXPもここで実際に付与する（users のみ: experience/level を更新）
      final int paidAmount = widget.paid ?? 0;
      final int paidXp = paidAmount > 0 ? LevelService().experienceForPayment(paidAmount) : 0;
      if (paidXp > 0) {
        final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        // no-op flag removed; we proceed regardless
        // 1) トランザクションで加算 + レベル更新
        try {
          await FirebaseFirestore.instance.runTransaction((tx) async {
            final snap = await tx.get(usersRef);
            int currentExp = 0;
            if (snap.exists) {
              final d = snap.data() as Map<String, dynamic>;
              currentExp = (d['experience'] is num) ? (d['experience'] as num).toInt() : 0;
            }
            final newExp = (currentExp + paidXp).clamp(0, 1 << 31);
            final newLevel = (newExp ~/ 100) + 1;
            tx.set(usersRef, {
              'experience': newExp,
              'level': newLevel,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
          // ok
        } catch (e) {
          // 2) フォールバック: experience をインクリメント → 取得して level を同期
          try {
            await usersRef.set({
              'experience': FieldValue.increment(paidXp),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            final snap2 = await usersRef.get();
            if (snap2.exists) {
              final d2 = snap2.data() as Map<String, dynamic>;
              final exp2 = (d2['experience'] is num) ? (d2['experience'] as num).toInt() : 0;
              final lvl2 = (exp2 ~/ 100) + 1;
              await usersRef.set({'level': lvl2}, SetOptions(merge: true));
              // ok
            }
          } catch (e2) {
            // 失敗は最後に無視（表示は続行）
          }
        }
      }
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final currentExp = (data['experience'] is num) ? (data['experience'] as num).toInt() : 0;
        // アニメーションでは押印等の獲得分 + 支払い分（この画面で付与）を合算して可視化
        final appliedPaidXp = (paidXp > 0) ? paidXp : 0;
        int startExp = math.max(0, currentExp - (widget.gainedExperience + appliedPaidXp));
        int endExp = currentExp;

        // フォールバック: 読み込みタイミングにより差分が0以下なら、ローカルで差分を可視化
        if (endExp <= startExp && widget.gainedExperience > 0) {
          startExp = math.max(0, endExp - widget.gainedExperience);
        }

        setState(() {
          _userData = data;
          _startExp = startExp;
          _endExp = endExp;
          _isLevelUp = (_startExp ~/ 100) < (_endExp ~/ 100);
          _startLevel = (_startExp ~/ 100) + 1;
          _endLevel = (_endExp ~/ 100) + 1;
        });
        _controller
          ..reset()
          ..forward();
      } else {
        // users ドキュメント未作成でもアニメが動くようにフォールバック
        if (!mounted) return;
        final appliedPaidXp = (paidXp > 0) ? paidXp : 0;
        setState(() {
          _userData = {};
          _startExp = 0;
          _endExp = widget.gainedExperience + appliedPaidXp;
          _isLevelUp = (_startExp ~/ 100) < (_endExp ~/ 100);
          _startLevel = (_startExp ~/ 100) + 1;
          _endLevel = (_endExp ~/ 100) + 1;
        });
        _controller
          ..reset()
          ..forward();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 現在のアニメーション進捗から擬似的なexp/level/progressを算出
  Map<String, dynamic> _animatedExpState(double t) {
    final expNow = (_startExp + ((_endExp - _startExp) * t)).clamp(0, 1 << 31).toDouble();
    final levelNow = (expNow ~/ 100) + 1;
    final levelBase = (levelNow - 1) * 100;
    final progress = ((expNow - levelBase) / 100.0).clamp(0.0, 1.0);
    return {
      'level': levelNow,
      'progress': progress,
    };
  }

  // キラキラ演出は廃止

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = (_userData?['profileImageUrl'] as String?);
    final breakdown = widget.breakdown ?? const [];
    final int paidAmount = widget.paid ?? 0;
    final int paidXp = paidAmount > 0 ? LevelService().experienceForPayment(paidAmount) : 0;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ヘッダー風：ユーザーアイコン + 円形経験値バー（アニメーション）
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final t = _controller.value;
                          double scale = 1.0;
                          if (_isLevelUp) {
                            if (t < 0.4) {
                              scale = 1.0 + 0.25 * (t / 0.4);
                            } else if (t < 0.8) {
                              scale = 1.25 - 0.15 * ((t - 0.4) / 0.4);
                            } else {
                              scale = 1.10 - 0.10 * ((t - 0.8) / 0.2);
                            }
                          }
                          final s = _animatedExpState(t);
                          final levelNow = s['level'] as int;
                          final progress = s['progress'] as double;
                          return Transform.scale(
                            scale: scale,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 104,
                                  height: 104,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                                  ),
                                ),
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                                  ),
                                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            profileImageUrl,
                                            width: 84,
                                            height: 84,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                        ),
                                ),
                                Positioned(
                                  bottom: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Lv.$levelNow',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                // キラキラ演出は非表示
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // アイコン直下に内訳
                    if (breakdown.isNotEmpty || paidXp > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '獲得詳細',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(breakdown.length, (index) {
                              final item = breakdown[index];
                              final label = (item['label'] ?? '').toString();
                              final xp = (item['xp'] is num) ? (item['xp'] as num).toInt() : 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '+$xp',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (paidXp > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '支払い',
                                      style: TextStyle(fontSize: 13, color: Colors.black54),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '+$paidXp',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // レベルアップ時の評価テキスト（LvX→LvY）
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        if (!_isLevelUp || _startLevel == _endLevel) return const SizedBox.shrink();
                        final t = _controller.value;
                        double opacity = 0.0;
                        if (t > 0.35 && t < 0.85) {
                          final r = ((t - 0.35) / 0.50).clamp(0.0, 1.0);
                          opacity = (r < 0.5) ? (r * 2) : (1.0 - (r - 0.5) * 2);
                        }
                        return Opacity(
                          opacity: opacity,
                          child: Text(
                            'Lv$_startLevel → Lv$_endLevel',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '経験値を獲得！',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Builder(builder: (context) {
                      final paidAmount = widget.paid ?? 0;
                      final paidXp = paidAmount > 0 ? LevelService().experienceForPayment(paidAmount) : 0;
                      final totalShown = widget.gainedExperience + (paidXp > 0 ? paidXp : 0);
                      return Text(
                        '+$totalShown XP',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF6B35),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final list = widget.badges;
                    if (list != null && list.isNotEmpty) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => BadgeAwardedView(badges: list),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('確認'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


