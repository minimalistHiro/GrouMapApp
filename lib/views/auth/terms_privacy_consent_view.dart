import 'package:flutter/material.dart';
import 'sign_up_view.dart';

class TermsPrivacyConsentView extends StatelessWidget {
  const TermsPrivacyConsentView({Key? key}) : super(key: key);

  static const _cardTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const _titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const _metaStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF757575),
  );

  static const _sectionTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  static const _bodyStyle = TextStyle(
    fontSize: 13,
    height: 1.7,
    color: Color(0xFF424242),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('利用規約・プライバシーポリシー'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: _ScrollableCard(
                  title: '利用規約',
                  child: _buildTermsContent(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _ScrollableCard(
                  title: 'プライバシーポリシー',
                  child: _buildPrivacyContent(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignUpView(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    '同意する',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ぐるまっぷ 利用規約', style: _titleStyle),
        const SizedBox(height: 4),
        const Text('制定日: 2025年3月1日', style: _metaStyle),
        const SizedBox(height: 12),
        _buildSection(
          title: '第1条（適用）',
          text:
              '本規約は、ぐるまっぷ（以下「本サービス」）の提供条件および本サービスの利用に関する'
              '当社（本サービス運営者）と利用者との間の権利義務関係を定めるものです。'
              '利用者は本規約に同意の上、本サービスを利用するものとします。',
        ),
        _buildSection(
          title: '第2条（定義）',
          bullets: const [
            '「利用者」とは、本サービスを利用するすべての方をいいます。',
            '「店舗利用者」とは、来店客としてポイントやマップ機能を利用する方をいいます。',
            '「加盟店舗」とは、当社と契約し本サービスに掲載・参加する飲食店等をいいます。',
            '「ポイント」とは、加盟店舗での来店・購入等により付与され、本サービス内で利用できるポイントをいいます。',
          ],
        ),
        _buildSection(
          title: '第3条（サービス内容）',
          text:
              '本サービスは、共通ポイント、マップ、店舗発見（SNS的要素）を統合した飲食店向けサービスです。'
              '利用者は、新しい店舗の発見やポイント利用を通じて、地域内の店舗回遊を促進できます。',
        ),
        _buildSection(
          title: '第4条（アカウント登録）',
          text:
              '本サービスの利用にあたり、当社が指定する情報の登録が必要となる場合があります。'
              '登録情報は正確かつ最新の状態で維持してください。',
        ),
        _buildSection(
          title: '第5条（ポイントの取扱い）',
          bullets: const [
            'ポイントの付与・利用条件は、本サービスおよび加盟店舗が定めるルールに従います。',
            '1会計あたりのポイント利用上限等の共通ルールを設定する場合があります。',
            'ポイントは現金への換金、第三者への譲渡・担保設定を行うことはできません。',
            'ポイントの清算は加盟店舗間で行われ、利用者の権利義務に影響しません。',
            '不正利用が疑われる場合、当社はポイントの無効化等の措置を行うことがあります。',
          ],
        ),
        _buildSection(
          title: '第6条（料金および支払い）',
          text:
              '店舗利用者の基本機能の利用は無料です。加盟店舗向けには月額課金プラン（ベーシック／プレミアム等）を提供し、'
              '10店舗まで無料、11店舗目以降は有料となる場合があります。詳細は別途当社が提示する条件に従います。',
        ),
        _buildSection(
          title: '第7条（禁止事項）',
          bullets: const [
            '法令または公序良俗に違反する行為',
            '虚偽情報の登録、なりすまし、第三者の権利侵害',
            'ポイントの不正取得・不正利用',
            '本サービスの運営を妨害する行為',
            '当社が不適切と判断する行為',
          ],
        ),
        _buildSection(
          title: '第8条（知的財産権）',
          text:
              '本サービスに関する一切の知的財産権は当社または正当な権利者に帰属します。'
              '利用者は、当社の許諾なくこれらを利用することはできません。',
        ),
        _buildSection(
          title: '第9条（サービスの変更・停止）',
          text:
              '当社は、必要に応じて本サービスの内容変更、提供の中断または終了を行うことがあります。'
              'これにより利用者に損害が生じた場合でも、当社は責任を負いません。',
        ),
        _buildSection(
          title: '第10条（利用停止・退会）',
          text:
              '利用者が本規約に違反した場合、当社は事前通知なく利用停止またはアカウント削除を行うことがあります。'
              '退会に伴い、ポイントその他の権利は消滅する場合があります。',
        ),
        _buildSection(
          title: '第11条（免責）',
          text:
              '当社は、本サービスに事実上または法律上の瑕疵がないことを保証しません。'
              '利用者が被った損害について、当社は当社の故意または重過失による場合を除き責任を負いません。',
        ),
        _buildSection(
          title: '第12条（規約の変更）',
          text:
              '当社は、必要に応じて本規約を変更できます。重要な変更の場合、当社は合理的な方法で告知します。'
              '変更後に利用者が本サービスを利用した場合、変更後の規約に同意したものとみなします。',
        ),
        _buildSection(
          title: '第13条（準拠法・管轄）',
          text:
              '本規約は日本法に準拠し、本サービスに関して紛争が生じた場合、当社の所在地を管轄する裁判所を専属的合意管轄とします。',
        ),
        _buildSection(
          title: '第14条（お問い合わせ）',
          text: '本サービスに関するお問い合わせは、アプリ内のお問い合わせ窓口または当社が指定する方法にてご連絡ください。',
        ),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ぐるまっぷ プライバシーポリシー', style: _titleStyle),
        const SizedBox(height: 4),
        const Text('制定日: 2025年3月1日', style: _metaStyle),
        const SizedBox(height: 12),
        _buildSection(
          title: '1. 取得する情報',
          text: '当社は、ぐるまっぷの提供にあたり、以下の情報を取得する場合があります。',
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
    );
  }

  Widget _buildSection({
    required String title,
    String? text,
    List<String>? bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle),
          if (text != null) ...[
            const SizedBox(height: 6),
            Text(text, style: _bodyStyle),
          ],
          if (bullets != null) ...[
            const SizedBox(height: 6),
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
              padding: const EdgeInsets.only(bottom: 4),
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

class _ScrollableCard extends StatelessWidget {
  const _ScrollableCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TermsPrivacyConsentView._cardTitleStyle),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 8),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
