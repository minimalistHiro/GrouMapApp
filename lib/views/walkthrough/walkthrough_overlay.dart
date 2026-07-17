import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'walkthrough_painter.dart';
import 'walkthrough_step_config.dart';

/// グレーアウト + ハイライト + テキスト表示のオーバーレイウィジェット
class WalkthroughOverlay extends StatefulWidget {
  /// ハイライト対象のGlobalKey
  final GlobalKey? targetKey;

  /// GlobalKeyが使えない場合の直接Rect指定
  final Rect? targetRect;

  /// 説明テキスト
  final String message;

  /// サブテキスト（補足説明）
  final String? subMessage;

  /// スキップ時のコールバック
  final VoidCallback? onSkip;

  /// ハイライト部分のタップ透過
  final bool allowTapThrough;

  /// メッセージの表示位置
  final MessagePosition messagePosition;

  /// ハイライト部分がタップされた時のコールバック
  final VoidCallback? onTargetTap;

  /// オーバーレイ全体をタップ透過にする（メッセージとスキップのみ表示）
  final bool passThrough;

  /// オーバーレイの透明度（0.0〜1.0）
  final double overlayOpacity;

  /// ユーザー操作が必要かどうか（falseなら「次へ」ボタンを表示）
  final bool requiresAction;

  /// 「次へ」ボタンが押された時のコールバック
  final VoidCallback? onNext;

  /// コンセプト画面レイアウト（3アイコン説明）を表示するか
  final bool showConceptLayout;

  const WalkthroughOverlay({
    super.key,
    this.targetKey,
    this.targetRect,
    required this.message,
    this.subMessage,
    this.onSkip,
    this.allowTapThrough = true,
    this.messagePosition = MessagePosition.center,
    this.onTargetTap,
    this.passThrough = false,
    this.overlayOpacity = 0.6,
    this.requiresAction = true,
    this.onNext,
    this.showConceptLayout = false,
  });

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Rect? _computedRect;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
  }

  @override
  void didUpdateWidget(covariant WalkthroughOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateRect() {
    Rect? newRect = widget.targetRect;
    if (newRect == null && widget.targetKey?.currentContext != null) {
      final renderBox =
          widget.targetKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        newRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );
      }
    }
    if (newRect != _computedRect && mounted) {
      setState(() => _computedRect = newRect);
    }
  }

  @override
  Widget build(BuildContext context) {
    // フルスクリーンモード（操作不要 + ターゲットなし）
    if (!widget.requiresAction &&
        widget.targetRect == null &&
        widget.targetKey == null) {
      return _buildFullscreenOverlay(context);
    }

    final screenSize = MediaQuery.of(context).size;
    final overlayColor = Colors.black.withOpacity(widget.overlayOpacity);

    // passThrough モード: オーバーレイは表示するがタップは全て透過
    if (widget.passThrough) {
      return IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  size: screenSize,
                  painter: WalkthroughPainter(
                    highlightRect: _computedRect,
                    overlayColor: overlayColor,
                  ),
                ),
              ),
              _buildMessage(context),
              if (widget.onSkip != null) _buildSkipButton(context),
            ],
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // グレーアウトオーバーレイ（穴あき）
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // 暗い部分はタップしても何も起きない
              },
              child: CustomPaint(
                size: screenSize,
                painter: WalkthroughPainter(
                  highlightRect: _computedRect,
                  overlayColor: overlayColor,
                ),
              ),
            ),
          ),

          // ハイライト部分のタップ透過エリア
          if (_computedRect != null && widget.allowTapThrough)
            Positioned(
              left: _computedRect!.left - 8,
              top: _computedRect!.top - 8,
              width: _computedRect!.width + 16,
              height: _computedRect!.height + 16,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.onTargetTap,
                child: const SizedBox.expand(),
              ),
            ),

          // パルスアニメーション（ハイライト枠）
          if (_computedRect != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final inflate = 8 + _pulseAnimation.value * 6;
                return Positioned(
                  left: _computedRect!.left - inflate,
                  top: _computedRect!.top - inflate,
                  width: _computedRect!.width + inflate * 2,
                  height: _computedRect!.height + inflate * 2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white
                              .withOpacity(0.6 - _pulseAnimation.value * 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // メッセージテキスト
          _buildMessage(context),

          // スキップボタン
          if (widget.onSkip != null) _buildSkipButton(context),
        ],
      ),
    );
  }

  /// フルスクリーンオーバーレイ（concept / learnNfcTouch ステップ用）
  Widget _buildFullscreenOverlay(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: SafeArea(
          child: Stack(
            children: [
              // スキップボタン
              if (widget.onSkip != null)
                Positioned(
                  top: 8,
                  right: 16,
                  child: GestureDetector(
                    onTap: widget.onSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'スキップ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              // メインコンテンツ（中央）
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: widget.showConceptLayout
                      ? _buildConceptContent()
                      : _buildFullscreenMessageContent(),
                ),
              ),

              // 「次へ」ボタン（下部）
              Positioned(
                bottom: 32 + safeArea.bottom,
                left: 32,
                right: 32,
                child: CustomButton(
                  text: widget.showConceptLayout ? 'はじめる' : '次へ',
                  onPressed: widget.onNext,
                  backgroundColor: const Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// コンセプト画面コンテンツ（3アイコン説明）
  Widget _buildConceptContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        if (widget.subMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 48),
        // 3ステップ説明
        _buildConceptStep(
          icon: Icons.map_outlined,
          label: 'マップで未発見の店を探す',
        ),
        const SizedBox(height: 8),
        const Icon(Icons.arrow_downward, color: Colors.white38, size: 20),
        const SizedBox(height: 8),
        _buildConceptStep(
          icon: Icons.nfc,
          label: 'NFCタッチで図鑑カードGET',
        ),
        const SizedBox(height: 8),
        const Icon(Icons.arrow_downward, color: Colors.white38, size: 20),
        const SizedBox(height: 8),
        _buildConceptStep(
          icon: Icons.menu_book_outlined,
          label: 'コレクション達成！',
        ),
      ],
    );
  }

  Widget _buildConceptStep({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 通常のフルスクリーンメッセージコンテンツ（learnNfcTouch など）
  Widget _buildFullscreenMessageContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        if (widget.subMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.subMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: GestureDetector(
        onTap: widget.onSkip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'スキップ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;

    double top;
    switch (widget.messagePosition) {
      case MessagePosition.top:
        top = safeTop + 60;
        break;
      case MessagePosition.center:
        top = screenSize.height * 0.35;
        break;
      case MessagePosition.aboveTarget:
        if (_computedRect != null) {
          top = _computedRect!.top - 100;
          if (top < safeTop + 40) top = safeTop + 40;
        } else {
          top = screenSize.height * 0.35;
        }
        break;
    }

    return Positioned(
      top: top,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            if (widget.subMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.subMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
