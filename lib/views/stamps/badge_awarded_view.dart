import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_navigation_view.dart';
import '../../widgets/custom_button.dart';
import 'recommendation_after_badge_view.dart';

class BadgeAwardedView extends StatefulWidget {
  final List<Map<String, dynamic>> badges;
  final String? sourceStoreId;

  const BadgeAwardedView({
    Key? key,
    required this.badges,
    this.sourceStoreId,
  }) : super(key: key);

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

    // 画面に渡されたバッジをそのまま表示（既に保存済みかどうかは問わない）
    final List<Map<String, dynamic>> onlyNew = widget.badges
        .where((b) => (b['alreadyOwned'] == true) ? false : true)
        .toList(growable: false);
    _displayBadges
      ..clear()
      ..addAll(_uniqueBadges(onlyNew));
  }

  List<Map<String, dynamic>> _uniqueBadges(List<Map<String, dynamic>> source) {
    final Set<String> seen = <String>{};
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> b in source) {
      final dynamic rawId = b['badgeId'] ?? b['id'] ?? b['name'] ?? '';
      final String key = rawId.toString();
      if (key.isEmpty) {
        result.add(b);
        continue;
      }
      if (seen.add(key)) {
        result.add(b);
      }
    }
    return result;
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
      if (widget.sourceStoreId != null && widget.sourceStoreId!.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RecommendationAfterBadgeView(
              sourceStoreId: widget.sourceStoreId!,
            ),
          ),
        );
      } else {
        // ProviderScope を再作成して Riverpod のキャッシュをクリアした状態でホームへ
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ProviderScope(
              key: UniqueKey(),
              child: const MainNavigationView(initialIndex: 0),
            ),
          ),
          (route) => false,
        );
      }
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
                CustomButton(
                  text: '確認',
                  onPressed: () {
                    if (widget.sourceStoreId != null && widget.sourceStoreId!.isNotEmpty) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => RecommendationAfterBadgeView(
                            sourceStoreId: widget.sourceStoreId!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
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
              CustomButton(
                text: isLast ? '確認' : '次へ',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
