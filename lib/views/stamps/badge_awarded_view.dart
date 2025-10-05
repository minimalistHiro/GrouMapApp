import 'package:flutter/material.dart';
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
  late final Animation<double> _spin;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _spin = CurvedAnimation(parent: _spinController, curve: Curves.easeOutBack);
    _spinController.forward();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < widget.badges.length - 1) {
      setState(() => _index++);
      _spinController
        ..reset()
        ..forward();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationView()),
        (route) => false,
      );
    }
  }

  Widget _buildBadgeImage(Map<String, dynamic> badge) {
    final image = (badge['imageUrl'] ?? badge['iconUrl'] ?? badge['iconPath'] ?? '').toString();
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 72,
        height: 72,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
      );
    }
    if (image.isNotEmpty) {
      return Image.asset(
        'assets/images/badges/$image',
        width: 72,
        height: 72,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
      );
    }
    return const Icon(Icons.emoji_events, size: 72, color: Colors.amber);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == widget.badges.length - 1;
    final badge = widget.badges[_index];

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                  height: 220,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RotationTransition(
                            turns: Tween<double>(begin: 0.0, end: 1.0).animate(_spin),
                            child: _buildBadgeImage(badge),
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
                const SizedBox(height: 24),
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
      ),
    );
  }
}


