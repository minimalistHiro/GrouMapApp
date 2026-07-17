import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';
import '../../widgets/error_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactView extends StatelessWidget {
  const ContactView({Key? key}) : super(key: key);

  static const _titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const _labelStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF757575),
  );

  static const _valueStyle = TextStyle(
    fontSize: 16,
    height: 1.6,
    color: Color(0xFF424242),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: const Text('お問い合わせ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('お問い合わせ', style: _titleStyle),
            const SizedBox(height: 16),
            _InfoRow(
              label: '電話番号',
              value: '080-6050-7194',
              onTap: () => _launchPhone(context),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'メールアドレス',
              value: 'info@groumapapp.com',
              onTap: () => _launchEmail(context),
            ),
            const SizedBox(height: 12),
            const _InfoRow(
              label: '住所',
              value: '埼玉県川口市芝5-5-13',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '080-6050-7194');
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ErrorDialog.showError(
          context,
          title: '起動できませんでした',
          message: '電話アプリを起動できませんでした。',
        );
      }
    } else if (context.mounted) {
      ErrorDialog.showError(
        context,
        title: '電話機能を利用できません',
        message: 'この端末では電話機能を利用できません。',
      );
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'info@groumapapp.com',
    );
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ErrorDialog.showError(
          context,
          title: '起動できませんでした',
          message: 'メールアプリを起動できませんでした。',
        );
      }
    } else if (context.mounted) {
      ErrorDialog.showError(
        context,
        title: 'メール機能を利用できません',
        message: 'この端末ではメール機能を利用できません。',
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ContactView._labelStyle),
        const SizedBox(height: 4),
        Text(
          value,
          style: ContactView._valueStyle.copyWith(
            color: onTap != null ? const Color(0xFF1E88E5) : ContactView._valueStyle.color,
            decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}
