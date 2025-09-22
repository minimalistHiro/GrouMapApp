import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String category;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.isUnlocked,
    this.unlockedAt,
    required this.category,
  });
}

class BadgesView extends ConsumerStatefulWidget {
  const BadgesView({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgesView> createState() => _BadgesViewState();
}

class _BadgesViewState extends ConsumerState<BadgesView> {
  String _selectedCategory = 'すべて';
  final List<String> _categories = [
    'すべて',
    '基礎バッジ',
    'ジャンル別バッジ',
  ];
  
  // バッジのロック状態を管理するMap
  final Map<String, bool> _badgeUnlockStates = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('バッジ一覧'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // カテゴリフィルター
          _buildCategoryFilter(),
          
          // バッジグリッド
          Expanded(
            child: _buildBadgeGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFFFF6B35).withOpacity(0.2),
              checkmarkColor: const Color(0xFFFF6B35),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeGrid() {
    final badges = _generateSampleBadges();
    final filteredBadges = _selectedCategory == 'すべて'
        ? badges
        : badges.where((badge) => badge.category == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: filteredBadges.length,
        itemBuilder: (context, index) {
          final badge = filteredBadges[index];
          return _buildBadgeCard(badge);
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    // 現在のロック状態を取得（デフォルトはbadge.isUnlocked）
    final isCurrentlyUnlocked = _badgeUnlockStates[badge.id] ?? badge.isUnlocked;
    
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // バッジアイコン
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isCurrentlyUnlocked 
                    ? const Color(0xFFFF6B35).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: isCurrentlyUnlocked
                    ? null
                    : Border.all(
                        color: Colors.grey,
                        width: 2,
                      ),
              ),
              child: _getBadgeIcon(
                badge.iconPath,
                isUnlocked: isCurrentlyUnlocked,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // バッジ名
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isCurrentlyUnlocked ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // ロック状態
            if (!isCurrentlyUnlocked)
              const Icon(
                Icons.lock,
                size: 12,
                color: Colors.grey,
              )
            else
              const Icon(
                Icons.check_circle,
                size: 12,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _getBadgeIcon(String iconPath, {bool isUnlocked = true, double size = 24}) {
    // アンロック状態に応じて表示を切り替え
    if (!isUnlocked) {
      return Icon(
        Icons.lock,
        size: size,
        color: Colors.grey,
      );
    }
    
    // 画像ファイルパスに基づいてアイコンを返す
    return Image.asset(
      'assets/images/badges/$iconPath',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // デバッグ用にエラーをコンソールに出力
        print('画像読み込みエラー: assets/images/badges/$iconPath - $error');
        return Icon(
          Icons.star,
          size: size,
          color: isUnlocked ? const Color(0xFFFF6B35) : Colors.grey,
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge) {
    // 現在のロック状態を取得
    final isCurrentlyUnlocked = _badgeUnlockStates[badge.id] ?? badge.isUnlocked;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: isCurrentlyUnlocked 
                        ? const Color(0xFFFF6B35).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(150),
                    border: isCurrentlyUnlocked
                        ? null
                        : Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                  ),
                  child: _getBadgeIcon(
                    badge.iconPath,
                    isUnlocked: isCurrentlyUnlocked,
                    size: 144,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                badge.category,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // テストボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _unlockBadge(badge);
                      setState(() {
                        _badgeUnlockStates[badge.id] = true;
                      });
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('アンロック'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _lockBadge(badge);
                      setState(() {
                        _badgeUnlockStates[badge.id] = false;
                      });
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text('ロック'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 現在の状態表示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentlyUnlocked 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentlyUnlocked 
                        ? Colors.green
                        : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCurrentlyUnlocked ? Icons.check_circle : Icons.lock,
                      size: 20,
                      color: isCurrentlyUnlocked ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCurrentlyUnlocked ? 'アンロック済み' : 'ロック中',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCurrentlyUnlocked ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((category) {
            return ListTile(
              title: Text(category),
              leading: Radio<String>(
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  List<BadgeModel> _generateSampleBadges() {
    final badges = <BadgeModel>[];
    final now = DateTime.now();
    
    // 基礎バッジ（16個）
    badges.addAll([
      BadgeModel(
        id: 'hajime_no_ippo',
        name: 'はじめの一歩',
        description: '初めてチェックイン',
        iconPath: 'hajimenoippo_badge_icon.png',
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 30)),
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'san_shoku_course',
        name: '一日三食コース',
        description: '同日に3回利用',
        iconPath: 'san_shoku_course_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'jimoto_ouendan',
        name: '地元応援団',
        description: '同じ店舗に10回来店',
        iconPath: 'jimoto_ouendan_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'hashigo_master',
        name: 'はしごの達人',
        description: '同じ日に2店舗以上で利用',
        iconPath: 'hashigo_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'bouken_sha',
        name: '冒険者',
        description: '2市以上で利用',
        iconPath: 'bouken_sha_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'hayaoki_san',
        name: '早起きさん',
        description: '朝7〜9時に来店',
        iconPath: 'hayaoki_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'yorufukashi_gourmet',
        name: '夜更かしグルメ',
        description: '22時以降に来店',
        iconPath: 'yorufukashi_gourmet_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'weekend_star',
        name: '週末の主役',
        description: '土日連続で来店',
        iconPath: 'weekend_star_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'weekday_lunch_king',
        name: '平日ランチ王',
        description: '平日昼（11〜14時）5回利用',
        iconPath: 'weekday_lunch_king_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'summer_gourmet_trip',
        name: '夏のグルメ旅',
        description: '夏に来店（7〜8月）',
        iconPath: 'summer_gourmet_trip_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'shinshun_start_dash',
        name: '新春スタートダッシュ',
        description: '1月に来店',
        iconPath: 'shinshun_start_dash_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'anniv_half',
        name: 'ハーフアニバーサリー',
        description: 'サービス開始半年で来店',
        iconPath: 'anniv_half_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'anniv_1yr',
        name: '1周年記念',
        description: 'サービス開始1周年で来店',
        iconPath: 'anniv_1yr_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'anniv_2yr',
        name: '2周年記念',
        description: 'サービス開始2周年で来店',
        iconPath: 'anniv_2yr_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'event_participant',
        name: 'イベント参加者',
        description: '店舗イベントで来店',
        iconPath: 'event_participant_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
      BadgeModel(
        id: 'himitsu_joren',
        name: '秘密の常連',
        description: '15〜16時に利用',
        iconPath: 'himitsu_joren_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: '基礎バッジ',
      ),
    ]);
    
    // ジャンル別バッジ（レストラン/カフェ/居酒屋/ファストフード/ラーメン/寿司/焼肉/スイーツ/パン/バー）
    badges.addAll([
      // レストラン系
      BadgeModel(
        id: 'restaurant_debut',
        name: 'レストランデビュー',
        description: 'レストランを初めて利用',
        iconPath: 'restaurant_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'restaurant_hunter',
        name: 'レストランハンター',
        description: 'レストランを3店舗利用',
        iconPath: 'restaurant_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'restaurant_master',
        name: 'レストランマスター',
        description: 'レストランを10店舗利用',
        iconPath: 'restaurant_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'restaurant_complete',
        name: 'レストランコンプリート',
        description: 'レストランを30店舗利用',
        iconPath: 'restaurant_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // カフェ系
      BadgeModel(
        id: 'cafe_debut',
        name: 'カフェデビュー',
        description: 'カフェを初めて利用',
        iconPath: 'cafe_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'cafe_hunter',
        name: 'カフェハンター',
        description: 'カフェを3店舗利用',
        iconPath: 'cafe_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'cafe_master',
        name: 'カフェマスター',
        description: 'カフェを10店舗利用',
        iconPath: 'cafe_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'cafe_complete',
        name: 'カフェコンプリート',
        description: 'カフェを30店舗利用',
        iconPath: 'cafe_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // 居酒屋系
      BadgeModel(
        id: 'izakaya_debut',
        name: '居酒屋デビュー',
        description: '居酒屋を初めて利用',
        iconPath: 'izakaya_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'izakaya_hunter',
        name: '居酒屋ハンター',
        description: '居酒屋を3店舗利用',
        iconPath: 'izakaya_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'izakaya_master',
        name: '居酒屋マスター',
        description: '居酒屋を10店舗利用',
        iconPath: 'izakaya_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'izakaya_complete',
        name: '居酒屋コンプリート',
        description: '居酒屋を30店舗利用',
        iconPath: 'izakaya_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // ファストフード系
      BadgeModel(
        id: 'fastfood_debut',
        name: 'ファストフードデビュー',
        description: 'ファストフードを初めて利用',
        iconPath: 'fastfood_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'fastfood_hunter',
        name: 'ファストフードハンター',
        description: 'ファストフードを3店舗利用',
        iconPath: 'fastfood_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'fastfood_master',
        name: 'ファストフードマスター',
        description: 'ファストフードを10店舗利用',
        iconPath: 'fastfood_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'fastfood_complete',
        name: 'ファストフードコンプリート',
        description: 'ファストフードを30店舗利用',
        iconPath: 'fastfood_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // ラーメン系
      BadgeModel(
        id: 'ramen_debut',
        name: 'ラーメンデビュー',
        description: 'ラーメン屋を初めて利用',
        iconPath: 'ramen_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'ramen_hunter',
        name: 'ラーメンハンター',
        description: 'ラーメン屋を3店舗利用',
        iconPath: 'restaurant_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'ramen_master',
        name: 'ラーメンマスター',
        description: 'ラーメン屋を10店舗利用',
        iconPath: 'restaurant_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'ramen_complete',
        name: 'ラーメンコンプリート',
        description: 'ラーメン屋を30店舗利用',
        iconPath: 'restaurant_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // 寿司系
      BadgeModel(
        id: 'sushi_debut',
        name: '寿司デビュー',
        description: '寿司屋を初めて利用',
        iconPath: 'sushi_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'sushi_hunter',
        name: '寿司ハンター',
        description: '寿司屋を3店舗利用',
        iconPath: 'sushi_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'sushi_master',
        name: '寿司マスター',
        description: '寿司屋を10店舗利用',
        iconPath: 'sushi_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'sushi_complete',
        name: '寿司コンプリート',
        description: '寿司屋を30店舗利用',
        iconPath: 'sushi_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // 焼肉系
      BadgeModel(
        id: 'yakiniku_debut',
        name: '焼肉デビュー',
        description: '焼肉店を初めて利用',
        iconPath: 'yakiniku_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'yakiniku_hunter',
        name: '焼肉ハンター',
        description: '焼肉店を3店舗利用',
        iconPath: 'yakiniku_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'yakiniku_master',
        name: '焼肉マスター',
        description: '焼肉店を10店舗利用',
        iconPath: 'yakiniku_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'yakiniku_complete',
        name: '焼肉コンプリート',
        description: '焼肉店を30店舗利用',
        iconPath: 'yakiniku_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // スイーツ系
      BadgeModel(
        id: 'sweets_debut',
        name: 'スイーツデビュー',
        description: 'スイーツ店を初めて利用',
        iconPath: 'sweets_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'sweets_hunter',
        name: 'スイーツハンター',
        description: 'スイーツ店を3店舗利用',
        iconPath: 'sweets_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'sweets_master',
        name: 'スイーツマスター',
        description: 'スイーツ店を10店舗利用',
        iconPath: 'sweets_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'sweets_complete',
        name: 'スイーツコンプリート',
        description: 'スイーツ店を30店舗利用',
        iconPath: 'sweets_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // パン系
      BadgeModel(
        id: 'bread_debut',
        name: 'パンデビュー',
        description: 'パン屋を初めて利用',
        iconPath: 'bread_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'bread_hunter',
        name: 'パンハンター',
        description: 'パン屋を3店舗利用',
        iconPath: 'bread_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'bread_master',
        name: 'パンマスター',
        description: 'パン屋を10店舗利用',
        iconPath: 'bread_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'bread_complete',
        name: 'パンコンプリート',
        description: 'パン屋を30店舗利用',
        iconPath: 'bread_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),

      // バー系
      BadgeModel(
        id: 'bar_debut',
        name: 'バーデビュー',
        description: 'バーを初めて利用',
        iconPath: 'bar_debut_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'bar_hunter',
        name: 'バーハンター',
        description: 'バーを3店舗利用',
        iconPath: 'bar_hunter_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'bar_master',
        name: 'バーマスター',
        description: 'バーを10店舗利用',
        iconPath: 'bar_master_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
      BadgeModel(
        id: 'bar_complete',
        name: 'バーコンプリート',
        description: 'バーを30店舗利用',
        iconPath: 'bar_complete_badge_icon.png',
        isUnlocked: false,
        unlockedAt: null,
        category: 'ジャンル別バッジ',
      ),
    ]);
    
    return badges;
  }

  // Firestore: バッジを付与（user_badges/{userId}/badges/{badgeId}）
  Future<void> _unlockBadge(BadgeModel badge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です')),
        );
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      final ref = firestore
          .collection('user_badges')
          .doc(user.uid)
          .collection('badges')
          .doc(badge.id);

      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'userId': user.uid,
          'badgeId': badge.id,
          'unlockedAt': FieldValue.serverTimestamp(),
          'progress': 1,
          'requiredValue': 1,
          'isNew': true,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バッジを保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  // Firestore: バッジを削除（ロックに戻す）user_badges/{userId}/badges/{badgeId}
  Future<void> _lockBadge(BadgeModel badge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です')),
        );
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      final ref = firestore
          .collection('user_badges')
          .doc(user.uid)
          .collection('badges')
          .doc(badge.id);
      await ref.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バッジを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }
}
