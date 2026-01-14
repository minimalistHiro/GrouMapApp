import 'package:flutter/material.dart';

class HelpView extends StatelessWidget {
  const HelpView({Key? key}) : super(key: key);

  static const _titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const _sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const _bodyStyle = TextStyle(
    fontSize: 14,
    height: 1.7,
    color: Color(0xFF424242),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ヘルプ', style: _titleStyle),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Q. GrouMapはどんなアプリですか？',
              text:
                  'A. 中小飲食店向けの共通ポイントアプリです。ポイント機能に加えて、マップで新しい店舗を発見できる仕組みを提供します。',
            ),
            _buildSection(
              title: 'Q. 利用者にとってのメリットは？',
              text:
                  'A. 新しい店舗の発見がしやすく、店舗をまたいで共通ポイントを貯めたり使ったりできます。',
            ),
            _buildSection(
              title: 'Q. 店舗側にとってのメリットは？',
              text:
                  'A. マップ上での露出を増やし、新規顧客の獲得を促進できます。共通ポイント運用で来店のハードルも下げられます。',
            ),
            _buildSection(
              title: 'Q. ポイントはどのように使えますか？',
              text:
                  'A. 全店舗共通で利用でき、1会計あたりの利用上限などの共通ルールが設定される場合があります。',
            ),
            _buildSection(
              title: 'Q. バッジ機能とは？',
              text:
                  'A. 複数店舗の利用などで獲得できるバッジを用意し、ゲーム性を高める仕組みです。',
            ),
            _buildSection(
              title: 'Q. プレミアムプランの特徴は？',
              text:
                  'A. ベーシックの機能に加えて、投稿やクーポンの発行が利用できます。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle),
          const SizedBox(height: 6),
          Text(text, style: _bodyStyle),
        ],
      ),
    );
  }
}
