import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../main_navigation_view.dart';
import 'badge_awarded_view.dart';

class StampPunchView extends StatefulWidget {
  final String storeId;

  const StampPunchView({Key? key, required this.storeId}) : super(key: key);

  @override
  State<StampPunchView> createState() => _StampPunchViewState();
}

class _StampPunchViewState extends State<StampPunchView>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  // Store data
  String _storeName = '店舗名';
  String _storeCategory = 'その他';
  String? _iconImageUrl;

  // User stamp data
  int _stamps = 0;
  static const int _maxStamps = 10;

  // Animation
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  int? _punchIndex; // 追加されたスタンプのインデックス

  // Shine effect for “スタンプコンプリート”
  late final AnimationController _shineController;
  late final Animation<double> _shineAnim;

  // Newly awarded badges in this session
  final List<Map<String, dynamic>> _newlyAwardedBadges = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.2, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_animController);

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shineController, curve: Curves.linear));
    _initialize();
  }

  @override
  void dispose() {
    _animController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'ログインが必要です';
          _loading = false;
        });
        return;
      }

      // 店舗情報取得
      final storeSnap = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();
      if (storeSnap.exists) {
        final s = storeSnap.data() as Map<String, dynamic>;
        _storeName = (s['name'] as String?) ?? _storeName;
        _storeCategory = (s['category'] as String?) ?? _storeCategory;
        _iconImageUrl = s['iconImageUrl'] as String?;
      }

      // ユーザーのスタンプ情報取得（users/{uid}/stores/{storeId}）
      final userStoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId);
      final userStoreSnap = await userStoreRef.get();
      if (userStoreSnap.exists) {
        final d = userStoreSnap.data() as Map<String, dynamic>;
        _stamps = (d['stamps'] as int?) ?? 0;
      } else {
        // 初期作成
        await userStoreRef.set({
          'stamps': 0,
          'lastVisited': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _stamps = 0;
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      // 自動で1つ押印
      await _punchOneStamp();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _punchOneStamp() async {
    if (_stamps >= _maxStamps) return; // 既に満了
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userStoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId);

      // Firestoreを先に更新
      await userStoreRef.update({
        'stamps': FieldValue.increment(1),
        'lastVisited': FieldValue.serverTimestamp(),
      });

      final newIndex = _stamps; // 新規に増える場所
      setState(() {
        _stamps = _stamps + 1;
        _punchIndex = newIndex;
      });

      // アニメーション
      await _animController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _punchIndex = null;
        });
      }

      // 事前チェックでボタン文言を更新（保存はしない）
      await _checkAndAwardBadges(save: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('スタンプ押印に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('スタンプ押印'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_submitting) return;
                    setState(() => _submitting = true);
                    try {
                      // 次へ押下時に判定を実行（保存も行う）
                      final awarded = await _checkAndAwardBadges(save: true);
                      if (!mounted) return;
                      if (awarded.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BadgeAwardedView(
                              badges: List<Map<String, dynamic>>.from(awarded),
                            ),
                          ),
                        );
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainNavigationView()),
                          (route) => false,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('確認'),
                          ],
                        )
                      : const Text('確認'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text('エラー: $_error'),
      );
    }

    final progress = _stamps / _maxStamps;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(_storeCategory).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(_storeCategory).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getCategoryColor(_storeCategory).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: _buildStoreIcon(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _storeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(_storeCategory).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _storeCategory,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getCategoryColor(_storeCategory),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_stamps/$_maxStamps',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(_storeCategory),
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _maxStamps,
                        itemBuilder: (context, index) {
                          final hasStamp = index < _stamps;
                          final isPunched = _punchIndex != null && index == _punchIndex;
                          final base = Container(
                            decoration: BoxDecoration(
                              color: hasStamp
                                  ? _getCategoryColor(_storeCategory)
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: hasStamp
                                    ? _getCategoryColor(_storeCategory).withOpacity(0.7)
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: hasStamp
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
                            ),
                          );

                          if (isPunched) {
                            return ScaleTransition(scale: _scaleAnim, child: base);
                          }
                          return base;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_stamps >= _maxStamps)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shineAnim,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Color(0xFF9C27B0),
                              Color(0xFFFFD54F),
                              Color(0xFF9C27B0),
                            ],
                            stops: [
                              (_shineAnim.value - 0.2).clamp(0.0, 1.0),
                              (_shineAnim.value).clamp(0.0, 1.0),
                              (_shineAnim.value + 0.2).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: const Text(
                          'スタンプコンプリート',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreIcon() {
    if (_iconImageUrl != null && _iconImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _iconImageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getCategoryIcon(_storeCategory),
              color: _getCategoryColor(_storeCategory),
              size: 25,
            );
          },
        ),
      );
    }
    return Icon(
      _getCategoryIcon(_storeCategory),
      color: _getCategoryColor(_storeCategory),
      size: 25,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'レストラン':
        return Colors.red;
      case 'カフェ':
        return Colors.brown;
      case 'ショップ':
        return Colors.blue;
      case '美容院':
        return Colors.pink;
      case '薬局':
        return Colors.green;
      case 'コンビニ':
        return Colors.orange;
      case 'スーパー':
        return Colors.lightGreen;
      case '書店':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'レストラン':
        return Icons.restaurant;
      case 'カフェ':
        return Icons.local_cafe;
      case 'ショップ':
        return Icons.shopping_bag;
      case '美容院':
        return Icons.content_cut;
      case '薬局':
        return Icons.local_pharmacy;
      case 'コンビニ':
        return Icons.store;
      case 'スーパー':
        return Icons.shopping_cart;
      case '書店':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }

  // バッジ達成チェックと付与（JSON条件ベース）
  Future<List<Map<String, dynamic>>> _checkAndAwardBadges({bool save = true}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const <Map<String, dynamic>>[];

      final firestore = FirebaseFirestore.instance;
      // 全バッジ取得
      final badgesSnap = await firestore.collection('badges').get();

      // 事前にユーザーデータを集計
      final int badgeCount = await _getUserBadgeCount(user.uid);
      final int userLevel = await _getUserLevel(user.uid);
      final int totalPoints = await _getUserTotalPoints(user.uid);

      // 期間別のデータを作るヘルパー
      Future<int> countTransactions({
        required DateTime since,
        bool onlyPositive = true,
        String? dayOfWeek,
        String? storeId,
      }) async {
        int count = 0;
        final Iterable<String> targetStoreIds = storeId != null
            ? [storeId]
            : (await firestore.collection('stores').get()).docs.map((d) => d.id);
        for (final sid in targetStoreIds) {
          final snap = await firestore
              .collection('point_transactions')
              .doc(sid)
              .collection(user.uid)
              .get();
          for (final d in snap.docs) {
            final data = d.data() as Map<String, dynamic>;
            final amount = (data['amount'] is num) ? (data['amount'] as num).toInt() : 0;
            final raw = data['createdAt'];
            DateTime? ts;
            if (raw is Timestamp) {
              ts = raw.toDate();
            } else if (raw is String) {
              try { ts = DateTime.parse(raw); } catch (_) {}
            } else if (raw is int) {
              // milliseconds since epoch
              ts = DateTime.fromMillisecondsSinceEpoch(raw);
            }
            ts ??= DateTime.now();
            final inPeriod = !ts.isBefore(since);
            final weekdayOk = dayOfWeek == null ? true : _weekdayToStr(ts.weekday) == dayOfWeek;
            final positiveOk = onlyPositive ? amount > 0 : true;
            if (inPeriod && weekdayOk && positiveOk) count++;
          }
        }
        // ignore: avoid_print
        print('[BadgeCheck] countTransactions since=${since.toIso8601String()} storeId=${storeId ?? 'ALL'} onlyPositive=$onlyPositive dayOfWeek=${dayOfWeek ?? '-'} => $count');
        return count;
      }

      Future<int> sumAmounts({required DateTime since}) async {
        int sum = 0;
        final stores = await firestore.collection('stores').get();
        for (final s in stores.docs) {
          final snap = await firestore
              .collection('point_transactions')
              .doc(s.id)
              .collection(user.uid)
              .get();
          for (final d in snap.docs) {
            final data = d.data() as Map<String, dynamic>;
            final raw = data['createdAt'];
            DateTime? ts;
            if (raw is Timestamp) {
              ts = raw.toDate();
            } else if (raw is String) {
              try { ts = DateTime.parse(raw); } catch (_) {}
            } else if (raw is int) {
              ts = DateTime.fromMillisecondsSinceEpoch(raw);
            }
            ts ??= DateTime.now();
            if (!ts.isBefore(since)) {
              final amount = (data['amount'] is num) ? (data['amount'] as num).toInt() : 0;
              if (amount > 0) sum += amount;
            }
          }
        }
        return sum;
      }

      final List<Map<String, dynamic>> newlyAwarded = [];

      for (final doc in badgesSnap.docs) {
        final data = doc.data();

        // 作成側の仕様に合わせて isActive=false のバッジはスキップ
        final bool isActive = (data['isActive'] as bool?) ?? true;
        if (!isActive) {
          // ignore: avoid_print
          print('[BadgeCheck] skip inactive badge name=${data['name']}');
          continue;
        }

        // 条件JSONを取得（作成側の保存フィールドに合わせて冗長に対応）
        // 優先: condition > conditionData > jsonLogicCondition
        final rawCond = data['condition'] ?? data['conditionData'] ?? data['jsonLogicCondition'];
        if (rawCond == null) continue;

        Map<String, dynamic>? condMap;
        if (rawCond is String) {
          try {
            final parsed = jsonDecode(rawCond);
            if (parsed is Map<String, dynamic>) {
              condMap = parsed;
            }
          } catch (_) {}
        } else if (rawCond is Map<String, dynamic>) {
          condMap = Map<String, dynamic>.from(rawCond);
        }
        if (condMap == null) continue;

        bool isSatisfied = false;
        {
          final mode = (condMap['mode'] ?? 'typed').toString();
          if (mode == 'typed') {
            final rule = (condMap['rule'] ?? {}) as Map<String, dynamic>;
            final type = (rule['type'] ?? '').toString();
            final params = Map<String, dynamic>.from(rule['params'] ?? {});

            switch (type) {
              case 'first_checkin': {
                final c = await countTransactions(since: DateTime.fromMillisecondsSinceEpoch(0));
                isSatisfied = c >= 1;
                // ignore: avoid_print
                print('[BadgeCheck] first_checkin count=$c satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'points_total': {
                final threshold = _asInt(params['threshold']);
                isSatisfied = totalPoints >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] points_total total=$totalPoints threshold=$threshold satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'points_in_period': {
                final threshold = _asInt(params['threshold']);
                final period = (params['period'] ?? 'month').toString();
                final since = _startFromPeriod(period);
                final sum = await sumAmounts(since: since);
                isSatisfied = sum >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] points_in_period sum=$sum threshold=$threshold period=$period since=${since.toIso8601String()} satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'checkins_count': {
                final threshold = _asInt(params['threshold']);
                final period = (params['period'] ?? 'month').toString();
                final since = _startFromPeriod(period);
                final c = await countTransactions(since: since);
                isSatisfied = c >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] checkins_count count=$c threshold=$threshold period=$period since=${since.toIso8601String()} satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'user_level': {
                final threshold = _asInt(params['threshold']);
                isSatisfied = userLevel >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] user_level level=$userLevel threshold=$threshold satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'badge_count': {
                final threshold = _asInt(params['threshold']);
                isSatisfied = badgeCount >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] badge_count count=$badgeCount threshold=$threshold satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'payment_amount': {
                final threshold = _asInt(params['threshold']);
                final period = (params['period'] ?? 'month').toString();
                final since = _startFromPeriod(period);
                final total = await sumAmounts(since: since);
                isSatisfied = total >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] payment_amount total=$total threshold=$threshold period=$period since=${since.toIso8601String()} satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'day_of_week_count': {
                final threshold = _asInt(params['threshold']);
                final period = (params['period'] ?? 'week').toString();
                final dow = (params['day_of_week'] ?? 'monday').toString();
                final since = _startFromPeriod(period);
                final c = await countTransactions(since: since, dayOfWeek: dow);
                isSatisfied = c >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] day_of_week_count count=$c threshold=$threshold period=$period dow=$dow since=${since.toIso8601String()} satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'usage_count': {
                final threshold = _asInt(params['threshold']);
                final period = (params['period'] ?? 'month').toString();
                final since = period == 'unlimited' ? DateTime.fromMillisecondsSinceEpoch(0) : _startFromPeriod(period);
                final c = await countTransactions(since: since);
                isSatisfied = c >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] usage_count count=$c threshold=$threshold period=$period since=${since.toIso8601String()} satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              case 'visit_frequency': {
                final threshold = _asInt(params['threshold']);
                final period = (params['period'] ?? 'day').toString();
                final since = period == 'unlimited' ? DateTime.fromMillisecondsSinceEpoch(0) : _startFromPeriod(period);
                // 同一店舗での利用回数を期間内でカウント（増減問わず）
                final c = await countTransactions(
                  since: since,
                  storeId: widget.storeId,
                  onlyPositive: false,
                );
                isSatisfied = c >= threshold;
                // ignore: avoid_print
                print('[BadgeCheck] visit_frequency count=$c threshold=$threshold period=$period since=${since.toIso8601String()} storeId=${widget.storeId} satisfied=$isSatisfied name=${data['name']}');
                break;
              }
              default:
                isSatisfied = false;
            }
          } else {
            // jsonlogic モードは簡易未対応: 将来的な拡張ポイント
            isSatisfied = false;
          }
        }

        if (!isSatisfied) continue;

        final String badgeId = doc.id;
        // 既に獲得済みか確認
        final userBadgeRef = firestore
            .collection('user_badges')
            .doc(user.uid)
            .collection('badges')
            .doc(badgeId);
        final userBadgeSnap = await userBadgeRef.get();
        final bool alreadyOwned = userBadgeSnap.exists;

        // 未獲得なら保存（save=true のときのみ）
        if (!alreadyOwned && save) {
          await userBadgeRef.set({
            'userId': user.uid,
            'badgeId': badgeId,
            'unlockedAt': FieldValue.serverTimestamp(),
            'isNew': true,
            'name': data['name'],
            'description': data['description'],
            'category': data['category'],
            'imageUrl': data['imageUrl'],
            'iconUrl': data['iconUrl'],
            'iconPath': data['iconPath'],
            'rarity': data['rarity'],
            'order': data['order'] ?? 0,
          });
        }

        newlyAwarded.add({
          'id': badgeId,
          'name': data['name'],
          'description': data['description'],
          'category': data['category'],
          'imageUrl': data['imageUrl'],
          'iconUrl': data['iconUrl'],
          'iconPath': data['iconPath'],
          'rarity': data['rarity'],
          'order': data['order'] ?? 0,
          'alreadyOwned': alreadyOwned,
        });
        // ignore: avoid_print
        print('[BadgeCheck] queued badge id=$badgeId name=${data['name']} alreadyOwned=$alreadyOwned');
      }

      // 表示順でソート（order昇順）
      newlyAwarded.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      if (mounted) {
        setState(() {
          _newlyAwardedBadges
            ..clear()
            ..addAll(newlyAwarded);
        });
      }
      // ignore: avoid_print
      print('[BadgeCheck] newlyAwarded total=${newlyAwarded.length}');
      return newlyAwarded;
    } catch (e) {
      // エラーはユーザー表示せずログに留める
      // ignore: avoid_print
      print('Badge check failed: $e');
      return const [];
    }
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  DateTime _startFromPeriod(String period) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (period) {
      case 'day':
        return todayStart;
      case 'week':
        final int diff = (todayStart.weekday - DateTime.monday) % 7;
        return todayStart.subtract(Duration(days: diff));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  String _weekdayToStr(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  Future<int> _getUserBadgeCount(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('user_badges')
        .doc(userId)
        .collection('badges')
        .get();
    return snap.size;
  }

  Future<int> _getUserLevel(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_levels')
          .doc(userId)
          .get();
      if (!doc.exists) return 1;
      final data = doc.data()!;
      final lvl = data['currentLevel'];
      return _asInt(lvl);
    } catch (_) {
      return 1;
    }
  }

  Future<int> _getUserTotalPoints(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_point_balances')
          .doc(userId)
          .get();
      if (!doc.exists) return 0;
      final data = doc.data()!;
      return _asInt(data['totalPoints']);
    } catch (_) {
      return 0;
    }
  }
}


