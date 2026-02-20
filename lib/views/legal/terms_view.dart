import 'package:flutter/material.dart';

class TermsView extends StatelessWidget {
  const TermsView({Key? key}) : super(key: key);

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
        title: const Text('利用規約'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ぐるまっぷ 利用規約', style: _titleStyle),
            const SizedBox(height: 6),
            const Text('制定日: 2025年3月1日', style: _metaStyle),
            const SizedBox(height: 20),
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
                '「店舗利用者」とは、来店客としてスタンプやマップ機能を利用する方をいいます。',
                '「加盟店舗」とは、当社と契約し本サービスに掲載・参加する飲食店等をいいます。',
                '「スタンプ」とは、加盟店舗への来店時にQRコードによるチェックインで獲得できる来店の証をいいます。',
                '「コイン」とは、本サービス内のアクティビティ（ミッション達成、連続ログイン、来店等）により獲得でき、クーポン交換等に利用できるプラットフォーム独自の通貨をいいます。',
                '「バッジ」とは、利用者の利用実績に応じて自動的に付与される達成記録をいいます。',
              ],
            ),
            _buildSection(
              title: '第3条（サービス内容）',
              text:
                  '本サービスは、スタンプ、マップ、店舗発見（SNS的要素）を統合した飲食店向けプラットフォームサービスです。'
                  '利用者は、マップやレコメンド機能を通じた新しい店舗の発見、スタンプの収集と特典の獲得、'
                  'コインによるクーポン交換、バッジの獲得等を通じて、地域内の店舗回遊を楽しむことができます。',
            ),
            _buildSection(
              title: '第4条（アカウント登録）',
              text:
                  '本サービスの利用にあたり、当社が指定する情報の登録が必要となる場合があります。'
                  '登録情報は正確かつ最新の状態で維持してください。'
                  '利用者は、メールアドレス/パスワード、Googleアカウント、またはApple IDにより登録・ログインできます。'
                  '利用者は、自己の責任においてアカウント情報を適切に管理するものとし、第三者に譲渡または貸与することはできません。'
                  '一部の機能はログインなしでも利用できます（ゲストモード）。',
            ),
            _buildSection(
              title: '第5条（スタンプの取扱い）',
              bullets: const [
                'スタンプは、加盟店舗への来店時にQRコードによるチェックインを行うことで獲得できます。',
                'スタンプの獲得条件および特典内容は、各加盟店舗が設定するルールに従います。',
                'スタンプは現金への換金、第三者への譲渡・担保設定を行うことはできません。',
                '不正利用が疑われる場合、当社はスタンプの無効化等の措置を行うことがあります。',
              ],
            ),
            _buildSection(
              title: '第6条（コインの取扱い）',
              bullets: const [
                'コインは、デイリーミッションの達成、連続ログインボーナス、新規登録ミッション、来店ボーナス等により獲得できます。',
                'コインは、未訪問店舗クーポンの取得、スロット等に利用できます。',
                'コインには最終獲得日から180日間の有効期限があり、期限を過ぎたコインは自動的に失効します。',
                'コインは現金への換金、第三者への譲渡・担保設定を行うことはできません。',
                '不正利用が疑われる場合、当社はコインの無効化等の措置を行うことがあります。',
              ],
            ),
            _buildSection(
              title: '第7条（クーポンの取扱い）',
              bullets: const [
                'クーポンは、スタンプの達成条件を満たした場合、またはコインとの交換により取得できます。',
                'クーポンの利用条件（有効期限、対象店舗、割引内容等）は、各クーポンに定められた条件に従います。',
                'クーポンは現金への換金、第三者への譲渡を行うことはできません。',
              ],
            ),
            _buildSection(
              title: '第8条（料金および支払い）',
              text:
                  '店舗利用者の基本機能の利用は無料です。加盟店舗向けには月額課金プラン（ベーシック等）を提供し、'
                  '5店舗まで無料、6店舗目以降は有料となります。詳細は別途当社が提示する条件に従います。',
            ),
            _buildSection(
              title: '第9条（禁止事項）',
              text: '利用者は、本サービスの利用にあたり、以下の行為をしてはなりません。',
              bullets: const [
                '法令または公序良俗に違反する行為',
                '虚偽情報の登録、なりすまし、第三者の権利侵害',
                'スタンプ・コイン・バッジ・クーポンの不正取得・不正利用',
                '本サービスの運営を妨害する行為（不正アクセス、QRコードの偽造・複製を含む）',
                '他の利用者に関する個人情報を不正に収集または蓄積する行為',
                '当社が不適切と判断する行為',
              ],
            ),
            _buildSection(
              title: '第10条（知的財産権）',
              text:
                  '本サービスに関する一切の知的財産権は当社または正当な権利者に帰属します。'
                  '利用者は、当社の許諾なくこれらを利用することはできません。',
            ),
            _buildSection(
              title: '第11条（サービスの変更・停止）',
              text:
                  '当社は、必要に応じて本サービスの内容変更、提供の中断または終了を行うことがあります。'
                  'システム保守、天災、通信障害等のやむを得ない事由により、事前の通知なくサービスを一時停止する場合があります。'
                  'これにより利用者に損害が生じた場合でも、当社は責任を負いません。',
            ),
            _buildSection(
              title: '第12条（利用停止・退会）',
              text:
                  '利用者が本規約に違反した場合、当社は事前通知なく利用停止またはアカウント削除を行うことがあります。'
                  '利用者は、当社の定める退会手続によりアカウントを削除できます。'
                  '退会に伴い、スタンプ・コイン・バッジ・クーポンその他の権利は消滅します。',
            ),
            _buildSection(
              title: '第13条（免責）',
              text:
                  '当社は、本サービスに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、'
                  'セキュリティ等に関する欠陥、エラーやバグ、権利侵害等を含みます）がないことを保証しません。'
                  '利用者が被った損害について、当社は当社の故意または重過失による場合を除き責任を負いません。'
                  '加盟店舗の提供するサービス・商品に関する紛争は、利用者と当該店舗との間で解決するものとし、当社は一切の責任を負いません。',
            ),
            _buildSection(
              title: '第14条（規約の変更）',
              text:
                  '当社は、必要に応じて本規約を変更できます。重要な変更の場合、当社はアプリ内通知等の合理的な方法で告知します。'
                  '変更後に利用者が本サービスを利用した場合、変更後の規約に同意したものとみなします。',
            ),
            _buildSection(
              title: '第15条（準拠法・管轄）',
              text:
                  '本規約は日本法に準拠し、本サービスに関して紛争が生じた場合、当社の所在地を管轄する裁判所を専属的合意管轄とします。',
            ),
            _buildSection(
              title: '第16条（お問い合わせ）',
              text: '本サービスに関するお問い合わせは、アプリ内のお問い合わせ窓口または当社が指定する方法にてご連絡ください。',
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
