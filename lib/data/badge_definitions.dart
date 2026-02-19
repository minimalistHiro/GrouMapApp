import '../models/badge_model.dart';

/// カテゴリグループマッピング（カテゴリ別来店バッジ用）
const Map<String, List<String>> kCategoryGroupMap = {
  'cafe_sweets': ['カフェ・喫茶店', 'スイーツ', 'ケーキ', 'タピオカ', 'パン・サンドイッチ'],
  'washoku': ['和食', '日本料理', '海鮮', '寿司', 'そば', 'うどん', 'うなぎ', '天ぷら'],
  'izakaya_bar': ['居酒屋', 'バー・お酒', 'スナック'],
  'yakitori_age': ['焼き鳥', 'とんかつ', '串揚げ', 'お好み焼き', 'もんじゃ焼き'],
  'nabe_yakiniku': ['しゃぶしゃぶ', '鍋', '焼肉', 'ホルモン'],
  'ramen_chinese': ['ラーメン', '中華料理', '餃子'],
  'asian_ethnic': ['韓国料理', 'タイ料理', 'カレー', '沖縄料理'],
  'western_french': ['レストラン', '洋食', 'フレンチ', 'スペイン料理', 'ビストロ'],
  'italian_meat': ['パスタ', 'ピザ', 'ステーキ', 'ハンバーグ', 'ハンバーガー'],
  'shokudo_other': ['ビュッフェ', '食堂', '料理旅館', 'その他'],
};

/// アプリ内蔵バッジ定義（全141個）
/// バッジ画像は assets/images/badges/{badgeId}.png に配置
const List<BadgeModel> kBadgeDefinitions = [
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // スタンプ（stampsTotal）15個
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  BadgeModel(badgeId: 'stamps_total_1', name: 'はじめてのスタンプ', description: 'スタンプを1個集める', iconUrl: 'stamps_total_1.png', type: BadgeType.stampsTotal, requiredValue: 1, rarity: BadgeRarity.common, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_3', name: 'スタンプビギナー', description: 'スタンプを3個集める', iconUrl: 'stamps_total_3.png', type: BadgeType.stampsTotal, requiredValue: 3, rarity: BadgeRarity.common, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_5', name: 'スタンプルーキー', description: 'スタンプを5個集める', iconUrl: 'stamps_total_5.png', type: BadgeType.stampsTotal, requiredValue: 5, rarity: BadgeRarity.common, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_10', name: 'スタンプコレクター', description: 'スタンプを10個集める', iconUrl: 'stamps_total_10.png', type: BadgeType.stampsTotal, requiredValue: 10, rarity: BadgeRarity.common, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_20', name: 'スタンプハンター', description: 'スタンプを20個集める', iconUrl: 'stamps_total_20.png', type: BadgeType.stampsTotal, requiredValue: 20, rarity: BadgeRarity.rare, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_30', name: 'スタンプシーカー', description: 'スタンプを30個集める', iconUrl: 'stamps_total_30.png', type: BadgeType.stampsTotal, requiredValue: 30, rarity: BadgeRarity.rare, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_50', name: 'スタンプマスター', description: 'スタンプを50個集める', iconUrl: 'stamps_total_50.png', type: BadgeType.stampsTotal, requiredValue: 50, rarity: BadgeRarity.rare, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_75', name: 'スタンプベテラン', description: 'スタンプを75個集める', iconUrl: 'stamps_total_75.png', type: BadgeType.stampsTotal, requiredValue: 75, rarity: BadgeRarity.rare, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_100', name: 'スタンプエリート', description: 'スタンプを100個集める', iconUrl: 'stamps_total_100.png', type: BadgeType.stampsTotal, requiredValue: 100, rarity: BadgeRarity.epic, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_150', name: 'スタンプチャンピオン', description: 'スタンプを150個集める', iconUrl: 'stamps_total_150.png', type: BadgeType.stampsTotal, requiredValue: 150, rarity: BadgeRarity.epic, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_200', name: 'スタンプエキスパート', description: 'スタンプを200個集める', iconUrl: 'stamps_total_200.png', type: BadgeType.stampsTotal, requiredValue: 200, rarity: BadgeRarity.epic, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_300', name: 'スタンプグランドマスター', description: 'スタンプを300個集める', iconUrl: 'stamps_total_300.png', type: BadgeType.stampsTotal, requiredValue: 300, rarity: BadgeRarity.epic, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_500', name: 'スタンプレジェンド', description: 'スタンプを500個集める', iconUrl: 'stamps_total_500.png', type: BadgeType.stampsTotal, requiredValue: 500, rarity: BadgeRarity.legendary, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_750', name: 'スタンプゴッド', description: 'スタンプを750個集める', iconUrl: 'stamps_total_750.png', type: BadgeType.stampsTotal, requiredValue: 750, rarity: BadgeRarity.legendary, category: 'スタンプ'),
  BadgeModel(badgeId: 'stamps_total_1000', name: 'スタンプキング', description: 'スタンプを1000個集める', iconUrl: 'stamps_total_1000.png', type: BadgeType.stampsTotal, requiredValue: 1000, rarity: BadgeRarity.legendary, category: 'スタンプ'),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 来店（visitsCount）4個
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  BadgeModel(badgeId: 'visits_count_common', name: 'はじめての常連', description: '5回来店する', iconUrl: 'visits_count_common.png', type: BadgeType.visitsCount, requiredValue: 5, rarity: BadgeRarity.common, category: '来店'),
  BadgeModel(badgeId: 'visits_count_rare', name: 'おなじみさん', description: '20回来店する', iconUrl: 'visits_count_rare.png', type: BadgeType.visitsCount, requiredValue: 20, rarity: BadgeRarity.rare, category: '来店'),
  BadgeModel(badgeId: 'visits_count_epic', name: '街の探検家', description: '50回来店する', iconUrl: 'visits_count_epic.png', type: BadgeType.visitsCount, requiredValue: 50, rarity: BadgeRarity.epic, category: '来店'),
  BadgeModel(badgeId: 'visits_count_legendary', name: 'レジェンドビジター', description: '100回来店する', iconUrl: 'visits_count_legendary.png', type: BadgeType.visitsCount, requiredValue: 100, rarity: BadgeRarity.legendary, category: '来店'),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 連続ログイン（consecutiveDays）4個
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  BadgeModel(badgeId: 'consecutive_days_common', name: '3日坊主突破', description: '3日連続ログインする', iconUrl: 'consecutive_days_common.png', type: BadgeType.consecutiveDays, requiredValue: 3, rarity: BadgeRarity.common, category: '連続ログイン'),
  BadgeModel(badgeId: 'consecutive_days_rare', name: 'ウィークリーチャンプ', description: '7日連続ログインする', iconUrl: 'consecutive_days_rare.png', type: BadgeType.consecutiveDays, requiredValue: 7, rarity: BadgeRarity.rare, category: '連続ログイン'),
  BadgeModel(badgeId: 'consecutive_days_epic', name: 'マンスリーチャンプ', description: '30日連続ログインする', iconUrl: 'consecutive_days_epic.png', type: BadgeType.consecutiveDays, requiredValue: 30, rarity: BadgeRarity.epic, category: '連続ログイン'),
  BadgeModel(badgeId: 'consecutive_days_legendary', name: '継続は力なり', description: '100日連続ログインする', iconUrl: 'consecutive_days_legendary.png', type: BadgeType.consecutiveDays, requiredValue: 100, rarity: BadgeRarity.legendary, category: '連続ログイン'),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 店舗巡り（storesVisited）4個
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  BadgeModel(badgeId: 'stores_visited_common', name: 'お店探検家', description: '3店舗を訪問する', iconUrl: 'stores_visited_common.png', type: BadgeType.storesVisited, requiredValue: 3, rarity: BadgeRarity.common, category: '店舗巡り'),
  BadgeModel(badgeId: 'stores_visited_rare', name: '街歩きの達人', description: '10店舗を訪問する', iconUrl: 'stores_visited_rare.png', type: BadgeType.storesVisited, requiredValue: 10, rarity: BadgeRarity.rare, category: '店舗巡り'),
  BadgeModel(badgeId: 'stores_visited_epic', name: '地域マスター', description: '25店舗を訪問する', iconUrl: 'stores_visited_epic.png', type: BadgeType.storesVisited, requiredValue: 25, rarity: BadgeRarity.epic, category: '店舗巡り'),
  BadgeModel(badgeId: 'stores_visited_legendary', name: 'グランドツーリスト', description: '50店舗を訪問する', iconUrl: 'stores_visited_legendary.png', type: BadgeType.storesVisited, requiredValue: 50, rarity: BadgeRarity.legendary, category: '店舗巡り'),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // イベント（specialEvents）4個
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  BadgeModel(badgeId: 'special_events_common', name: 'イベント参加者', description: 'イベントに1回参加する', iconUrl: 'special_events_common.png', type: BadgeType.specialEvents, requiredValue: 1, rarity: BadgeRarity.common, category: 'イベント'),
  BadgeModel(badgeId: 'special_events_rare', name: 'イベントファン', description: 'イベントに5回参加する', iconUrl: 'special_events_rare.png', type: BadgeType.specialEvents, requiredValue: 5, rarity: BadgeRarity.rare, category: 'イベント'),
  BadgeModel(badgeId: 'special_events_epic', name: 'イベントマニア', description: 'イベントに10回参加する', iconUrl: 'special_events_epic.png', type: BadgeType.specialEvents, requiredValue: 10, rarity: BadgeRarity.epic, category: 'イベント'),
  BadgeModel(badgeId: 'special_events_legendary', name: 'イベントレジェンド', description: 'イベントに25回参加する', iconUrl: 'special_events_legendary.png', type: BadgeType.specialEvents, requiredValue: 25, rarity: BadgeRarity.legendary, category: 'イベント'),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // カテゴリ別来店（categoryVisit）50個
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // カフェ・スイーツ系（cafe_sweets）
  BadgeModel(badgeId: 'category_cafe_sweets_visit_1', name: 'カフェデビュー', description: 'カフェ・スイーツ系の店舗に初めて来店', iconUrl: 'category_cafe_sweets_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: 'カフェ・スイーツ系', categoryGroupKey: 'cafe_sweets'),
  BadgeModel(badgeId: 'category_cafe_sweets_visit_2', name: 'カフェリピーター', description: 'カフェ・スイーツ系の店舗に2回来店', iconUrl: 'category_cafe_sweets_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: 'カフェ・スイーツ系', categoryGroupKey: 'cafe_sweets'),
  BadgeModel(badgeId: 'category_cafe_sweets_visit_3', name: 'カフェ通', description: 'カフェ・スイーツ系の店舗に3回来店', iconUrl: 'category_cafe_sweets_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: 'カフェ・スイーツ系', categoryGroupKey: 'cafe_sweets'),
  BadgeModel(badgeId: 'category_cafe_sweets_visit_4', name: 'カフェマニア', description: 'カフェ・スイーツ系の店舗に4回来店', iconUrl: 'category_cafe_sweets_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: 'カフェ・スイーツ系', categoryGroupKey: 'cafe_sweets'),
  BadgeModel(badgeId: 'category_cafe_sweets_visit_5', name: 'カフェマスター', description: 'カフェ・スイーツ系の店舗に5回来店', iconUrl: 'category_cafe_sweets_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: 'カフェ・スイーツ系', categoryGroupKey: 'cafe_sweets'),

  // 和食系（washoku）
  BadgeModel(badgeId: 'category_washoku_visit_1', name: '和食デビュー', description: '和食系の店舗に初めて来店', iconUrl: 'category_washoku_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: '和食系', categoryGroupKey: 'washoku'),
  BadgeModel(badgeId: 'category_washoku_visit_2', name: '和食リピーター', description: '和食系の店舗に2回来店', iconUrl: 'category_washoku_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: '和食系', categoryGroupKey: 'washoku'),
  BadgeModel(badgeId: 'category_washoku_visit_3', name: '和食通', description: '和食系の店舗に3回来店', iconUrl: 'category_washoku_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: '和食系', categoryGroupKey: 'washoku'),
  BadgeModel(badgeId: 'category_washoku_visit_4', name: '和食マニア', description: '和食系の店舗に4回来店', iconUrl: 'category_washoku_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: '和食系', categoryGroupKey: 'washoku'),
  BadgeModel(badgeId: 'category_washoku_visit_5', name: '和食マスター', description: '和食系の店舗に5回来店', iconUrl: 'category_washoku_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: '和食系', categoryGroupKey: 'washoku'),

  // 居酒屋・バー系（izakaya_bar）
  BadgeModel(badgeId: 'category_izakaya_bar_visit_1', name: '居酒屋デビュー', description: '居酒屋・バー系の店舗に初めて来店', iconUrl: 'category_izakaya_bar_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: '居酒屋・バー系', categoryGroupKey: 'izakaya_bar'),
  BadgeModel(badgeId: 'category_izakaya_bar_visit_2', name: '居酒屋リピーター', description: '居酒屋・バー系の店舗に2回来店', iconUrl: 'category_izakaya_bar_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: '居酒屋・バー系', categoryGroupKey: 'izakaya_bar'),
  BadgeModel(badgeId: 'category_izakaya_bar_visit_3', name: '居酒屋通', description: '居酒屋・バー系の店舗に3回来店', iconUrl: 'category_izakaya_bar_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: '居酒屋・バー系', categoryGroupKey: 'izakaya_bar'),
  BadgeModel(badgeId: 'category_izakaya_bar_visit_4', name: '居酒屋マニア', description: '居酒屋・バー系の店舗に4回来店', iconUrl: 'category_izakaya_bar_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: '居酒屋・バー系', categoryGroupKey: 'izakaya_bar'),
  BadgeModel(badgeId: 'category_izakaya_bar_visit_5', name: '居酒屋マスター', description: '居酒屋・バー系の店舗に5回来店', iconUrl: 'category_izakaya_bar_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: '居酒屋・バー系', categoryGroupKey: 'izakaya_bar'),

  // 焼き鳥・揚げ物系（yakitori_age）
  BadgeModel(badgeId: 'category_yakitori_age_visit_1', name: '焼き鳥デビュー', description: '焼き鳥・揚げ物系の店舗に初めて来店', iconUrl: 'category_yakitori_age_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: '焼き鳥・揚げ物系', categoryGroupKey: 'yakitori_age'),
  BadgeModel(badgeId: 'category_yakitori_age_visit_2', name: '焼き鳥リピーター', description: '焼き鳥・揚げ物系の店舗に2回来店', iconUrl: 'category_yakitori_age_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: '焼き鳥・揚げ物系', categoryGroupKey: 'yakitori_age'),
  BadgeModel(badgeId: 'category_yakitori_age_visit_3', name: '焼き鳥通', description: '焼き鳥・揚げ物系の店舗に3回来店', iconUrl: 'category_yakitori_age_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: '焼き鳥・揚げ物系', categoryGroupKey: 'yakitori_age'),
  BadgeModel(badgeId: 'category_yakitori_age_visit_4', name: '焼き鳥マニア', description: '焼き鳥・揚げ物系の店舗に4回来店', iconUrl: 'category_yakitori_age_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: '焼き鳥・揚げ物系', categoryGroupKey: 'yakitori_age'),
  BadgeModel(badgeId: 'category_yakitori_age_visit_5', name: '焼き鳥マスター', description: '焼き鳥・揚げ物系の店舗に5回来店', iconUrl: 'category_yakitori_age_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: '焼き鳥・揚げ物系', categoryGroupKey: 'yakitori_age'),

  // 鍋・焼肉系（nabe_yakiniku）
  BadgeModel(badgeId: 'category_nabe_yakiniku_visit_1', name: '焼肉デビュー', description: '鍋・焼肉系の店舗に初めて来店', iconUrl: 'category_nabe_yakiniku_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: '鍋・焼肉系', categoryGroupKey: 'nabe_yakiniku'),
  BadgeModel(badgeId: 'category_nabe_yakiniku_visit_2', name: '焼肉リピーター', description: '鍋・焼肉系の店舗に2回来店', iconUrl: 'category_nabe_yakiniku_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: '鍋・焼肉系', categoryGroupKey: 'nabe_yakiniku'),
  BadgeModel(badgeId: 'category_nabe_yakiniku_visit_3', name: '焼肉通', description: '鍋・焼肉系の店舗に3回来店', iconUrl: 'category_nabe_yakiniku_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: '鍋・焼肉系', categoryGroupKey: 'nabe_yakiniku'),
  BadgeModel(badgeId: 'category_nabe_yakiniku_visit_4', name: '焼肉マニア', description: '鍋・焼肉系の店舗に4回来店', iconUrl: 'category_nabe_yakiniku_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: '鍋・焼肉系', categoryGroupKey: 'nabe_yakiniku'),
  BadgeModel(badgeId: 'category_nabe_yakiniku_visit_5', name: '焼肉マスター', description: '鍋・焼肉系の店舗に5回来店', iconUrl: 'category_nabe_yakiniku_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: '鍋・焼肉系', categoryGroupKey: 'nabe_yakiniku'),

  // ラーメン・中華系（ramen_chinese）
  BadgeModel(badgeId: 'category_ramen_chinese_visit_1', name: 'ラーメンデビュー', description: 'ラーメン・中華系の店舗に初めて来店', iconUrl: 'category_ramen_chinese_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: 'ラーメン・中華系', categoryGroupKey: 'ramen_chinese'),
  BadgeModel(badgeId: 'category_ramen_chinese_visit_2', name: 'ラーメンリピーター', description: 'ラーメン・中華系の店舗に2回来店', iconUrl: 'category_ramen_chinese_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: 'ラーメン・中華系', categoryGroupKey: 'ramen_chinese'),
  BadgeModel(badgeId: 'category_ramen_chinese_visit_3', name: 'ラーメン通', description: 'ラーメン・中華系の店舗に3回来店', iconUrl: 'category_ramen_chinese_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: 'ラーメン・中華系', categoryGroupKey: 'ramen_chinese'),
  BadgeModel(badgeId: 'category_ramen_chinese_visit_4', name: 'ラーメンマニア', description: 'ラーメン・中華系の店舗に4回来店', iconUrl: 'category_ramen_chinese_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: 'ラーメン・中華系', categoryGroupKey: 'ramen_chinese'),
  BadgeModel(badgeId: 'category_ramen_chinese_visit_5', name: 'ラーメンマスター', description: 'ラーメン・中華系の店舗に5回来店', iconUrl: 'category_ramen_chinese_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: 'ラーメン・中華系', categoryGroupKey: 'ramen_chinese'),

  // アジア・エスニック系（asian_ethnic）
  BadgeModel(badgeId: 'category_asian_ethnic_visit_1', name: 'エスニックデビュー', description: 'アジア・エスニック系の店舗に初めて来店', iconUrl: 'category_asian_ethnic_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: 'アジア・エスニック系', categoryGroupKey: 'asian_ethnic'),
  BadgeModel(badgeId: 'category_asian_ethnic_visit_2', name: 'エスニックリピーター', description: 'アジア・エスニック系の店舗に2回来店', iconUrl: 'category_asian_ethnic_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: 'アジア・エスニック系', categoryGroupKey: 'asian_ethnic'),
  BadgeModel(badgeId: 'category_asian_ethnic_visit_3', name: 'エスニック通', description: 'アジア・エスニック系の店舗に3回来店', iconUrl: 'category_asian_ethnic_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: 'アジア・エスニック系', categoryGroupKey: 'asian_ethnic'),
  BadgeModel(badgeId: 'category_asian_ethnic_visit_4', name: 'エスニックマニア', description: 'アジア・エスニック系の店舗に4回来店', iconUrl: 'category_asian_ethnic_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: 'アジア・エスニック系', categoryGroupKey: 'asian_ethnic'),
  BadgeModel(badgeId: 'category_asian_ethnic_visit_5', name: 'エスニックマスター', description: 'アジア・エスニック系の店舗に5回来店', iconUrl: 'category_asian_ethnic_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: 'アジア・エスニック系', categoryGroupKey: 'asian_ethnic'),

  // 洋食・フレンチ系（western_french）
  BadgeModel(badgeId: 'category_western_french_visit_1', name: '洋食デビュー', description: '洋食・フレンチ系の店舗に初めて来店', iconUrl: 'category_western_french_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: '洋食・フレンチ系', categoryGroupKey: 'western_french'),
  BadgeModel(badgeId: 'category_western_french_visit_2', name: '洋食リピーター', description: '洋食・フレンチ系の店舗に2回来店', iconUrl: 'category_western_french_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: '洋食・フレンチ系', categoryGroupKey: 'western_french'),
  BadgeModel(badgeId: 'category_western_french_visit_3', name: '洋食通', description: '洋食・フレンチ系の店舗に3回来店', iconUrl: 'category_western_french_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: '洋食・フレンチ系', categoryGroupKey: 'western_french'),
  BadgeModel(badgeId: 'category_western_french_visit_4', name: '洋食マニア', description: '洋食・フレンチ系の店舗に4回来店', iconUrl: 'category_western_french_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: '洋食・フレンチ系', categoryGroupKey: 'western_french'),
  BadgeModel(badgeId: 'category_western_french_visit_5', name: '洋食マスター', description: '洋食・フレンチ系の店舗に5回来店', iconUrl: 'category_western_french_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: '洋食・フレンチ系', categoryGroupKey: 'western_french'),

  // イタリアン・肉料理系（italian_meat）
  BadgeModel(badgeId: 'category_italian_meat_visit_1', name: 'イタリアンデビュー', description: 'イタリアン・肉料理系の店舗に初めて来店', iconUrl: 'category_italian_meat_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: 'イタリアン・肉料理系', categoryGroupKey: 'italian_meat'),
  BadgeModel(badgeId: 'category_italian_meat_visit_2', name: 'イタリアンリピーター', description: 'イタリアン・肉料理系の店舗に2回来店', iconUrl: 'category_italian_meat_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: 'イタリアン・肉料理系', categoryGroupKey: 'italian_meat'),
  BadgeModel(badgeId: 'category_italian_meat_visit_3', name: 'イタリアン通', description: 'イタリアン・肉料理系の店舗に3回来店', iconUrl: 'category_italian_meat_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: 'イタリアン・肉料理系', categoryGroupKey: 'italian_meat'),
  BadgeModel(badgeId: 'category_italian_meat_visit_4', name: 'イタリアンマニア', description: 'イタリアン・肉料理系の店舗に4回来店', iconUrl: 'category_italian_meat_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: 'イタリアン・肉料理系', categoryGroupKey: 'italian_meat'),
  BadgeModel(badgeId: 'category_italian_meat_visit_5', name: 'イタリアンマスター', description: 'イタリアン・肉料理系の店舗に5回来店', iconUrl: 'category_italian_meat_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: 'イタリアン・肉料理系', categoryGroupKey: 'italian_meat'),

  // 食堂・その他（shokudo_other）
  BadgeModel(badgeId: 'category_shokudo_other_visit_1', name: '食堂デビュー', description: '食堂・その他の店舗に初めて来店', iconUrl: 'category_shokudo_other_visit_1.png', type: BadgeType.categoryVisit, requiredValue: 1, rarity: BadgeRarity.common, category: '食堂・その他', categoryGroupKey: 'shokudo_other'),
  BadgeModel(badgeId: 'category_shokudo_other_visit_2', name: '食堂リピーター', description: '食堂・その他の店舗に2回来店', iconUrl: 'category_shokudo_other_visit_2.png', type: BadgeType.categoryVisit, requiredValue: 2, rarity: BadgeRarity.common, category: '食堂・その他', categoryGroupKey: 'shokudo_other'),
  BadgeModel(badgeId: 'category_shokudo_other_visit_3', name: '食堂通', description: '食堂・その他の店舗に3回来店', iconUrl: 'category_shokudo_other_visit_3.png', type: BadgeType.categoryVisit, requiredValue: 3, rarity: BadgeRarity.rare, category: '食堂・その他', categoryGroupKey: 'shokudo_other'),
  BadgeModel(badgeId: 'category_shokudo_other_visit_4', name: '食堂マニア', description: '食堂・その他の店舗に4回来店', iconUrl: 'category_shokudo_other_visit_4.png', type: BadgeType.categoryVisit, requiredValue: 4, rarity: BadgeRarity.epic, category: '食堂・その他', categoryGroupKey: 'shokudo_other'),
  BadgeModel(badgeId: 'category_shokudo_other_visit_5', name: '食堂マスター', description: '食堂・その他の店舗に5回来店', iconUrl: 'category_shokudo_other_visit_5.png', type: BadgeType.categoryVisit, requiredValue: 5, rarity: BadgeRarity.legendary, category: '食堂・その他', categoryGroupKey: 'shokudo_other'),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // アクション系バッジ 60個
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // マップ閲覧（mapOpened）5個
  BadgeModel(badgeId: 'map_opened_1', name: 'マップデビュー', description: 'マップ画面を初めて開く', iconUrl: 'map_opened_1.png', type: BadgeType.mapOpened, requiredValue: 1, rarity: BadgeRarity.common, category: 'マップ閲覧'),
  BadgeModel(badgeId: 'map_opened_5', name: 'マップウォーカー', description: 'マップ画面を5回開く', iconUrl: 'map_opened_5.png', type: BadgeType.mapOpened, requiredValue: 5, rarity: BadgeRarity.common, category: 'マップ閲覧'),
  BadgeModel(badgeId: 'map_opened_10', name: 'マップナビゲーター', description: 'マップ画面を10回開く', iconUrl: 'map_opened_10.png', type: BadgeType.mapOpened, requiredValue: 10, rarity: BadgeRarity.rare, category: 'マップ閲覧'),
  BadgeModel(badgeId: 'map_opened_25', name: 'マップエクスプローラー', description: 'マップ画面を25回開く', iconUrl: 'map_opened_25.png', type: BadgeType.mapOpened, requiredValue: 25, rarity: BadgeRarity.epic, category: 'マップ閲覧'),
  BadgeModel(badgeId: 'map_opened_50', name: 'マップマスター', description: 'マップ画面を50回開く', iconUrl: 'map_opened_50.png', type: BadgeType.mapOpened, requiredValue: 50, rarity: BadgeRarity.legendary, category: 'マップ閲覧'),

  // 店舗詳細閲覧（storeDetailViewed）5個
  BadgeModel(badgeId: 'store_detail_viewed_1', name: '店舗チェッカー', description: '店舗詳細を初めて閲覧', iconUrl: 'store_detail_viewed_1.png', type: BadgeType.storeDetailViewed, requiredValue: 1, rarity: BadgeRarity.common, category: '店舗詳細閲覧'),
  BadgeModel(badgeId: 'store_detail_viewed_5', name: '店舗リサーチャー', description: '店舗詳細を5回閲覧', iconUrl: 'store_detail_viewed_5.png', type: BadgeType.storeDetailViewed, requiredValue: 5, rarity: BadgeRarity.common, category: '店舗詳細閲覧'),
  BadgeModel(badgeId: 'store_detail_viewed_10', name: '店舗アナリスト', description: '店舗詳細を10回閲覧', iconUrl: 'store_detail_viewed_10.png', type: BadgeType.storeDetailViewed, requiredValue: 10, rarity: BadgeRarity.rare, category: '店舗詳細閲覧'),
  BadgeModel(badgeId: 'store_detail_viewed_25', name: '店舗ウォッチャー', description: '店舗詳細を25回閲覧', iconUrl: 'store_detail_viewed_25.png', type: BadgeType.storeDetailViewed, requiredValue: 25, rarity: BadgeRarity.epic, category: '店舗詳細閲覧'),
  BadgeModel(badgeId: 'store_detail_viewed_50', name: '店舗博士', description: '店舗詳細を50回閲覧', iconUrl: 'store_detail_viewed_50.png', type: BadgeType.storeDetailViewed, requiredValue: 50, rarity: BadgeRarity.legendary, category: '店舗詳細閲覧'),

  // プロフィール完成（profileCompleted）1個
  BadgeModel(badgeId: 'profile_completed', name: '自己紹介マスター', description: 'プロフィールを完成させる', iconUrl: 'profile_completed.png', type: BadgeType.profileCompleted, requiredValue: 1, rarity: BadgeRarity.rare, category: 'プロフィール'),

  // お気に入り登録（favoriteAdded）5個
  BadgeModel(badgeId: 'favorite_added_1', name: 'はじめてのお気に入り', description: '初めてお気に入り登録する', iconUrl: 'favorite_added_1.png', type: BadgeType.favoriteAdded, requiredValue: 1, rarity: BadgeRarity.common, category: 'お気に入り'),
  BadgeModel(badgeId: 'favorite_added_3', name: 'お気に入りビギナー', description: '3店舗をお気に入りに登録', iconUrl: 'favorite_added_3.png', type: BadgeType.favoriteAdded, requiredValue: 3, rarity: BadgeRarity.common, category: 'お気に入り'),
  BadgeModel(badgeId: 'favorite_added_5', name: 'お気に入りコレクター', description: '5店舗をお気に入りに登録', iconUrl: 'favorite_added_5.png', type: BadgeType.favoriteAdded, requiredValue: 5, rarity: BadgeRarity.rare, category: 'お気に入り'),
  BadgeModel(badgeId: 'favorite_added_10', name: 'お気に入りマニア', description: '10店舗をお気に入りに登録', iconUrl: 'favorite_added_10.png', type: BadgeType.favoriteAdded, requiredValue: 10, rarity: BadgeRarity.epic, category: 'お気に入り'),
  BadgeModel(badgeId: 'favorite_added_25', name: 'お気に入りキング', description: '25店舗をお気に入りに登録', iconUrl: 'favorite_added_25.png', type: BadgeType.favoriteAdded, requiredValue: 25, rarity: BadgeRarity.legendary, category: 'お気に入り'),

  // スロット（slotPlayed）5個
  BadgeModel(badgeId: 'slot_played_1', name: 'スロットデビュー', description: 'スロットを初めてプレイ', iconUrl: 'slot_played_1.png', type: BadgeType.slotPlayed, requiredValue: 1, rarity: BadgeRarity.common, category: 'スロット'),
  BadgeModel(badgeId: 'slot_played_5', name: 'スロットプレイヤー', description: 'スロットを5回プレイ', iconUrl: 'slot_played_5.png', type: BadgeType.slotPlayed, requiredValue: 5, rarity: BadgeRarity.common, category: 'スロット'),
  BadgeModel(badgeId: 'slot_played_10', name: 'スロットファン', description: 'スロットを10回プレイ', iconUrl: 'slot_played_10.png', type: BadgeType.slotPlayed, requiredValue: 10, rarity: BadgeRarity.rare, category: 'スロット'),
  BadgeModel(badgeId: 'slot_played_25', name: 'スロットマニア', description: 'スロットを25回プレイ', iconUrl: 'slot_played_25.png', type: BadgeType.slotPlayed, requiredValue: 25, rarity: BadgeRarity.epic, category: 'スロット'),
  BadgeModel(badgeId: 'slot_played_50', name: 'スロットキング', description: 'スロットを50回プレイ', iconUrl: 'slot_played_50.png', type: BadgeType.slotPlayed, requiredValue: 50, rarity: BadgeRarity.legendary, category: 'スロット'),

  // スロット当選（slotWin）3個
  BadgeModel(badgeId: 'slot_win_1', name: 'ビギナーズラック', description: 'スロットに初めて当選', iconUrl: 'slot_win_1.png', type: BadgeType.slotWin, requiredValue: 1, rarity: BadgeRarity.rare, category: 'スロット当選'),
  BadgeModel(badgeId: 'slot_win_3', name: 'ラッキーガイ', description: 'スロットに3回当選', iconUrl: 'slot_win_3.png', type: BadgeType.slotWin, requiredValue: 3, rarity: BadgeRarity.epic, category: 'スロット当選'),
  BadgeModel(badgeId: 'slot_win_5', name: '幸運の持ち主', description: 'スロットに5回当選', iconUrl: 'slot_win_5.png', type: BadgeType.slotWin, requiredValue: 5, rarity: BadgeRarity.legendary, category: 'スロット当選'),

  // クーポン使用（couponUsed）5個
  BadgeModel(badgeId: 'coupon_used_1', name: 'クーポンデビュー', description: 'クーポンを初めて使用', iconUrl: 'coupon_used_1.png', type: BadgeType.couponUsed, requiredValue: 1, rarity: BadgeRarity.common, category: 'クーポン'),
  BadgeModel(badgeId: 'coupon_used_3', name: 'クーポンユーザー', description: 'クーポンを3回使用', iconUrl: 'coupon_used_3.png', type: BadgeType.couponUsed, requiredValue: 3, rarity: BadgeRarity.common, category: 'クーポン'),
  BadgeModel(badgeId: 'coupon_used_5', name: 'クーポンハンター', description: 'クーポンを5回使用', iconUrl: 'coupon_used_5.png', type: BadgeType.couponUsed, requiredValue: 5, rarity: BadgeRarity.rare, category: 'クーポン'),
  BadgeModel(badgeId: 'coupon_used_10', name: 'クーポンマスター', description: 'クーポンを10回使用', iconUrl: 'coupon_used_10.png', type: BadgeType.couponUsed, requiredValue: 10, rarity: BadgeRarity.epic, category: 'クーポン'),
  BadgeModel(badgeId: 'coupon_used_25', name: 'クーポンレジェンド', description: 'クーポンを25回使用', iconUrl: 'coupon_used_25.png', type: BadgeType.couponUsed, requiredValue: 25, rarity: BadgeRarity.legendary, category: 'クーポン'),

  // いいね（likeGiven）5個
  BadgeModel(badgeId: 'like_given_1', name: 'はじめてのいいね', description: '投稿に初めていいねする', iconUrl: 'like_given_1.png', type: BadgeType.likeGiven, requiredValue: 1, rarity: BadgeRarity.common, category: 'いいね'),
  BadgeModel(badgeId: 'like_given_10', name: 'いいねビギナー', description: '投稿に10回いいねする', iconUrl: 'like_given_10.png', type: BadgeType.likeGiven, requiredValue: 10, rarity: BadgeRarity.common, category: 'いいね'),
  BadgeModel(badgeId: 'like_given_25', name: 'いいねファン', description: '投稿に25回いいねする', iconUrl: 'like_given_25.png', type: BadgeType.likeGiven, requiredValue: 25, rarity: BadgeRarity.rare, category: 'いいね'),
  BadgeModel(badgeId: 'like_given_50', name: 'いいねマスター', description: '投稿に50回いいねする', iconUrl: 'like_given_50.png', type: BadgeType.likeGiven, requiredValue: 50, rarity: BadgeRarity.epic, category: 'いいね'),
  BadgeModel(badgeId: 'like_given_100', name: 'いいねレジェンド', description: '投稿に100回いいねする', iconUrl: 'like_given_100.png', type: BadgeType.likeGiven, requiredValue: 100, rarity: BadgeRarity.legendary, category: 'いいね'),

  // コメント投稿（commentPosted）5個
  BadgeModel(badgeId: 'comment_posted_1', name: 'はじめてのコメント', description: '初めてコメントを投稿', iconUrl: 'comment_posted_1.png', type: BadgeType.commentPosted, requiredValue: 1, rarity: BadgeRarity.common, category: 'コメント'),
  BadgeModel(badgeId: 'comment_posted_5', name: 'コメンター', description: 'コメントを5回投稿', iconUrl: 'comment_posted_5.png', type: BadgeType.commentPosted, requiredValue: 5, rarity: BadgeRarity.common, category: 'コメント'),
  BadgeModel(badgeId: 'comment_posted_10', name: 'コメントファン', description: 'コメントを10回投稿', iconUrl: 'comment_posted_10.png', type: BadgeType.commentPosted, requiredValue: 10, rarity: BadgeRarity.rare, category: 'コメント'),
  BadgeModel(badgeId: 'comment_posted_25', name: 'コメントマスター', description: 'コメントを25回投稿', iconUrl: 'comment_posted_25.png', type: BadgeType.commentPosted, requiredValue: 25, rarity: BadgeRarity.epic, category: 'コメント'),
  BadgeModel(badgeId: 'comment_posted_50', name: 'コメントレジェンド', description: 'コメントを50回投稿', iconUrl: 'comment_posted_50.png', type: BadgeType.commentPosted, requiredValue: 50, rarity: BadgeRarity.legendary, category: 'コメント'),

  // フォロー（followUser）4個
  BadgeModel(badgeId: 'follow_user_1', name: 'はじめてのフォロー', description: '初めて他ユーザーをフォロー', iconUrl: 'follow_user_1.png', type: BadgeType.followUser, requiredValue: 1, rarity: BadgeRarity.common, category: 'フォロー'),
  BadgeModel(badgeId: 'follow_user_5', name: 'フォロワー', description: '5人をフォロー', iconUrl: 'follow_user_5.png', type: BadgeType.followUser, requiredValue: 5, rarity: BadgeRarity.common, category: 'フォロー'),
  BadgeModel(badgeId: 'follow_user_10', name: 'ソーシャルバタフライ', description: '10人をフォロー', iconUrl: 'follow_user_10.png', type: BadgeType.followUser, requiredValue: 10, rarity: BadgeRarity.rare, category: 'フォロー'),
  BadgeModel(badgeId: 'follow_user_25', name: 'コミュニティリーダー', description: '25人をフォロー', iconUrl: 'follow_user_25.png', type: BadgeType.followUser, requiredValue: 25, rarity: BadgeRarity.epic, category: 'フォロー'),

  // コイン獲得（coinsEarned）5個
  BadgeModel(badgeId: 'coins_earned_10', name: 'コインビギナー', description: 'コインを累計10枚獲得', iconUrl: 'coins_earned_10.png', type: BadgeType.coinsEarned, requiredValue: 10, rarity: BadgeRarity.common, category: 'コイン'),
  BadgeModel(badgeId: 'coins_earned_50', name: 'コインコレクター', description: 'コインを累計50枚獲得', iconUrl: 'coins_earned_50.png', type: BadgeType.coinsEarned, requiredValue: 50, rarity: BadgeRarity.common, category: 'コイン'),
  BadgeModel(badgeId: 'coins_earned_100', name: 'コインハンター', description: 'コインを累計100枚獲得', iconUrl: 'coins_earned_100.png', type: BadgeType.coinsEarned, requiredValue: 100, rarity: BadgeRarity.rare, category: 'コイン'),
  BadgeModel(badgeId: 'coins_earned_300', name: 'コインリッチ', description: 'コインを累計300枚獲得', iconUrl: 'coins_earned_300.png', type: BadgeType.coinsEarned, requiredValue: 300, rarity: BadgeRarity.epic, category: 'コイン'),
  BadgeModel(badgeId: 'coins_earned_500', name: 'コインタイクーン', description: 'コインを累計500枚獲得', iconUrl: 'coins_earned_500.png', type: BadgeType.coinsEarned, requiredValue: 500, rarity: BadgeRarity.legendary, category: 'コイン'),

  // ミッション達成（missionCompleted）5個
  BadgeModel(badgeId: 'mission_completed_1', name: 'ミッションクリア', description: 'ミッションを初めて達成', iconUrl: 'mission_completed_1.png', type: BadgeType.missionCompleted, requiredValue: 1, rarity: BadgeRarity.common, category: 'ミッション'),
  BadgeModel(badgeId: 'mission_completed_5', name: 'ミッションハンター', description: 'ミッションを5回達成', iconUrl: 'mission_completed_5.png', type: BadgeType.missionCompleted, requiredValue: 5, rarity: BadgeRarity.common, category: 'ミッション'),
  BadgeModel(badgeId: 'mission_completed_10', name: 'ミッションファイター', description: 'ミッションを10回達成', iconUrl: 'mission_completed_10.png', type: BadgeType.missionCompleted, requiredValue: 10, rarity: BadgeRarity.rare, category: 'ミッション'),
  BadgeModel(badgeId: 'mission_completed_25', name: 'ミッションヒーロー', description: 'ミッションを25回達成', iconUrl: 'mission_completed_25.png', type: BadgeType.missionCompleted, requiredValue: 25, rarity: BadgeRarity.epic, category: 'ミッション'),
  BadgeModel(badgeId: 'mission_completed_50', name: 'ミッションレジェンド', description: 'ミッションを50回達成', iconUrl: 'mission_completed_50.png', type: BadgeType.missionCompleted, requiredValue: 50, rarity: BadgeRarity.legendary, category: 'ミッション'),

  // レコメンド閲覧（recommendViewed）3個
  BadgeModel(badgeId: 'recommend_viewed_1', name: 'レコメンドチェック', description: 'レコメンドを初めて閲覧', iconUrl: 'recommend_viewed_1.png', type: BadgeType.recommendViewed, requiredValue: 1, rarity: BadgeRarity.common, category: 'レコメンド'),
  BadgeModel(badgeId: 'recommend_viewed_5', name: 'レコメンドウォッチャー', description: 'レコメンドを5回閲覧', iconUrl: 'recommend_viewed_5.png', type: BadgeType.recommendViewed, requiredValue: 5, rarity: BadgeRarity.rare, category: 'レコメンド'),
  BadgeModel(badgeId: 'recommend_viewed_10', name: 'レコメンドマニア', description: 'レコメンドを10回閲覧', iconUrl: 'recommend_viewed_10.png', type: BadgeType.recommendViewed, requiredValue: 10, rarity: BadgeRarity.epic, category: 'レコメンド'),

  // スタンプカード達成（stampCardCompleted）4個
  BadgeModel(badgeId: 'stamp_card_completed_1', name: 'カード達成', description: 'スタンプカードを初めて達成', iconUrl: 'stamp_card_completed_1.png', type: BadgeType.stampCardCompleted, requiredValue: 1, rarity: BadgeRarity.common, category: 'スタンプカード'),
  BadgeModel(badgeId: 'stamp_card_completed_3', name: 'カードコレクター', description: 'スタンプカードを3枚達成', iconUrl: 'stamp_card_completed_3.png', type: BadgeType.stampCardCompleted, requiredValue: 3, rarity: BadgeRarity.rare, category: 'スタンプカード'),
  BadgeModel(badgeId: 'stamp_card_completed_5', name: 'カードマスター', description: 'スタンプカードを5枚達成', iconUrl: 'stamp_card_completed_5.png', type: BadgeType.stampCardCompleted, requiredValue: 5, rarity: BadgeRarity.epic, category: 'スタンプカード'),
  BadgeModel(badgeId: 'stamp_card_completed_10', name: 'カードレジェンド', description: 'スタンプカードを10枚達成', iconUrl: 'stamp_card_completed_10.png', type: BadgeType.stampCardCompleted, requiredValue: 10, rarity: BadgeRarity.legendary, category: 'スタンプカード'),
];

/// badgeIdからBadgeModelを検索
BadgeModel? findBadgeById(String badgeId) {
  for (final badge in kBadgeDefinitions) {
    if (badge.badgeId == badgeId) return badge;
  }
  return null;
}

/// BadgeTypeで絞り込み
List<BadgeModel> getBadgesByType(BadgeType type) {
  return kBadgeDefinitions.where((b) => b.type == type).toList();
}

/// categoryGroupKeyで絞り込み（カテゴリ別来店バッジ用）
List<BadgeModel> getBadgesByCategoryGroup(String groupKey) {
  return kBadgeDefinitions
      .where((b) => b.type == BadgeType.categoryVisit && b.categoryGroupKey == groupKey)
      .toList();
}

/// BadgeTypeからカテゴリ表示名を取得
String badgeTypeDisplayName(BadgeType type) {
  switch (type) {
    case BadgeType.stampsTotal:
      return 'スタンプ';
    case BadgeType.visitsCount:
      return '来店';
    case BadgeType.consecutiveDays:
      return '連続ログイン';
    case BadgeType.storesVisited:
      return '店舗巡り';
    case BadgeType.specialEvents:
      return 'イベント';
    case BadgeType.categoryVisit:
      return 'カテゴリ別来店';
    case BadgeType.mapOpened:
      return 'マップ閲覧';
    case BadgeType.storeDetailViewed:
      return '店舗詳細閲覧';
    case BadgeType.profileCompleted:
      return 'プロフィール';
    case BadgeType.favoriteAdded:
      return 'お気に入り';
    case BadgeType.slotPlayed:
      return 'スロット';
    case BadgeType.slotWin:
      return 'スロット当選';
    case BadgeType.couponUsed:
      return 'クーポン';
    case BadgeType.likeGiven:
      return 'いいね';
    case BadgeType.commentPosted:
      return 'コメント';
    case BadgeType.followUser:
      return 'フォロー';
    case BadgeType.coinsEarned:
      return 'コイン';
    case BadgeType.missionCompleted:
      return 'ミッション';
    case BadgeType.recommendViewed:
      return 'レコメンド';
    case BadgeType.stampCardCompleted:
      return 'スタンプカード';
  }
}

/// カテゴリ名からグループキーを逆引き
String? findCategoryGroupKey(String categoryName) {
  for (final entry in kCategoryGroupMap.entries) {
    if (entry.value.contains(categoryName)) {
      return entry.key;
    }
  }
  return null;
}
