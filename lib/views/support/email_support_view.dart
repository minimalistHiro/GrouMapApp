import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/error_dialog.dart';

class EmailSupportView extends ConsumerStatefulWidget {
  const EmailSupportView({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailSupportView> createState() => _EmailSupportViewState();
}

class _EmailSupportViewState extends ConsumerState<EmailSupportView> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedCategory = 'その他';
  bool _isLoading = false;
  
  final List<String> _categories = [
    'QRコードスキャンについて',
    '店舗情報の変更',
    'クーポン作成',
    'ポイント付与',
    'アカウント設定',
    '支払い・請求',
    'アプリの不具合',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user != null) {
      if ((user.email ?? '').isNotEmpty) {
        _emailController.text = user.email!;
      }
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists && mounted) {
        final email = userDoc.data()?['email'] as String?;
        if (email != null) {
          _emailController.text = email;
        }
      }
    }
  }

  Future<void> _submitSupport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      
      // お問い合わせ内容をFirestoreに保存
      await FirebaseFirestore.instance.collection('support_requests').add({
        'userId': user?.uid ?? 'anonymous',
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'email': _emailController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // メール送信
      await _sendEmail();

      if (mounted) {
        // 成功ダイアログを表示
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text('送信完了'),
              ],
            ),
            content: const Text(
              'お問い合わせを受け付けました。\n担当者より24時間以内にご連絡いたします。',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // フォーム画面も閉じる
                },
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context,
          title: '送信に失敗しました',
          message: '時間をおいて再度お試しください。',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendEmail() async {
    final subject = Uri.encodeComponent('[お問い合わせ] ${_subjectController.text.trim()}');
    final body = Uri.encodeComponent(
      'カテゴリ: $_selectedCategory\n'
      '件名: ${_subjectController.text.trim()}\n'
      '返信先: ${_emailController.text.trim()}\n\n'
      '---お問い合わせ内容---\n'
      '${_messageController.text.trim()}\n\n'
      '---\n'
      'このメールはGroumapアプリのお問い合わせフォームから送信されました。'
    );
    
    final emailUrl = Uri.parse('mailto:info@groumapapp.com?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
      } else {
        print('メールクライアントを開けませんでした');
      }
    } catch (e) {
      print('メール送信エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null && previous?.value?.uid != next.value?.uid) {
        _loadUserEmail();
      }
    });
    return Scaffold(
      appBar: const CommonHeader(
        title: 'メールサポート',
      ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          DismissKeyboard(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー情報
                    _buildHeaderCard(),
                    
                    const SizedBox(height: 24),
                    
                    // お問い合わせフォーム
                    _buildFormCard(),
                    
                    const SizedBox(height: 24),
                    
                    // 送信ボタン
                    _buildSubmitButton(),
                    
                    const SizedBox(height: 16),
                    
                    // 注意事項
                    _buildNoticeCard(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
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
                Icons.email_outlined,
                size: 26,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'お問い合わせフォーム',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'ご質問やご要望をお寄せください\n24時間以内に返信いたします',
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

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリ選択
          const Text(
            'お問い合わせカテゴリ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.category, size: 20),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // メールアドレス
          const Text(
            'メールアドレス',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'your.email@example.com',
              prefixIcon: const Icon(Icons.email, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'メールアドレスを入力してください';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return '有効なメールアドレスを入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // 件名
          const Text(
            '件名',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectController,
            decoration: InputDecoration(
              hintText: 'お問い合わせの件名を入力',
              prefixIcon: const Icon(Icons.title, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '件名を入力してください';
              }
              if (value.trim().length < 5) {
                return '件名は5文字以上で入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // メッセージ
          const Text(
            'お問い合わせ内容',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'お問い合わせ内容を詳しくご記入ください',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 8,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'お問い合わせ内容を入力してください';
              }
              if (value.trim().length < 10) {
                return 'お問い合わせ内容は10文字以上で入力してください';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: '送信する',
      height: 48,
      borderRadius: 999,
      isLoading: _isLoading,
      onPressed: _submitSupport,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFFFF6B35),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'ご注意',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• 回答には最大24時間かかる場合があります\n'
            '• 緊急のご用件は電話サポートをご利用ください\n'
            '• セキュリティ上、パスワード等の情報は記載しないでください',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
