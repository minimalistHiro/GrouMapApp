import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge_model.freezed.dart';
part 'badge_model.g.dart';

@freezed
class BadgeModel with _$BadgeModel {
  const factory BadgeModel({
    required String badgeId,
    required String name,
    required String description,
    required String iconUrl,
    required BadgeType type,
    required int requiredValue,
    required BadgeRarity rarity,
    @Default(false) bool isUnlocked,
    DateTime? unlockedAt,
    String? category,
    String? categoryGroupKey,
  }) = _BadgeModel;

  factory BadgeModel.fromJson(Map<String, dynamic> json) => _$BadgeModelFromJson(json);
}

@freezed
class UserBadgeModel with _$UserBadgeModel {
  const factory UserBadgeModel({
    required String userId,
    required String badgeId,
    required DateTime unlockedAt,
    required int progress,
    required int requiredValue,
    @Default(false) bool isNew,
  }) = _UserBadgeModel;

  factory UserBadgeModel.fromJson(Map<String, dynamic> json) => _$UserBadgeModelFromJson(json);
}

enum BadgeType {
  @JsonValue('stamps_total')
  stampsTotal,
  @JsonValue('visits_count')
  visitsCount,
  @JsonValue('consecutive_days')
  consecutiveDays,
  @JsonValue('stores_visited')
  storesVisited,
  @JsonValue('special_events')
  specialEvents,
  @JsonValue('category_visit')
  categoryVisit,
  @JsonValue('map_opened')
  mapOpened,
  @JsonValue('store_detail_viewed')
  storeDetailViewed,
  @JsonValue('profile_completed')
  profileCompleted,
  @JsonValue('favorite_added')
  favoriteAdded,
  @JsonValue('slot_played')
  slotPlayed,
  @JsonValue('slot_win')
  slotWin,
  @JsonValue('coupon_used')
  couponUsed,
  @JsonValue('like_given')
  likeGiven,
  @JsonValue('comment_posted')
  commentPosted,
  @JsonValue('follow_user')
  followUser,
  @JsonValue('coins_earned')
  coinsEarned,
  @JsonValue('mission_completed')
  missionCompleted,
  @JsonValue('recommend_viewed')
  recommendViewed,
  @JsonValue('stamp_card_completed')
  stampCardCompleted,
}

enum BadgeRarity {
  @JsonValue('common')
  common,
  @JsonValue('rare')
  rare,
  @JsonValue('epic')
  epic,
  @JsonValue('legendary')
  legendary,
}

extension BadgeRarityExtension on BadgeRarity {
  String get displayName {
    switch (this) {
      case BadgeRarity.common:
        return 'コモン';
      case BadgeRarity.rare:
        return 'レア';
      case BadgeRarity.epic:
        return 'エピック';
      case BadgeRarity.legendary:
        return 'レジェンダリー';
    }
  }

  String get colorHex {
    switch (this) {
      case BadgeRarity.common:
        return '#9CA3AF'; // グレー
      case BadgeRarity.rare:
        return '#3B82F6'; // ブルー
      case BadgeRarity.epic:
        return '#8B5CF6'; // パープル
      case BadgeRarity.legendary:
        return '#F59E0B'; // ゴールド
    }
  }
}
