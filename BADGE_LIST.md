# バッジ一覧

バッジ定義はアプリ内蔵（`lib/data/badge_definitions.dart`）で管理。
全141種（既存基本20種 + スタンプ追加11種 + カテゴリ別来店50種 + アクション系60種）。

## レア度

| レア度 | 表示名 | カラー |
|--------|--------|--------|
| common | コモン | #9CA3AF（グレー） |
| rare | レア | #3B82F6（ブルー） |
| epic | エピック | #8B5CF6（パープル） |
| legendary | レジェンダリー | #F59E0B（ゴールド） |

---

## 既存バッジ

### スタンプ（stampsTotal）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| stamps_total_1 | はじめてのスタンプ | スタンプを1個集める | common |
| stamps_total_3 | スタンプビギナー | スタンプを3個集める | common |
| stamps_total_5 | スタンプルーキー | スタンプを5個集める | common |
| stamps_total_10 | スタンプコレクター | スタンプを10個集める | common |
| stamps_total_20 | スタンプハンター | スタンプを20個集める | rare |
| stamps_total_30 | スタンプシーカー | スタンプを30個集める | rare |
| stamps_total_50 | スタンプマスター | スタンプを50個集める | rare |
| stamps_total_75 | スタンプベテラン | スタンプを75個集める | rare |
| stamps_total_100 | スタンプエリート | スタンプを100個集める | epic |
| stamps_total_150 | スタンプチャンピオン | スタンプを150個集める | epic |
| stamps_total_200 | スタンプエキスパート | スタンプを200個集める | epic |
| stamps_total_300 | スタンプグランドマスター | スタンプを300個集める | epic |
| stamps_total_500 | スタンプレジェンド | スタンプを500個集める | legendary |
| stamps_total_750 | スタンプゴッド | スタンプを750個集める | legendary |
| stamps_total_1000 | スタンプキング | スタンプを1000個集める | legendary |

### 来店（visitsCount）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| visits_count_common | はじめての常連 | 5回来店する | common |
| visits_count_rare | おなじみさん | 20回来店する | rare |
| visits_count_epic | 街の探検家 | 50回来店する | epic |
| visits_count_legendary | レジェンドビジター | 100回来店する | legendary |

### 連続ログイン（consecutiveDays）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| consecutive_days_common | 3日坊主突破 | 3日連続ログインする | common |
| consecutive_days_rare | ウィークリーチャンプ | 7日連続ログインする | rare |
| consecutive_days_epic | マンスリーチャンプ | 30日連続ログインする | epic |
| consecutive_days_legendary | 継続は力なり | 100日連続ログインする | legendary |

### 店舗巡り（storesVisited）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| stores_visited_common | お店探検家 | 3店舗を訪問する | common |
| stores_visited_rare | 街歩きの達人 | 10店舗を訪問する | rare |
| stores_visited_epic | 地域マスター | 25店舗を訪問する | epic |
| stores_visited_legendary | グランドツーリスト | 50店舗を訪問する | legendary |

### イベント（specialEvents）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| special_events_common | イベント参加者 | イベントに1回参加する | common |
| special_events_rare | イベントファン | イベントに5回参加する | rare |
| special_events_epic | イベントマニア | イベントに10回参加する | epic |
| special_events_legendary | イベントレジェンド | イベントに25回参加する | legendary |

---

## カテゴリ別来店バッジ（categoryVisit）

カテゴリをグループ化し、各グループに5段階のバッジを用意。
対象グループ内のいずれかのカテゴリの店舗に来店した回数でカウント。

### グループ一覧

| # | グループ名 | グループキー | 含まれるカテゴリ |
|---|-----------|-------------|-----------------|
| 1 | カフェ・スイーツ系 | cafe_sweets | カフェ・喫茶店、スイーツ、ケーキ、タピオカ、パン・サンドイッチ |
| 2 | 和食系 | washoku | 和食、日本料理、海鮮、寿司、そば、うどん、うなぎ、天ぷら |
| 3 | 居酒屋・バー系 | izakaya_bar | 居酒屋、バー・お酒、スナック |
| 4 | 焼き鳥・揚げ物系 | yakitori_age | 焼き鳥、とんかつ、串揚げ、お好み焼き、もんじゃ焼き |
| 5 | 鍋・焼肉系 | nabe_yakiniku | しゃぶしゃぶ、鍋、焼肉、ホルモン |
| 6 | ラーメン・中華系 | ramen_chinese | ラーメン、中華料理、餃子 |
| 7 | アジア・エスニック系 | asian_ethnic | 韓国料理、タイ料理、カレー、沖縄料理 |
| 8 | 洋食・フレンチ系 | western_french | レストラン、洋食、フレンチ、スペイン料理、ビストロ |
| 9 | イタリアン・肉料理系 | italian_meat | パスタ、ピザ、ステーキ、ハンバーグ、ハンバーガー |
| 10 | 食堂・その他 | shokudo_other | ビュッフェ、食堂、料理旅館、その他 |

### カフェ・スイーツ系（cafe_sweets）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_cafe_sweets_visit_1 | カフェデビュー | カフェ・スイーツ系の店舗に初めて来店 | common |
| category_cafe_sweets_visit_2 | カフェリピーター | カフェ・スイーツ系の店舗に2回来店 | common |
| category_cafe_sweets_visit_3 | カフェ通 | カフェ・スイーツ系の店舗に3回来店 | rare |
| category_cafe_sweets_visit_4 | カフェマニア | カフェ・スイーツ系の店舗に4回来店 | epic |
| category_cafe_sweets_visit_5 | カフェマスター | カフェ・スイーツ系の店舗に5回来店 | legendary |

### 和食系（washoku）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_washoku_visit_1 | 和食デビュー | 和食系の店舗に初めて来店 | common |
| category_washoku_visit_2 | 和食リピーター | 和食系の店舗に2回来店 | common |
| category_washoku_visit_3 | 和食通 | 和食系の店舗に3回来店 | rare |
| category_washoku_visit_4 | 和食マニア | 和食系の店舗に4回来店 | epic |
| category_washoku_visit_5 | 和食マスター | 和食系の店舗に5回来店 | legendary |

### 居酒屋・バー系（izakaya_bar）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_izakaya_bar_visit_1 | 居酒屋デビュー | 居酒屋・バー系の店舗に初めて来店 | common |
| category_izakaya_bar_visit_2 | 居酒屋リピーター | 居酒屋・バー系の店舗に2回来店 | common |
| category_izakaya_bar_visit_3 | 居酒屋通 | 居酒屋・バー系の店舗に3回来店 | rare |
| category_izakaya_bar_visit_4 | 居酒屋マニア | 居酒屋・バー系の店舗に4回来店 | epic |
| category_izakaya_bar_visit_5 | 居酒屋マスター | 居酒屋・バー系の店舗に5回来店 | legendary |

### 焼き鳥・揚げ物系（yakitori_age）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_yakitori_age_visit_1 | 焼き鳥デビュー | 焼き鳥・揚げ物系の店舗に初めて来店 | common |
| category_yakitori_age_visit_2 | 焼き鳥リピーター | 焼き鳥・揚げ物系の店舗に2回来店 | common |
| category_yakitori_age_visit_3 | 焼き鳥通 | 焼き鳥・揚げ物系の店舗に3回来店 | rare |
| category_yakitori_age_visit_4 | 焼き鳥マニア | 焼き鳥・揚げ物系の店舗に4回来店 | epic |
| category_yakitori_age_visit_5 | 焼き鳥マスター | 焼き鳥・揚げ物系の店舗に5回来店 | legendary |

### 鍋・焼肉系（nabe_yakiniku）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_nabe_yakiniku_visit_1 | 焼肉デビュー | 鍋・焼肉系の店舗に初めて来店 | common |
| category_nabe_yakiniku_visit_2 | 焼肉リピーター | 鍋・焼肉系の店舗に2回来店 | common |
| category_nabe_yakiniku_visit_3 | 焼肉通 | 鍋・焼肉系の店舗に3回来店 | rare |
| category_nabe_yakiniku_visit_4 | 焼肉マニア | 鍋・焼肉系の店舗に4回来店 | epic |
| category_nabe_yakiniku_visit_5 | 焼肉マスター | 鍋・焼肉系の店舗に5回来店 | legendary |

### ラーメン・中華系（ramen_chinese）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_ramen_chinese_visit_1 | ラーメンデビュー | ラーメン・中華系の店舗に初めて来店 | common |
| category_ramen_chinese_visit_2 | ラーメンリピーター | ラーメン・中華系の店舗に2回来店 | common |
| category_ramen_chinese_visit_3 | ラーメン通 | ラーメン・中華系の店舗に3回来店 | rare |
| category_ramen_chinese_visit_4 | ラーメンマニア | ラーメン・中華系の店舗に4回来店 | epic |
| category_ramen_chinese_visit_5 | ラーメンマスター | ラーメン・中華系の店舗に5回来店 | legendary |

### アジア・エスニック系（asian_ethnic）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_asian_ethnic_visit_1 | エスニックデビュー | アジア・エスニック系の店舗に初めて来店 | common |
| category_asian_ethnic_visit_2 | エスニックリピーター | アジア・エスニック系の店舗に2回来店 | common |
| category_asian_ethnic_visit_3 | エスニック通 | アジア・エスニック系の店舗に3回来店 | rare |
| category_asian_ethnic_visit_4 | エスニックマニア | アジア・エスニック系の店舗に4回来店 | epic |
| category_asian_ethnic_visit_5 | エスニックマスター | アジア・エスニック系の店舗に5回来店 | legendary |

### 洋食・フレンチ系（western_french）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_western_french_visit_1 | 洋食デビュー | 洋食・フレンチ系の店舗に初めて来店 | common |
| category_western_french_visit_2 | 洋食リピーター | 洋食・フレンチ系の店舗に2回来店 | common |
| category_western_french_visit_3 | 洋食通 | 洋食・フレンチ系の店舗に3回来店 | rare |
| category_western_french_visit_4 | 洋食マニア | 洋食・フレンチ系の店舗に4回来店 | epic |
| category_western_french_visit_5 | 洋食マスター | 洋食・フレンチ系の店舗に5回来店 | legendary |

### イタリアン・肉料理系（italian_meat）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_italian_meat_visit_1 | イタリアンデビュー | イタリアン・肉料理系の店舗に初めて来店 | common |
| category_italian_meat_visit_2 | イタリアンリピーター | イタリアン・肉料理系の店舗に2回来店 | common |
| category_italian_meat_visit_3 | イタリアン通 | イタリアン・肉料理系の店舗に3回来店 | rare |
| category_italian_meat_visit_4 | イタリアンマニア | イタリアン・肉料理系の店舗に4回来店 | epic |
| category_italian_meat_visit_5 | イタリアンマスター | イタリアン・肉料理系の店舗に5回来店 | legendary |

### 食堂・その他（shokudo_other）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| category_shokudo_other_visit_1 | 食堂デビュー | 食堂・その他の店舗に初めて来店 | common |
| category_shokudo_other_visit_2 | 食堂リピーター | 食堂・その他の店舗に2回来店 | common |
| category_shokudo_other_visit_3 | 食堂通 | 食堂・その他の店舗に3回来店 | rare |
| category_shokudo_other_visit_4 | 食堂マニア | 食堂・その他の店舗に4回来店 | epic |
| category_shokudo_other_visit_5 | 食堂マスター | 食堂・その他の店舗に5回来店 | legendary |

---

## アクション系バッジ

### マップ閲覧（mapOpened）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| map_opened_1 | マップデビュー | マップ画面を初めて開く | common |
| map_opened_5 | マップウォーカー | マップ画面を5回開く | common |
| map_opened_10 | マップナビゲーター | マップ画面を10回開く | rare |
| map_opened_25 | マップエクスプローラー | マップ画面を25回開く | epic |
| map_opened_50 | マップマスター | マップ画面を50回開く | legendary |

### 店舗詳細閲覧（storeDetailViewed）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| store_detail_viewed_1 | 店舗チェッカー | 店舗詳細を初めて閲覧 | common |
| store_detail_viewed_5 | 店舗リサーチャー | 店舗詳細を5回閲覧 | common |
| store_detail_viewed_10 | 店舗アナリスト | 店舗詳細を10回閲覧 | rare |
| store_detail_viewed_25 | 店舗ウォッチャー | 店舗詳細を25回閲覧 | epic |
| store_detail_viewed_50 | 店舗博士 | 店舗詳細を50回閲覧 | legendary |

### プロフィール完成（profileCompleted）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| profile_completed | 自己紹介マスター | プロフィールを完成させる | rare |

### お気に入り登録（favoriteAdded）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| favorite_added_1 | はじめてのお気に入り | 初めてお気に入り登録する | common |
| favorite_added_3 | お気に入りビギナー | 3店舗をお気に入りに登録 | common |
| favorite_added_5 | お気に入りコレクター | 5店舗をお気に入りに登録 | rare |
| favorite_added_10 | お気に入りマニア | 10店舗をお気に入りに登録 | epic |
| favorite_added_25 | お気に入りキング | 25店舗をお気に入りに登録 | legendary |

### スロット（slotPlayed）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| slot_played_1 | スロットデビュー | スロットを初めてプレイ | common |
| slot_played_5 | スロットプレイヤー | スロットを5回プレイ | common |
| slot_played_10 | スロットファン | スロットを10回プレイ | rare |
| slot_played_25 | スロットマニア | スロットを25回プレイ | epic |
| slot_played_50 | スロットキング | スロットを50回プレイ | legendary |

### スロット当選（slotWin）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| slot_win_1 | ビギナーズラック | スロットに初めて当選 | rare |
| slot_win_3 | ラッキーガイ | スロットに3回当選 | epic |
| slot_win_5 | 幸運の持ち主 | スロットに5回当選 | legendary |

### クーポン使用（couponUsed）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| coupon_used_1 | クーポンデビュー | クーポンを初めて使用 | common |
| coupon_used_3 | クーポンユーザー | クーポンを3回使用 | common |
| coupon_used_5 | クーポンハンター | クーポンを5回使用 | rare |
| coupon_used_10 | クーポンマスター | クーポンを10回使用 | epic |
| coupon_used_25 | クーポンレジェンド | クーポンを25回使用 | legendary |

### いいね（likeGiven）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| like_given_1 | はじめてのいいね | 投稿に初めていいねする | common |
| like_given_10 | いいねビギナー | 投稿に10回いいねする | common |
| like_given_25 | いいねファン | 投稿に25回いいねする | rare |
| like_given_50 | いいねマスター | 投稿に50回いいねする | epic |
| like_given_100 | いいねレジェンド | 投稿に100回いいねする | legendary |

### コメント投稿（commentPosted）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| comment_posted_1 | はじめてのコメント | 初めてコメントを投稿 | common |
| comment_posted_5 | コメンター | コメントを5回投稿 | common |
| comment_posted_10 | コメントファン | コメントを10回投稿 | rare |
| comment_posted_25 | コメントマスター | コメントを25回投稿 | epic |
| comment_posted_50 | コメントレジェンド | コメントを50回投稿 | legendary |

### フォロー（followUser）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| follow_user_1 | はじめてのフォロー | 初めて他ユーザーをフォロー | common |
| follow_user_5 | フォロワー | 5人をフォロー | common |
| follow_user_10 | ソーシャルバタフライ | 10人をフォロー | rare |
| follow_user_25 | コミュニティリーダー | 25人をフォロー | epic |

### コイン獲得（coinsEarned）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| coins_earned_10 | コインビギナー | コインを累計10枚獲得 | common |
| coins_earned_50 | コインコレクター | コインを累計50枚獲得 | common |
| coins_earned_100 | コインハンター | コインを累計100枚獲得 | rare |
| coins_earned_300 | コインリッチ | コインを累計300枚獲得 | epic |
| coins_earned_500 | コインタイクーン | コインを累計500枚獲得 | legendary |

### ミッション達成（missionCompleted）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| mission_completed_1 | ミッションクリア | ミッションを初めて達成 | common |
| mission_completed_5 | ミッションハンター | ミッションを5回達成 | common |
| mission_completed_10 | ミッションファイター | ミッションを10回達成 | rare |
| mission_completed_25 | ミッションヒーロー | ミッションを25回達成 | epic |
| mission_completed_50 | ミッションレジェンド | ミッションを50回達成 | legendary |

### レコメンド閲覧（recommendViewed）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| recommend_viewed_1 | レコメンドチェック | レコメンドを初めて閲覧 | common |
| recommend_viewed_5 | レコメンドウォッチャー | レコメンドを5回閲覧 | rare |
| recommend_viewed_10 | レコメンドマニア | レコメンドを10回閲覧 | epic |

### スタンプカード達成（stampCardCompleted）

| バッジID | 名前 | 獲得条件 | レア度 |
|----------|------|----------|--------|
| stamp_card_completed_1 | カード達成 | スタンプカードを初めて達成 | common |
| stamp_card_completed_3 | カードコレクター | スタンプカードを3枚達成 | rare |
| stamp_card_completed_5 | カードマスター | スタンプカードを5枚達成 | epic |
| stamp_card_completed_10 | カードレジェンド | スタンプカードを10枚達成 | legendary |

---

## バッジ数サマリー

| カテゴリ | 個数 |
|---------|------|
| スタンプ（stampsTotal） | 15 |
| 来店（visitsCount） | 4 |
| 連続ログイン（consecutiveDays） | 4 |
| 店舗巡り（storesVisited） | 4 |
| イベント（specialEvents） | 4 |
| カテゴリ別来店（categoryVisit）10グループ | 50 |
| アクション系（14カテゴリ） | 60 |
| **合計** | **141** |

---

## 画像

- 保存先: `assets/images/badges/{badgeId}.png`
- サイズ: 512x512px（推奨）
- 形式: PNG（背景透明）
- 生成ツール: Nano Banana Pro（Gemini 3 Pro Image）API
- 生成スキル: `badge-image-gen`（統一テンプレートでバッジ画像を生成）
- 生成済み: 1/141（`stamps_total_1.png`）

## 獲得処理

- 獲得ロジック: `lib/providers/badge_provider.dart`
  - アクション系: `incrementBadgeCounter()` → カウンター更新後に即座に `_checkAndAwardBadge()` で判定・付与
  - スタンプ/来店/連続ログイン等: `runComprehensiveBadgeCheck()` で日次包括判定
- 獲得状況の保存先: Firestore `user_badges/{userId}/badges/{badgeId}`
- 進捗の保存先: Firestore `badge_progress/{userId}_{counterKey}`
- ポップアップ制御: `lib/views/main_navigation_view.dart` で一元管理
  - 毎回ホーム画面表示時: `isNew: true` の軽量チェック → 2秒後にポップアップ
  - 本日初ログイン時: 包括チェック → レコメンドポップアップ優先 → 閉じた後2秒でバッジポップアップ
- トリガー実装状況: **実装済み**（13箇所）
  - マップ画面表示 (`mapOpened`): `lib/views/map/map_view.dart`
  - 店舗詳細表示 (`storeDetailViewed`): `lib/views/stores/store_detail_view.dart`
  - お気に入り登録 (`favoriteAdded`): `lib/views/stores/store_detail_view.dart`
  - スロットプレイ (`slotPlayed`): `lib/views/lottery/lottery_view.dart`
  - スロット当選 (`slotWin`): `lib/views/lottery/lottery_view.dart`
  - コイン獲得 (`coinsEarned`): `lib/views/lottery/lottery_view.dart`, `lib/views/missions/missions_view.dart`
  - クーポン使用 (`couponUsed`): `lib/views/coupons/coupon_detail_view.dart`
  - いいね (`likeGiven`): `lib/providers/social_provider.dart`
  - コメント投稿 (`commentPosted`): `lib/providers/social_provider.dart`
  - フォロー (`followUser`): `lib/providers/social_provider.dart`
  - ミッション達成 (`missionCompleted`): `lib/views/missions/missions_view.dart`
  - レコメンド閲覧 (`recommendViewed`): `lib/views/stamps/daily_recommendation_view.dart`
  - スタンプカード達成 (`stampCardCompleted`): `lib/views/stores/store_detail_view.dart`
