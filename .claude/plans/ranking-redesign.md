# ランキング刷新設計プラン

作成日: 2026-03-05
対象ブランチ: 2026-03-04
依存:
- block-a-cloud-functions.md（`nfcCheckin` の `isFirstVisit` フラグ追加済みであること）

---

## 概要

現行のランキングシステムはクライアント側で全ユーザーデータを毎回取得・集計するため、
ユーザー数増加に伴うパフォーマンス問題が懸念される。
また、店舗探索ゲームとしての主軸指標「開拓店舗数（discoveredStoreCount）」がランキングに存在しない。

本プランでは以下の 2 点を改善する:
1. `discoveredStoreCount` を新規ランキング指標として追加（デフォルト指標に変更）
2. 期間別ランキング用の専用 Firestore スキーマを導入し、クライアント側の集計負荷を解消
3. 管理者・オーナー専用 → 全ユーザーに開放

---

## 1. users コレクションへの `discoveredStoreCount` フィールド追加

### スキーマ定義

```
users/{uid}:
  discoveredStoreCount: int  // 初回 NFCチェックイン済みのユニーク店舗数（累計）
```

**更新タイミング:** `nfcCheckin` Cloud Function で `isFirstVisit == true` の場合にインクリメント

### Cloud Functions 変更（block-a の変更後の位置に追記）

`backend/functions/src/index.ts` の `nfcCheckin` 関数（L4236 付近）に追加:

```typescript
// discoveredStoreCount のインクリメント（初回来店時のみ）
if (result.isFirstVisit) {
  try {
    await targetUserRef.update({
      discoveredStoreCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error('[nfcCheckin] discoveredStoreCount increment error:', e);
  }
}
```

---

## 2. 期間別ランキング用の新 Firestore スキーマ

### 2-1. コレクション定義

```
ranking_scores/{periodId}/users/{userId}
  score:        number     // ランキングスコア（当期間内の discoveredStoreCount 増分）
  displayName:  string     // ユーザー表示名（書き込み時のスナップショット）
  photoURL:     string?    // プロフィール画像URL（スナップショット）
  updatedAt:    Timestamp  // 最終更新日時
```

**periodId の命名規則:**

| 期間種別 | periodId 形式 | 例 |
|---------|-------------|-----|
| 全期間 | `alltime` | `alltime` |
| 週別 | `{yyyy}-W{nn}` | `2026-W10`（ISO 8601 週番号） |
| 月別 | `{yyyy}-{MM}` | `2026-03` |
| 日別 | `{yyyy}-{MM}-{dd}` | `2026-03-05` |

**設計メモ:**
- `alltime` のスコアは全期間累計（削除しない）
- weekly / monthly / daily のドキュメントは自然に生成・蓄積される
- 古い期間のドキュメントは削除しない（履歴として残す）

### 2-2. 更新タイミング

`nfcCheckin` Cloud Function で `isFirstVisit == true` の場合に alltime / weekly / monthly / daily の 4 ドキュメントを batch 更新する。

**periodId 計算ヘルパー関数:**

```typescript
function getPeriodIds(now: Date): { alltime: string; weekly: string; monthly: string; daily: string } {
  const yyyy = now.getFullYear();
  const MM = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');

  // ISO 8601 週番号計算
  const startOfYear = new Date(yyyy, 0, 1);
  const weekNum = Math.ceil(
    ((now.getTime() - startOfYear.getTime()) / 86400000 + startOfYear.getDay() + 1) / 7
  );
  const ww = String(weekNum).padStart(2, '0');

  return {
    alltime: 'alltime',
    weekly: `${yyyy}-W${ww}`,
    monthly: `${yyyy}-${MM}`,
    daily: `${yyyy}-${MM}-${dd}`,
  };
}
```

**ranking_scores batch 更新（isFirstVisit == true 時のみ）:**

```typescript
if (result.isFirstVisit) {
  try {
    const now = new Date();
    const periodIds = getPeriodIds(now);

    const targetUserSnap = await targetUserRef.get();
    const userData = targetUserSnap.data();
    const displayName = typeof userData?.displayName === 'string'
      ? userData.displayName : '不明なユーザー';
    const photoURL = typeof userData?.profileImageUrl === 'string'
      ? userData.profileImageUrl : null;

    const rankingBatch = db.batch();

    for (const periodId of Object.values(periodIds)) {
      const rankingRef = db
        .collection('ranking_scores')
        .doc(periodId)
        .collection('users')
        .doc(userId);
      rankingBatch.set(
        rankingRef,
        {
          score: FieldValue.increment(1),
          displayName,
          photoURL: photoURL ?? null,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    await rankingBatch.commit();
  } catch (e) {
    console.error('[nfcCheckin] ranking_scores update error:', e);
  }
}
```

### 2-3. ranking_scores の読み取りクエリ（Flutter 側）

```dart
// 特定期間のランキング上位 N 件を取得
final snapshot = await FirebaseFirestore.instance
    .collection('ranking_scores')
    .doc(periodId)  // 例: 'alltime', '2026-W10', '2026-03'
    .collection('users')
    .orderBy('score', descending: true)
    .limit(100)
    .get();
```

---

## 3. RankingType enum への `discoveredStoreCount` 追加

**対象ファイル:** `lib/models/ranking_model.dart`（L55-66）

```dart
// Before:
enum RankingType {
  @JsonValue('total_points') totalPoints,
  @JsonValue('badge_count') badgeCount,
  @JsonValue('stamp_count') stampCount,
  @JsonValue('total_payment') totalPayment,
  @JsonValue('coins') coins,
}

// After:
enum RankingType {
  @JsonValue('discovered_store_count') discoveredStoreCount,  // ← 追加（先頭・デフォルト）
  @JsonValue('total_points') totalPoints,
  @JsonValue('badge_count') badgeCount,
  @JsonValue('stamp_count') stampCount,
  @JsonValue('total_payment') totalPayment,
  @JsonValue('coins') coins,
}
```

**注意:** freezed を使用しているため、変更後に `flutter pub run build_runner build` で再生成が必要。

---

## 4. RankingModel への `discoveredStoreCount` フィールド追加

**対象ファイル:** `lib/models/ranking_model.dart`（L7-23）

```dart
@freezed
class RankingModel with _$RankingModel {
  const factory RankingModel({
    required String userId,
    required String displayName,
    required String? photoURL,
    @Default(0) int discoveredStoreCount,  // ← 追加
    required int totalPoints,
    required int badgeCount,
    required int stampCount,
    required int totalPayment,
    @Default(0) int coins,
    required DateTime lastUpdated,
    required int rank,
    @Default(0) int previousRank,
    @Default(0) int rankChange,
  }) = _RankingModel;
  // ...
}
```

---

## 5. RankingService の刷新

**対象ファイル:** `lib/providers/ranking_provider.dart`

### 5-1. `_getRankingFromScores()` 新規メソッド追加

```dart
Future<List<RankingModel>> _getRankingFromScores(RankingQuery query) async {
  final periodId = _buildPeriodId(query.period);
  final snapshot = await _firestore
      .collection('ranking_scores')
      .doc(periodId)
      .collection('users')
      .orderBy('score', descending: true)
      .limit(query.limit)
      .get();

  final rankings = <RankingModel>[];
  for (int i = 0; i < snapshot.docs.length; i++) {
    final doc = snapshot.docs[i];
    final data = doc.data();
    rankings.add(RankingModel(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? '不明なユーザー',
      photoURL: data['photoURL'] as String?,
      discoveredStoreCount: (data['score'] as num?)?.toInt() ?? 0,
      totalPoints: 0,
      badgeCount: 0,
      stampCount: 0,
      totalPayment: 0,
      coins: 0,
      lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rank: i + 1,
    ));
  }
  return rankings;
}
```

### 5-2. `_buildPeriodId()` ヘルパー追加

```dart
String _buildPeriodId(RankingPeriodType period) {
  final now = DateTime.now();
  final yyyy = now.year;
  final mm = now.month.toString().padLeft(2, '0');
  final dd = now.day.toString().padLeft(2, '0');

  switch (period) {
    case RankingPeriodType.allTime:
      return 'alltime';
    case RankingPeriodType.monthly:
      return '$yyyy-$mm';
    case RankingPeriodType.weekly:
      final startOfYear = DateTime(yyyy, 1, 1);
      final weekNum = ((now.difference(startOfYear).inDays + startOfYear.weekday) / 7).ceil();
      return '$yyyy-W${weekNum.toString().padLeft(2, '0')}';
    case RankingPeriodType.daily:
      return '$yyyy-$mm-$dd';
  }
}
```

### 5-3. `getRankingDataOnce()` に分岐追加（L122-247）

```dart
Future<List<RankingModel>> getRankingDataOnce(RankingQuery query) async {
  // discoveredStoreCount は ranking_scores から高速取得
  if (query.type == RankingType.discoveredStoreCount) {
    return _getRankingFromScores(query);
  }

  // 既存のロジック（他の RankingType は users コレクションから取得）
  // ... 既存コード ...
}
```

### 5-4. sort ロジックへの `discoveredStoreCount` 追加

```dart
rankings.sort((a, b) {
  switch (query.type) {
    case RankingType.discoveredStoreCount:  // ← 追加
      return b.discoveredStoreCount.compareTo(a.discoveredStoreCount);
    case RankingType.totalPoints:
      return b.totalPoints.compareTo(a.totalPoints);
    // ... 既存 ...
  }
});
```

---

## 6. leaderboard_view.dart の変更内容（L1-373）

### 6-1. デフォルト指標を `discoveredStoreCount` に変更（L16）

```dart
// Before:
RankingType _selectedType = RankingType.totalPoints;

// After:
RankingType _selectedType = RankingType.discoveredStoreCount;
```

### 6-2. `_getRankingTypeLabel()` に `discoveredStoreCount` を追加（L326-339）

```dart
String _getRankingTypeLabel(RankingType type) {
  switch (type) {
    case RankingType.discoveredStoreCount:  // ← 追加
      return '開拓店舗数';
    case RankingType.totalPoints:
      return 'ポイント';
    // ... 既存 ...
  }
}
```

### 6-3. `_getRankingDisplayValue()` に `discoveredStoreCount` を追加（L358-371）

```dart
String _getRankingDisplayValue(RankingModel ranking) {
  switch (_selectedType) {
    case RankingType.discoveredStoreCount:  // ← 追加
      return '${ranking.discoveredStoreCount} 店舗';
    case RankingType.totalPoints:
      return '${ranking.totalPoints} pt';
    // ... 既存 ...
  }
}
```

### 6-4. 全ユーザー開放について

`leaderboard_view.dart` にはログイン制限ロジックは存在しない。
`RankingService.getRankingDataOnce()` でも認証チェックは行っていない。
ただし、`ranking_scores` コレクションの Firestore ルールで読み取りを公開する必要がある（下記参照）。

---

## 7. Firestore ルール追加

`/Users/kanekohiroki/Desktop/groumapapp/firestore.rules` に追加:

```javascript
// ranking_scores コレクション
match /ranking_scores/{periodId} {
  allow read: if true;
  allow write: if false;

  match /users/{userId} {
    allow read: if true;    // 全公開（認証不要）
    allow write: if false;  // Cloud Functions のみ書き込み可能
  }
}
```

**デプロイコマンド:**
```bash
firebase deploy --only firestore:rules
```

---

## 8. FIRESTORE.md 更新箇所

### 8-1. `users/{uid}` セクションに追加

```
- `discoveredStoreCount`: NFCチェックイン済みのユニーク店舗数（int、初回来店時に nfcCheckin でインクリメント）
```

### 8-2. 新規セクション `ranking_scores` を追加

```markdown
### ranking_scores
- `ranking_scores/{periodId}/users/{userId}`: 期間別開拓ランキングスコア
  - periodId: `alltime`（全期間）/ `{yyyy}-W{nn}`（週別）/ `{yyyy}-{MM}`（月別）/ `{yyyy}-{MM}-{dd}`（日別）
  - `score`: スコア（当期間内の discoveredStoreCount 増分）
  - `displayName`: ユーザー表示名（書き込み時のスナップショット）
  - `photoURL`: プロフィール画像URL（スナップショット、nullable）
  - `updatedAt`: 最終更新日時
- 更新タイミング: `nfcCheckin` で `isFirstVisit == true` の場合に alltime / weekly / monthly / daily の 4 ドキュメントを batch 更新
- アクセス制御: read は全公開（認証不要）、write は Cloud Functions のみ（`allow write: if false`）
```

---

## 9. 移行戦略（既存ユーザーへの対応）

既存ユーザーの `users/{uid}.discoveredStoreCount` は初期値が存在しない（`undefined`）。
Flutter 側では `(data['discoveredStoreCount'] as num?)?.toInt() ?? 0` で安全にフォールバック可能。

過去の来店データから `discoveredStoreCount` を遡及計算することも可能だが、
初期フェーズでは行わない（実装コスト大・ユーザー体験への影響が少ない）。

`ranking_scores` も今後のチェックインから累積されるため、サービス開始当初は全ユーザーのスコアが
0 または小さい値になる。これは想定内の動作とする。

---

## 10. 変更対象ファイル一覧

| ファイルパス | 変更内容 | 参考行番号 |
|-------------|---------|-----------|
| `lib/models/ranking_model.dart` | `RankingType` enum に `discoveredStoreCount` 追加（先頭）; `RankingModel` に `discoveredStoreCount` フィールド追加 | L7-23, L55-66 |
| `lib/models/ranking_model.freezed.dart` | `flutter pub run build_runner build` で自動再生成 | 自動生成 |
| `lib/models/ranking_model.g.dart` | `flutter pub run build_runner build` で自動再生成 | 自動生成 |
| `lib/providers/ranking_provider.dart` | `_getRankingFromScores()`, `_buildPeriodId()` 追加; `getRankingDataOnce()` に分岐追加; sort ロジックに `discoveredStoreCount` 追加 | L122-247 |
| `lib/views/ranking/leaderboard_view.dart` | デフォルト指標を `discoveredStoreCount` に変更; ラベル・表示値メソッドに `discoveredStoreCount` 追加 | L16, L326-371 |
| `backend/functions/src/index.ts` | `nfcCheckin` に `discoveredStoreCount` インクリメント追加; `ranking_scores` batch 更新追加; `getPeriodIds()` ヘルパー追加 | L4236 付近 |
| `firestore.rules` | `ranking_scores` コレクションのルール追加 | 末尾 |
| `FIRESTORE.md` | `users/{uid}` に `discoveredStoreCount` 追記; `ranking_scores` 新規セクション追加 | L752-916, 新規 |

---

## 11. 実装順序と依存関係

```
[前提] block-a-cloud-functions.md の isFirstVisit 追加完了
  ↓
Step 1: ranking_model.dart の RankingType enum / RankingModel フィールド更新
  ↓
Step 2: flutter pub run build_runner build（freezed コード再生成）
  ↓
Step 3: ranking_provider.dart に _getRankingFromScores() / _buildPeriodId() 追加
        sort ロジックに discoveredStoreCount 追加
  ↓
Step 4: leaderboard_view.dart のデフォルト指標変更・ラベル追加
  ↓
Step 5: firestore.rules に ranking_scores ルール追加 → デプロイ
  ↓
Step 6: backend/functions に discoveredStoreCount インクリメントと
        ranking_scores batch 更新を追加 → デプロイ
  ↓
Step 7: FIRESTORE.md 更新
  ↓
Step 8: 動作確認・検証
```

---

## 12. 検証チェックリスト

- [ ] NFCチェックイン後（初回）に `users/{uid}.discoveredStoreCount` が +1 されること
- [ ] NFCチェックイン後（2回目以降）に `discoveredStoreCount` が変化しないこと
- [ ] `ranking_scores/alltime/users/{userId}.score` が初回来店時に更新されること
- [ ] `ranking_scores/{weekly}/users/{userId}.score` が週別で正しく更新されること
- [ ] `ranking_scores/{monthly}/users/{userId}.score` が月別で正しく更新されること
- [ ] leaderboard_view.dart でデフォルトが「開拓店舗数」になっていること
- [ ] 「開拓店舗数」ランキングが正しくソートされて表示されること（スコア降順）
- [ ] 他の RankingType（ポイント・バッジ数等）のランキングが引き続き正常動作すること
- [ ] `ranking_scores` コレクションの read が認証なしで可能なこと
- [ ] `ranking_scores` コレクションへの直接 write がクライアントから拒否されること
- [ ] `RankingType.discoveredStoreCount` が JSON シリアライズ/デシリアライズで `'discovered_store_count'` として動作すること
- [ ] `flutter pub run build_runner build` でエラーなくコード生成されること
