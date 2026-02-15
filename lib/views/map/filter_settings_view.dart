import 'package:flutter/material.dart';
import '../../models/map_filter_model.dart';
import '../../services/map_filter_service.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_switch_tile.dart';

class FilterSettingsView extends StatefulWidget {
  final MapFilterModel initialFilter;

  const FilterSettingsView({
    super.key,
    required this.initialFilter,
  });

  @override
  State<FilterSettingsView> createState() => _FilterSettingsViewState();
}

class _FilterSettingsViewState extends State<FilterSettingsView> {
  late MapFilterModel _filter;
  bool _isSaving = false;

  // カテゴリ一覧
  static const List<String> _allCategories = [
    'カフェ・喫茶店',
    'レストラン',
    '居酒屋',
    '和食',
    '日本料理',
    '海鮮',
    '寿司',
    'そば',
    'うどん',
    'うなぎ',
    '焼き鳥',
    'とんかつ',
    '串揚げ',
    '天ぷら',
    'お好み焼き',
    'もんじゃ焼き',
    'しゃぶしゃぶ',
    '鍋',
    '焼肉',
    'ホルモン',
    'ラーメン',
    '中華料理',
    '餃子',
    '韓国料理',
    'タイ料理',
    'カレー',
    '洋食',
    'フレンチ',
    'スペイン料理',
    'ビストロ',
    'パスタ',
    'ピザ',
    'ステーキ',
    'ハンバーグ',
    'ハンバーガー',
    'ビュッフェ',
    '食堂',
    'パン・サンドイッチ',
    'スイーツ',
    'ケーキ',
    'タピオカ',
    'バー・お酒',
    'スナック',
    '料理旅館',
    '沖縄料理',
    'その他',
  ];

  // 開拓状態の選択肢
  static const List<Map<String, String>> _explorationOptions = [
    {'value': 'unvisited', 'label': '未開拓'},
    {'value': 'exploring', 'label': '開拓中'},
    {'value': 'regular', 'label': '常連'},
  ];

  // 決済方法カテゴリの選択肢
  static const List<Map<String, String>> _paymentCategories = [
    {'value': 'cash', 'label': '現金'},
    {'value': 'card', 'label': 'クレジットカード'},
    {'value': 'emoney', 'label': '電子マネー'},
    {'value': 'qr', 'label': 'QR決済'},
  ];

  // 距離の選択肢
  static const List<Map<String, dynamic>> _distanceOptions = [
    {'value': null, 'label': '制限なし'},
    {'value': 0.5, 'label': '500m以内'},
    {'value': 1.0, 'label': '1km以内'},
    {'value': 3.0, 'label': '3km以内'},
    {'value': 5.0, 'label': '5km以内'},
    {'value': 10.0, 'label': '10km以内'},
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  Future<void> _saveFilter() async {
    setState(() => _isSaving = true);
    try {
      await MapFilterService.saveFilter(_filter);
      if (mounted) {
        Navigator.of(context).pop(_filter);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('エラー'),
            content: const Text('フィルター設定の保存に失敗しました。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetFilter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルターをリセット'),
        content: const Text('すべてのフィルター設定を初期状態に戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'リセット',
              style: TextStyle(color: Color(0xFFFF6B35)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      const resetFilter = MapFilterModel();
      await MapFilterService.saveFilter(resetFilter);
      if (mounted) {
        setState(() {
          _filter = resetFilter;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: CommonHeader(
        title: 'フィルター設定',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 営業状況セクション
                _buildSectionCard(
                  title: '営業状況',
                  child: CustomSwitchListTile(
                    title: const Text('営業中のみ表示'),
                    subtitle: const Text(
                      '現在営業中の店舗のみマップに表示します',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _filter.showOpenNowOnly,
                    onChanged: (val) {
                      setState(() {
                        _filter = _filter.copyWith(showOpenNowOnly: val);
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ジャンルセクション
                _buildSectionCard(
                  title: 'ジャンル',
                  subtitle: '複数選択可（未選択は全て表示）',
                  child: _buildCategorySelector(),
                ),

                const SizedBox(height: 12),

                // 開拓状態セクション
                _buildSectionCard(
                  title: '開拓状態',
                  subtitle: '複数選択可（未選択は全て表示）',
                  child: _buildExplorationSelector(),
                ),

                const SizedBox(height: 12),

                // お気に入りセクション
                _buildSectionCard(
                  title: 'お気に入り',
                  child: CustomSwitchListTile(
                    title: const Text('お気に入りのみ表示'),
                    subtitle: const Text(
                      'お気に入り登録した店舗のみマップに表示します',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _filter.favoritesOnly,
                    onChanged: (val) {
                      setState(() {
                        _filter = _filter.copyWith(favoritesOnly: val);
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // 決済方法セクション
                _buildSectionCard(
                  title: '決済方法',
                  subtitle: '対応している決済方法で絞り込み',
                  child: _buildPaymentMethodSelector(),
                ),

                const SizedBox(height: 12),

                // クーポンセクション
                _buildSectionCard(
                  title: 'クーポン',
                  child: Column(
                    children: [
                      CustomSwitchListTile(
                        title: const Text('クーポンあり'),
                        subtitle: const Text(
                          '有効なクーポンがある店舗のみ表示',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        value: _filter.hasCoupon,
                        onChanged: (val) {
                          setState(() {
                            _filter = _filter.copyWith(
                              hasCoupon: val,
                              hasAvailableCoupon:
                                  val ? _filter.hasAvailableCoupon : false,
                            );
                          });
                        },
                      ),
                      CustomSwitchListTile(
                        title: const Text('利用可能クーポンあり'),
                        subtitle: const Text(
                          '現在のスタンプ数で使えるクーポンがある店舗のみ表示',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        value: _filter.hasAvailableCoupon,
                        onChanged: _filter.hasCoupon
                            ? (val) {
                                setState(() {
                                  _filter = _filter.copyWith(
                                      hasAvailableCoupon: val);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 距離セクション
                _buildSectionCard(
                  title: '距離',
                  subtitle: '現在地からの距離で絞り込み',
                  child: _buildDistanceSelector(),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // 下部ボタン
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'リセット',
                    onPressed: _resetFilter,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFFFF6B35),
                    borderColor: const Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: '保存',
                    onPressed: _saveFilter,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final selected = _filter.selectedCategories;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allCategories.map((category) {
          final isSelected = selected.contains(category);
          return GestureDetector(
            onTap: () {
              setState(() {
                final updated = List<String>.from(selected);
                if (isSelected) {
                  updated.remove(category);
                } else {
                  updated.add(category);
                }
                _filter =
                    _filter.copyWith(selectedCategories: updated);
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF6B35)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFFF6B35) : Colors.grey[300]!,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExplorationSelector() {
    final selected = _filter.explorationStatus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: _explorationOptions.map((option) {
          final value = option['value']!;
          final label = option['label']!;
          final isSelected = selected.contains(value);

          IconData icon;
          Color iconColor;
          switch (value) {
            case 'unvisited':
              icon = Icons.radio_button_unchecked;
              iconColor = const Color(0xFFBDBDBD);
              break;
            case 'exploring':
              icon = Icons.radio_button_checked;
              iconColor = const Color(0xFFFB8C00);
              break;
            case 'regular':
              icon = Icons.star;
              iconColor = const Color(0xFFFFB300);
              break;
            default:
              icon = Icons.help_outline;
              iconColor = Colors.grey;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final updated = List<String>.from(selected);
                  if (isSelected) {
                    updated.remove(value);
                  } else {
                    updated.add(value);
                  }
                  _filter =
                      _filter.copyWith(explorationStatus: updated);
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B35).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B35)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: isSelected ? iconColor : Colors.grey, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final selected = _filter.paymentMethodCategories;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _paymentCategories.map((option) {
          final value = option['value']!;
          final label = option['label']!;
          final isSelected = selected.contains(value);

          IconData icon;
          switch (value) {
            case 'cash':
              icon = Icons.payments_outlined;
              break;
            case 'card':
              icon = Icons.credit_card;
              break;
            case 'emoney':
              icon = Icons.contactless;
              break;
            case 'qr':
              icon = Icons.qr_code;
              break;
            default:
              icon = Icons.payment;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                final updated = List<String>.from(selected);
                if (isSelected) {
                  updated.remove(value);
                } else {
                  updated.add(value);
                }
                _filter =
                    _filter.copyWith(paymentMethodCategories: updated);
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF6B35)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF6B35)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistanceSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _distanceOptions.map((option) {
          final double? value = option['value'] as double?;
          final String label = option['label'] as String;
          final bool isSelected = _filter.maxDistanceKm == value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _filter = _filter.copyWith(
                  maxDistanceKm: () => value,
                );
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF6B35)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF6B35)
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
