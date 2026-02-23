# ログアウト時にisOwner店舗が表示される問題の修正プラン

## Context

ログアウト状態でホーム画面のおすすめ店舗一覧に、isOwnerユーザーが作成した店舗が表示されてしまう。

### 根本原因

現在の除外ロジックは2段階で動作する:

1. **店舗フラグチェック**: `stores.isOwner == true` → 認証不要で動作する
2. **作成者チェック**: `stores.createdBy` が `users.isOwner == true` のユーザーか → `users`コレクションの読み取りが必要

**問題点**: Firestoreルールで `users` コレクションの読み取りは認証必須（`request.auth != null`）かつ自分のドキュメントまたはisOwner/isStoreStaffのみ許可。そのため:

- **ログアウト時**: `ownerUserIds` の取得をスキップ → `createdBy` チェックが機能しない
- **一般ログインユーザー**: `users` コレクションへのクエリが権限不足で失敗 → catch で無視され同様に機能しない

結果: `stores.isOwner` フラグが設定されていないが、isOwnerユーザーが作成した店舗が表示されてしまう。

### 影響範囲（同じパターンの箇所: 4画面）

| ファイル | 行 |
|---------|-----|
| `lib/views/home_view.dart` | 1380-1417 |
| `lib/views/map/map_view.dart` | 260-301 |
| `lib/views/stores/store_list_view.dart` | 100-141 |
| `lib/views/stamps/daily_recommendation_view.dart` | 119-158 |

## 修正方針

**店舗ドキュメント自体の `isOwner` フラグを確実に設定する**ことで、クロスコレクション参照に依存しない設計にする。

## 修正手順

### Step 1: Cloud Function追加 — 店舗作成時の自動isOwnerフラグ設定

**ファイル**: `backend/functions/src/index.ts`

`stores`コレクションへの新規ドキュメント作成をトリガーし、作成者（`createdBy` or `ownerId`）が `users.isOwner == true` のユーザーであれば、その店舗ドキュメントに `isOwner: true` を自動設定する。

```typescript
// 店舗作成時にisOwnerフラグを自動設定
export const onStoreCreated = onDocumentCreated("stores/{storeId}", async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const createdBy = data.createdBy || data.ownerId;
  if (!createdBy) return;

  const userDoc = await db.collection('users').doc(createdBy).get();
  if (userDoc.exists && userDoc.data()?.isOwner === true) {
    await event.data?.ref.update({ isOwner: true });
  }
});
```

### Step 2: 既存データの修正 — HTTPS Callable Function

isOwnerユーザーが過去に作成した店舗で `isOwner` フラグが未設定のものを一括修正するCallable Functionを追加。

```typescript
export const syncStoreOwnerFlags = onCall(async (request) => {
  // isOwner権限チェック
  // isOwner=true の全ユーザーIDを取得
  // そのユーザーが作成した全店舗に isOwner=true を設定
});
```

実行後、正しく設定されたことを確認したらこのfunctionは削除可能。

### Step 3: クライアント側の整理（4画面共通）

`ownerUserIds` のクロスコレクション参照ロジックを削除し、`stores.isOwner` フラグのみでフィルタリングする。コードが簡潔になり、認証状態に依存しなくなる。

**変更前** (各画面で ~20行):
```dart
var ownerUserIds = <String>{};
try {
  if (user != null) {
    // users コレクションから isOwner=true を2回クエリ
    // ownerUserIds に追加
  }
} catch (_) {}

// フィルタリング
final hasOwnerFlag = ...;
final isOwnerByCreator = createdBy != null && ownerUserIds.contains(createdBy);
if (hasOwnerFlag || isOwnerByCreator) continue;
```

**変更後** (各画面で ~5行):
```dart
// isOwner店舗を除外（店舗ドキュメントのフラグで判定）
final rawIsOwner = data['isOwner'];
final isOwnerStore = rawIsOwner == true ||
    rawIsOwner?.toString().toLowerCase() == 'true';
if (isOwnerStore) continue;
```

### 修正対象ファイル一覧

| ファイル | 修正内容 |
|---------|---------|
| `backend/functions/src/index.ts` | onStoreCreated トリガー + syncStoreOwnerFlags 追加 |
| `lib/views/home_view.dart` | ownerUserIds クロス参照削除、isOwnerフラグのみで判定 |
| `lib/views/map/map_view.dart` | 同上 |
| `lib/views/stores/store_list_view.dart` | 同上 |
| `lib/views/stamps/daily_recommendation_view.dart` | 同上 |

## 検証方法

1. `syncStoreOwnerFlags` を実行し、既存データを修正
2. Firestore上で isOwnerユーザーが作成した店舗に `isOwner: true` が設定されていることを確認
3. ログアウト状態でホーム画面のおすすめ店舗一覧を表示し、isOwner店舗が除外されていることを確認
4. ログイン状態でも同様に確認
5. マップ画面・店舗一覧画面・デイリーおすすめ画面でも同様に確認
6. Cloud Function `onStoreCreated` のテスト: isOwnerユーザーで新規店舗を作成し、自動的に `isOwner: true` が設定されることを確認
