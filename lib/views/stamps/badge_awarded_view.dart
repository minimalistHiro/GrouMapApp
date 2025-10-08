import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_navigation_view.dart';

class BadgeAwardedView extends StatefulWidget {
  final List<Map<String, dynamic>> badges;

  const BadgeAwardedView({Key? key, required this.badges}) : super(key: key);

  @override
  State<BadgeAwardedView> createState() => _BadgeAwardedViewState();
}

class _BadgeAwardedViewState extends State<BadgeAwardedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late final Animation<double> _curve;
  late final Animation<double> _angle;
  int _index = 0;
  final List<Map<String, dynamic>> _displayBadges = <Map<String, dynamic>>[];
  bool _loadingOwned = true;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _curve = CurvedAnimation(parent: _spinController, curve: Curves.decelerate);
    _angle = Tween<double>(begin: 0.0, end: 6 * math.pi).animate(_curve);
    _spinController.forward();

    _loadOwnedAndFilter();
  }

  Future<void> _loadOwnedAndFilter() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // 未ログインならそのまま全て表示
        setState(() {
          _displayBadges
            ..clear()
            ..addAll(widget.badges);
          _loadingOwned = false;
        });
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('user_badges')
          .doc(user.uid)
          .collection('badges')
          .get();
      final ownedIds = snap.docs.map((d) => d.id).toSet();

      // badgeId または id を優先的に比較
      final filtered = widget.badges.where((b) {
        final dynamic rawId = b['badgeId'] ?? b['id'];
        final badgeId = rawId == null ? '' : rawId.toString();
        if (badgeId.isEmpty) return true; // id 不明なら除外しない
        return !ownedIds.contains(badgeId);
      }).toList(growable: false);

      setState(() {
        _displayBadges
          ..clear()
          ..addAll(filtered);
        _loadingOwned = false;
      });
    } catch (_) {
      // 失敗時はとりあえず全件表示（ログは省略）
      setState(() {
        _displayBadges
          ..clear()
          ..addAll(widget.badges);
        _loadingOwned = false;
      });
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _displayBadges.length - 1) {
      setState(() => _index++);
      _spinController
        ..reset()
        ..forward();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationView(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  Widget _buildBadgeImage(Map<String, dynamic> badge) {
    final image = (badge['imageUrl'] ?? badge['iconUrl'] ?? badge['iconPath'] ?? '').toString();
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 288,
        height: 288,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
      );
    }
    if (image.isNotEmpty) {
      return Image.asset(
        'assets/images/badges/$image',
        width: 288,
        height: 288,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
      );
    }
    return const Icon(Icons.emoji_events, size: 288, color: Colors.amber);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingOwned) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_displayBadges.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      '新規で獲得したバッジはありません',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('確認'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isLast = _index == _displayBadges.length - 1;
    final badge = _displayBadges[_index];
    final double cardWidth = MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Scrollable content to avoid bottom overflows
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                        const SizedBox(height: 12),
                        const Text(
                          'バッジを獲得しました！',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: cardWidth,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _angle,
                                    child: _buildBadgeImage(badge),
                                    builder: (context, child) {
                                      return Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateY(_angle.value),
                                        child: child,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    (badge['name'] ?? '').toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    (badge['description'] ?? '').toString(),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bottom pinned button stays visible
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(isLast ? '確認' : '次へ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


