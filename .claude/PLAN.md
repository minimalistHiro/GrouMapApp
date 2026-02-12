# スタンプ押印画面（StampPunchView）改修プラン

## Context

スタンプ押印画面に「スタンプ獲得」テキストとクーポンリストを追加する。スタンプカードの上に大きめの「スタンプ獲得」テキスト、下にその店舗の未使用クーポンをリスト表示する。クーポンUIは店舗用アプリの `CouponSelectForCheckoutView` と同じリスト形式（チェックボックスなし・表示のみ）。

## 変更対象ファイル

- `lib/views/stamps/stamp_punch_view.dart` - 唯一の変更対象

## 参照ファイル

- 店舗アプリ `lib/views/coupons/coupon_select_for_checkout_view.dart` - クーポンリストUIの参考元
- `lib/providers/coupon_provider.dart` - フィルタリングロジックの参考

## 実装手順

### 1. state変数の追加
- `_availableCoupons`: クーポンリスト
- `_couponsLoading`: クーポン読み込み状態

### 2. `_loadCoupons()` メソッド追加
- `public_coupons` から店舗のクーポン取得
- `users/{uid}/used_coupons` で使用済み除外
- 有効期限・使用回数チェック

### 3. ヘルパーメソッド追加
- `_parseInt`, `_parseValidUntil`, `_isNoExpiryCoupon`

### 4. `_buildBody()` 構造変更
- Stack → Column に変更
- 「スタンプ獲得」テキスト追加（上部）
- クーポンセクション追加（下部）

### 5. `_buildCouponSection()` / `_buildCouponCard()` 追加
- 店舗アプリと同じCard/リスト形式（チェックボックスなし）
- スタンプ不足時のオーバーレイ表示
