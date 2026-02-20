import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_view.dart';

class UserInfoView extends ConsumerStatefulWidget {
  const UserInfoView({Key? key}) : super(key: key);

  @override
  ConsumerState<UserInfoView> createState() => _UserInfoViewState();
}

class _UserInfoViewState extends ConsumerState<UserInfoView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
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

                if (!_isGoogleUser())
                  const SizedBox(height: 16),

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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: _dayOptions.map((day) {
                          return DropdownMenuItem<int>(
                            value: day,
                            child: Text('$day'),
                          );
                        }).toList(),
                        onChanged: (_selectedYear == null || _selectedMonth == null)
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
    return List.generate(currentYear - 1900 + 1, (index) => currentYear - index);
  }

  List<int> get _monthOptions {
    return List.generate(12, (index) => index + 1);
  }

  List<int> get _dayOptions {
    if (_selectedYear == null || _selectedMonth == null) {
      return [];
    }
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear!, _selectedMonth!);
    return List.generate(daysInMonth, (index) => index + 1);
  }

  void _syncDaySelection() {
    final validDays = _dayOptions;
    if (_selectedDay != null && !validDays.contains(_selectedDay)) {
      _selectedDay = null;
    }
  }

  void _updateSelectedDate() {
    if (_selectedYear != null && _selectedMonth != null && _selectedDay != null) {
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

        await authService.updateUserInfo(userInfo);
        await authService.updateAuthProfile(
          displayName: displayName.isEmpty ? null : displayName,
          photoUrl: null,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationView()),
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
    return currentUser.providerData.any((provider) => provider.providerId == 'google.com');
  }
}
