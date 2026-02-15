import 'package:cloud_firestore/cloud_firestore.dart';

class MapFilterModel {
  /// 営業中のみ表示
  final bool showOpenNowOnly;

  /// 選択されたカテゴリ（空リスト = 全カテゴリ表示）
  final List<String> selectedCategories;

  /// 開拓状態フィルター（空リスト = 全て表示）
  /// 'unvisited' = 未開拓, 'exploring' = 開拓中, 'regular' = 常連
  final List<String> explorationStatus;

  /// お気に入りのみ表示
  final bool favoritesOnly;

  /// 決済方法フィルター（カテゴリ単位）
  /// 'cash', 'card', 'emoney', 'qr'
  final List<String> paymentMethodCategories;

  /// クーポンあり店舗のみ
  final bool hasCoupon;

  /// 利用可能クーポンあり店舗のみ
  final bool hasAvailableCoupon;

  /// 最大距離（km単位、null = 制限なし）
  final double? maxDistanceKm;

  /// 更新日時
  final DateTime? updatedAt;

  const MapFilterModel({
    this.showOpenNowOnly = false,
    this.selectedCategories = const [],
    this.explorationStatus = const [],
    this.favoritesOnly = false,
    this.paymentMethodCategories = const [],
    this.hasCoupon = false,
    this.hasAvailableCoupon = false,
    this.maxDistanceKm,
    this.updatedAt,
  });

  /// フィルターが有効かどうか（何か1つでもデフォルトから変更されているか）
  bool get isActive =>
      showOpenNowOnly ||
      selectedCategories.isNotEmpty ||
      explorationStatus.isNotEmpty ||
      favoritesOnly ||
      paymentMethodCategories.isNotEmpty ||
      hasCoupon ||
      hasAvailableCoupon ||
      maxDistanceKm != null;

  MapFilterModel copyWith({
    bool? showOpenNowOnly,
    List<String>? selectedCategories,
    List<String>? explorationStatus,
    bool? favoritesOnly,
    List<String>? paymentMethodCategories,
    bool? hasCoupon,
    bool? hasAvailableCoupon,
    double? Function()? maxDistanceKm,
    DateTime? updatedAt,
  }) {
    return MapFilterModel(
      showOpenNowOnly: showOpenNowOnly ?? this.showOpenNowOnly,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      explorationStatus: explorationStatus ?? this.explorationStatus,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      paymentMethodCategories:
          paymentMethodCategories ?? this.paymentMethodCategories,
      hasCoupon: hasCoupon ?? this.hasCoupon,
      hasAvailableCoupon: hasAvailableCoupon ?? this.hasAvailableCoupon,
      maxDistanceKm:
          maxDistanceKm != null ? maxDistanceKm() : this.maxDistanceKm,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showOpenNowOnly': showOpenNowOnly,
      'selectedCategories': selectedCategories,
      'explorationStatus': explorationStatus,
      'favoritesOnly': favoritesOnly,
      'paymentMethodCategories': paymentMethodCategories,
      'hasCoupon': hasCoupon,
      'hasAvailableCoupon': hasAvailableCoupon,
      'maxDistanceKm': maxDistanceKm,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MapFilterModel.fromMap(Map<String, dynamic> map) {
    return MapFilterModel(
      showOpenNowOnly: map['showOpenNowOnly'] as bool? ?? false,
      selectedCategories:
          (map['selectedCategories'] as List<dynamic>?)?.cast<String>() ??
              const [],
      explorationStatus:
          (map['explorationStatus'] as List<dynamic>?)?.cast<String>() ??
              const [],
      favoritesOnly: map['favoritesOnly'] as bool? ?? false,
      paymentMethodCategories:
          (map['paymentMethodCategories'] as List<dynamic>?)?.cast<String>() ??
              const [],
      hasCoupon: map['hasCoupon'] as bool? ?? false,
      hasAvailableCoupon: map['hasAvailableCoupon'] as bool? ?? false,
      maxDistanceKm: (map['maxDistanceKm'] as num?)?.toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
