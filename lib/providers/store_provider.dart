import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';

// 店舗情報を取得するプロバイダー
List<String> _buildImagesList(Map<String, dynamic> data) {
  final List<String> images = List<String>.from(data['images'] ?? []);
  final String? iconImageUrl = data['iconImageUrl'];
  
  // iconImageUrlが存在し、imagesに含まれていない場合は追加
  if (iconImageUrl != null && iconImageUrl.isNotEmpty && !images.contains(iconImageUrl)) {
    images.insert(0, iconImageUrl); // 最初に追加
  }
  
  return images;
}

final storeProvider = FutureProvider.family<StoreModel?, String>((ref, storeId) async {
  try {
    print('storeProvider: 店舗情報取得開始 - storeId: $storeId');
    
    final doc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();
    
    print('storeProvider: ドキュメント取得完了 - exists: ${doc.exists}');
    
    if (!doc.exists) {
      print('storeProvider: 店舗が見つかりません');
      return null;
    }
    
    final data = doc.data()!;
    print('storeProvider: 店舗データ: $data');
    print('storeProvider: 店舗名: ${data['name']}');
    print('storeProvider: 説明: ${data['description']}');
    print('storeProvider: 住所: ${data['address']}');
    print('storeProvider: カテゴリ: ${data['category']}');
    print('storeProvider: createdBy: ${data['createdBy']}');
    print('storeProvider: createdAt: ${data['createdAt']}');
    print('storeProvider: updatedAt: ${data['updatedAt']}');
    print('storeProvider: iconImageUrl: ${data['iconImageUrl']}');
    print('storeProvider: storeImageUrl: ${data['storeImageUrl']}');
    print('storeProvider: 利用可能なフィールド: ${data.keys.toList()}');
    
    // businessHoursの構造を変換
    final businessHours = data['businessHours'] as Map<String, dynamic>?;
    Map<String, dynamic>? convertedBusinessHours;
    
    if (businessHours != null) {
      convertedBusinessHours = {};
      for (final entry in businessHours.entries) {
        final dayData = entry.value as Map<String, dynamic>;
        final openTime = dayData['open']?.toString() ?? '09:00';
        final closeTime = dayData['close']?.toString() ?? '18:00';
        convertedBusinessHours[entry.key] = {
          'open': openTime,
          'close': closeTime,
          'isClosed': !(dayData['isOpen'] ?? true),
        };
        print('storeProvider: ${entry.key} - open: $openTime, close: $closeTime, isOpen: ${dayData['isOpen']}');
      }
    }
    
    // 実際のFirestoreデータ構造に合わせてフィールドを設定
    final storeData = {
      'storeId': storeId,
      'name': data['name'] ?? '店舗名なし',
      'description': data['description'] ?? '説明なし',
      'address': data['address'] ?? '住所なし',
      'location': data['location'] ?? {'latitude': 0.0, 'longitude': 0.0},
      'category': data['category'] ?? 'その他',
      'ownerId': data['createdBy'] ?? 'unknown',
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'images': _buildImagesList(data), // iconImageUrlとimagesを組み合わせ
      'plan': 'small', // デフォルト値
      'isCompanyAdmin': false, // デフォルト値
      'monthlyPointsIssued': 0, // デフォルト値
      'pointsLimit': 1000, // デフォルト値
      'qrCode': null, // デフォルト値
      'companyInfo': null, // デフォルト値
      if (convertedBusinessHours != null) 'operatingHours': convertedBusinessHours,
    };
    
    // businessHoursフィールドを削除（operatingHoursに変換済み）
    storeData.remove('businessHours');
    
    print('storeProvider: 変換後の店舗データ: $storeData');
    
    final store = StoreModel.fromJson(storeData);
    print('storeProvider: 店舗モデル作成完了 - name: ${store.name}');
    
    return store;
  } catch (e) {
    print('storeProvider: 店舗情報取得エラー: $e');
    return null;
  }
});

// 店舗情報の状態管理
class StoreState {
  final StoreModel? store;
  final bool isLoading;
  final String? error;

  StoreState({
    this.store,
    this.isLoading = false,
    this.error,
  });

  StoreState copyWith({
    StoreModel? store,
    bool? isLoading,
    String? error,
  }) {
    return StoreState(
      store: store ?? this.store,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StoreNotifier extends StateNotifier<StoreState> {
  StoreNotifier() : super(StoreState());

  Future<void> loadStore(String storeId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('店舗情報を取得中: $storeId');
      
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();
      
      print('店舗ドキュメントの存在: ${doc.exists}');
      
      if (!doc.exists) {
        state = state.copyWith(
          isLoading: false,
          error: '店舗が見つかりません',
        );
        return;
      }
      
      final data = doc.data()!;
      print('店舗データ: $data');
      
      // storeIdフィールドを追加してStoreModelを作成
      final storeData = {
        'storeId': storeId,
        ...data,
      };
      
      final store = StoreModel.fromJson(storeData);
      print('作成された店舗モデル: ${store.name}');
      
      state = state.copyWith(
        store: store,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      print('店舗情報取得エラー: $e');
      state = state.copyWith(
        isLoading: false,
        error: '店舗情報の取得に失敗しました: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final storeNotifierProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  return StoreNotifier();
});

// 店舗名を取得するプロバイダー
final storeNameProvider = FutureProvider.family<String?, String>((ref, storeId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();
    
    if (!doc.exists) {
      return null;
    }
    
    final data = doc.data()!;
    return data['name'] as String?;
  } catch (e) {
    print('店舗名取得エラー: $e');
    return null;
  }
});

// 全店舗一覧を取得するプロバイダー
final storesProvider = StreamProvider<List<StoreModel>>((ref) async* {
  try {
    yield* FirebaseFirestore.instance
        .collection('stores')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StoreModel.fromJson({
          'storeId': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  } catch (e) {
    print('店舗一覧取得エラー: $e');
    yield <StoreModel>[];
  }
});