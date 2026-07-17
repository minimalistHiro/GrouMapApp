# エリア管理 & 店舗設定 管理者UIの設計書

> 作成日: 2026-03-06
> 対象アプリ: 店舗用アプリ（groumapapp_store）
> 目的: Firestoreコンソールでの手動設定を廃止し、オーナー専用UIで `areas` コレクション・`stores.areaId`・`stores.rarityOverride` を管理できるようにする

---

## 概要

### 背景

フェーズ2で `areas` コレクションのFirestoreスキーマとFlutterのコード実装は完了済み。しかし、以下の設定がFirestoreコンソールでの手動作業のまま残っている。

| 設定 | 現状 | 目標 |
|------|------|------|
| `areas/{areaId}` | Firestoreコンソールで手動作成 | 管理者UIで作成・編集・削除 |
| `stores/{storeId}.areaId` | Firestoreコンソールで手動設定 | 管理者UIで店舗ごとに設定 |
| `stores/{storeId}.rarityOverride` | 未実装 | 管理者UIで手動設定 |

### オーナー判定

`users/{uid}.isOwner == true` のユーザーのみが編集可能。

- Firestoreルール: `areas` コレクションの write は `isOwner()` で保護済み
- Flutter側: `userIsOwnerProvider` で判定（既存の `OwnerSettingsView` と同じパターン）
- `isStoreOwner`（個別店舗アカウント）は閲覧のみ、編集不可

---

## 実装場所

既存の `OwnerSettingsView` に2つのナビゲーション項目を追加し、それぞれのサブページに遷移する設計とする。

### 追加する画面一覧

| 画面ファイル | 役割 |
|------------|------|
| `lib/views/settings/area_management_view.dart`（店舗用アプリ） | エリア一覧・作成・編集・削除 |
| `lib/views/settings/area_edit_view.dart`（店舗用アプリ） | エリア作成・編集フォーム |
| `lib/views/settings/store_area_rarity_view.dart`（店舗用アプリ） | 全店舗のareaId・rarityOverride設定 |

### OwnerSettingsView への追加項目

既存の「データ管理」セクションの下に「ゲーム設定」セクションを追加する。

```dart
_buildSectionCard(
  title: 'ゲーム設定',
  subtitle: 'エリア定義と店舗のレア度・エリア設定を管理します',
  icon: Icons.map_outlined,
  children: [
    _buildNavigationRow(
      label: 'エリア管理',
      description: '蕨駅周辺・川口駅周辺などのエリアを作成・編集',
      icon: Icons.location_on_outlined,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AreaManagementView()),
      ),
    ),
    const Divider(height: 1),
    _buildNavigationRow(
      label: '店舗エリア・レア度設定',
      description: '各店舗のエリア帰属とレア度（手動）を設定',
      icon: Icons.tune_outlined,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StoreAreaRarityView()),
      ),
    ),
  ],
),
```

---

## 1. AreaManagementView（エリア管理）

### 画面構成

```
AreaManagementView
├── AppBar:「エリア管理」+ 追加ボタン（isOwner のみ表示）
│
└── ListView
    └── AreaListTile × N
        ├── エリア名（例: 蕨駅周辺）
        ├── 半径（例: 700m）
        ├── 表示状態チップ（isActive: 緑/グレー）
        └── タップ → AreaEditView（編集）
```

### Provider設計

```dart
// lib/providers/area_provider.dart（既存・ユーザーアプリ）に同等のものを店舗アプリに作成

// 店舗アプリ: lib/providers/area_admin_provider.dart
final areasAdminProvider = StreamProvider<List<AreaModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('areas')
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs.map((d) => AreaModel.fromJson(d.data())).toList());
});
```

### データ操作

**作成:**
```dart
// areas コレクションに新規ドキュメントを追加
// areaId は自動生成（FirebaseFirestore.instance.collection('areas').doc()）
await FirebaseFirestore.instance.collection('areas').doc(areaId).set({
  'areaId': areaId,
  'name': name,
  'description': description,
  'center': {'latitude': lat, 'longitude': lng},
  'radiusMeters': radiusMeters,
  'color': color,         // 例: '#FF6B35'
  'isActive': true,
  'order': order,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**更新:**
```dart
await FirebaseFirestore.instance.collection('areas').doc(areaId).update({
  'name': name,
  'description': description,
  'center': {'latitude': lat, 'longitude': lng},
  'radiusMeters': radiusMeters,
  'color': color,
  'isActive': isActive,
  'order': order,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**削除:**
- ソフトデリート: `isActive: false` に更新（物理削除なし）
- 理由: 削除後に `areaId` を参照している `stores.areaId` のデータが孤立するため

---

## 2. AreaEditView（エリア作成・編集フォーム）

### フォーム項目

| フィールド | UI | バリデーション |
|-----------|-----|--------------|
| エリア名 | TextFormField | 必須・10文字以内（BUSINESS_MODEL.md命名ルール） |
| 説明 | TextFormField | 任意・50文字以内 |
| 中心座標（緯度） | TextFormField（数値） | 必須・-90〜90 |
| 中心座標（経度） | TextFormField（数値） | 必須・-180〜180 |
| 半径（メートル） | TextFormField（数値） | 必須・100〜5000 |
| 表示色 | DropdownButton（プリセット色）| デフォルト: #FF6B35 |
| 表示順 | TextFormField（整数） | 任意・1以上 |
| 有効フラグ | Switch | デフォルト: true |

**色プリセット（ドロップダウン）:**
```dart
const List<Map<String, dynamic>> areaColorPresets = [
  {'label': 'オレンジ（デフォルト）', 'value': '#FF6B35'},
  {'label': 'ブルー', 'value': '#4A90E2'},
  {'label': 'グリーン', 'value': '#27AE60'},
  {'label': 'パープル', 'value': '#8E44AD'},
  {'label': 'レッド', 'value': '#E74C3C'},
];
```

### マッププレビュー

座標入力後にGoogle Mapsのミニプレビューを表示（`GoogleMap` ウィジェット、高さ200px）。
中心ピン + 半径Circleをリアルタイムで表示し、設定内容を視覚的に確認できる。

```dart
// 座標・半径の変更でリアルタイム更新
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(lat, lng),
    zoom: 15,
  ),
  circles: {
    Circle(
      circleId: const CircleId('preview'),
      center: LatLng(lat, lng),
      radius: radiusMeters,
      fillColor: hexToColor(color).withOpacity(0.2),
      strokeColor: hexToColor(color),
      strokeWidth: 2,
    ),
  },
  markers: {
    Marker(
      markerId: const MarkerId('center'),
      position: LatLng(lat, lng),
    ),
  },
  myLocationButtonEnabled: false,
  zoomControlsEnabled: false,
);
```

### 現在地取得ボタン

座標フィールドの横に「現在地を使用」ボタンを配置。
`geolocator` パッケージ（既存で使用済み）で現在地を取得してフォームに自動入力。

---

## 3. StoreAreaRarityView（店舗エリア・レア度設定）

### 画面構成

```
StoreAreaRarityView
├── AppBar: 「店舗エリア・レア度設定」
│
├── 検索バー（店舗名でフィルタリング）
│
└── ListView
    └── StoreAreaRarityTile × N（承認済み全店舗）
        ├── 店舗アイコン + 店舗名
        ├── 現在のエリア（チップ表示）
        ├── 現在のrarityOverride（星表示、未設定は「自動」）
        └── タップ → 編集ボトムシート
```

### 編集ボトムシート

各店舗タイルをタップすると、以下のボトムシートが表示される。

```
DraggableScrollableSheet または ModalBottomSheet
├── 店舗名（ヘッダー）
│
├── エリア選択
│   ├── DropdownButton（areas コレクションの全エリア + 「未設定（秘境スポット）」）
│   └── 選択中のエリア: 「蕨駅周辺」 or「秘境スポット」
│
├── レア度手動設定（rarityOverride）
│   ├── 「自動（discoveredCountから計算）」ラジオボタン
│   ├── ★ コモン ラジオボタン
│   ├── ★★ レア ラジオボタン
│   ├── ★★★ エピック ラジオボタン
│   └── ★★★★ レジェンド ラジオボタン
│
├── 現在のdiscoveredCount表示（参考情報）
│   └── 「現在の来店者数: ○人（自動計算: ★○）」
│
└── 保存ボタン + キャンセルボタン
```

### データ操作

**areaId 設定:**
```dart
await FirebaseFirestore.instance.collection('stores').doc(storeId).update({
  'areaId': selectedAreaId,  // null の場合は FieldValue.delete() または null 直接設定
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**rarityOverride 設定:**
```dart
await FirebaseFirestore.instance.collection('stores').doc(storeId).update({
  // 自動（設定解除）の場合は null
  'rarityOverride': selectedRarity,  // 1〜4 or null
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### Provider設計

```dart
// 全承認済み店舗の一覧（管理者用）
final allApprovedStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('stores')
      .where('isApproved', isEqualTo: true)
      .where('isOwner', isEqualTo: false)
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map((d) => StoreModel.fromJson(d.data())).toList());
});
```

---

## 4. Firestoreルールの確認

### areasコレクション（既存）

```
match /areas/{areaId} {
  allow read: if true;  // 全公開
  allow write: if isOwner();  // オーナーのみ
}
```

→ **変更不要**（既に `isOwner()` で保護済み）

### stores/{storeId}のareaId・rarityOverride書き込み

```
match /stores/{storeId} {
  // 既存のルールに areaId・rarityOverride の更新権限を追加
  allow update: if isOwner() || (isStoreOwner(storeId) && !updatesRestrictedFields());
}

// 店舗アカウントが変更できないフィールド（オーナー専用フィールド）
function updatesRestrictedFields() {
  return request.resource.data.diff(resource.data).changedKeys()
    .hasAny(['areaId', 'rarityOverride', 'isApproved', 'isOwner', 'founderMember']);
}
```

→ `firestore.rules` に `updatesRestrictedFields()` 関数を追加して、`areaId`・`rarityOverride` はオーナーのみが変更可能にする。

---

## 5. 実装タスク一覧

### Phase A: エリア管理（AreaManagementView + AreaEditView）

```
① 店舗アプリに area_admin_provider.dart を新規作成
   - areasAdminProvider（StreamProvider）
   - createArea() / updateArea() / deactivateArea() メソッド

② area_management_view.dart 新規作成
   - エリア一覧 ListView
   - isOwner チェック（閲覧/編集の切り替え）

③ area_edit_view.dart 新規作成
   - フォーム入力（名前・座標・半径・色・順序・isActive）
   - GoogleMap プレビュー
   - 現在地取得ボタン

④ owner_settings_view.dart に「ゲーム設定」セクションを追加
   - AreaManagementView への遷移ボタン
   - StoreAreaRarityView への遷移ボタン
```

### Phase B: 店舗エリア・レア度設定（StoreAreaRarityView）

```
⑤ store_area_rarity_view.dart 新規作成
   - 全承認済み店舗の一覧
   - 検索フィルター
   - 編集ボトムシート（areaId + rarityOverride）

⑥ Firestoreルール更新
   - updatesRestrictedFields() 関数追加
   - stores/{storeId} の update ルール修正
   - firebase deploy --only firestore:rules
```

### Phase C: ドキュメント更新

```
⑦ FIRESTORE.md に以下を追記:
   - stores.areaId の設定方法（コンソール → 管理者UIに変更）
   - stores.rarityOverride の管理方法
   - areas コレクションの管理方法

⑧ IMPLEMENTATION_ROADMAP.md の フェーズ2①「手動設定」チェックボックスを更新:
   - [ ] Firestore コンソールで手動 → [x] 管理者UIで設定可能
```

---

## 6. OwnerSettingsView への統合方法

### _buildNavigationRow ヘルパーの追加

既存の `_buildSectionCard` 内に使えるナビゲーション行ウィジェットを追加する。

```dart
Widget _buildNavigationRow({
  required String label,
  required String description,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: const Color(0xFFFF6B35)),
    title: Text(label),
    subtitle: Text(
      description,
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
```

---

## 7. 依存関係・前提条件

| 依存 | 状態 |
|------|------|
| `areas` コレクションのFirestoreスキーマ | 定義済み（FIRESTORE.md） |
| `area_model.dart`（ユーザーアプリ） | 実装済み（フェーズ2） |
| `area_provider.dart`（ユーザーアプリ） | 実装済み（フェーズ2） |
| Firestoreルール: areas の isOwner() 保護 | 実装済み（フェーズ2） |
| `userIsOwnerProvider`（店舗アプリ） | 実装済み（既存） |
| Google Maps Flutter SDK（店舗アプリ） | 要確認 ※マップ未使用なら `google_maps_flutter` を追加 |

---

## 8. 注意事項

### areaId の nullと空文字の扱い
- `areaId: null` = 秘境スポット（エリア外）
- Firestoreの `FieldValue.delete()` で明示的にフィールドを削除するか、`null` を直接設定する
- Flutter側では `areaId == null` で判定しているため、空文字（`''`）は使用しない

### rarityOverride の null扱い
- `rarityOverride: null` = 自動計算（`discoveredCount` ベース）
- `rarityOverride: 1〜4` = 手動固定

### 店舗追加時のareaId自動帰属
- BUSINESS_MODEL.md では「新規店舗登録時に座標でエリアを自動判定」とされているが、
  現時点の実装では `areaId` は手動設定のみ（自動帰属は未実装）
- 本設計書のUIで手動設定を可能にする。将来的に自動帰属処理（Cloud Functions）を追加予定

### 店舗用アプリに `area_model.dart` のコピーが必要か
- ユーザーアプリの `lib/models/area_model.dart` を店舗アプリにもコピーするか、
  同等のシンプルなモデルクラスを作成する
- Provider の Stream購読には `AreaModel` が必要なため、コピーが最もシンプル

---

## 9. 実装プロンプト（AGENT_TEAM_GUIDE.md形式）

```
エリア管理UIを実装してください。

参照ファイル（必ず最初に全て読むこと）:
- /Users/kanekohiroki/Desktop/groumapapp/.claude/plans/area-admin-ui-design.md（本設計書）
- /Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md（areasスキーマ・storesスキーマ確認）
- /Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/owner_settings_view.dart（既存UIとの統合）
- /Users/kanekohiroki/Desktop/groumapapp/lib/models/area_model.dart（モデル参照）

実装タスク（Phase A: エリア管理）:
1. 店舗アプリに lib/providers/area_admin_provider.dart を新規作成
2. lib/views/settings/area_management_view.dart を新規作成
3. lib/views/settings/area_edit_view.dart を新規作成（Googleマッププレビュー含む）
4. owner_settings_view.dart に「ゲーム設定」セクションを追加（_buildNavigationRow 追加）

実装タスク（Phase B: 店舗エリア・レア度設定）:
5. lib/views/settings/store_area_rarity_view.dart を新規作成
6. firestore.rules に updatesRestrictedFields() を追加し stores の update ルールを修正
   → firebase deploy --only firestore:rules

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ2① 手動設定タスクを [x] に更新
- 変更したファイルと変更概要を報告
```
