# マップ拡張設計プラン

作成日: 2026-03-05
対象ブランチ: 2026-03-04
依存:
- block-a-cloud-functions.md（`stores.discoveredCount` 追加済みであること）
- area-system-design.md（`areas` コレクション・`_loadAreas()` 実装済みであること）

---

## 概要

既存のマップ表示モードに 2 つの新しいビュー（個人マップレイヤー・コミュニティマップ）を追加する。
既存の `_buildMarkerBitmap()` / `_resolveMarkerVisual()` の仕組みを最大限流用し、
新規コードを最小限に抑えた設計とする。

---

## 1. 個人マップレイヤー: totalVisits に応じたピン色変化

### 1-1. 5段階ステータス定義

| ステータス名 | 条件 | ピン色（pinAccentColor） | 意味 |
|------------|------|------------------------|------|
| undiscovered（未発見） | `users/{uid}/stores/{storeId}` 存在しない | `Color(0xFFBDBDBD)` グレー | 未チェックイン |
| discovered（初発見） | `totalVisits == 1` | `Color(0xFF29B6F6)` ライトブルー | 初めて来店 |
| exploring（探索中） | `totalVisits 2〜4` | `Color(0xFF66BB6A)` グリーン | リピーター途中 |
| regular（常連） | `totalVisits 5〜9` | `Color(0xFFFB8C00)` オレンジ | 常連（既存の開拓モードに準拠） |
| legend（レジェンド） | `totalVisits >= 10` | `Color(0xFFFFB300)` ゴールド | 最高ランク（既存の常連色に準拠） |

**既存モードとの整合性:**
- 既存の `_pioneerMode` では `visited`（スタンプ1枚以上）= オレンジ、`regular`（スタンプ多め）= ゴールドだった
- 新しい個人マップレイヤーはこの色設計を継承・拡張する

### 1-2. totalVisits の取得元

`users/{uid}/stores/{storeId}` に `totalVisits` フィールドをミラー書き込みする（Cloud Functions 側で対応）。

**実装方針:**
- `nfcCheckin` Cloud Function のトランザクション内で `users/{uid}/stores/{storeId}.totalVisits` をミラー書き込み
- これにより既存の `_userStamps` 読み込みロジックを変更せずに `totalVisits` を参照できる
- `_userStamps[storeId]['totalVisits']` として参照可能になる

### 1-3. `_resolveMarkerVisual()` への追加（L920-975）

```dart
// 個人マップモード（_personalMapMode == true 時）を最優先で処理
if (_personalMapMode) {
  final totalVisits = (_userStamps[storeId]?['totalVisits'] as num?)?.toInt() ?? 0;
  final status = _getPersonalMapStatus(totalVisits);
  return _MarkerVisual(
    color: Colors.white,
    iconData: _getPersonalMapIcon(status),
    useImage: false,
    iconColor: _getPersonalMapColor(status),
  );
}
```

```dart
String _getPersonalMapStatus(int totalVisits) {
  if (totalVisits == 0) return 'undiscovered';
  if (totalVisits == 1) return 'discovered';
  if (totalVisits <= 4) return 'exploring';
  if (totalVisits <= 9) return 'regular';
  return 'legend';
}

Color _getPersonalMapColor(String status) {
  switch (status) {
    case 'undiscovered': return const Color(0xFFBDBDBD);
    case 'discovered':   return const Color(0xFF29B6F6);
    case 'exploring':    return const Color(0xFF66BB6A);
    case 'regular':      return const Color(0xFFFB8C00);
    case 'legend':       return const Color(0xFFFFB300);
    default:             return const Color(0xFFBDBDBD);
  }
}

IconData _getPersonalMapIcon(String status) {
  switch (status) {
    case 'undiscovered': return Icons.radio_button_unchecked;
    case 'discovered':   return Icons.explore;
    case 'exploring':    return Icons.directions_walk;
    case 'regular':      return Icons.radio_button_checked;
    case 'legend':       return Icons.star;
    default:             return Icons.radio_button_unchecked;
  }
}
```

---

## 2. コミュニティマップ: エリアオーバーレイ + 賑わい度のトグル

### 2-1. コミュニティマップモードの定義

`_communityMapMode` フラグを追加し、以下の 2 つのサブビューをトグルで切り替える:

| サブビュー | 値 | 表示内容 |
|----------|-------|---------|
| 開拓率ビュー | `_communitySubMode == 'exploration'` | エリアサークルオーバーレイ（area-system-design.md 参照） |
| 賑わい度ビュー | `_communitySubMode == 'activity'` | `discoveredCount` に応じたサークルオーバーレイ（ヒートマップ代替） |

```dart
// _MapViewState に追加するフィールド
bool _communityMapMode = false;
String _communitySubMode = 'exploration'; // 'exploration' | 'activity'
```

### 2-2. 賑わい度ビュー: discoveredCount に応じたサークルオーバーレイ

`flutter_google_maps` の Heatmap 機能は Flutter プラグインとしてサポートが限定的なため、
`Circle` オーバーレイで代替する。

**賑わい度の5段階:**

| discoveredCount | サークル色（fillColor） | 半径 | 意味 |
|---------------|----------|------|------|
| 0 | 表示なし | - | 未開拓 |
| 1〜5 | `Color(0x1A29B6F6)` | 40m | ほぼ未開拓 |
| 6〜20 | `Color(0x3366BB6A)` | 60m | 探索始まり |
| 21〜50 | `Color(0x4DFB8C00)` | 80m | 賑わっている |
| 51〜 | `Color(0x66FFB300)` | 100m | 超人気スポット |

```dart
Set<Circle> _buildActivityCircles() {
  final circles = <Circle>{};
  for (final store in _filteredStores) {
    final discoveredCount = (store['discoveredCount'] as num?)?.toInt() ?? 0;
    if (discoveredCount == 0) continue;

    final lat = store['location']?['latitude'] as double?;
    final lng = store['location']?['longitude'] as double?;
    if (lat == null || lng == null) continue;
    final storeId = store['storeId'] as String;

    Color fillColor;
    double radius;
    if (discoveredCount <= 5) {
      fillColor = const Color(0x1A29B6F6);
      radius = 40;
    } else if (discoveredCount <= 20) {
      fillColor = const Color(0x3366BB6A);
      radius = 60;
    } else if (discoveredCount <= 50) {
      fillColor = const Color(0x4DFB8C00);
      radius = 80;
    } else {
      fillColor = const Color(0x66FFB300);
      radius = 100;
    }

    circles.add(Circle(
      circleId: CircleId('activity_$storeId'),
      center: LatLng(lat, lng),
      radius: radius,
      fillColor: fillColor,
      strokeWidth: 0,
    ));
  }
  return circles;
}
```

---

## 3. モード切り替え UI の設計

### 3-1. 既存の `_selectedMode` を拡張

現在の `_selectedMode` は `'none' | 'category' | 'pioneer'` の 3 値。
これを拡張し、新モードを追加する:

```dart
// 変更後の値一覧
// 'none' | 'category' | 'pioneer' | 'personal' | 'community'
bool _personalMapMode = false;
bool _communityMapMode = false;
```

```dart
// モード一括切り替えメソッドを追加
void _setMapMode(String mode) {
  setState(() {
    _selectedMode = mode;
    _categoryMode = mode == 'category';
    _pioneerMode = mode == 'pioneer';
    _personalMapMode = mode == 'personal';
    _communityMapMode = mode == 'community';
    if (mode != 'community') {
      _communitySubMode = 'exploration'; // リセット
    }
  });
  _markerIconFutureCache.clear();
  _createMarkers();
}
```

### 3-2. フィルターチップ UI の更新（L2276-2400 付近）

既存の「開拓モード」チップの後に 2 つのチップを追加:

```dart
FilterChip(
  label: const Text('個人マップ'),
  selected: _selectedMode == 'personal',
  onSelected: (val) => _setMapMode(val ? 'personal' : 'none'),
  avatar: const Icon(Icons.person_pin, size: 16),
),
FilterChip(
  label: const Text('コミュニティ'),
  selected: _selectedMode == 'community',
  onSelected: (val) => _setMapMode(val ? 'community' : 'none'),
  avatar: const Icon(Icons.groups, size: 16),
),
```

### 3-3. コミュニティモード時のサブモードトグル UI

コミュニティモード選択時に、マップ上部に「開拓率」/「賑わい度」のトグルを表示:

```dart
Widget _buildCommunitySubModeToggle() {
  return Positioned(
    top: topPadding + 60,
    left: 20,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          _buildSubModeButton('開拓率', 'exploration'),
          const SizedBox(width: 4),
          _buildSubModeButton('賑わい度', 'activity'),
        ],
      ),
    ),
  );
}

Widget _buildSubModeButton(String label, String mode) {
  final isSelected = _communitySubMode == mode;
  return GestureDetector(
    onTap: () => setState(() => _communitySubMode = mode),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}
```

---

## 4. GoogleMap ウィジェットへの circles 統合

コミュニティモードと area-system-design.md のエリアオーバーレイを統合:

```dart
Set<Circle> _getActiveCircles() {
  if (_communityMapMode) {
    if (_communitySubMode == 'exploration') {
      return _areaCircles; // area-system-design.md で実装
    } else {
      return _buildActivityCircles();
    }
  }
  return {};
}

// GoogleMap ウィジェット
GoogleMap(
  // ...,
  circles: _getActiveCircles(),
)
```

---

## 5. `_resolveMarkerVisual()` の最終フロー

```dart
_MarkerVisual _resolveMarkerVisual({
  required String flowerType,
  required String category,
  required String storeIconUrl,
  String storeId = '',  // ← 引数追加
}) {
  // [追加] 個人マップモード（最優先）
  if (_personalMapMode) {
    final totalVisits = (_userStamps[storeId]?['totalVisits'] as num?)?.toInt() ?? 0;
    final status = _getPersonalMapStatus(totalVisits);
    return _MarkerVisual(
      color: Colors.white,
      iconData: _getPersonalMapIcon(status),
      useImage: false,
      iconColor: _getPersonalMapColor(status),
    );
  }

  // [既存] 開拓モード
  if (_pioneerMode) { /* ... 既存コード ... */ }

  // [既存] カテゴリモード
  if (_categoryMode) { /* ... 既存コード ... */ }

  // [既存] 通常モード
  // ...
}
```

**注意:** `_resolveMarkerVisual()` の呼び出し元（`_createMarkers()` L1197）も `storeId` を渡すよう変更が必要。

---

## 6. cacheKey の更新（L1219-1220）

```dart
final String cacheKey = _personalMapMode
    ? 'personal|${(_userStamps[storeId]?['totalVisits'] as num?)?.toInt() ?? 0}|$isExpanded'
    : '${_selectedMode}|$flowerType|$category|$isExpanded|$storeIconUrl|'
      '${_showExplorationMode ? pinAccentColor.value : 0}';
```

---

## 7. totalVisits のミラー書き込み（Cloud Functions 側）

`nfcCheckin` Cloud Function のトランザクション内（`block-a-cloud-functions.md` の変更後）に追記:

```typescript
// users/{uid}/stores/{storeId} に totalVisits をミラー書き込み
const currentTotalVisits = asInt(storeUserStatsSnap.data()?.['totalVisits'], 0);
txn.set(
  targetStoreRef,  // users/{uid}/stores/{storeId}
  stripUndefined({
    storeId,
    storeName: storeName || undefined,
    totalVisits: isFirstVisit ? 1 : currentTotalVisits + 1,  // ← 追加
    lastStampDate: todayJst,
    lastVisited: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }),
  { merge: true },
);
```

---

## 8. 変更対象ファイル一覧

| ファイルパス | 変更内容 | 参考行番号 |
|-------------|---------|-----------|
| `lib/views/map/map_view.dart` | `_personalMapMode`, `_communityMapMode`, `_communitySubMode` フィールド追加; `_setMapMode()`, `_getPersonalMapStatus()`, `_getPersonalMapColor()`, `_getPersonalMapIcon()`, `_buildActivityCircles()`, `_getActiveCircles()`, `_buildCommunitySubModeToggle()` メソッド追加; `_resolveMarkerVisual()` に `storeId` 引数追加; `_buildFilterChips()` にチップ追加; `GoogleMap` に `circles` パラメータ追加 | L25-100, L920-975, L1175-1260, L2276-2400 |
| `backend/functions/src/index.ts` | `nfcCheckin` トランザクション内で `totalVisits` を `users/{uid}/stores/{storeId}` にミラー書き込み | L4159-4234 |

---

## 9. 実装順序と依存関係

```
[前提] block-a-cloud-functions.md 完了
[前提] area-system-design.md の _loadAreas() 実装完了
  ↓
Step 1: backend/functions に totalVisits ミラー書き込みを追加 → デプロイ
  ↓
Step 2: _resolveMarkerVisual() に storeId 引数追加・個人マップロジック追加
  ↓
Step 3: _setMapMode() で既存フラグ管理を統一
  ↓
Step 4: _buildFilterChips() に「個人マップ」「コミュニティ」チップ追加
  ↓
Step 5: _buildActivityCircles() 実装
  ↓
Step 6: _getActiveCircles() で circles を統合、GoogleMap に渡す
  ↓
Step 7: _buildCommunitySubModeToggle() UI 実装
  ↓
Step 8: cacheKey を新モードに対応
```

---

## 10. 検証チェックリスト

- [ ] 個人マップモードで `totalVisits=0` の店舗がグレーピンになること
- [ ] 個人マップモードで `totalVisits=1` の店舗がライトブルーになること
- [ ] 個人マップモードで `totalVisits=5` 以上の店舗がオレンジになること
- [ ] 個人マップモードで `totalVisits=10` 以上の店舗がゴールドになること
- [ ] コミュニティモード・開拓率サブビューでエリアサークルが表示されること
- [ ] コミュニティモード・賑わい度サブビューで `discoveredCount` に応じたサークルが表示されること
- [ ] 既存の「開拓モード」「カテゴリモード」「開拓・未開拓トグル」が引き続き正常に動作すること
- [ ] モード切り替え時にマーカーキャッシュがクリアされ、正しいアイコンで再描画されること
- [ ] NFCチェックイン後に `totalVisits` が `users/{uid}/stores/{storeId}` に正しく反映されること
- [ ] コミュニティモード非選択時にサークルが非表示になること
