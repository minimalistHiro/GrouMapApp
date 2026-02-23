import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../services/mission_service.dart';

class InterestCategoryView extends ConsumerStatefulWidget {
  const InterestCategoryView({Key? key}) : super(key: key);

  @override
  ConsumerState<InterestCategoryView> createState() => _InterestCategoryViewState();
}

class _InterestCategoryViewState extends ConsumerState<InterestCategoryView> {
  List<String> _selectedCategories = [];
  bool _isLoading = true;
  bool _isSaving = false;

  static const List<String> _allCategories = [
    'カフェ・喫茶店', 'レストラン', '居酒屋', '和食', '日本料理',
    '海鮮', '寿司', 'そば', 'うどん', 'うなぎ',
    '焼き鳥', 'とんかつ', '串揚げ', '天ぷら',
    'お好み焼き', 'もんじゃ焼き', 'しゃぶしゃぶ', '鍋',
    '焼肉', 'ホルモン', 'ラーメン', '中華料理', '餃子',
    '韓国料理', 'タイ料理', 'カレー', '洋食', 'フレンチ',
    'スペイン料理', 'ビストロ', 'パスタ', 'ピザ',
    'ステーキ', 'ハンバーグ', 'ハンバーガー',
    'ビュッフェ', '食堂', 'パン・サンドイッチ',
    'スイーツ', 'ケーキ', 'タピオカ',
    'バー・お酒', 'スナック', '料理旅館', '沖縄料理', 'その他',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentCategories();
  }

  Future<void> _loadCurrentCategories() async {
    try {
      final authService = ref.read(authServiceProvider);
      final doc = await authService.getUserInfo();
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final interests = data['interestCategories'];
        if (interests is List) {
          _selectedCategories = interests.cast<String>().toList();
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      await ref.read(authServiceProvider).updateUserInfo({
        'interestCategories': _selectedCategories,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // プロフィール完成ミッション判定（全項目が揃った場合）
      if (user != null && _selectedCategories.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          final displayName = (data['displayName'] as String?) ?? '';
          final hasBasicProfile = displayName.isNotEmpty &&
              data['birthDate'] != null &&
              (data['gender'] as String?)?.isNotEmpty == true &&
              (data['prefecture'] as String?)?.isNotEmpty == true &&
              (data['city'] as String?)?.isNotEmpty == true &&
              (data['occupation'] as String?)?.isNotEmpty == true &&
              (data['bio'] as String?)?.trim().isNotEmpty == true &&
              (data['profileImageUrl'] as String?)?.isNotEmpty == true;
          if (hasBasicProfile) {
            MissionService().markRegistrationMission(user.uid, 'profile_completed');
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('興味カテゴリを更新しました'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '興味カテゴリ設定'),
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'あなたの興味のあるカテゴリを選んでください',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'あなたに合ったお店が見つかりやすくなります',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _allCategories.map((category) {
                            final isSelected = _selectedCategories.contains(category);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCategories.remove(category);
                                  } else {
                                    _selectedCategories.add(category);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: '保存',
                        onPressed: _isSaving ? null : _save,
                        isLoading: _isSaving,
                        backgroundColor: const Color(0xFFFF6B35),
                        textColor: Colors.white,
                        borderRadius: 999,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
