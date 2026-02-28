import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common_header.dart';
import '../auth/account_deletion_views.dart';
import 'email_support_view.dart';
import 'phone_support_view.dart';
import 'live_chat_view.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(
        title: 'ヘルプ・サポート',
      ),
      backgroundColor: const Color(0xFFFBF6F2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーセクション
            _buildHeaderSection(),

            const SizedBox(height: 24),

            // よくある質問セクション
            _buildFAQSection(context),

            const SizedBox(height: 24),

            // お問い合わせセクション
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_outline,
                size: 28,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ヘルプ・サポート',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'よくある質問やサポート情報をご確認ください',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'スタンプはどうやって獲得できますか？',
        'answer': '来店時にQRコード画面を表示し、店舗スタッフにスキャンしてもらうとスタンプが1個獲得できます。スタンプは来店のたびに累積加算され、10個達成ごとに次のカードへ進みます。',
      },
      {
        'question': 'コインはどうやって貯めますか？',
        'answer': 'デイリーミッション（毎日最大3コイン）、連続ログインボーナス（3日連続+2コイン、7日連続+5コイン、30日連続+10コイン）、来店（スタンプ獲得時+1コイン）などで獲得できます。コインの有効期限は最終獲得日から180日です。',
      },
      {
        'question': 'コインは何に使えますか？',
        'answer': 'コイン10枚で、まだ行ったことのない未訪問店舗限定の100円引きクーポン1枚に交換できます。ミッション画面の「コイン交換」タブから利用できます。コインの現金化・払戻し・譲渡はできません。',
      },
      {
        'question': '新しいお店を見つけるには？',
        'answer': 'マップ画面で近くの店舗を探したり、ホーム画面の「今日のレコメンド」で未訪問のおすすめ店舗を確認できます。お気に入りの店舗をフォローすると、新しいクーポンや投稿があると通知が届きます。',
      },
      {
        'question': 'バッジはどうやって獲得できますか？',
        'answer': '来店・スタンプ達成・連続ログインなど、特定の条件を満たすと自動でバッジが付与されます。全162種のバッジがあり、バッジ一覧画面でカテゴリごとに確認できます。',
      },
      {
        'question': 'ログインできません',
        'answer': 'メールアドレスとパスワードを再確認してください。パスワードを忘れた場合はログイン画面の「パスワードを忘れた方」から再設定をお試しください。',
      },
      {
        'question': '位置情報が取得できません',
        'answer': '端末の設定でアプリの位置情報許可が「アプリの使用中のみ許可」または「常に許可」になっているか確認してください。マップ機能や距離表示に位置情報が必要です。',
      },
    ];

    return _buildSection(
      title: 'よくある質問',
      icon: Icons.quiz,
      children: [
        ...faqs.map((faq) => _buildFAQItem(
              question: faq['question']!,
              answer: faq['answer']!,
            )),
        _buildWithdrawalFAQItem(context),
      ],
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

  Widget _buildWithdrawalFAQItem(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        '退会するには？',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'アカウントを削除（退会）するには、以下のボタンから手続きを行ってください。退会するとすべてのデータが削除され、元に戻すことはできません。',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountDeletionReasonView(),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  '退会するにはこちら',
                  style: TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
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
          subtitle: '080-6050-7194（平日 11:00-18:00）',
          onTap: () => _navigateToPhoneSupport(context),
        ),
        _buildContactItem(
          icon: Icons.chat,
          title: 'ライブチャット',
          subtitle: 'オンラインで質問',
          trailing: _buildLiveChatUnreadTrailing(),
          onTap: () => _navigateToLiveChat(context),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
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
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildLiveChatUnreadTrailing() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final userId = authSnapshot.data?.uid;
        if (userId == null) {
          return const Icon(Icons.chevron_right);
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('messages')
              .where('userId', isEqualTo: userId)
              .where('senderRole', isEqualTo: 'owner')
              .where('readByUserAt', isNull: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Icon(Icons.chevron_right);
            }
            final totalUnread = snapshot.data?.docs.length ?? 0;
            if (totalUnread <= 0) {
              return const Icon(Icons.chevron_right);
            }
            final badgeText = totalUnread > 99 ? '99+' : totalUnread.toString();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            );
          },
        );
      },
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

  void _navigateToLiveChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LiveChatView(),
      ),
    );
  }
}
