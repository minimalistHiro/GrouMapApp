import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';

class TermsView extends StatefulWidget {
  const TermsView({
    super.key,
    this.showConsentButton = false,
  });

  final bool showConsentButton;

  @override
  State<TermsView> createState() => _TermsViewState();
}

class _TermsViewState extends State<TermsView> {
  final ScrollController _scrollController = ScrollController();
  bool _canAgree = false;

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
  void initState() {
    super.initState();
    if (widget.showConsentButton) {
      _scrollController.addListener(_updateAgreementAvailability);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateAgreementAvailability();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateAgreementAvailability);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateAgreementAvailability() {
    if (!widget.showConsentButton || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final reachedBottom = position.extentAfter <= 8;

    if (!reachedBottom || _canAgree) {
      return;
    }

    setState(() {
      _canAgree = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '利用規約'),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ぐるまっぷ（ユーザー向け）利用規約', style: _titleStyle),
            const SizedBox(height: 6),
            const Text('制定日: 2025年3月1日', style: _metaStyle),
            const Text('改定日: 2026年2月23日', style: _metaStyle),
            const SizedBox(height: 20),
            _buildSection(
              title: '第1条（適用）',
              text:
                  '本規約は、ぐるまっぷ（ユーザー向け。以下「本サービス」）の提供条件および利用に関する当社と利用者との間の権利義務を定めるものです。利用者は、本規約に同意したうえで本サービスを利用するものとします。',
            ),
            _buildSection(
              title: '第2条（定義）',
              text: '本規約において使用する用語の定義は、次のとおりです。',
              bullets: const [
                '「利用者」: 本サービスを利用するすべての者',
                '「加盟店舗」: 当社所定の手続で本サービスに参加する店舗',
                '「スタンプ」: 加盟店舗への来店時に付与される来店記録',
                '「コイン」: 本サービス内の行動に応じて無償で付与されるポイント',
                '「クーポン」: 本サービス上で取得・利用できる割引等の特典',
                '「バッジ」: 利用実績に応じて付与される達成記録',
              ],
            ),
            _buildSection(
              title: '第3条（サービス内容）',
              text:
                  '本サービスは、マップを通じた店舗発見、来店時のスタンプ付与、クーポン利用、コイン獲得・消費、投稿閲覧、通知受信等の機能を提供します。提供機能の詳細は当社が定める画面・ヘルプ・案内に従います。',
            ),
            _buildSection(
              title: '第4条（アカウント登録）',
              bullets: const [
                '1. 本サービスの利用には、当社所定の登録が必要となる場合があります。',
                '2. 利用者は、登録情報を真実かつ最新の内容に維持するものとします。',
                '3. 利用者は、自己の責任でアカウント情報を管理し、第三者に譲渡・貸与してはなりません。',
                '4. 当社は、登録申請者が不適当と判断される場合、登録を拒否または取消すことができます。',
              ],
            ),
            _buildSection(
              title: '第5条（認証手段）',
              text:
                  '利用者は、メールアドレス/パスワード、Google、Apple等、当社が提供する認証手段によりログインできます。一部機能はゲスト利用が可能ですが、機能制限があります。',
            ),
            _buildSection(
              title: '第6条（スタンプ）',
              bullets: const [
                '1. スタンプは、当社所定の方法（QRチェックイン等）によって付与されます。',
                '2. スタンプ付与条件や特典内容は、加盟店舗または当社が定める条件に従います。',
                '3. スタンプは、現金化、払戻し、第三者譲渡、担保設定の対象とできません。',
                '4. 不正取得または不正利用が疑われる場合、当社はスタンプを無効化できます。',
              ],
            ),
            _buildSection(
              title: '第7条（コイン）',
              bullets: const [
                '1. コインは、デイリーミッション、ログインボーナス、来店等の条件達成時に無償で付与されます。',
                '2. コインの有償販売・有償発行は行いません。',
                '3. コインの利用先は、当社が別途定めるクーポン取得等に限られます（現時点では未訪問店舗向け100円引きクーポンの取得）。',
                '4. コインには最終獲得日から180日の有効期限があり、期限経過後は自動失効します。',
                '5. コインおよびコインにより取得したクーポンは、現金化、払戻し、第三者譲渡、担保設定ができません。',
                '6. 取引付随抽選（スロット等）および加盟店へのコイン精算は、現時点では実施しません。',
                '7. 不正取得・不正利用が疑われる場合、当社はコインの無効化その他必要な措置を講じます。',
              ],
            ),
            _buildSection(
              title: '第8条（クーポン）',
              bullets: const [
                '1. クーポンは、スタンプ達成またはコイン交換等の条件により取得できます。',
                '2. クーポンの利用条件（対象店舗、有効期限、内容等）は、各クーポンの表示条件に従います。',
                '3. 未訪問店舗向けクーポンは、利用者が当該店舗で過去にスタンプを獲得していない場合に限り利用できることがあります。',
                '4. クーポンは現金化、払戻し、第三者譲渡できません。',
                '5. クーポン利用に関する店舗との紛争は、利用者と当該店舗の間で解決するものとします。',
              ],
            ),
            _buildSection(
              title: '第9条（料金）',
              text: '利用者向け基本機能の利用料は無料です。ただし、通信費その他の費用は利用者の負担とします。',
            ),
            _buildSection(
              title: '第10条（禁止事項）',
              text: '利用者は、本サービスの利用にあたり、次の行為をしてはなりません。',
              bullets: const [
                '法令または公序良俗に反する行為',
                '虚偽情報登録、なりすまし、アカウントの不正利用',
                'スタンプ、コイン、クーポン、バッジの不正取得・不正利用',
                'QRコードの偽造、複製、解析等の不正行為',
                '本サービスの運営妨害、不正アクセス、過度な負荷を与える行為',
                '他者の権利侵害（知的財産権、プライバシー権、名誉権等）',
                '当社が不適切と判断する行為',
              ],
            ),
            _buildSection(
              title: '第11条（知的財産権）',
              text:
                  '本サービスおよび本サービスに関連する一切の知的財産権は、当社または正当な権利者に帰属します。利用者は、当社の許諾なくこれらを利用できません。',
            ),
            _buildSection(
              title: '第12条（サービスの変更・中断・終了）',
              bullets: const [
                '1. 当社は、必要に応じて本サービスの内容を変更し、または提供を中断・終了できます。',
                '2. システム保守、障害、天災その他やむを得ない事由により、事前通知なく提供を停止する場合があります。',
              ],
            ),
            _buildSection(
              title: '第13条（利用停止・退会）',
              bullets: const [
                '1. 当社は、利用者が本規約に違反した場合、事前通知なく利用停止またはアカウント削除を行えます。',
                '2. 利用者は、当社所定の方法により退会できます。',
                '3. 退会または利用停止時、スタンプ、コイン、クーポン、バッジその他の利用上の地位・権利は消滅します。',
              ],
            ),
            _buildSection(
              title: '第14条（免責）',
              bullets: const [
                '1. 当社は、本サービスに事実上または法律上の瑕疵がないことを保証しません。',
                '2. 当社は、当社の故意または重過失による場合を除き、本サービス利用により利用者に生じた損害について責任を負いません。',
                '3. 加盟店舗が提供する商品・サービスに関する紛争について、当社は責任を負いません。',
              ],
            ),
            _buildSection(
              title: '第15条（個人情報の取扱い）',
              text: '当社は、本サービスに関して取得する個人情報を、別途定めるプライバシーポリシーに従い取り扱います。',
            ),
            _buildSection(
              title: '第16条（規約の変更）',
              text:
                  '当社は、法令改正またはサービス内容変更等に応じて本規約を変更できるものとします。重要な変更時は、アプリ内通知その他相当な方法で周知します。',
            ),
            _buildSection(
              title: '第17条（分離可能性）',
              text: '本規約の一部が無効または執行不能と判断された場合でも、その他の規定は引き続き有効に存続します。',
            ),
            _buildSection(
              title: '第18条（準拠法・管轄）',
              text:
                  '本規約は日本法に準拠し、本サービスに関して紛争が生じた場合、当社所在地を管轄する裁判所を第一審の専属的合意管轄裁判所とします。',
            ),
            _buildSection(
              title: '第19条（事業者情報・お問い合わせ）',
              bullets: const [
                '事業者名: ぐるまっぷ Inc.',
                '代表者: 金子広樹',
                '所在地: 埼玉県川口市芝5-5-13',
                'メール: info@groumapapp.com',
                '公式サイト: https://groumap.com',
              ],
              footerText: 'お問い合わせは、アプリ内のお問い合わせ窓口または上記連絡先までご連絡ください。',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: widget.showConsentButton
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: CustomButton(
                  text: '同意する',
                  onPressed:
                      _canAgree ? () => Navigator.of(context).pop(true) : null,
                  height: 52,
                  backgroundColor: const Color(0xFFFF6B35),
                  textColor: Colors.white,
                  borderRadius: 999,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSection({
    required String title,
    String? text,
    List<String>? bullets,
    String? footerText,
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
          if (footerText != null) ...[
            const SizedBox(height: 8),
            Text(footerText, style: _bodyStyle),
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
