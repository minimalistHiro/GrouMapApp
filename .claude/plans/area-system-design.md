# エリアシステム設計プラン

作成日: 2026-03-05
対象ブランチ: 2026-03-04
依存: block-a-cloud-functions.md（`stores.discoveredCount` フィールドが追加済みであること）

---

## 概要

地図上に「エリア」という概念を導入し、ユーザーが各エリアの店舗をどれだけ開拓したかを可視化する。
エリア外の店舗（`areaId == null`）は「秘境スポット」として特別扱いし、探索欲求を高める。

---

## 1. Firestore スキーマ設計

### 1-1. 新規コレクション: `areas`

```
areas/{areaId}
  areaId:        string   // ドキュメントID と同値（例: "shibuya", "shinjuku"）
  name:          string   // 表示名（例: "渋谷エリア"）
  description:   string?  // エリア説明（任意）
  center:        { latitude: number, longitude: number }  // 円の中心座標
  radiusMeters:  number   // 円の半径（メートル単位、例: 500）
  color:         string?  // マップ表示色（16進数 hex、例: "#FF6B35"。未設定時はデフォルト色）
  isActive:      bool     // 表示フラグ（false の場合はマップに表示しない）
  order:         int?     // 表示優先度（小さい値ほど先に表示）
  createdAt:     Timestamp
  updatedAt:     Timestamp
```

**設計メモ:**
- 初期フェーズは Firestore コンソールで管理者が手動設定
- 将来的に `isOwner` 権限を持つ管理画面で UI 設定可能にする
- エリアの重複（複数エリアに属する店舗）は許容する（店舗側の `areaId` は単一）
- 半径は Google Maps SDK の `Circle` ウィジェットと完全互換

### 1-2. `stores/{storeId}` への追加フィールド

```
stores/{storeId}:
  areaId:          string?  // 所属エリアID（null = 秘境スポット）
  discoveredCount: int      // NFCチェックイン初回来店ユニーク数（block-a で追加済み）
```

**設計メモ:**
- `areaId` の設定は初期フェーズは Firestore コンソールで手動設定
- 将来的に `areas` コレクションの `center + radiusMeters` を参照し Cloud Functions で自動設定する余地を残す
- `areaId == null` かつ `isActive=true` かつ `isApproved=true` の店舗が「秘境スポット」

---

## 2. 開拓率のリアルタイム計算方式

### 計算ロジック（クライアントサイド）

開拓率は Firestore からデータを取得後、Flutter クライアント側で計算する。

```
エリア開拓率 = そのエリアの「自分が訪問済みの店舗数」/ そのエリアの「総店舗数」× 100
```

**訪問済み判定:** `users/{uid}/stores/{storeId}` ドキュメントが存在する、かつ `lastVisited != null`

**計算の流れ:**
1. `areas` コレクションを全件取得（`isActive=true` のみ）
2. `stores` コレクションを `isActive=true && isApproved=true` で取得（マップ表示と共通）
3. `users/{uid}/stores/` サブコレクションを取得（既存の `_userStamps` データを流用）
4. エリアごとに `stores.filter(s => s.areaId == area.areaId)` で総数を計算
5. `userVisitedStoreIds.filter(id => areaStoreIds.includes(id))` で訪問済み数を計算
6. 結果をプロバイダー/状態で保持

**パフォーマンス考慮:**
- 店舗数が増加した場合でも計算は O(n × m)（n=店舗数、m=エリア数）で許容範囲
- 初期フェーズは全件取得で問題なし（店舗数が数百程度の想定）
- 将来的に店舗数が 1,000 を超えた場合は `areaId` でインデックスを追加してフィルタ取得を検討

---

## 3. 「秘境スポット」の判定ロジック

```dart
bool isHiddenSpot(Map<String, dynamic> store) {
  final areaId = store['areaId'];
  return areaId == null || areaId == '';
}
```

**表示方針:**
- マップ上でのピン表示: 既存の通常ピンと同じ（特別なアイコンは付けない。コミュニティマップモードでのみ視覚差別化）
- 店舗詳細画面: 「秘境スポット」バッジを表示（`StoreDetailView` に条件追加）
- 将来的に「秘境スポットバッジ」（`hidden_spot_visit_1` など）をバッジ定義に追加する余地を残す

---

## 4. マップ上のエリアオーバーレイ表示

### Google Maps Circle を使用

`google_maps_flutter` の `Circle` ウィジェットを使用する。
`flutter_google_maps` の Heatmap は機能が限定的なため採用しない。

```dart
// _MapViewState 内に追加するフィールド
Set<Circle> _areaCircles = {};
List<Map<String, dynamic>> _areas = [];  // Firestore から取得したエリアデータ
bool _showAreaOverlay = false;           // エリアオーバーレイ表示フラグ
```

```dart
// Circle 生成ロジック（新規メソッド _buildAreaCircles）
Set<Circle> _buildAreaCircles(List<Map<String, dynamic>> areas) {
  final circles = <Circle>{};
  for (final area in areas) {
    if (area['isActive'] != true) continue;
    final lat = area['center']?['latitude'] as double?;
    final lng = area['center']?['longitude'] as double?;
    if (lat == null || lng == null) continue;
    final radius = (area['radiusMeters'] as num?)?.toDouble() ?? 500.0;
    final colorHex = area['color'] as String?;
    final fillColor = _parseHexColor(colorHex, defaultColor: const Color(0xFFFF6B35))
        .withOpacity(0.15);
    final strokeColor = _parseHexColor(colorHex, defaultColor: const Color(0xFFFF6B35))
        .withOpacity(0.6);
    circles.add(Circle(
      circleId: CircleId(area['areaId'] as String),
      center: LatLng(lat, lng),
      radius: radius,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: 2,
    ));
  }
  return circles;
}
```

```dart
// GoogleMap ウィジェットに circles パラメータを追加
GoogleMap(
  // ...,
  circles: _showAreaOverlay ? _areaCircles : {},
)
```

---

## 5. エリア情報の Firestore 読み込み

```dart
// _initializeMapData() 内に追加
await _loadAreas();
```

```dart
Future<void> _loadAreas() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('areas')
        .where('isActive', isEqualTo: true)
        .get();
    final areas = snapshot.docs.map((doc) {
      final data = doc.data();
      data['areaId'] = doc.id;
      return data;
    }).toList();
    if (mounted) {
      setState(() {
        _areas = areas;
        _areaCircles = _buildAreaCircles(areas);
      });
    }
  } catch (e) {
    debugPrint('エリア情報の読み込みに失敗しました: $e');
  }
}
```

---

## 6. 管理者 UI（フェーズ別）

### フェーズ 1: Firestore コンソール手動設定（初期実装）

- `areas` コレクションに管理者が直接ドキュメントを作成
- `stores/{storeId}.areaId` を手動で設定
- `firestore.rules` にルールを追加（下記参照）

### フェーズ 2: 管理画面 UI（将来実装）

- `isOwner` 権限ユーザー向けに管理画面を追加
- マップ上でエリアの円を描画してエリアを作成・編集できる UI
- 店舗にエリアを一括割り当てる機能

---

## 7. Firestore ルール追加

`/Users/kanekohiroki/Desktop/groumapapp/firestore.rules` に追加:

```javascript
// areas コレクション
match /areas/{areaId} {
  allow read: if true;       // 全ユーザー読み取り可能（認証不要）
  allow write: if isOwner(); // 管理者のみ書き込み可能
}
```

**デプロイコマンド:**
```bash
firebase deploy --only firestore:rules
```

---

## 8. Firestore 複合インデックス

今回の実装では以下のクエリが新規発生するが、単一フィールドフィルタのみのため追加インデックスは不要:

- `areas` の `where('isActive', isEqualTo: true)` → 単一フィールドのためインデックス不要
- `stores` の `where('areaId', isEqualTo: areaId)` → 将来実装時に追加を検討

---

## 9. FIRESTORE.md 更新箇所

`stores` セクションに以下を追記:

```
- `areaId`: 所属エリアID（string?、null = 秘境スポット。areas/{areaId} のドキュメントIDと対応）
- `discoveredCount`: NFCチェックイン初回来店ユニーク数（int、block-a で追加）
```

新規セクション `areas` を追加:

```markdown
### areas
- `areas/{areaId}`: エリア定義
  - `areaId`: エリアID（ドキュメントIDと同値）
  - `name`: エリア表示名（例: "渋谷エリア"）
  - `description`: エリア説明（任意）
  - `center`: 中心座標（`{ latitude: number, longitude: number }`）
  - `radiusMeters`: 円の半径（メートル）
  - `color`: マップ表示色（16進数 hex、任意）
  - `isActive`: 表示フラグ
  - `order`: 表示優先度（任意）
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時
- アクセス制御: read は全公開、write は `isOwner()` のみ
```

---

## 10. 新規追加する Flutter ファイル一覧

| ファイルパス | 役割 |
|-------------|------|
| `lib/models/area_model.dart` | エリアデータモデル（`AreaModel`: areaId, name, center, radiusMeters, color, isActive） |
| `lib/providers/area_provider.dart` | エリアデータの Riverpod プロバイダー（`areasProvider`, `areaExplorationRateProvider`） |
| `lib/views/area/area_exploration_view.dart` | エリア開拓率一覧画面（エリアリスト + 開拓率プログレスバー表示） |

---

## 11. 変更対象ファイル一覧

| ファイルパス | 変更内容 |
|-------------|---------|
| `lib/views/map/map_view.dart` | `_areas`, `_areaCircles`, `_showAreaOverlay` フィールド追加、`_loadAreas()`, `_buildAreaCircles()` メソッド追加、`GoogleMap` に `circles` パラメータ追加 |
| `lib/views/stores/store_detail_view.dart` | `areaId == null` の場合に「秘境スポット」バッジを表示 |
| `firestore.rules` | `areas` コレクションのルール追加 |
| `FIRESTORE.md` | `areas` コレクション追加、`stores` に `areaId` / `discoveredCount` フィールド追記 |

---

## 12. 実装順序と依存関係

```
[前提] block-a-cloud-functions.md の実装完了（stores.discoveredCount 追加）
  ↓
Step 1: Firestore コンソールで areas コレクションにサンプルエリアを手動作成
  ↓
Step 2: lib/models/area_model.dart 作成
  ↓
Step 3: lib/providers/area_provider.dart 作成（areasProvider, areaExplorationRateProvider）
  ↓
Step 4: map_view.dart に _loadAreas(), _buildAreaCircles() 追加
  ↓
Step 5: firestore.rules に areas ルール追加 → デプロイ
  ↓
Step 6: FIRESTORE.md 更新
  ↓
Step 7: store_detail_view.dart に「秘境スポット」バッジ追加
  ↓
Step 8: lib/views/area/area_exploration_view.dart 作成（エリア開拓率一覧）
```

---

## 13. 検証チェックリスト

- [ ] Firestore `areas` コレクションが作成でき、マップにサークルオーバーレイが表示されること
- [ ] `_showAreaOverlay` が false のときにサークルが非表示になること
- [ ] `areaId == null` の店舗が「秘境スポット」として判定されること
- [ ] エリア開拓率が正しく計算されること（訪問済み数 / 総店舗数）
- [ ] `areas` コレクションの read が認証不要で可能なこと
- [ ] `areas` コレクションへの write が `isOwner()` 以外で拒否されること
- [ ] `isActive=false` のエリアがマップに表示されないこと
- [ ] 店舗の `areaId` が null の場合に `store_detail_view.dart` で「秘境スポット」バッジが表示されること
