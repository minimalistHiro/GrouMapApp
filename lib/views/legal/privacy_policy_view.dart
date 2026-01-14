import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  static const _titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const _metaStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF757575),
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
        title: const Text('プライバシーポリシー'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GrouMap プライバシーポリシー', style: _titleStyle),
            const SizedBox(height: 6),
            const Text('制定日: 2025年3月1日', style: _metaStyle),
            const SizedBox(height: 20),
            _buildSection(
              title: '1. 取得する情報',
              text: '当社は、GrouMapの提供にあたり、以下の情報を取得する場合があります。',
              bullets: const [
                '登録情報（氏名またはニックネーム、メールアドレス等）',
                'プロフィール情報（アイコン、自己紹介等）',
                '位置情報（マップ機能や周辺店舗表示のため）',
                '利用履歴（ポイント付与・利用履歴、閲覧・検索履歴等）',
                '端末情報・ログ情報（IPアドレス、ブラウザ・OS、アクセス日時等）',
                '加盟店舗に関する契約・請求情報（店舗利用者向けプランの申込時）',
              ],
            ),
            _buildSection(
              title: '2. 利用目的',
              bullets: const [
                '本サービスの提供、運営、保守、改善のため',
                '共通ポイントの付与・利用・精算のため',
                '加盟店舗および利用者への連絡、サポート対応のため',
                '不正利用の防止、セキュリティ確保のため',
                '新機能やキャンペーン等の案内のため',
                '統計情報の作成およびサービス改善のため（個人を特定しない形）',
              ],
            ),
            _buildSection(
              title: '3. 第三者提供',
              text: '当社は、以下の場合を除き、個人情報を第三者に提供しません。',
              bullets: const [
                '利用者の同意がある場合',
                '法令に基づく場合',
                '人の生命、身体または財産の保護のために必要な場合',
                '業務委託先に必要な範囲で提供する場合（第4項参照）',
              ],
            ),
            _buildSection(
              title: '4. 委託',
              text:
                  '当社は、サービス運営に必要な範囲で、個人情報の取り扱いを外部事業者に委託することがあります。'
                  'この場合、適切な委託先の選定および管理を行います。',
            ),
            _buildSection(
              title: '5. 安全管理',
              text:
                  '当社は、個人情報の漏えい、滅失、毀損の防止その他の安全管理のために必要かつ適切な措置を講じます。',
            ),
            _buildSection(
              title: '6. 保有期間',
              text:
                  '当社は、利用目的に必要な期間に限り個人情報を保有し、不要となった情報は適切な方法で削除または匿名化します。',
            ),
            _buildSection(
              title: '7. 開示・訂正・削除等',
              text:
                  '利用者は、当社所定の方法により、自己の個人情報の開示、訂正、追加、削除、利用停止を求めることができます。',
            ),
            _buildSection(
              title: '8. クッキー等の利用',
              text:
                  '当社は、利便性向上や利用状況分析のためにクッキーや類似技術を使用する場合があります。'
                  'ブラウザ設定によりクッキーの受け取りを拒否できますが、一部機能が利用できない場合があります。',
            ),
            _buildSection(
              title: '9. ポリシーの改定',
              text:
                  '当社は、法令の改正やサービス内容の変更等に応じて本ポリシーを改定することがあります。'
                  '重要な変更の場合、当社は合理的な方法で告知します。',
            ),
            _buildSection(
              title: '10. お問い合わせ',
              text: '本ポリシーに関するお問い合わせは、アプリ内のお問い合わせ窓口または当社が指定する方法にてご連絡ください。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? text,
    List<String>? bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(text, style: _bodyStyle),
          ],
          if (bullets != null) ...[
            const SizedBox(height: 8),
            _buildBulletList(bullets),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: _bodyStyle),
                  Expanded(child: Text(item, style: _bodyStyle)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
