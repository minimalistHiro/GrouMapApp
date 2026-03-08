# NFCチェックイン セキュリティ強化計画

作成日: 2026-03-08

## 背景・目的

NFCタッチ時に生成されるチェックインURLは静的な `tagSecret` を含む。このURLがブラウザ履歴に残ると、ユーザーが翌日以降に自宅から同URLを開いてアプリを起動し、実際に店舗へ行かずにチェックインできてしまう問題がある。

以下の2つの対策を組み合わせて実装する：
1. **位置情報チェック（ジオフェンス）**: チェックイン時に店舗から200m以内であることを検証
2. **チェックインセッション**: Deep Link起動時に10分間有効な使い捨てトークンを発行し、`tagSecret` を直接使わせない

---

## 現状の問題

| 問題 | 内容 |
|------|------|
| 静的なURL | `https://groumapapp.web.app/checkin?storeId=xxx&secret=yyy` がブラウザ履歴に残る |
| 位置情報チェックなし | Cloud Functions `nfcCheckin` は `tagSecret` の有効性と1日1回制限しか検証しない |
| `stores.location` 未活用 | Firestoreに `location: { latitude, longitude }` は存在するが使われていない |

---

## 設計内容

### セキュリティフロー（変更後）

```
① Deep Link起動（NFC or ブラウザ履歴）
   ↓
② createCheckinSession(storeId, tagSecret)  ← 新規Cloud Function
   - tagSecret を検証
   - sessionToken（UUID）を生成、10分間有効でFirestoreに保存
   ↓
③ NfcCouponSelectView 表示（sessionTokenを保持）
   ↓
④ ユーザーが「発見する」タップ
   ↓
⑤ 位置情報を取得（geolocator）
   ↓
⑥ nfcCheckin(sessionToken, userLat, userLng, selectedCouponIds)
   - セッション有効性チェック（期限切れ・使用済み・userId不一致 → エラー）
   - 位置情報チェック（店舗から200m超 → エラー）
   - sessionToken を used:true に更新
   - 既存のスタンプ処理を実行
```

### 新規Firestoreコレクション: `checkin_sessions`

```
checkin_sessions/{sessionId}: {
  userId:    string,      // チェックインを実行するユーザーUID
  storeId:   string,      // 対象店舗ID
  expiresAt: Timestamp,   // now + 10分
  used:      boolean,     // 使用済みフラグ（初期値: false）
  createdAt: Timestamp
}
```

---

## 実装内容

### 1. Cloud Functions: `createCheckinSession`（新規）

**ファイル**: `backend/functions/src/index.ts`

```typescript
export const createCheckinSession = onCall({ region: 'asia-northeast1' }, async (request) => {
  // 認証チェック
  // storeId + tagSecret で nfc_tags を検索・検証
  // 店舗の isActive/isApproved チェック
  // checkin_sessions に sessionId（UUID）を保存（expiresAt = now + 10min）
  // return { sessionToken: sessionId }
})
```

**エラーケース**:
- `unauthenticated`: 未ログイン
- `not-found`: 無効な tagSecret
- `failed-precondition`: タグ無効化済み / 店舗非アクティブ

---

### 2. Cloud Functions: `nfcCheckin`（修正）

**ファイル**: `backend/functions/src/index.ts`（行4095〜）

**入力パラメータの変更**:

| 変更前 | 変更後 |
|--------|--------|
| `storeId`, `tagSecret`, `selectedUserCouponIds?` | `sessionToken`, `userLat`, `userLng`, `selectedUserCouponIds?` |

**追加するバリデーション（既存処理の前に挿入）**:

```typescript
// 1. セッション検証
const sessionRef = db.collection('checkin_sessions').doc(sessionToken);
const sessionSnap = await sessionRef.get();
if (!sessionSnap.exists) throw new HttpsError('not-found', 'Invalid session');
const session = sessionSnap.data()!;
if (session.used) throw new HttpsError('already-exists', 'Session already used');
if (session.userId !== userId) throw new HttpsError('permission-denied', 'Session user mismatch');
if (session.expiresAt.toDate() < new Date()) throw new HttpsError('deadline-exceeded', 'Session expired');
const storeId = session.storeId;

// 2. 位置情報チェック
const storeLocation = storeData['location'] as { latitude: number; longitude: number };
const distanceMeters = haversineDistance(
  { lat: userLat, lng: userLng },
  { lat: storeLocation.latitude, lng: storeLocation.longitude }
);
if (distanceMeters > 200) {
  throw new HttpsError('permission-denied', `Too far from store: ${Math.round(distanceMeters)}m`);
}

// 3. セッションを使用済みにマーク（トランザクション外で先に実行）
await sessionRef.update({ used: true });
```

**Haversine距離計算関数**（index.ts に追加）:
```typescript
function haversineDistance(a: {lat: number, lng: number}, b: {lat: number, lng: number}): number {
  const R = 6371000; // 地球半径（m）
  const φ1 = a.lat * Math.PI / 180;
  const φ2 = b.lat * Math.PI / 180;
  const Δφ = (b.lat - a.lat) * Math.PI / 180;
  const Δλ = (b.lng - a.lng) * Math.PI / 180;
  const x = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
             Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ/2) * Math.sin(Δλ/2);
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1-x));
}
```

---

### 3. Flutter: `NfcCheckinService`（修正）

**ファイル**: `lib/services/nfc_checkin_service.dart`

```dart
// 新規追加: セッション作成
Future<String> createCheckinSession({
  required String storeId,
  required String tagSecret,
}) async {
  final callable = _functions.httpsCallable('createCheckinSession');
  final result = await callable.call({'storeId': storeId, 'tagSecret': tagSecret});
  return (result.data as Map)['sessionToken'] as String;
}

// 変更: tagSecret → sessionToken + 位置情報
Future<NfcCheckinResult> checkin({
  required String sessionToken,
  required double userLat,
  required double userLng,
  List<String>? selectedUserCouponIds,
}) async { ... }
```

---

### 4. Flutter: `MainNavigationView`（修正）

**ファイル**: `lib/views/main_navigation_view.dart`

`_handleCheckinDeepLink()` 内でDeep Link受信直後に `createCheckinSession` を呼び出し、`sessionToken` を `NfcCouponSelectView` に渡す。

```dart
// 変更前
Navigator.push(...NfcCouponSelectView(storeId: ..., tagSecret: ...))

// 変更後（ローディング表示後にセッション作成）
final sessionToken = await NfcCheckinService().createCheckinSession(
  storeId: link.storeId,
  tagSecret: link.tagSecret,
);
Navigator.push(...NfcCouponSelectView(storeId: ..., sessionToken: sessionToken))
```

**エラーハンドリング**:
- `not-found` / `failed-precondition`: 「無効なNFCタグです」ダイアログ
- `deadline-exceeded`: 「セッションの有効期限が切れました。もう一度NFCにタッチしてください」

---

### 5. Flutter: `NfcCouponSelectView`（修正）

**ファイル**: `lib/views/checkin/nfc_coupon_select_view.dart`

- コンストラクタの `tagSecret` を `sessionToken` に変更
- `_doCheckin()` 内で `geolocator` を使って現在地を取得してから `checkin()` を呼び出す

```dart
// _doCheckin() 内
// 位置情報取得
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
  timeLimit: const Duration(seconds: 10),
);

final result = await NfcCheckinService().checkin(
  sessionToken: widget.sessionToken,
  userLat: position.latitude,
  userLng: position.longitude,
  selectedUserCouponIds: _selectedCouponIds.toList(),
);
```

**権限チェック**（`_doCheckin()` の先頭）:
```dart
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
if (permission == LocationPermission.denied ||
    permission == LocationPermission.deniedForever) {
  // エラーダイアログ表示: 位置情報が必要です
  return;
}
```

**エラーハンドリング追加**:
| エラーコード | 表示メッセージ |
|------------|-------------|
| `permission-denied` (距離) | 「店舗から離れすぎています。店舗の近くでチェックインしてください」 |
| `deadline-exceeded` | 「セッションの有効期限が切れました。再度NFCにタッチしてください」 |
| `already-exists` (セッション使用済み) | 「このチェックインは既に使用されています」 |
| 位置情報取得失敗 | 「位置情報の取得に失敗しました。しばらく待ってから再試行してください」 |

---

### 6. Firestore Rules（追加）

**ファイル**: `firestore.rules`

```
match /checkin_sessions/{sessionId} {
  // クライアントからの直接読み書き禁止（Cloud Functions のみ操作）
  allow read, write: if false;
}
```

---

### 7. Firestore Indexes（追加）

**ファイル**: `firestore.indexes.json`

`checkin_sessions` は sessionId（ドキュメントID）でのみアクセスするため追加インデックス不要。

---

### 8. pubspec.yaml（追加）

```yaml
dependencies:
  geolocator: ^13.0.0
```

**iOS Info.plist に追加**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>チェックイン時に店舗の近くにいることを確認するために位置情報を使用します。</string>
```

**Android AndroidManifest.xml に追加**:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

---

## ファイル変更一覧

| ファイル | 変更内容 |
|---------|---------|
| `backend/functions/src/index.ts` | `createCheckinSession` 新規追加、`nfcCheckin` のパラメータ変更・バリデーション追加、haversineDistance 関数追加 |
| `lib/services/nfc_checkin_service.dart` | `createCheckinSession()` 追加、`checkin()` のシグネチャ変更 |
| `lib/views/main_navigation_view.dart` | セッション作成呼び出し追加、sessionToken を NfcCouponSelectView に渡す |
| `lib/views/checkin/nfc_coupon_select_view.dart` | `tagSecret` → `sessionToken`、位置情報取得・権限チェック追加 |
| `firestore.rules` | `checkin_sessions` コレクションのルール追加 |
| `pubspec.yaml` | `geolocator` パッケージ追加 |
| `ios/Runner/Info.plist` | 位置情報使用説明文追加 |
| `android/app/src/main/AndroidManifest.xml` | 位置情報パーミッション追加 |

---

## 実装優先順位

1. **フェーズ1（必須）**: Cloud Functions の `createCheckinSession` 新規実装 + `nfcCheckin` セッション検証追加
2. **フェーズ2（必須）**: Flutter側のセッション作成・パラメータ変更（`MainNavigationView` / `NfcCouponSelectView` / `NfcCheckinService`）
3. **フェーズ3（必須）**: 位置情報チェック実装（`geolocator` 導入、権限フロー、ジオフェンスバリデーション）
4. **フェーズ4（仕上げ）**: Firestoreルール追加・デプロイ、ネイティブ設定追加

---

## 注意事項

- `stores.location` フィールドは既存スキーマに存在するが、未登録店舗（location が null）の場合は位置情報チェックをスキップして `permission-denied` を返す
- GPS精度は `LocationAccuracy.high` を指定するが、屋内では誤差が大きくなる可能性あり。200mの閾値はこの誤差を考慮した設定
- セッション有効期限は10分。クーポン選択中に期限切れになった場合は「再度NFCにタッチ」を案内する
- `checkin_sessions` の古いドキュメントは定期クリーンアップ（Cloud Scheduler + 別Function）を将来的に検討
- 位置情報権限を拒否したユーザーはチェックイン不可。設定画面への誘導メッセージを表示する
