import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../legal/privacy_policy_view.dart';
import '../legal/terms_view.dart';
import 'sign_up_view.dart';

class TermsPrivacyConsentView extends StatefulWidget {
  const TermsPrivacyConsentView({super.key});

  @override
  State<TermsPrivacyConsentView> createState() =>
      _TermsPrivacyConsentViewState();
}

class _TermsPrivacyConsentViewState extends State<TermsPrivacyConsentView> {
  bool _agreed = false;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIntroBlock(),
                      const SizedBox(height: 12),
                      _LegalLinkCard(
                        icon: Icons.description_outlined,
                        title: '利用規約',
                        description: 'サービス利用条件を確認',
                        onTap: _openTerms,
                      ),
                      const SizedBox(height: 10),
                      _LegalLinkCard(
                        icon: Icons.privacy_tip_outlined,
                        title: 'プライバシーポリシー',
                        description: '個人情報の取り扱いを確認',
                        onTap: _openPrivacyPolicy,
                      ),
                      const SizedBox(height: 14),
                      _buildAgreementCard(),
                      const SizedBox(height: 10),
                      const Text(
                        '「同意して新規アカウント作成へ」を押すと同意したものとみなされます',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF616161),
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: CustomButton(
            text: '同意して新規アカウント作成へ',
            onPressed: _agreed ? _goToSignUp : null,
            height: 52,
            backgroundColor: const Color(0xFFFF6B35),
            textColor: Colors.white,
            borderRadius: 999,
          ),
        ),
      ),
    );
  }

  Widget _buildIntroBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アカウント作成前に2つの文書をご確認ください',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '各カードをタップすると、最新の内容を確認できます。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: _agreed,
        activeColor: const Color(0xFFFF6B35),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: const Text(
          '利用規約およびプライバシーポリシーに同意します',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        onChanged: (checked) {
          setState(() {
            _agreed = checked ?? false;
          });
        },
      ),
    );
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsView(),
      ),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyView(),
      ),
    );
  }

  void _goToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignUpView(),
      ),
    );
  }
}

class _LegalLinkCard extends StatelessWidget {
  const _LegalLinkCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF757575),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
