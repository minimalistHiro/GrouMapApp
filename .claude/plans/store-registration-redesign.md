# 店舗登録フロー再設計

> 作成日: 2026-03-06
> 対象リポジトリ: 店舗用アプリ（/Users/kanekohiroki/Desktop/groumapapp_store）
> 関連: BUSINESS_MODEL.md「パイロット運用方針」「店舗開拓モデル」

---

## 目次

- [背景・目的](#背景目的)
- [旧フロー（廃止）](#旧フロー廃止)
- [新フロー設計](#新フロー設計)
- [新規作成ファイル一覧](#新規作成ファイル一覧)
- [変更が必要な既存ファイル一覧](#変更が必要な既存ファイル一覧)
- [廃止・削除する機能](#廃止削除する機能)
- [Firestoreスキーマ変更](#firestoreスキーマ変更)
- [各画面の詳細設計](#各画面の詳細設計)
- [Firestoreルール変更](#firestoreルール変更)
- [実装順序](#実装順序)

---

## 背景・目的

### 旧モデルの問題点

現在の実装では「店舗オーナーが自分でアカウントを作り、店舗情報を入力して承認を待つ」フローになっている。

しかしビジネスモデルでは以下の方針が確定している：

> 店舗側に求めるのは「スタンドを置く」だけ。店舗アプリのインストール不要。（BUSINESS_MODEL.md パイロット運用方針）

> 運営が実際に店舗へ足を運び、店舗オーナーに直接声をかけて店舗情報の掲載を依頼する。（店舗開拓モデル）

つまり、**店舗登録は運営（オーナー/管理者）が行うもの**であり、店舗オーナーがアプリをインストールして自分で登録するフローは現在の運用と噛み合っていない。

### 新モデルの方針

| 誰が | 何をするか |
|------|-----------|
| **運営（管理者）** | 営業訪問時に店舗用アプリから全店舗を作成する |
| **店舗オーナー（任意）** | 来店データを自分で見たい場合のみアカウントを作成し、既存店舗に紐づける |

---

## 旧フロー（廃止）

```
LoginView
  └─ 新規登録 → TermsPrivacyConsentView
                    └─ StoreInfoView（店舗情報入力）
                         └─ SignUpView（アカウント作成）
                              └─ EmailVerificationPendingView
                                   └─ ApprovalPendingView（承認待ち）
                                        └─ PendingStoresView（管理者が承認）
```

**問題点:**
- 店舗オーナー自身がアカウント作成と店舗登録を同時に行う設計
- 承認フローが存在するため、登録から使用開始まで時間がかかる
- 運営が直接営業して登録する現在の運用と乖離している

---

## 新フロー設計

### A. 管理者による店舗作成フロー（メイン）

```
OwnerSettingsView
  └─ 「店舗管理」セクション → AdminStoreListView（管理者専用・isOwner=true）
                                  ├─ 店舗一覧（作成済み店舗 + リンクコード確認）
                                  └─ 「+ 新規店舗を作成」
                                       └─ AdminStoreCreateView
                                            ├─ 店舗情報フォーム入力
                                            ├─ 位置情報選択（StoreLocationPickerView）
                                            └─ 作成完了 → リンクコード表示ダイアログ
```

- 作成された店舗は `isApproved: true` で即座に公開状態になる（承認不要）
- 作成時に6文字の英数字リンクコードを自動生成（店舗オーナーが紐づけ時に使用）
- `PendingStoresView` の承認フローは不要になる（詳細は廃止セクション参照）

### B. 店舗オーナーのアカウント作成フロー（任意・オプション）

```
LoginView
  └─ 「来店データを確認したい方はこちら」
       └─ TermsPrivacyConsentView（規約同意）
            └─ StoreOwnerSignUpView（アカウント作成のみ・店舗情報入力なし）
                 └─ EmailVerificationPendingView
                      └─ StoreLinkView（店舗との紐づけ）
                           ├─ リンクコード入力 → 紐づけ完了 → MainNavigationView
                           └─ 「後で紐づける」 → MainNavigationView（店舗未紐づけ状態）
```

- アカウント作成時に店舗情報の入力は不要
- 紐づけはリンクコード（6文字英数字）で行う
- 紐づけ後は既存の `MainNavigationView` でデータ閲覧が可能
- 紐づけなしで利用した場合は「紐づけ先の店舗がありません」状態で制限された画面になる

---

## 新規作成ファイル一覧

### 店舗用アプリ（/Users/kanekohiroki/Desktop/groumapapp_store）

| ファイル | 役割 |
|---------|------|
| `lib/views/settings/admin_store_list_view.dart` | 管理者専用 店舗一覧・リンクコード管理画面 |
| `lib/views/settings/admin_store_create_view.dart` | 管理者専用 新規店舗作成画面 |
| `lib/views/auth/store_owner_sign_up_view.dart` | 店舗オーナー向けアカウント作成画面（店舗情報入力なし） |
| `lib/views/auth/store_link_view.dart` | リンクコード入力による店舗紐づけ画面 |
| `lib/providers/admin_store_provider.dart` | 管理者の店舗作成・管理用 Provider |

---

## 変更が必要な既存ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `lib/views/auth/login_view.dart` | 「新規登録」テキストを「来店データを確認したい方はこちら」に変更し、`StoreOwnerSignUpView` に遷移 |
| `lib/views/auth/terms_privacy_consent_view.dart` | 遷移先を `StoreInfoView` から `StoreOwnerSignUpView` に変更 |
| `lib/views/settings/owner_settings_view.dart` | 「店舗管理」セクションを追加し、`AdminStoreListView` への遷移ボタンを追加 |
| `lib/views/auth/auth_wrapper.dart` | 店舗未紐づけ状態のハンドリングを追加（`StoreLinkView` へのリダイレクト or 警告表示） |
| `STORE_APP_SCREENS.md` | 新フローを反映（認証フロー・設定画面の更新） |

---

## 廃止・削除する機能

| 機能 | 対応方針 |
|------|---------|
| `StoreInfoView`（店舗情報入力）のサインアップフローへの組み込み | ファイル自体は残す。`AdminStoreCreateView` のフォームとして流用するため |
| `SignUpView` への `storeInfo` 引数の引き渡し | `StoreOwnerSignUpView` に移行。`SignUpView` 自体は削除せず残す（後方互換） |
| `ApprovalPendingView`（承認待ち画面） | 管理者が直接作成するため承認フロー不要。画面は残すが遷移しない |
| `PendingStoresView` の承認フロー | 管理者が作成するため不要。ただし画面自体は過去データのために残す |
| `TermsPrivacyConsentView` → `StoreInfoView` の連結 | `TermsPrivacyConsentView` → `StoreOwnerSignUpView` に変更 |

---

## Firestoreスキーマ変更

### 追加フィールド（`stores/{storeId}`）

```
stores/{storeId}
  ├─ linkCode: String?        // 6文字英数字。店舗オーナーが紐づけに使用。管理者作成時に自動生成。
  ├─ createdByOwner: bool     // true = 管理者が作成した店舗（新方式）
  │                           // false or null = 旧方式（店舗オーナーが自己登録）
  └─ linkedUids: List<String> // 紐づけ済みの店舗オーナーUID一覧
```

### 変更フィールド（`stores/{storeId}`）

```
isApproved: bool
  // 管理者作成時は true で作成（承認不要）
  // 旧フローで作成されたデータは既存のまま維持
```

### 追加フィールド（`users/{uid}`）

```
users/{uid}
  └─ linkedStoreId: String?   // 紐づけ先の店舗ID（店舗オーナーが1店舗に紐づく場合）
                              // 複数店舗管理は管理者（isOwner=true）のみ想定
```

---

## 各画面の詳細設計

### AdminStoreListView（管理者専用 店舗一覧）

**遷移元:** `OwnerSettingsView` の「店舗管理」セクション（`isOwner=true` のみ表示）

**構成:**
- `CommonHeader`（「店舗管理」）
- 店舗一覧（`StreamProvider<List<StoreModel>>`、全承認済み店舗）
  - 各カード: 店舗名 / カテゴリ / isActive状態 / リンクコード表示ボタン
  - リンクコードボタンタップ → ボトムシートでリンクコード表示 + コピーボタン
  - リンクコード未生成の場合は「生成する」ボタンを表示
- AppBar右上に「+ 新規店舗作成」ボタン（`AdminStoreCreateView` へ遷移）

**権限:** `isOwner=true` のみアクセス可能（`userIsOwnerProvider` で判定）

---

### AdminStoreCreateView（管理者専用 新規店舗作成）

**遷移元:** `AdminStoreListView` の「+ 新規店舗作成」ボタン

**構成:**
- `CommonHeader`（「新規店舗を作成」）
- `StoreInfoView` と同等のフォーム（以下のフィールドを含む）：
  - 店舗名（必須）
  - カテゴリ / サブカテゴリ（必須）
  - 住所（都道府県 + 市区町村 + 番地）（必須）
  - 位置情報（`StoreLocationPickerView` で選択）（必須）
  - 説明文（任意）
  - 電話番号（任意）
  - 営業時間（任意）
  - 定休日設定（任意）
  - 不定休フラグ（任意）
  - SNSリンク（Instagram / X / Facebook）（任意）
  - 経営形態（個人 / 法人）（任意）
  - 代表者名 / 法人名（任意）
  - 設備・サービス情報（座席数・駐車場・アクセス・テイクアウト・喫煙・Wi-Fi等）（任意）
- 店舗アイコン画像アップロード（任意）
- 店舗イメージ画像アップロード（任意）
- 「作成する」ボタン

**作成時の処理（`admin_store_provider.dart` の `createStore()` メソッド）:**

```
1. Firestore の stores コレクションに新規ドキュメントを作成
   - isApproved: true（即時承認）
   - isActive: false（デフォルト非公開。公開は StoreActivationSettingsView で手動ON）
   - createdByOwner: true
   - linkCode: ランダム6文字英数字（大文字 + 数字）を自動生成
   - createdAt: Timestamp.now()
   - その他のフォーム入力値

2. 作成完了後、リンクコード表示ダイアログを表示
   - ダイアログ内容: 「店舗を作成しました。下のリンクコードを店舗オーナーにお伝えください。」
   - リンクコード（大きく表示）+ コピーボタン
   - 「閉じる」でダイアログを閉じて AdminStoreListView に戻る
```

**バリデーション:**
- 店舗名: 必須、1〜50文字
- カテゴリ: 必須
- 住所（都道府県 + 市区町村）: 必須
- 位置情報: 必須（マップで選択済みであること）

---

### StoreOwnerSignUpView（店舗オーナー向けアカウント作成）

**遷移元:** `TermsPrivacyConsentView` → `StoreOwnerSignUpView`

**旧 `SignUpView` との違い:**
- `storeInfo` パラメータを受け取らない
- アカウント作成のみ行い、店舗情報の入力フォームは存在しない
- 完了後は `EmailVerificationPendingView` → `StoreLinkView` に遷移

**構成:**
- ロゴ
- タイトル「アカウント作成」
- サブタイトル「来店データをアプリで確認するためのアカウントを作成します」
- メールアドレス入力
- パスワード入力
- パスワード確認入力
- 「アカウント作成」ボタン

**作成時の処理:**
```
1. Firebase Auth でアカウント作成（メール + パスワード）
2. Firestore users/{uid} ドキュメントを作成
   - isStoreOwner: true（後でリンクコードで店舗紐づけを行うフラグ）
   - linkedStoreId: null（未紐づけ）
   - createdAt: Timestamp.now()
3. EmailVerificationPendingView へ遷移
4. メール認証完了後 → StoreLinkView へ遷移
```

---

### StoreLinkView（店舗紐づけ画面）

**遷移元:** `EmailVerificationPendingView` の認証完了後 OR `MainNavigationView` 内の「店舗を紐づける」ボタン

**構成:**
- `CommonHeader`（「店舗との紐づけ」）
- 説明テキスト: 「運営から受け取ったリンクコードを入力してください」
- リンクコード入力フィールド（6文字・大文字英数字・自動大文字変換）
- 「紐づける」ボタン
- 「後で紐づける」テキストボタン（`MainNavigationView` に遷移するが、機能が制限された状態）

**紐づけ処理:**
```
1. 入力されたリンクコードで stores コレクションを検索
   - stores.where('linkCode', isEqualTo: inputCode).where('isApproved', isEqualTo: true)

2. 該当店舗が存在しない場合 → 「このリンクコードは無効です」エラー表示

3. 既に他のユーザーが同じ店舗に紐づいている場合（linkedUids に含まれている）
   → 「このコードは既に使用されています。運営にお問い合わせください」エラー表示
   ※ 1つのリンクコードに複数のアカウントを紐づけ可能にする場合は本チェックを削除

4. 紐づけ成功時:
   - stores/{storeId}.linkedUids に uid を追加（arrayUnion）
   - users/{uid}.linkedStoreId = storeId
   - users/{uid}.createdStores = [storeId]（既存の createdStores 配列との整合性維持）
   - MainNavigationView へ遷移（完全機能状態）
```

---

### AdminStoreListView のリンクコード再生成機能

**用途:** 店舗オーナーへの連絡ミス・コード忘れ等のケースに対応

**操作フロー:**
- 店舗カードのリンクコードボタン → ボトムシート表示
- ボトムシート内に「コードを再生成」ボタン（確認ダイアログあり）
- 再生成後は古いコードは無効化され、新しいコードが表示される

**Firestore 更新:**
```
stores/{storeId}.linkCode = 新しいランダム6文字
```

---

## Firestoreルール変更

`/Users/kanekohiroki/Desktop/groumapapp/firestore.rules` への追記が必要。

### linkCode / createdByOwner / linkedUids のアクセス制御

```
// stores コレクションの update ルールに追加
// linkCode・createdByOwner はオーナー専用フィールドとして保護
function updatesRestrictedStoreFields() {
  return !request.resource.data.diff(resource.data).affectedKeys()
    .hasAny(['linkCode', 'createdByOwner', 'isApproved', 'isOwner', 'founderMember']);
}

// linkedUids はアカウント保有ユーザーが自分の UID のみ追加可能
// stores/{storeId}.linkedUids に arrayUnion で自分の uid を追加する操作のみ許可
```

### 新規ルール（stores コレクション）

```javascript
// ①管理者のみ store を isApproved: true で新規作成可能
allow create: if request.auth != null
  && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isOwner == true
  && request.resource.data.isApproved == true;

// ②通常の store 作成（isApproved: false、旧フロー互換維持）
allow create: if request.auth != null
  && request.resource.data.isApproved == false;

// ③linkedUids への自己 UID arrayUnion のみ許可
allow update: if request.auth != null
  && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['linkedUids'])
  && request.resource.data.linkedUids.hasAll(resource.data.linkedUids)
  && request.resource.data.linkedUids.hasAll([request.auth.uid]);
```

---

## OwnerSettingsView への「店舗管理」セクション追加

`owner_settings_view.dart` の「ゲーム設定」セクションの**上**に「店舗管理」セクションを追加する。

```dart
_buildSectionCard(
  title: '店舗管理',
  subtitle: '店舗の新規作成・リンクコード管理を行います',
  icon: Icons.store_outlined,
  children: [
    _buildNavigationRow(
      label: '店舗一覧・新規作成',
      description: '店舗の作成・リンクコードの確認・再生成',
      icon: Icons.add_business_outlined,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminStoreListView()),
      ),
    ),
  ],
),
```

---

## auth_wrapper.dart の変更

`EmailVerificationPendingView` 認証完了後のルーティングに、`linkedStoreId` が null の場合の分岐を追加する。

```dart
// 認証完了後
final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
final isStoreOwner = userDoc.data()?['isStoreOwner'] ?? false;
final linkedStoreId = userDoc.data()?['linkedStoreId'];

if (isStoreOwner && linkedStoreId == null) {
  // 店舗未紐づけ → StoreLinkView へ
  return const StoreLinkView(isFromSignUp: true);
}
return const MainNavigationView();
```

---

## 実装順序

```
Step 1: Firestoreスキーマ更新（FIRESTORE.md への追記）
  - stores.linkCode / stores.createdByOwner / stores.linkedUids
  - users.linkedStoreId

Step 2: admin_store_provider.dart 新規作成
  - createStore() メソッド（isApproved: true、linkCode 自動生成）
  - regenerateLinkCode() メソッド
  - allStoresForAdminProvider（StreamProvider<List<StoreModel>>）

Step 3: AdminStoreCreateView 新規作成
  - StoreInfoView のフォームを流用
  - 作成完了後にリンクコード表示ダイアログ

Step 4: AdminStoreListView 新規作成
  - 店舗一覧 + リンクコード確認ボトムシート
  - AdminStoreCreateView への遷移

Step 5: OwnerSettingsView に「店舗管理」セクション追加
  → firebase deploy 不要（Flutter のみ）

Step 6: StoreOwnerSignUpView 新規作成
  - SignUpView のコピーから storeInfo 関連を削除
  - 遷移先を StoreLinkView に変更

Step 7: StoreLinkView 新規作成
  - リンクコード入力 → stores 検索 → 紐づけ処理

Step 8: TermsPrivacyConsentView の遷移先変更
  - StoreInfoView → StoreOwnerSignUpView

Step 9: LoginView のテキスト変更
  - 「新規登録」→「来店データを確認したい方はこちら」

Step 10: auth_wrapper.dart の変更
  - linkedStoreId null 時の StoreLinkView リダイレクト

Step 11: Firestoreルール更新
  - linkCode / linkedUids のアクセス制御追加
  → firebase deploy --only firestore:rules

Step 12: STORE_APP_SCREENS.md 更新
  - 新フローを反映
```

---

## 既存データとの互換性

旧フローで作成されたユーザー・店舗データへの影響:

| データ | 影響 |
|--------|------|
| 旧フローで作成された store ドキュメント | `createdByOwner` フィールドが存在しない（null 扱い）。既存の承認フロー `isApproved=false` のデータはそのまま残す。`PendingStoresView` は既存の未承認店舗がある場合のために残す |
| 旧フローで作成されたユーザー（`createdStores` あり） | `linkedStoreId` フィールドが存在しない（null 扱い）。`createdStores[0]` を `linkedStoreId` として扱うことで既存の動作を維持 |
| `StoreInfoView` ファイル | 削除しない。`AdminStoreCreateView` のフォームロジックのベースとして参照 |

---

## 未設計・後続検討事項

| 項目 | メモ |
|------|------|
| 店舗オーナーが複数店舗を管理する場合 | 現設計では `linkedStoreId` は単一。複数店舗を持つ場合は `linkedStoreIds: List<String>` に変更検討 |
| リンクコードの有効期限 | 現設計では無期限。セキュリティ要件に応じて有効期限（例: 30日）の追加を検討 |
| 店舗オーナーへの通知 | 紐づけ完了時に「○○店舗と紐づきました」プッシュ通知を送ることを将来検討 |
| `discountParticipating` フラグ | BUSINESS_MODEL.md に記載済みの未実装フィールド。`AdminStoreCreateView` に「100円引き参加」トグルを追加することを検討 |
