import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 図鑑用の統合データクラス
class ZukanStoreItem {
  final Map<String, dynamic> store;
  final bool isDiscovered;

  const ZukanStoreItem({required this.store, required this.isDiscovered});

  String get storeId => store['storeId'] as String;
  String get name => store['name'] as String? ?? '';
  String get category => store['category'] as String? ?? 'その他';
  String? get description => store['description'] as String?;
  String? get areaId => store['areaId'] as String?;

  // レア度計算（rarityOverrideが存在する場合は優先）
  int get rarityLevel {
    final override = store['rarityOverride'];
    if (override != null) return (override as num).toInt();
    final count = (store['discoveredCount'] as num?)?.toInt() ?? 0;
    if (count == 0) return 4; // レジェンド
    if (count <= 5) return 3; // エピック
    if (count <= 20) return 2; // レア
    return 1; // コモン
  }

  String get rarityLabel {
    switch (rarityLevel) {
      case 4:
        return 'レジェンド';
      case 3:
        return 'エピック';
      case 2:
        return 'レア';
      default:
        return 'コモン';
    }
  }

  String get rarityStars {
    return '★' * rarityLevel + '☆' * (4 - rarityLevel);
  }

  Color get rarityColor {
    switch (rarityLevel) {
      case 4:
        return const Color(0xFFFFB300); // ゴールド
      case 3:
        return const Color(0xFF7B1FA2); // パープル
      case 2:
        return const Color(0xFF1565C0); // ブルー
      default:
        return const Color(0xFF757575); // グレー
    }
  }

  int get discoveredCount => (store['discoveredCount'] as num?)?.toInt() ?? 0;

  String? get iconImageUrl => store['iconImageUrl'] as String?;

  List<String> get images {
    final raw = store['images'];
    if (raw is List) return raw.cast<String>();
    return [];
  }

  String? get firstImageUrl =>
      iconImageUrl ?? (images.isNotEmpty ? images.first : null);
}

// 全店舗一覧（isActive=true / isApproved=true / isOwner=false）
// discoveredCount / rarityOverride / areaId を含む rawMap で取得
// zukanOrder 順（未設定の場合は createdAt 順）でソート
final zukanAllStoresProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('stores')
      .where('isActive', isEqualTo: true)
      .where('isApproved', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    final docs = snapshot.docs
        .where((doc) {
          final data = doc.data();
          final isOwner = data['isOwner'];
          return isOwner != true &&
              isOwner?.toString().toLowerCase() != 'true';
        })
        .map((doc) {
          final data = doc.data();
          data['storeId'] = doc.id;
          return data;
        })
        .toList();
    // zukanOrder 順でソート（未設定は末尾に）
    docs.sort((a, b) {
      final aOrder = (a['zukanOrder'] as num?)?.toInt();
      final bOrder = (b['zukanOrder'] as num?)?.toInt();
      if (aOrder == null && bOrder == null) return 0;
      if (aOrder == null) return 1;
      if (bOrder == null) return -1;
      return aOrder.compareTo(bOrder);
    });
    return docs;
  });
});

// ログイン中ユーザーの発見済みstoreId一覧
// users/{uid}/stores サブコレクションのドキュメントIDをSetで返す
final userVisitedStoreIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return Stream.value(<String>{});
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('stores')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .where((doc) {
          // lastVisited が存在するもののみ発見済みとみなす
          return doc.data()['lastVisited'] != null;
        })
        .map((doc) => doc.id)
        .toSet();
  });
});

// 図鑑用の統合データ（全店舗 + 発見済みフラグ）
final zukanStoresProvider = Provider<AsyncValue<List<ZukanStoreItem>>>((ref) {
  final allStores = ref.watch(zukanAllStoresProvider);
  final visitedIds = ref.watch(userVisitedStoreIdsProvider);
  return allStores.whenData((stores) {
    final visited = visitedIds.valueOrNull ?? {};
    return stores
        .map((s) => ZukanStoreItem(
              store: s,
              isDiscovered: visited.contains(s['storeId'] as String),
            ))
        .toList();
  });
});

// 発見済み店舗数（ホーム画面の統計カプセルバー / ProfileView で使用）
final userDiscoveredStoreCountProvider = Provider<int>((ref) {
  return ref.watch(userVisitedStoreIdsProvider).valueOrNull?.length ?? 0;
});
