# GrouMapアプリ - システム概要・アーキテクチャ

## 1. システム全体設計

### 1.1 アーキテクチャ概要
```
[ユーザーアプリ] ←→ [Firebase] ←→ [店舗用アプリ]
       ↓                 ↓              ↓
  [Google Maps]    [Firestore]    [管理機能]
                   [Auth]
                   [Storage]
                   [Functions]
                   [FCM]
```

### 1.2 技術スタック
- **フロントエンド**: Flutter (Dart SDK ^3.5.0)
- **状態管理**: Riverpod
- **バックエンド**: Firebase Suite
- **地図サービス**: Google Maps Platform
- **コードスタイル**: flutter_lints ^4.0.0

### 1.3 アプリケーション設計

#### プロジェクト構成
```
lib/
├── main.dart                    # エントリポイント
├── core/                        # 共通コア機能
├── models/                      # データモデル
├── repositories/                # データアクセス層
├── services/                    # サービス層
├── providers/                   # Riverpod状態管理
├── views/                       # UI画面
└── widgets/                     # 再利用可能ウィジェット
```

#### 状態管理設計（Riverpod）

##### 認証プロバイダー
```dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
```

##### ユーザープロバイダー
```dart
final userProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).getUserStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
```

##### 店舗プロバイダー
```dart
final storesProvider = StreamProvider<List<StoreModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getStoresStream();
});

final storeProvider = StreamProvider.family<StoreModel?, String>((ref, storeId) {
  return ref.watch(firestoreServiceProvider).getStoreStream(storeId);
});

final nearbyStoresProvider = StreamProvider.family<List<StoreModel>, LatLng>((ref, location) {
  return ref.watch(firestoreServiceProvider).getNearbyStoresStream(location);
});
```

### 1.4 パフォーマンス最適化設計

#### 画像最適化
```dart
class ImageOptimizationService {
  static Future<File> compressImage(File imageFile) async {
    final compressedImage = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 800,
      minHeight: 600,
      quality: 85,
    );
    
    return File.fromRawPath(compressedImage!);
  }
  
  static String getOptimizedImageUrl(String originalUrl, {int? width, int? height}) {
    // Firebase Storage の画像変換パラメータを使用
    final uri = Uri.parse(originalUrl);
    final params = <String, String>{};
    
    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    params['q'] = '85'; // 品質85%
    
    return uri.replace(queryParameters: {...uri.queryParameters, ...params}).toString();
  }
}
```

#### 地図パフォーマンス
```dart
class MapPerformanceService {
  static const int _maxMarkersDisplayed = 100;
  static const double _clusterRadius = 50.0;
  
  // マーカークラスタリング
  static List<MapMarker> clusterMarkers(List<StoreModel> stores, double zoom) {
    if (zoom > 12) {
      // 高ズーム時は全マーカー表示
      return stores.take(_maxMarkersDisplayed).map((store) => 
        MapMarker.fromStore(store)
      ).toList();
    } else {
      // 低ズーム時はクラスタリング
      return _performClustering(stores);
    }
  }
  
  static List<MapMarker> _performClustering(List<StoreModel> stores) {
    // クラスタリングアルゴリズムの実装
    // ...
  }
}
```

### 1.5 セキュリティ設計

#### 認証・認可
```dart
class SecurityService {
  // 権限レベルチェック
  static bool hasPermission(UserModel user, String permission) {
    switch (permission) {
      case 'store_management':
        return user.isStoreOwner || user.isCompanyAdmin;
      case 'company_admin':
        return user.isCompanyAdmin;
      case 'premium_features':
        return user.hasPremiumPlan;
      default:
        return false;
    }
  }
  
  // セキュアなファイルアップロード
  static Future<String> uploadSecureFile(File file, String path) async {
    // ファイルタイプチェック
    final mimeType = lookupMimeType(file.path);
    if (!_isAllowedMimeType(mimeType)) {
      throw Exception('許可されていないファイルタイプです');
    }
    
    // ファイルサイズチェック
    final fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) { // 10MB制限
      throw Exception('ファイルサイズが大きすぎます');
    }
    
    // Firebase Storage にアップロード
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = await ref.putFile(file);
    
    return await uploadTask.ref.getDownloadURL();
  }
  
  static bool _isAllowedMimeType(String? mimeType) {
    const allowedTypes = [
      'image/jpeg',
      'image/png',
      'image/webp',
    ];
    return mimeType != null && allowedTypes.contains(mimeType);
  }
}
```

---

**参照**：
- [データベース設計](./02-database.md)
- [QRコード機能設計](./06-qr-system.md)
- [投稿・クーポン機能](./08-posts-coupons.md)
- [Firebase Functions設計](./12-functions.md)