# KPI再定義プラン

## 背景

スタンプシステムの完全廃止（2026-03-05）に伴い、スタンプ付与回数を根拠としていたKPI定義を
来店トランザクション（`type: 'stamp'`）と `store_users` の来店記録ベースに移行する。

---

## 現行KPIの問題点

| 現行KPI | 問題 | 移行先 |
|--------|------|-------|
| 新規顧客数 = 「初回スタンプ付与」ユーザー数 | スタンプ廃止 | `firstVisitAt` 記録ベースに変更 |
| リピート率 = 「スタンプ付与2回以上」ユーザー | スタンプ廃止 | トランザクション（type:'stamp'）ベースに変更 |
| 来店頻度分布 = スタンプ付与回数の分布 | スタンプ廃止 | `totalVisits` フィールドベースに変更 |
| スタンプ達成率・特典利用率 | スタンプ/クーポン廃止 | **廃止** |
| 客単価・LTV proxy | 会計金額入力廃止 | **廃止（算出不可）** |

---

## 利用可能データソース

### 既存（変更なし）
| コレクション | 主なフィールド | 用途 |
|------------|-------------|------|
| `store_users/{storeId}/users/{userId}` | `firstVisitAt`, `lastVisitAt`, `totalVisits` | 初回来店・来店回数の根拠 |
| `stores/{storeId}/transactions` | `type:'stamp'`, `createdAt`, `userId`, `userGender`, `userAgeGroup` | 来店トランザクション明細 |
| `store_stats/{storeId}/daily/{date}` | `transactionCount`, `visitorCount` | 日次集計 |

### 新規追加（nfc-zukan-flow-redesign.md で定義済み）
| コレクション | フィールド | 用途 |
|------------|---------|------|
| `stores/{storeId}` | `discoveredCount` | 図鑑発見者数（ユニーク来店者数） |

### 要修正
| 問題 | 内容 | 対応 |
|------|------|------|
| `store_stats/daily.visitorCount` の更新条件 | `type='award'\|'use'` 時のみ更新。`type='stamp'`（NFCチェックイン）が対象外 | Cloud Functions の `updateStoreDailyStats` または `nfcCheckin` で `visitorCount` を `type='stamp'` 時にも加算するよう修正が必要 |

---

## 新KPI定義

### 主要KPI（変更あり）

#### 新規顧客数（月次/週次/日次）
```
新規顧客数 = store_users/{storeId}/users/{userId}.firstVisitAt
            が集計期間内に作成されたドキュメント数
```
- **変更点**: 「初回スタンプ付与レコード」→「`firstVisitAt` の記録日時」
- **根拠**: NFCチェックイン・QRチェックインの両方で `store_users` ドキュメントが作成される
- **集計粒度**: 店舗ごとに日次/週次/月次

#### リピート率（週次）
```
リピート率（週次） = 当週に来店（transactions type:'stamp'）が2回以上あるユーザー数
                  ÷ 当週に来店が1回以上あるユーザー数
```
- **変更点**: 「スタンプ付与回数」→「type:'stamp' のトランザクション回数」
- **実質的な変化**: ほぼ同一。スタンプ付与 ≒ NFCチェックイン来店記録

#### リピート率（月次）
```
リピート率（月次） = 当月に来店が2回以上あるユーザー数
                  ÷ 当月に来店が1回以上あるユーザー数
```

#### 来店頻度分布（月次）
```
来店頻度分布 = store_users/{storeId}/users/{userId}.totalVisits の分布
              （1回 / 2回 / 3回 / 4回以上 のユーザー数）
```
- **変更点**: 「月次スタンプ付与回数」→「累計 `totalVisits`」
- **注意**: `totalVisits` は累計値のため、月次の来店回数算出は `transactions` コレクションをクエリするか、月次スナップショット方式を採用する必要がある

### 補助KPI（変更なし）

| KPI | 変更 | 計算方法 |
|-----|------|---------|
| 未訪問来店率（月次） | 変更なし | 当月の「`firstVisitAt` 記録ユーザー数」÷ 当月の全来店ユーザー数 |
| レコメンド経由来店率（月次） | 変更なし | レコメンドクリック後に `firstVisitAt` が作成されたユーザー数 ÷ 当月の全来店ユーザー数 |
| 既存客数（月次） | 変更なし | 当月来店ユーザーのうち `firstVisitAt` が当月以前のユーザー数 |

### 廃止するKPI

| KPI | 廃止理由 |
|-----|---------|
| スタンプ達成率 | スタンプシステム廃止 |
| 特典利用率 | クーポン自動付与廃止 |
| 客単価（平均会計金額） | 会計金額入力廃止（算出不可） |
| スタンプ付与率（実績） | スタンプシステム廃止 |
| LTV proxy（短期） | 会計金額入力廃止（算出不可） |

### 新規追加（ゲーム指標）

#### 図鑑発見者数（月次・全期間）
```
図鑑発見者数（全期間） = stores/{storeId}.discoveredCount
                       （NFCチェックイン時に +1 される累計ユニーク来店者数）
```
- スタンプ廃止後の「新規顧客獲得力」を示す代替指標
- 店舗詳細・ダッシュボードに表示可能

#### 月次発見店舗数（アプリ全体）
```
月次発見店舗数 = 当月に firstVisitAt が作成された（ユーザー×店舗ペア）の総数
```
- プラットフォーム全体の活性度を示す指標
- 月次探検レポートでユーザーに配信（フェーズ3）

---

## BUSINESS_MODEL.md の修正箇所

`## KPI（初期）` セクションを以下のように更新する：

### 変更前（スタンプベース）
```
- 新規顧客数: 店舗ごとの「初回スタンプ付与」ユーザー数
  - 新規判定: DB上でそのユーザーへの初回スタンプ付与レコードが最初に作成された日付
- リピート率（週次）: 当週に「スタンプ付与が2回以上あるユーザー数」÷ ...
- リピート率（月次）: 当月に「スタンプ付与が2回以上あるユーザー数」÷ ...
- 来店頻度分布（月次）: 当月のユーザー別スタンプ付与回数の分布
```

### 変更後（来店トランザクション/firstVisitAtベース）
```
- 新規顧客数: 店舗ごとの「初回来店（firstVisitAt記録）」ユーザー数
  - 新規判定: store_users/{storeId}/users/{userId}.firstVisitAt の記録日時
  - 集計粒度: 店舗ごとに日次/週次/月次で集計
- リピート率（週次）: 当週に来店（type:'stamp' トランザクション）が2回以上あるユーザー数
              ÷ 当週に来店が1回以上あるユーザー数
- リピート率（月次）: 当月に来店が2回以上あるユーザー数 ÷ 当月に来店が1回以上あるユーザー数
- 既存客数（月次）: 当月の来店ユーザーのうち、firstVisitAt が当月以前のユーザー数
- 来店頻度分布（月次）: store_users.totalVisits または月次トランザクション集計による
                        1回 / 2回 / 3回 / 4回以上 の分布
```

---

## Cloud Functions 修正（store_stats/daily の修正）

### 問題
`updateStoreDailyStats` の `visitorCount` 更新条件が `type='award'|'use'` のみで、
NFCチェックイン（`type='stamp'`）が除外されている。

### 修正案

**ファイル**: `backend/functions/src/index.ts`（updateStoreDailyStats 関数）

```typescript
// Before:
if (type === 'award' || type === 'use') {
  updates['visitorCount'] = FieldValue.increment(1);
}

// After:
if (type === 'award' || type === 'use' || type === 'stamp') {
  updates['visitorCount'] = FieldValue.increment(1);
}
```

**または nfcCheckin 関数内で直接更新（推奨）**:
- `nfcCheckin` がトランザクション記録と同時に `store_stats/daily.visitorCount` を更新
- ポイント/スタンプ兼用の `updateStoreDailyStats` に依存しない独立した更新

### 注意点
- 既存の `visitorCount` データはスタンプ来店を含んでいないため過小評価
- 修正後のデータと以前のデータが不連続になる点を分析画面で注記する必要がある

---

## 実装の優先順位

| 優先度 | 作業 | 理由 |
|--------|------|------|
| 高 | BUSINESS_MODEL.md の KPI セクション更新 | ドキュメント整合性 |
| 高 | `store_stats/daily.visitorCount` の修正 | NFCチェックインが集計に入らないバグ修正 |
| 中 | 分析ダッシュボードの表示ラベル変更 | 「スタンプ」→「来店」表記の統一 |
| 低 | 図鑑発見者数の分析画面への追加 | フェーズ1完成後 |

---

## 検証チェックリスト

- [ ] NFCチェックイン時に `store_users.firstVisitAt` が正しく記録されること
- [ ] NFCチェックイン時に `store_users.totalVisits` が +1 されること
- [ ] `stores/{storeId}/transactions` に `type:'stamp'` レコードが作成されること
- [ ] `store_stats/daily.visitorCount` が NFCチェックイン時にも +1 されること（修正後）
- [ ] 分析ダッシュボードの「新規顧客数」が `firstVisitAt` ベースで正しく集計されること
