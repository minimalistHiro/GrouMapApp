import '../models/badge_model.dart';

/// アプリ内蔵バッジ定義
/// バッジ画像は assets/images/badges/{badgeId}.png に配置
const List<BadgeModel> kBadgeDefinitions = [
  // ── stampsTotal（スタンプ収集）──
  BadgeModel(
    badgeId: 'stamps_total_common',
    name: 'スタンプコレクター',
    description: 'スタンプを10個集めよう',
    iconUrl: 'stamps_total_common.png',
    type: BadgeType.stampsTotal,
    requiredValue: 10,
    rarity: BadgeRarity.common,
    category: 'スタンプ',
  ),
  BadgeModel(
    badgeId: 'stamps_total_rare',
    name: 'スタンプマスター',
    description: 'スタンプを50個集めよう',
    iconUrl: 'stamps_total_rare.png',
    type: BadgeType.stampsTotal,
    requiredValue: 50,
    rarity: BadgeRarity.rare,
    category: 'スタンプ',
  ),
  BadgeModel(
    badgeId: 'stamps_total_epic',
    name: 'スタンプエキスパート',
    description: 'スタンプを200個集めよう',
    iconUrl: 'stamps_total_epic.png',
    type: BadgeType.stampsTotal,
    requiredValue: 200,
    rarity: BadgeRarity.epic,
    category: 'スタンプ',
  ),
  BadgeModel(
    badgeId: 'stamps_total_legendary',
    name: 'スタンプレジェンド',
    description: 'スタンプを500個集めよう',
    iconUrl: 'stamps_total_legendary.png',
    type: BadgeType.stampsTotal,
    requiredValue: 500,
    rarity: BadgeRarity.legendary,
    category: 'スタンプ',
  ),

  // ── visitsCount（来店回数）──
  BadgeModel(
    badgeId: 'visits_count_common',
    name: 'はじめての常連',
    description: '5回来店しよう',
    iconUrl: 'visits_count_common.png',
    type: BadgeType.visitsCount,
    requiredValue: 5,
    rarity: BadgeRarity.common,
    category: '来店',
  ),
  BadgeModel(
    badgeId: 'visits_count_rare',
    name: 'おなじみさん',
    description: '20回来店しよう',
    iconUrl: 'visits_count_rare.png',
    type: BadgeType.visitsCount,
    requiredValue: 20,
    rarity: BadgeRarity.rare,
    category: '来店',
  ),
  BadgeModel(
    badgeId: 'visits_count_epic',
    name: '街の探検家',
    description: '50回来店しよう',
    iconUrl: 'visits_count_epic.png',
    type: BadgeType.visitsCount,
    requiredValue: 50,
    rarity: BadgeRarity.epic,
    category: '来店',
  ),
  BadgeModel(
    badgeId: 'visits_count_legendary',
    name: 'レジェンドビジター',
    description: '100回来店しよう',
    iconUrl: 'visits_count_legendary.png',
    type: BadgeType.visitsCount,
    requiredValue: 100,
    rarity: BadgeRarity.legendary,
    category: '来店',
  ),

  // ── consecutiveDays（連続ログイン日数）──
  BadgeModel(
    badgeId: 'consecutive_days_common',
    name: '3日坊主突破',
    description: '3日連続ログインしよう',
    iconUrl: 'consecutive_days_common.png',
    type: BadgeType.consecutiveDays,
    requiredValue: 3,
    rarity: BadgeRarity.common,
    category: '連続ログイン',
  ),
  BadgeModel(
    badgeId: 'consecutive_days_rare',
    name: 'ウィークリーチャンプ',
    description: '7日連続ログインしよう',
    iconUrl: 'consecutive_days_rare.png',
    type: BadgeType.consecutiveDays,
    requiredValue: 7,
    rarity: BadgeRarity.rare,
    category: '連続ログイン',
  ),
  BadgeModel(
    badgeId: 'consecutive_days_epic',
    name: 'マンスリーチャンプ',
    description: '30日連続ログインしよう',
    iconUrl: 'consecutive_days_epic.png',
    type: BadgeType.consecutiveDays,
    requiredValue: 30,
    rarity: BadgeRarity.epic,
    category: '連続ログイン',
  ),
  BadgeModel(
    badgeId: 'consecutive_days_legendary',
    name: '継続は力なり',
    description: '100日連続ログインしよう',
    iconUrl: 'consecutive_days_legendary.png',
    type: BadgeType.consecutiveDays,
    requiredValue: 100,
    rarity: BadgeRarity.legendary,
    category: '連続ログイン',
  ),

  // ── qrScans（QRスキャン回数）──
  BadgeModel(
    badgeId: 'qr_scans_common',
    name: 'QRビギナー',
    description: 'QRコードを3回スキャンしよう',
    iconUrl: 'qr_scans_common.png',
    type: BadgeType.qrScans,
    requiredValue: 3,
    rarity: BadgeRarity.common,
    category: 'QRスキャン',
  ),
  BadgeModel(
    badgeId: 'qr_scans_rare',
    name: 'QRスキャナー',
    description: 'QRコードを15回スキャンしよう',
    iconUrl: 'qr_scans_rare.png',
    type: BadgeType.qrScans,
    requiredValue: 15,
    rarity: BadgeRarity.rare,
    category: 'QRスキャン',
  ),
  BadgeModel(
    badgeId: 'qr_scans_epic',
    name: 'QRマスター',
    description: 'QRコードを50回スキャンしよう',
    iconUrl: 'qr_scans_epic.png',
    type: BadgeType.qrScans,
    requiredValue: 50,
    rarity: BadgeRarity.epic,
    category: 'QRスキャン',
  ),
  BadgeModel(
    badgeId: 'qr_scans_legendary',
    name: 'QRレジェンド',
    description: 'QRコードを100回スキャンしよう',
    iconUrl: 'qr_scans_legendary.png',
    type: BadgeType.qrScans,
    requiredValue: 100,
    rarity: BadgeRarity.legendary,
    category: 'QRスキャン',
  ),

  // ── storesVisited（訪問店舗数）──
  BadgeModel(
    badgeId: 'stores_visited_common',
    name: 'お店探検家',
    description: '3店舗を訪問しよう',
    iconUrl: 'stores_visited_common.png',
    type: BadgeType.storesVisited,
    requiredValue: 3,
    rarity: BadgeRarity.common,
    category: '店舗巡り',
  ),
  BadgeModel(
    badgeId: 'stores_visited_rare',
    name: '街歩きの達人',
    description: '10店舗を訪問しよう',
    iconUrl: 'stores_visited_rare.png',
    type: BadgeType.storesVisited,
    requiredValue: 10,
    rarity: BadgeRarity.rare,
    category: '店舗巡り',
  ),
  BadgeModel(
    badgeId: 'stores_visited_epic',
    name: '地域マスター',
    description: '25店舗を訪問しよう',
    iconUrl: 'stores_visited_epic.png',
    type: BadgeType.storesVisited,
    requiredValue: 25,
    rarity: BadgeRarity.epic,
    category: '店舗巡り',
  ),
  BadgeModel(
    badgeId: 'stores_visited_legendary',
    name: 'グランドツーリスト',
    description: '50店舗を訪問しよう',
    iconUrl: 'stores_visited_legendary.png',
    type: BadgeType.storesVisited,
    requiredValue: 50,
    rarity: BadgeRarity.legendary,
    category: '店舗巡り',
  ),

  // ── specialEvents（特別イベント）──
  BadgeModel(
    badgeId: 'special_events_common',
    name: 'イベント参加者',
    description: 'イベントに1回参加しよう',
    iconUrl: 'special_events_common.png',
    type: BadgeType.specialEvents,
    requiredValue: 1,
    rarity: BadgeRarity.common,
    category: 'イベント',
  ),
  BadgeModel(
    badgeId: 'special_events_rare',
    name: 'イベントファン',
    description: 'イベントに5回参加しよう',
    iconUrl: 'special_events_rare.png',
    type: BadgeType.specialEvents,
    requiredValue: 5,
    rarity: BadgeRarity.rare,
    category: 'イベント',
  ),
  BadgeModel(
    badgeId: 'special_events_epic',
    name: 'イベントマニア',
    description: 'イベントに10回参加しよう',
    iconUrl: 'special_events_epic.png',
    type: BadgeType.specialEvents,
    requiredValue: 10,
    rarity: BadgeRarity.epic,
    category: 'イベント',
  ),
  BadgeModel(
    badgeId: 'special_events_legendary',
    name: 'イベントレジェンド',
    description: 'イベントに25回参加しよう',
    iconUrl: 'special_events_legendary.png',
    type: BadgeType.specialEvents,
    requiredValue: 25,
    rarity: BadgeRarity.legendary,
    category: 'イベント',
  ),
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

/// BadgeTypeからカテゴリ表示名を取得
String badgeTypeDisplayName(BadgeType type) {
  switch (type) {
    case BadgeType.stampsTotal:
      return 'スタンプ';
    case BadgeType.visitsCount:
      return '来店';
    case BadgeType.consecutiveDays:
      return '連続ログイン';
    case BadgeType.qrScans:
      return 'QRスキャン';
    case BadgeType.storesVisited:
      return '店舗巡り';
    case BadgeType.specialEvents:
      return 'イベント';
  }
}
