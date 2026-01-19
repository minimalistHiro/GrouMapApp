import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'privacy_policy_view.dart';
import 'terms_of_service_view.dart';
import 'email_support_view.dart';
import 'phone_support_view.dart';

class HelpView extends StatelessWidget {
  const HelpView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ・サポート'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーセクション
            _buildHeaderSection(),
            
            const SizedBox(height: 24),
            
            // よくある質問セクション
            _buildFAQSection(),
            
            const SizedBox(height: 24),
            
            // お問い合わせセクション
            _buildContactSection(context),
            
            const SizedBox(height: 24),
            
            // アプリ情報セクション
            _buildAppInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.help_outline,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'ヘルプ・サポート',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'よくある質問やサポート情報をご確認ください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'ポイントはどこで貯められますか？',
        'answer': 'GrouMap加盟店でのお会計時にポイントが付与されます。店舗スタッフの案内に従ってください。',
      },
      {
        'question': 'ポイントはどうやって使いますか？',
        'answer': '加盟店でのお会計時にポイント利用をお伝えください。利用上限がある場合は店舗のルールに従います。',
      },
      {
        'question': '新しいお店を見つけるには？',
        'answer': 'マップ画面で近くの店舗を探したり、投稿・クーポンをチェックして気になるお店を見つけられます。',
      },
      {
        'question': 'バッジはどうやって獲得できますか？',
        'answer': '複数店舗の利用や特定の条件を満たすことでバッジが獲得できます。条件はバッジ詳細をご確認ください。',
      },
      {
        'question': 'ログインできません',
        'answer': 'メールアドレスとパスワードを再確認してください。パスワードを忘れた場合は再設定をお試しください。',
      },
      {
        'question': '位置情報が取得できません',
        'answer': '端末の位置情報設定と、アプリの位置情報許可がオンになっているか確認してください。',
      },
    ];

    return _buildSection(
      title: 'よくある質問',
      icon: Icons.quiz,
      children: faqs.map((faq) => _buildFAQItem(
        question: faq['question']!,
        answer: faq['answer']!,
      )).toList(),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return _buildSection(
      title: 'お問い合わせ',
      icon: Icons.contact_support,
      children: [
        _buildContactItem(
          icon: Icons.email,
          title: 'メールサポート',
          subtitle: 'お問い合わせフォームを開く',
          onTap: () => _navigateToEmailSupport(context),
        ),
        _buildContactItem(
          icon: Icons.phone,
          title: '電話サポート',
          subtitle: '080-6050-7194（平日 9:00-18:00）',
          onTap: () => _navigateToPhoneSupport(context),
        ),
        _buildContactItem(
          icon: Icons.chat,
          title: 'ライブチャット',
          subtitle: 'オンラインで質問',
          onTap: () => _showChatDialog(),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFF6B35),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return _buildSection(
      title: 'アプリ情報',
      icon: Icons.info,
      children: [
        _buildInfoItem(
          label: 'アプリバージョン',
          value: '1.0.0',
          copyable: false,
        ),
        _buildInfoItem(
          label: '最終更新日',
          value: '2024年12月',
          copyable: false,
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required bool copyable,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: copyable
          ? IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyToClipboard(value),
            )
          : onTap != null
              ? const Icon(Icons.chevron_right)
              : null,
      onTap: onTap,
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _navigateToEmailSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailSupportView(),
      ),
    );
  }

  void _navigateToPhoneSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PhoneSupportView(),
      ),
    );
  }

  void _showChatDialog() {
    // ライブチャットのダイアログを表示
    // 実際のアプリではチャット機能を実装
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // コピー完了のスナックバーを表示
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyView(),
      ),
    );
  }

  void _navigateToTermsOfService(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceView(),
      ),
    );
  }
}
