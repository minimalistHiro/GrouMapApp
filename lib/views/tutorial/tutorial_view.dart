import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// チュートリアルの各スライドデータ
class _TutorialSlide {
  final String imagePath;
  final String title;
  final String description;

  const _TutorialSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

/// 新規登録後に初回のみ表示するチュートリアル画面
class TutorialView extends StatefulWidget {
  final String userId;

  const TutorialView({super.key, required this.userId});

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_TutorialSlide> _slides = [
    _TutorialSlide(
      imagePath: 'assets/images/tutorial_1.png',
      title: '地図で近くのお店を発見',
      description: '位置情報をONにすると、マップ上で近くのお店を探せます。まだ行ったことのないお店がきっと見つかります。',
    ),
    _TutorialSlide(
      imagePath: 'assets/images/tutorial_2.png',
      title: '来店してスタンプを集めよう',
      description: 'お店でQRコードをスキャンするとスタンプが貯まります。スタンプが揃ったら値引き特典が使えます！',
    ),
    _TutorialSlide(
      imagePath: 'assets/images/tutorial_3.png',
      title: 'アプリを使ってコインを獲得',
      description: '毎日のミッション達成やアプリを開くだけでコインが貯まります。コインは未訪問店舗の100円引きクーポンと交換できます。',
    ),
    _TutorialSlide(
      imagePath: 'assets/images/tutorial_4.png',
      title: 'バッジを集めて冒険の記録に',
      description: '訪問した店舗数や来店回数に応じてバッジを獲得できます。162種のバッジがあなたの冒険を彩ります！',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTutorial() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'showTutorial': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      debugPrint('チュートリアル完了フラグ更新エラー: $e');
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: Stack(
          children: [
            // スライドコンテンツ
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _SlideWidget(slide: _slides[index]);
              },
            ),

            // 左上スキップボタン
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54, size: 24),
                onPressed: _completeTutorial,
              ),
            ),

            // 下部: ドットインジケーター + 次へボタン
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ドットインジケーター
                    Row(
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFFF6B35)
                                : const Color(0xFFFF6B35).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    // 次へ / はじめる ボタン
                    isLastPage
                        ? ElevatedButton(
                            onPressed: _completeTutorial,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'はじめる',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _onNext,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B35)
                                        .withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 各スライドのUI
class _SlideWidget extends StatelessWidget {
  final _TutorialSlide slide;

  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // イラスト画像
          Expanded(
            flex: 6,
            child: Center(
              child: Image.asset(
                slide.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // タイトル
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // 説明文
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.7,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
