import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
      appBar: const CommonHeader(title: 'プライバシーポリシー'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ぐるまっぷ（ユーザー向け）プライバシーポリシー', style: _titleStyle),
            const SizedBox(height: 6),
            const Text('制定日: 2025年3月1日', style: _metaStyle),
            const Text('改定日: 2026年2月23日', style: _metaStyle),
            const SizedBox(height: 20),
            _buildSection(
              title: '1. 事業者情報',
              text: '本ポリシーにおける個人情報取扱事業者は、以下のとおりです。',
              bullets: const [
                '事業者名: ぐるまっぷ Inc.',
                '代表者: 金子広樹',
                '所在地: 埼玉県川口市芝5-5-13',
                'サポートメール: info@groumapapp.com',
                '電話サポート: 080-6050-7194（平日 11:00-18:00）',
                '公式サイト: https://groumap.com',
              ],
            ),
            _buildSection(
              title: '2. 適用範囲',
              text:
                  '本ポリシーは、ぐるまっぷ（ユーザー向けアプリおよび関連するWeb機能を含み、以下「本サービス」）において、当社が取得する利用者情報の取扱いに適用されます。',
            ),
            _buildSection(
              title: '3. 取得する情報',
              text: '当社は、本サービスの提供にあたり、次の情報を取得することがあります。',
              bullets: const [
                'アカウント情報: 表示名、ユーザーID、メールアドレス、認証プロバイダ情報',
                'プロフィール情報: プロフィール画像、生年月日、性別、都道府県、市区町村、職業、自己紹介、興味カテゴリ',
                '位置情報: 現在地、店舗との距離算出に必要な位置情報',
                '利用履歴: スタンプ獲得・来店履歴、コイン獲得/消費履歴、クーポン取得/使用履歴、バッジ獲得履歴、ミッション進捗、ランキング関連情報',
                '行動情報: マップ閲覧、店舗詳細閲覧、お気に入り/フォロー、投稿の閲覧/いいね/コメント、レコメンドの表示/クリック',
                '通知関連情報: FCMトークン、通知設定、通知の既読状態',
                'お問い合わせ情報: 問い合わせ内容、返信先情報',
                '端末・ログ情報: IPアドレス、OS、端末識別情報、アクセス日時、エラーログ等',
              ],
            ),
            _buildSection(
              title: '4. 利用目的',
              text: '当社は、取得した情報を以下の目的で利用します。',
              bullets: const [
                '本サービスの提供、維持、改善',
                'スタンプ、コイン、クーポン、バッジ、ミッション、ランキング等の機能提供',
                'マップ表示、周辺店舗表示、レコメンド表示',
                '通知配信、重要なお知らせ、サポート対応',
                '不正利用防止、セキュリティ確保、障害対応',
                '利用状況の分析、統計データ作成、機能改善',
                '法令に基づく対応、権利行使への対応',
              ],
            ),
            _buildSection(
              title: '5. 第三者提供',
              text: '当社は、次の場合を除き、個人情報を第三者に提供しません。',
              bullets: const [
                '利用者本人の同意がある場合',
                '法令に基づく場合',
                '人の生命、身体または財産の保護のために必要な場合',
                '公衆衛生の向上または児童の健全育成の推進のために特に必要な場合',
                '国の機関等への協力が必要な場合',
                '利用目的達成に必要な範囲で業務委託する場合',
              ],
            ),
            _buildSection(
              title: '6. 委託および国外移転',
              text: '当社は、サービス運営に必要な範囲で、個人情報の取扱いを外部事業者に委託します。',
              bullets: const [
                '主な委託先: Google LLC（Firebase/Cloud Firestore/Cloud Functions/Cloud Storage/Cloud Messaging/Authentication など）',
                'これに伴い、利用者情報が外国（例: 米国その他、委託先の提供体制に応じた国・地域）で取り扱われる場合があります。',
              ],
              footerText: '当社は、委託先の選定、契約管理、アクセス制御等により、適切な安全管理措置を講じます。',
            ),
            _buildSection(
              title: '7. 安全管理措置',
              text: '当社は、個人情報の漏えい、滅失または毀損の防止その他の安全管理のため、次の措置を講じます。',
              bullets: const [
                '通信の暗号化（TLS）',
                'アクセス権限管理および認証制御',
                '監査ログの記録と不正アクセス監視',
                '従業員・関係者への必要な教育',
                '脆弱性対応、ライブラリ更新、設定監査',
              ],
            ),
            _buildSection(
              title: '8. 位置情報・通知・Cookie等',
              bullets: const [
                '位置情報は、現在地表示、距離計算、周辺店舗表示、レコメンド等のために利用します。',
                '通知配信のためにFCMトークン等を利用します。通知設定はアプリ内で変更できます。',
                '当社は、利便性向上や分析のためにCookieまたは類似技術（ローカルストレージ等）を利用する場合があります。',
              ],
            ),
            _buildSection(
              title: '9. 保有期間',
              text: '当社は、利用目的に必要な期間、または法令で求められる期間、情報を保有します。',
              bullets: const [
                'コインの有効期限は最終獲得日から180日です。期限到来後のコインは自動失効します。',
                '退会（アカウント削除）時は、サブコレクションおよびプロフィール画像を含む個人情報を原則として削除します。',
                '法令対応・不正対策等に必要な最小限のログは、必要期間保有する場合があります。',
              ],
            ),
            _buildSection(
              title: '10. 利用者の権利',
              text: '利用者は、当社所定の方法により、自己の個人情報について次の請求を行えます。',
              bullets: const [
                '開示',
                '訂正、追加、削除',
                '利用停止、消去',
              ],
              footerText: '請求内容によっては、本人確認のため追加情報の提出をお願いする場合があります。',
            ),
            _buildSection(
              title: '11. 未成年者の利用',
              text: '未成年者が本サービスを利用する場合は、保護者等の法定代理人の同意を得たうえで利用してください。',
            ),
            _buildSection(
              title: '12. ポリシーの変更',
              text:
                  '当社は、法令改正やサービス変更に応じて本ポリシーを改定することがあります。重要な変更を行う場合、アプリ内通知その他の適切な方法で周知します。',
            ),
            _buildSection(
              title: '13. お問い合わせ窓口',
              text: '本ポリシーに関するお問い合わせは、アプリ内お問い合わせ窓口または以下までご連絡ください。',
              bullets: const [
                'メール: info@groumapapp.com',
                '公式サイト: https://groumap.com',
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
