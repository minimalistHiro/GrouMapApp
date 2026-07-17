# 図鑑View 実装詳細統合設計書

作成日: 2026-03-05
対象ブランチ: 2026-03-04
依存:
- `block-a-cloud-functions.md`（`stores.discoveredCount` 追加・`isFirstVisit` フラグ実装済みであること）
- `nfc-zukan-flow-redesign.md`（ZukanCardWidget の仕様定義元）
- `ui-navigation-redesign-3tabs.md`（3タブ構成・画面レイアウト定義元）

---

## 0. 設計方針の統一（既存プランの矛盾解消）

### ファイルパス（確定）

| 対象 | 採用パス | 不採用パス |
|------|---------|-----------|
| 図鑑メイン画面 | `lib/views/zukan/zukan_view.dart` | `lib/views/encyclopedia/encyclopedia_view.dart` |
| カードウィジェット | `lib/widgets/zukan_card_widget.dart` | `lib/views/encyclopedia/encyclopedia_card_widget.dart` |
| Providerファイル | `lib/providers/zukan_provider.dart` | なし（新規） |

> 採用理由: `nfc-zukan-flow-redesign.md` との一貫性。コードとユーザー向け表記（「図鑑」）を統一するため。

### 発見済み判定（確定）

```
発見済み = users/{uid}/stores/{storeId} ドキュメントが存在する
```

- `stamps > 0` による判定は**使わない**（スタンプ廃止後の新規ユーザーはstamps=0のため）
- `map_view.dart` の `_userStamps` ローカル変数と同一のデータソースを使用
- `users/{uid}/stores/{storeId}` ドキュメントの `lastVisited != null` で判定する

### レア度計算（確定）

| discoveredCount | レア度 | 表示 |
|----------------|--------|------|
| 0 | レジェンド | ★★★★ |
| 1〜5 | エピック | ★★★ |
| 6〜20 | レア | ★★ |
| 21以上 | コモン | ★ |

`stores/{storeId}.rarityOverride` が存在する場合は手動設定を優先する。

---

## 1. 新規作成ファイル一覧

| ファイルパス | 種別 | 役割 |
|-------------|------|------|
| `lib/providers/zukan_provider.dart` | 新規 | 図鑑用Riverpod Provider群 |
| `lib/widgets/zukan_card_widget.dart` | 新規 | 図鑑カード（発見済み/未発見の2表示モード） |
| `lib/views/zukan/zukan_view.dart` | 新規 | 図鑑メイン画面（タブindex 1） |

---

## 2. lib/providers/zukan_provider.dart

### 提供するProvider一覧

```dart
// 全店舗一覧（isActive=true / isApproved=true / isOwner=false）
// ※ storesProvider（store_provider.dart）を再利用。
//    ただし discoveredCount / rarityOverride / areaId を含む rawMap も必要なため、
//    zukan 用に生の Firestore データを返す別 StreamProvider を用意する。

final zukanAllStoresProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  // Firestoreから Map<String, dynamic> で全店舗を取得
  // フィールド: storeId, name, category, description, images, iconImageUrl,
  //            discoveredCount, rarityOverride, areaId, isActive, isApproved, isOwner
});

// ログイン中ユーザーの発見済みstoreId一覧
final userVisitedStoreIdsProvider = StreamProvider<Set<String>>((ref) {
  // users/{uid}/stores サブコレクション全件取得
  // ドキュメントIDをSetとして返す（lastVisited != null のものだけ）
});

// 図鑑用の統合データ（全店舗 + 発見済みフラグ）
final zukanStoresProvider = Provider<AsyncValue<List<ZukanStoreItem>>>((ref) {
  final allStores = ref.watch(zukanAllStoresProvider);
  final visitedIds = ref.watch(userVisitedStoreIdsProvider);
  return allStores.whenData((stores) {
    final visited = visitedIds.valueOrNull ?? {};
    return stores.map((s) => ZukanStoreItem(
      store: s,
      isDiscovered: visited.contains(s['storeId'] as String),
    )).toList();
  });
});

// 発見済み店舗数（ProfileView統計 / nfc-result画面での「あなたが○人目」表示に使用）
final userDiscoveredStoreCountProvider = Provider<int>((ref) {
  return ref.watch(userVisitedStoreIdsProvider).valueOrNull?.length ?? 0;
});
```

### ZukanStoreItem データクラス

```dart
class ZukanStoreItem {
  final Map<String, dynamic> store;  // Firestoreの生データ
  final bool isDiscovered;

  const ZukanStoreItem({required this.store, required this.isDiscovered});

  String get storeId => store['storeId'] as String;
  String get name => store['name'] as String? ?? '';
  String get category => store['category'] as String? ?? 'その他';
  String? get description => store['description'] as String?;
  String? get areaId => store['areaId'] as String?;

  // レア度計算
  int get rarityLevel {
    final override = store['rarityOverride'];
    if (override != null) return (override as num).toInt();
    final count = (store['discoveredCount'] as num?)?.toInt() ?? 0;
    if (count == 0) return 4;      // レジェンド
    if (count <= 5) return 3;      // エピック
    if (count <= 20) return 2;     // レア
    return 1;                      // コモン
  }

  String get rarityLabel {
    switch (rarityLevel) {
      case 4: return 'レジェンド';
      case 3: return 'エピック';
      case 2: return 'レア';
      default: return 'コモン';
    }
  }

  String get rarityStars {
    return '★' * rarityLevel + '☆' * (4 - rarityLevel);
  }

  Color get rarityColor {
    switch (rarityLevel) {
      case 4: return const Color(0xFFFFB300); // ゴールド
      case 3: return const Color(0xFF7B1FA2); // パープル
      case 2: return const Color(0xFF1565C0); // ブルー
      default: return const Color(0xFF757575); // グレー
    }
  }

  int get discoveredCount => (store['discoveredCount'] as num?)?.toInt() ?? 0;

  String? get iconImageUrl => store['iconImageUrl'] as String?;
  List<String> get images {
    final raw = store['images'];
    if (raw is List) return raw.cast<String>();
    return [];
  }

  String? get firstImageUrl => iconImageUrl ?? (images.isNotEmpty ? images.first : null);
}
```

---

## 3. lib/widgets/zukan_card_widget.dart

### Widget定義

```dart
class ZukanCardWidget extends StatelessWidget {
  final ZukanStoreItem item;
  final VoidCallback? onTap;

  const ZukanCardWidget({super.key, required this.item, this.onTap});
}
```

### 発見済みカードの表示内容

- **背景**: `item.firstImageUrl` があれば画像（BoxFit.cover）、なければカテゴリカラー背景 + カテゴリアイコン
- **グラデーション**: 下部に黒グラデーション（テキスト可読性）
- **店舗名**: カードの下部に白テキスト
- **レア度バッジ**: 右上に角丸タグ（`rarityColor` 背景 + `rarityStars` + `rarityLabel`）
- **タップ動作**: `store_detail_view.dart` へ遷移（storeId を渡す）
- **カテゴリアイコン**: `StampCardWidget.getCategoryIcon()` / `getCategoryColor()` を static import で流用

### 未発見カードの表示内容

- **背景**: `item.firstImageUrl` があれば `ColorFiltered`（グレースケール） + `Opacity(0.5)`
  - 画像なし: カテゴリカラー背景 + カテゴリアイコン（グレースケール）
- **店舗名**: `？？？` に置き換え
- **表示する情報**（情報ギャップ理論 — 探索欲求の喚起）:
  - カテゴリ名
  - エリア名（`areaId` → `areas/{areaId}.name`、null の場合は「秘境スポット」）
  - レア度バッジ（グレースケール）
  - `discoveredCount` 発見者数（0人の場合は「まだ誰も発見していない」）
- **タップ動作**: 何もしない（または SnackBar「来店してNFCタッチすると発見できます！」）

### カードサイズ

- グリッド2列（`crossAxisCount: 2`）
- アスペクト比: `childAspectRatio: 0.75`（縦長カード）
- `mainAxisSpacing: 12`, `crossAxisSpacing: 12`

---

## 4. lib/views/zukan/zukan_view.dart

### 画面状態管理

```dart
class _ZukanViewState extends ConsumerState<ZukanView> {
  String _selectedFilter = 'all';       // 'all' | 'discovered' | 'undiscovered'
  String _selectedSort = 'category';    // 'category' | 'area' | 'rarity'
  String? _selectedCategory;            // null = 全カテゴリ
}
```

### 画面構成（確定）

```
┌─────────────────────────────────┐
│  図鑑             [フィルター▼] │  ← CommonHeader
├─────────────────────────────────┤
│  発見済み 7店舗 / 全18店舗      │  ← 開拓サマリーバー（プログレスバー付き）
├─────────────────────────────────┤
│  [全て] [発見済み] [未発見]     │  ← 発見状況フィルターチップ
│  ────────────────────           │
│  並び替え: [カテゴリ][エリア][レア度] │
├─────────────────────────────────┤
│  （カテゴリヘッダー: カフェ）   │  ← _selectedSort == 'category' の場合
│  ┌────┐ ┌────┐                 │
│  │発見│ │？？│                 │  ← ZukanCardWidget グリッド
│  └────┘ └────┘                 │
│  （カテゴリヘッダー: ラーメン）  │
│  ┌────┐ ┌────┐ ┌────┐         │
│  │発見│ │？？│ │発見│         │
│  └────┘ └────┘ └────┘         │
└─────────────────────────────────┘
```

### 開拓サマリーバーの仕様

```dart
Widget _buildSummaryBar(List<ZukanStoreItem> items) {
  final discovered = items.where((i) => i.isDiscovered).length;
  final total = items.length;
  final rate = total == 0 ? 0.0 : discovered / total;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('発見済み $discovered店舗 / 全$total店舗'),
            Text('${(rate * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: rate),  // AppThemeの primaryColor
      ],
    ),
  );
}
```

### ソート別グルーピングロジック

**カテゴリ別**: `StampCardWidget.getCategoryColor()` の定義順に従ってグルーピング（カテゴリ名ヘッダーを表示）

**エリア別**: `areaId` でグルーピング。areaId が null の店舗は「秘境スポット」グループに分類

**レア度別**: `rarityLevel` 降順（4→3→2→1）でグルーピング（レジェンド→エピック→レア→コモン）

### ゲストモード

```dart
// ログイン状態を ref.watch(authProvider) で判定
// 未ログイン時:
// - 発見済み件数を表示しない（「ログインして開拓率を確認しよう」テキスト）
// - 全店舗を未発見シルエットで表示
// - カードタップ → サインイン画面へ遷移（またはサインインダイアログを表示）
```

---

## 5. データ取得フロー

```
ZukanView 起動
  ↓
ref.watch(zukanStoresProvider)
  ├─ zukanAllStoresProvider → Firestore: stores（isActive=true, isApproved=true）
  │   ※ storesProvider (StreamProvider<List<StoreModel>>) とは別の raw map Provider
  │   ※ discoveredCount, rarityOverride, areaId を含む全フィールドを取得
  └─ userVisitedStoreIdsProvider → Firestore: users/{uid}/stores（lastVisited != null）
      ※ 未ログイン時は空Set を返す
  ↓
List<ZukanStoreItem> に変換
  ↓
_selectedFilter, _selectedSort, _selectedCategory でフィルタ・ソート・グルーピング
  ↓
GridView.builder でカード描画
```

---

## 6. stores コレクションの rawMap 取得 Provider

`storesProvider`（store_provider.dart）は `StoreModel` を返すが、
`StoreModel` に `discoveredCount` / `rarityOverride` / `areaId` が含まれていないため、
図鑑専用の raw map Provider を別途作成する。

```dart
// lib/providers/zukan_provider.dart 内に定義
final zukanAllStoresProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('stores')
      .where('isActive', isEqualTo: true)
      .where('isApproved', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .where((doc) {
              final data = doc.data();
              final isOwner = data['isOwner'];
              return isOwner != true && isOwner?.toString().toLowerCase() != 'true';
            })
            .map((doc) {
              final data = doc.data();
              data['storeId'] = doc.id;
              return data;
            })
            .toList();
      });
});
```

**StoreModel の更新（非推奨）**: `StoreModel` に `discoveredCount` を追加することは、
freezed の再生成が必要で影響範囲が広いため、今フェーズでは行わない。
図鑑と個人マップ（map-extension-design.md）で raw map を直接参照する方針とする。

---

## 7. 変更対象ファイル一覧

| ファイルパス | 変更種別 | 変更内容 |
|-------------|---------|---------|
| `lib/providers/zukan_provider.dart` | **新規** | `zukanAllStoresProvider`, `userVisitedStoreIdsProvider`, `zukanStoresProvider`, `userDiscoveredStoreCountProvider`, `ZukanStoreItem` クラス |
| `lib/widgets/zukan_card_widget.dart` | **新規** | 発見済み/未発見の2モードカードWidget |
| `lib/views/zukan/zukan_view.dart` | **新規** | 図鑑メイン画面（フィルター・ソート・グリッド表示） |
| `lib/views/main_navigation_view.dart` | 変更 | 3タブ化（ui-navigation-redesign-3tabs.md に基づく）、import に zukan_view.dart 追加 |
| `lib/widgets/user_stats_card.dart` | 変更 | `userDiscoveredStoreCountProvider` を使い発見店舗数を表示 |

---

## 8. 実装順序

```
Step 1: lib/providers/zukan_provider.dart 作成
  （ZukanStoreItem クラス + 4つの Provider）
  ↓
Step 2: lib/widgets/zukan_card_widget.dart 作成
  （StampCardWidget.getCategoryIcon/getCategoryColor を流用）
  ↓
Step 3: lib/views/zukan/zukan_view.dart 作成
  （仮状態で StatefulWidget + Provider 接続のみ先に実装）
  ↓
Step 4: lib/views/main_navigation_view.dart の3タブ化
  （ZukanView を index 1 に差し込み、動作確認）
  ↓
Step 5: ZukanView のフィルター・ソート・グルーピング実装
  ↓
Step 6: ゲストモード対応（未ログイン時の表示分岐）
  ↓
Step 7: user_stats_card.dart の発見店舗数更新
```

---

## 9. Firestore ルール確認

`stores` コレクションは既存ルールで読み取り可能（変更不要）。
`users/{uid}/stores` サブコレクションは認証済みユーザー本人のみ読み取り可能（既存ルールで対応済みの想定。要確認）。

---

## 10. 検証チェックリスト

- [ ] 図鑑タブに全店舗がグリッド表示されること
- [ ] 発見済み店舗がフルカラーカードで表示されること
- [ ] 未発見店舗がグレースケール + 「？？？」で表示されること
- [ ] 未発見カードにカテゴリ・レア度バッジが表示されること
- [ ] レア度が `discoveredCount` から正しく計算されること（0人→★★★★）
- [ ] `rarityOverride` が設定されている場合に手動レア度が優先されること
- [ ] 開拓サマリーバーの発見数/総数/進捗バーが正しいこと
- [ ] カテゴリ別ソートでグループヘッダーが表示されること
- [ ] エリア別ソートで `areaId=null` の店舗が「秘境スポット」グループに入ること
- [ ] 発見済みフィルターで発見済み店舗のみ表示されること
- [ ] 未発見フィルターで未発見店舗のみ表示されること
- [ ] 未ログイン時に全店舗シルエット表示 + ログイン促進が表示されること
- [ ] 発見済みカードタップで店舗詳細画面に遷移すること
- [ ] NFCチェックイン後に図鑑タブへ戻ると当該店舗が発見済みに更新されること（StreamProvider のリアルタイム反映）
