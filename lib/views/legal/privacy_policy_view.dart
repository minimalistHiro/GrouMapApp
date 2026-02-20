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
            const Text('ぐるまっぷ プライバシーポリシー', style: _titleStyle),
            const SizedBox(height: 6),
            const Text('制定日: 2025年3月1日', style: _metaStyle),
            const SizedBox(height: 20),
            _buildSection(
              title: '1. 取得する情報',
              text: '当社は、ぐるまっぷ（以下「本サービス」）の提供にあたり、以下の情報を取得する場合があります。',
              bullets: const [
                '登録情報（表示名、ユーザーID、メールアドレス、認証プロバイダ情報等）',
                'プロフィール情報（プロフィール画像、生年月日、性別、都道府県、市区町村、職業、自己紹介、興味のあるカテゴリ等）',
                '位置情報（マップ機能、周辺店舗表示、店舗までの距離計算、レコメンド機能のため）',
                '利用履歴（スタンプ獲得・来店履歴、コイン獲得・消費履歴、クーポン取得・使用履歴、バッジ獲得履歴、スロット利用履歴、ミッション達成状況、ランキング情報等）',
                '行動情報（マップ閲覧回数、店舗詳細閲覧回数、お気に入り登録、投稿へのいいね・コメント、フォロー情報、レコメンド表示・クリック記録等）',
                '端末情報・ログ情報（IPアドレス、ブラウザ・OS情報、アクセス日時、FCMトークン等）',
                '加盟店舗に関する契約・請求情報（店舗向けプランの申込時）',
              ],
            ),
            _buildSection(
              title: '2. 利用目的',
              bullets: const [
                '本サービスの提供、運営、保守、改善のため',
                'スタンプ・コイン・バッジ・クーポン等の各種機能の提供・管理のため',
                'マップ機能およびレコメンド機能における店舗表示・おすすめ提案のため',
                '加盟店舗および利用者への連絡、サポート対応のため',
                'プッシュ通知およびお知らせの配信のため',
                '不正利用の防止、セキュリティ確保のため',
                'ランキング機能の算出および表示のため',
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
                  '委託先には、Firebase（Google LLC）等のクラウドサービスを含みます。'
                  'この場合、適切な委託先の選定および管理を行います。',
            ),
            _buildSection(
              title: '5. 安全管理',
              text:
                  '当社は、個人情報の漏えい、滅失、毀損の防止その他の安全管理のために必要かつ適切な措置を講じます。',
            ),
            _buildSection(
              title: '6. 位置情報の取り扱い',
              text:
                  '本サービスでは、マップ機能・周辺店舗表示・レコメンド機能の提供のために、利用者の端末から位置情報を取得します。'
                  '位置情報の取得にはOSの位置情報サービスを使用し、利用者は端末の設定から取得の許可・拒否をいつでも変更できます。'
                  'ただし、位置情報の取得を拒否した場合、一部機能が利用できない場合があります。',
            ),
            _buildSection(
              title: '7. プッシュ通知',
              text:
                  '本サービスでは、お知らせ・クーポン発行・投稿通知等のためにプッシュ通知を使用する場合があります。'
                  '利用者はアプリ内の通知設定から通知項目ごとの受信可否を変更できます。',
            ),
            _buildSection(
              title: '8. 保有期間',
              text:
                  '当社は、利用目的に必要な期間に限り個人情報を保有し、不要となった情報は適切な方法で削除または匿名化します。'
                  'コインには最終獲得日から180日間の有効期限があり、期限切れのコインは自動的に失効します。',
            ),
            _buildSection(
              title: '9. 開示・訂正・削除等',
              text:
                  '利用者は、当社所定の方法により、自己の個人情報の開示、訂正、追加、削除、利用停止を求めることができます。'
                  'また、利用者はアプリ内のアカウント設定からアカウント削除（退会）を行うことができ、この場合サブコレクション・プロフィール画像を含む個人情報が完全に削除されます。',
            ),
            _buildSection(
              title: '10. クッキー等の利用',
              text:
                  '当社は、利便性向上や利用状況分析のためにクッキーや類似技術（ローカルストレージ等）を使用する場合があります。'
                  'また、サービス改善のためにアナリティクスツールを使用し、利用状況を分析する場合があります。'
                  'これらにより収集される情報は、個人を特定しない形で処理されます。',
            ),
            _buildSection(
              title: '11. ポリシーの改定',
              text:
                  '当社は、法令の改正やサービス内容の変更等に応じて本ポリシーを改定することがあります。'
                  '重要な変更の場合、当社はアプリ内通知等の合理的な方法で告知します。',
            ),
            _buildSection(
              title: '12. お問い合わせ',
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
