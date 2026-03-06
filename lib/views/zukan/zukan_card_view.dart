import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/zukan_provider.dart';
import '../../widgets/stamp_card_widget.dart';
import '../main_navigation_view.dart';

/// NFCチェックイン後に表示する図鑑カード発見演出画面
///
/// [isFirstVisit] = true  → フリップアニメーション + 「発見！」演出
/// [isFirstVisit] = false → 「再訪問」静的表示
class ZukanCardView extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;
  final bool isFirstVisit;

  const ZukanCardView({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.isFirstVisit,
  });

  @override
  ConsumerState<ZukanCardView> createState() => _ZukanCardViewState();
}

class _ZukanCardViewState extends ConsumerState<ZukanCardView>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final AnimationController _glowController;
  late final AnimationController _textController;
  late final Animation<double> _flipAnim;
  late final Animation<double> _glowAnim;
  late final Animation<double> _textFadeAnim;

  bool _showFront = false;
  ZukanStoreItem? _storeItem;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flipAnim = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _textFadeAnim = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showFront = true);
        _textController.forward();
      }
    });

    _loadStoreData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    try {
      final zukanAsync = ref.read(zukanStoresProvider);
      final items = zukanAsync.valueOrNull ?? [];
      final found = items.where((i) => i.storeId == widget.storeId).firstOrNull;

      if (mounted) {
        setState(() {
          _storeItem = found;
          _loading = false;
        });
      }

      if (widget.isFirstVisit) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _flipController.forward();
      } else {
        if (mounted) {
          setState(() => _showFront = true);
          _textController.forward();
        }
      }
    } catch (e) {
      debugPrint('ZukanCardView: データ取得エラー $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _storeItem?.rarityColor ?? const Color(0xFF757575);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          // アニメーション背景
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => CustomPaint(
              painter: _CardBackgroundPainter(rarityColor, _glowAnim.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Column(
                    children: [
                      // ヘッダー
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            FadeTransition(
                              opacity: _textFadeAnim,
                              child: Text(
                                widget.isFirstVisit ? '発見！' : '再訪問',
                                style: TextStyle(
                                  color: rarityColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: rarityColor.withOpacity(0.8),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),

                      // カードエリア
                      Expanded(
                        child: Center(
                          child: widget.isFirstVisit
                              ? _buildFlipCard(rarityColor)
                              : _CardFront(
                                  storeItem: _storeItem,
                                  storeName: widget.storeName,
                                  glowAnim: _glowAnim,
                                ),
                        ),
                      ),

                      // カード下部情報
                      FadeTransition(
                        opacity: _textFadeAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Text(
                                _buildDiscoveredText(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              _buildRarityStars(rarityColor),
                              const SizedBox(height: 4),
                              Text(
                                _storeItem?.rarityLabel ?? 'コモン',
                                style: TextStyle(
                                  color: rarityColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 完了ボタン（レア度カラーのグラデーション）
                      FadeTransition(
                        opacity: _textFadeAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: GestureDetector(
                            onTap: _onComplete,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    rarityColor,
                                    rarityColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: rarityColor.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.isFirstVisit ? '図鑑に登録完了！' : 'ホームに戻る',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(Color rarityColor) {
    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (_, __) {
        final angle = _flipAnim.value;
        final isFront = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _CardFront(
                    storeItem: _storeItem,
                    storeName: widget.storeName,
                    glowAnim: _glowAnim,
                  ),
                )
              : _CardBack(rarityColor: rarityColor),
        );
      },
    );
  }

  String _buildDiscoveredText() {
    final count = _storeItem?.discoveredCount ?? 0;
    if (count <= 1) return 'あなたが最初の発見者です！';
    return 'あなたが$count人目の発見者です！';
  }

  Widget _buildRarityStars(Color rarityColor) {
    final level = _storeItem?.rarityLevel ?? 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        return Icon(
          i < level ? Icons.star : Icons.star_border,
          color: rarityColor,
          size: 24,
        );
      }),
    );
  }

  void _onComplete() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationView()),
      (route) => false,
    );
  }
}

// ────────────────────────────────────────────
// カード表面
// ────────────────────────────────────────────
class _CardFront extends StatelessWidget {
  final ZukanStoreItem? storeItem;
  final String storeName;
  final Animation<double> glowAnim;

  const _CardFront({
    required this.storeItem,
    required this.storeName,
    required this.glowAnim,
  });

  @override
  Widget build(BuildContext context) {
    final color = storeItem?.rarityColor ?? const Color(0xFF757575);
    final category = storeItem?.category ?? 'その他';
    final imageUrl = storeItem?.firstImageUrl;
    final rarityStars = storeItem?.rarityStars ?? '★☆☆☆';
    final discoveredCount = storeItem?.discoveredCount ?? 0;

    return AnimatedBuilder(
      animation: glowAnim,
      builder: (_, __) => Container(
        width: 260,
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.3),
              const Color(0xFF1A1A2E),
              color.withOpacity(0.15),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.7 * glowAnim.value),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4 * glowAnim.value),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景パターン（同心円）
            CustomPaint(
              painter: _CardPatternPainter(color),
              child: Container(),
            ),
            // コンテンツ
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // レア度バッジ
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          storeItem?.rarityLabel ?? 'コモン',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      // カテゴリ
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 店舗画像エリア
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _CategoryIcon(
                                        category: category,
                                        color: color,
                                      ),
                                )
                              : _CategoryIcon(
                                  category: category,
                                  color: color,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 店舗名
                  Text(
                    storeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // カテゴリ（下部）
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 星と発見者数
                  Row(
                    children: [
                      Text(
                        rarityStars,
                        style: TextStyle(color: color, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.people, size: 12, color: Colors.white38),
                      const SizedBox(width: 2),
                      Text(
                        '$discoveredCount人',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
// カード裏面（フリップ前）
// ────────────────────────────────────────────
class _CardBack extends StatelessWidget {
  final Color rarityColor;

  const _CardBack({required this.rarityColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF16213E),
        border: Border.all(
          color: rarityColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _CardPatternPainter(rarityColor),
            child: Container(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rarityColor.withOpacity(0.15),
                  border: Border.all(
                    color: rarityColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text('🗺️', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ぐるまっぷ',
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '図鑑カード',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────
// カテゴリアイコン（画像なし時のフォールバック）
// ────────────────────────────────────────────
class _CategoryIcon extends StatelessWidget {
  final String category;
  final Color color;

  const _CategoryIcon({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = StampCardWidget.getCategoryIcon(category);
    return Container(
      color: color.withOpacity(0.2),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 56,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
// カードの同心円パターン
// ────────────────────────────────────────────
class _CardPatternPainter extends CustomPainter {
  final Color color;

  const _CardPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final r = 30.0 + i * 25;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ────────────────────────────────────────────
// 背景: 暗い背景 + レア度グロー + スパークル
// ────────────────────────────────────────────
class _CardBackgroundPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  const _CardBackgroundPainter(this.color, this.glowIntensity);

  @override
  void paint(Canvas canvas, Size size) {
    // ベース: 深い暗色
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A14),
    );

    // 中央グロー
    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.15 * glowIntensity),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // スパークル（光の粒）
    final sparkPaint = Paint()
      ..color = color.withOpacity(0.3 * glowIntensity);
    final positions = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.15),
      Offset(size.width * 0.05, size.height * 0.6),
      Offset(size.width * 0.95, size.height * 0.5),
      Offset(size.width * 0.85, size.height * 0.85),
      Offset(size.width * 0.15, size.height * 0.9),
    ];
    for (final pos in positions) {
      canvas.drawCircle(pos, 3, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardBackgroundPainter old) =>
      old.glowIntensity != glowIntensity;
}
