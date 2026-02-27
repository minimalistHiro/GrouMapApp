import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_settings_provider.dart';
import '../main_navigation_view.dart';
import '../tutorial/tutorial_view.dart';

class UserInfoView extends ConsumerStatefulWidget {
  const UserInfoView({Key? key}) : super(key: key);

  @override
  ConsumerState<UserInfoView> createState() => _UserInfoViewState();
}

class _UserInfoViewState extends ConsumerState<UserInfoView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _friendCodeController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  String? _selectedGender;
  bool _showBirthDateError = false;
  bool _isSubmitting = false;

  final List<String> _genders = ['男性', '女性', 'その他', '回答しない'];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'ja';
    _selectedYear = 2000;
    _selectedMonth = 1;
    _selectedDay = 1;
    _updateSelectedDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _friendCodeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _resolveCurrentSettings(Map<String, dynamic>? settings) {
    final rawCurrent = settings?['current'];
    if (rawCurrent is Map<String, dynamic>) {
      return rawCurrent;
    }
    return settings ?? <String, dynamic>{};
  }

  bool _isFriendCampaignActive(Map<String, dynamic>? settings) {
    if (settings == null) return false;
    final current = _resolveCurrentSettings(settings);
    final startVal = current['friendCampaignStartDate'];
    final endVal = current['friendCampaignEndDate'];
    final start = _parseDateValue(startVal);
    final end = _parseDateValue(endVal);
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return !now.isBefore(start) && !now.isAfter(end);
  }

  DateTime? _parseDateValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ownerSettingsAsync = ref.watch(ownerSettingsProvider);
    final isFriendCampaignActive = ownerSettingsAsync.maybeWhen(
      data: (settings) => _isFriendCampaignActive(settings),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: CommonHeader(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'ユーザー情報入力',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                const Text(
                  'あと少しで完了です！',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '基本情報を入力してアカウントを作成しましょう',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ユーザー名入力（メール/Apple登録時のみ）
                if (!_isGoogleUser())
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'ユーザー名',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ユーザー名を入力してください';
                      }
                      if (value.length < 2) {
                        return 'ユーザー名は2文字以上で入力してください';
                      }
                      return null;
                    },
                  ),

                if (!_isGoogleUser()) const SizedBox(height: 16),

                // 生年月日選択
                const Text(
                  '生年月日',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: '年',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: _yearOptions.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text('$year'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _showBirthDateError = false;
                            _selectedYear = newValue;
                            _syncDaySelection();
                            _updateSelectedDate();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: '月',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: _monthOptions.map((month) {
                          return DropdownMenuItem<int>(
                            value: month,
                            child: Text('$month'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _showBirthDateError = false;
                            _selectedMonth = newValue;
                            _syncDaySelection();
                            _updateSelectedDate();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: '日',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: _dayOptions.map((day) {
                          return DropdownMenuItem<int>(
                            value: day,
                            child: Text('$day'),
                          );
                        }).toList(),
                        onChanged:
                            (_selectedYear == null || _selectedMonth == null)
                                ? null
                                : (int? newValue) {
                                    setState(() {
                                      _showBirthDateError = false;
                                      _selectedDay = newValue;
                                      _updateSelectedDate();
                                    });
                                  },
                      ),
                    ),
                  ],
                ),
                if (_showBirthDateError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      '生年月日を選択してください',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // 性別選択
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: '性別',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: _genders.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '性別を選択してください';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 友達紹介コード入力（キャンペーン期間中のみ表示）
                if (isFriendCampaignActive) ...[
                  CustomTextField(
                    controller: _friendCodeController,
                    labelText: '紹介コード（任意）',
                    hintText: '例: ABC12345',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      '紹介コードを入力すると、初めてお店でスタンプを獲得した際に\nあなたと紹介者の両方にコインが付与されます',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 設定を完了ボタン
                CustomButton(
                  text: '設定を完了',
                  onPressed: _isSubmitting ? null : _handleNext,
                  borderRadius: 999,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<int> get _yearOptions {
    final currentYear = DateTime.now().year;
    return List.generate(
        currentYear - 1900 + 1, (index) => currentYear - index);
  }

  List<int> get _monthOptions {
    return List.generate(12, (index) => index + 1);
  }

  List<int> get _dayOptions {
    if (_selectedYear == null || _selectedMonth == null) {
      return [];
    }
    final daysInMonth =
        DateUtils.getDaysInMonth(_selectedYear!, _selectedMonth!);
    return List.generate(daysInMonth, (index) => index + 1);
  }

  void _syncDaySelection() {
    final validDays = _dayOptions;
    if (_selectedDay != null && !validDays.contains(_selectedDay)) {
      _selectedDay = null;
    }
  }

  void _updateSelectedDate() {
    if (_selectedYear != null &&
        _selectedMonth != null &&
        _selectedDay != null) {
      _selectedDate = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
      _showBirthDateError = false;
    } else {
      _selectedDate = null;
    }
  }

  void _handleNext() async {
    if (_isSubmitting) return;
    if (_selectedDate == null) {
      setState(() {
        _showBirthDateError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('生年月日を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final authService = ref.read(authServiceProvider);
        final currentUser = authService.currentUser;
        final isGoogleUser = _isGoogleUser();
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('先にログインしてください'),
              backgroundColor: Colors.red,
            ),
          );
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
          return;
        }

        final displayName = isGoogleUser
            ? (currentUser.displayName ?? '')
            : _nameController.text.trim();

        final userInfo = <String, dynamic>{
          'displayName': displayName,
          'birthDate': _selectedDate,
          'gender': _selectedGender,
        };

        // 紹介コードが入力されている場合は Firestore に保存
        // Cloud Functions の processFriendReferral トリガーが自動検証・処理する
        final enteredFriendCode = _friendCodeController.text.trim().toUpperCase();
        if (enteredFriendCode.isNotEmpty) {
          userInfo['friendCode'] = enteredFriendCode;
        }

        await authService.updateUserInfo(userInfo);
        await authService.updateAuthProfile(
          displayName: displayName.isEmpty ? null : displayName,
          photoUrl: null,
        );

        // 紹介コードを使って登録した場合、ウェルカムお知らせを作成
        if (enteredFriendCode.isNotEmpty) {
          await _createReferralWelcomeNotification(
            userId: currentUser.uid,
            friendCode: enteredFriendCode,
          );
        }

        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => TutorialView(userId: currentUser.uid),
          ),
        );

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationView()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ユーザー情報の保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _isGoogleUser() {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return false;
    return currentUser.providerData
        .any((provider) => provider.providerId == 'google.com');
  }

  /// 友達紹介コードを使って登録したユーザーへのウェルカムお知らせを作成する
  Future<void> _createReferralWelcomeNotification({
    required String userId,
    required String friendCode,
  }) async {
    try {
      // 紹介者の displayName を取得
      final referrerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: friendCode)
          .limit(1)
          .get();

      String referrerName = '友達';
      if (referrerQuery.docs.isNotEmpty) {
        final data = referrerQuery.docs.first.data();
        referrerName = (data['displayName'] as String?)?.isNotEmpty == true
            ? data['displayName'] as String
            : '友達';
      }

      // owner_settings から付与コイン数を取得
      final ownerSettings = ref.read(ownerSettingsProvider).maybeWhen(
        data: (settings) => _resolveCurrentSettings(settings),
        orElse: () => <String, dynamic>{},
      );
      final inviterCoins = _resolveSettingInt(ownerSettings, 'friendCampaignInviterPoints', 5);
      final inviteeCoins = _resolveSettingInt(ownerSettings, 'friendCampaignInviteePoints', 5);

      final title = '$referrerNameさんの紹介コードで登録完了！';
      final body =
          'お店でスタンプを1つ獲得すると、$referrerNameさんに${inviterCoins}コイン・あなたに${inviteeCoins}コインがプレゼントされます！\n\n'
          '【コイン獲得までの手順】\n'
          '① ホーム画面のマップやレコメンドでお近くのお店を探す\n'
          '② お店でアプリのQRコードを提示してスタンプをもらう\n'
          '③ 初めてスタンプを獲得した瞬間、$referrerNameさんと双方にコインが付与されます！\n\n'
          '獲得したコインは「10コイン＝未訪問店舗100円引きクーポン1枚」と交換できます。\n'
          'さっそくお近くのお店に行ってみましょう！';

      final notifRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();

      await notifRef.set({
        'id': notifRef.id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'social',
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'isDelivered': true,
        'data': {
          'referrerName': referrerName,
          'inviterCoins': inviterCoins,
          'inviteeCoins': inviteeCoins,
          'friendCode': friendCode,
        },
        'tags': ['referral', 'welcome'],
      });
    } catch (e) {
      // 通知作成失敗は登録フローをブロックしない
      debugPrint('友達紹介ウェルカムお知らせの作成に失敗しました: $e');
    }
  }

  int _resolveSettingInt(Map<String, dynamic> settings, String key, int fallback) {
    final value = settings[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
