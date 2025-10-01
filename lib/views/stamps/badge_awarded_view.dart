import 'package:flutter/material.dart';

class BadgeAwardedView extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const BadgeAwardedView({Key? key, required this.badges}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 16),
                _AwardedBadgesList(badges: badges),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AwardedBadgesList extends StatefulWidget {
  final List<Map<String, dynamic>> badges;
  const _AwardedBadgesList({Key? key, required this.badges}) : super(key: key);

  @override
  State<_AwardedBadgesList> createState() => _AwardedBadgesListState();
}

class _AwardedBadgesListState extends State<_AwardedBadgesList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: widget.badges.length,
        itemBuilder: (context, index) {
          final b = widget.badges[index];
          return ScaleTransition(
            scale: _scale,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadgeImage(b['imageUrl']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    Text(
                      (b['name'] ?? '').toString(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (b['description'] ?? '').toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
      );
    }
    if (imageUrl.isNotEmpty) {
      return Image.asset(
        'assets/images/badges/$imageUrl',
        width: 72,
        height: 72,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
      );
    }
    return const Icon(Icons.emoji_events, size: 72, color: Colors.amber);
  }
}


