# ユーザー用アプリ 画面一覧（構成と説明）

この一覧は `/Users/kanekohiroki/Desktop/groumapapp/lib/views` 配下の画面実装を基に整理しています。各画面の「構成」は主要なUI要素の概要、「説明」は用途の軽い要約です。
※ 2026-03-07更新（アカウント画面ランクゲージ移設・UI改善）: ProfileViewのXP進捗カード（ルーキー→探索者のゲージ欄）を廃止し、アバターアイコン周りに円形ランクプログレスリングを追加（ポケモンGO風）。`_RankProgressPainter`（`CustomPainter`）で実装: 背景トラック（半透明白リング）＋ランクカラーの進捗アーク＋アーク先端に輝点を表示。アバター外径92px・内径76px・ストローク幅4px。アニメーションは既存の `_xpAnimController`（1200ms `Curves.easeOut`）を再利用。ゲームアクショングリッド（2列GridView）を廃止し `FloatingMenuItem` リスト形式（`_buildSettingsMenuContainer`）に変更。
※ 2026-03-07更新（アカウント画面ゲームUI全面刷新）: ProfileViewをゲーム性重視のUIに全面リデザイン。①プレイヤーカード: ダークネイビー背景（`Color(0xE6101E2E)`）に発見数ベース5段階ランク（Lv.1 ルーキー 0-5店舗 / Lv.2 探索者 5-15店舗 / Lv.3 冒険家 15-30店舗 / Lv.4 開拓者 30-50店舗 / Lv.5 レジェンド 50店舗+）・ランク色アバターリング・Lv.Nバッジ・3つの統計セル（発見数・バッジ・ランキング）を配置。②XP進捗カード: 1200ms `Curves.easeOut` アニメーション付きLinearProgressIndicatorで次ランクまでの進捗を可視化（`SingleTickerProviderStateMixin`）。③ゲームアクショングリッド: 2列GridViewのダークスタイルカード（`Color(0xFF0D1B2A)` + アクセントカラーボーダー: バッジ/ランキング/月次レポート/通知（StreamBuilderで未読バッジ付き）/スタンプカード（条件付き））を配置。ログアウト確認を `showGameDialog` に統一。未使用メソッド（`_buildWebImageWidget` 等）・未使用import（`dart:convert` / `http`）を削除してwarning0件に。
※ 2026-03-07更新（UIコンポーネント統一・ダイアログリデザイン）: `CustomButton`（`custom_button.dart`）にデフォルトオレンジグラデーション（`#FF6B35`→`#FF8C42`）を追加。`backgroundColor`・`borderColor`・`gradient` のいずれも未指定の場合に自動適用。アウトラインボタン（`borderColor`指定）・ソリッドカラーボタン（`backgroundColor`指定）には影響なし。MapViewの「詳細を見る」ボタン（`GestureDetector`+`Container`+手動グラデーション）を`CustomButton`に統一。ProfileViewのプロフィール編集ボタン（`ElevatedButton`）を`CustomButton`に統一。`GameDialog`（`game_dialog.dart`）を全面リデザイン: オレンジヘッダー・アイコンを廃止し全面白背景に変更。ダイアログの影を中立グレー（`Colors.black 12%`）に変更。ボタンが2つの場合は`Row`+`Expanded`で左右均等配置（左: グレー背景セカンダリ・右: オレンジグラデーションプライマリ）。3ボタン以上は従来通り縦並び。`icon`・`headerColor`パラメータは後方互換のため残存（表示には非反映）。
※ 2026-03-07更新（マップピン全タイプグラデーション化・スピンアニメーション改良）: 通常ピン（`else`分岐: 個人モードの発見済み/探索中/常連、開拓モードの開拓済み青ピンなど）に `ui.Gradient.linear` を追加し、全ピンタイプがグラデーション対応に。グラデーションは `pinAccentColor` を基準に上端45%白混合→中央元色→下端30%黒混合の3段階。Y軸スピンアニメーションを改良: 1回転→5〜6回転（`Random().nextInt(2)`）に変更。イージングを等間隔から cubic ease-out（`1-(1-t)³`）に変更し、最初は速く回転して徐々に重力に引かれるように減速。40フレーム×50ms = 計2秒のアニメーション。`cos(angle).abs()` で全回転分の角度をスケールに変換。
※ 2026-03-07更新（マップピンアニメーション＆グラデーション追加）: MapViewのピンに2種のアニメーションを追加。①ふわふわアニメーション: `AnimationController`（2.5秒周期・`repeat(reverse: true)`）で `easeInOut` カーブ＋sin波を用いてピンの `anchor.dy` を 1.0〜1.12 の範囲で揺動。②スピンアニメーション: 5秒ごとに `Timer.periodic` で発火、0.7秒かけて `rotation` を 0→360度に変化。ビットマップ再生成なしで `_getAnimatedMarkers()` が毎フレーム `Marker.copyWith` で anchor/rotation のみ更新する設計で軽量実装。通常モードの営業中ピン（緑 `#43A047`）に明→暗3段階グラデーション（`#81C784`→`#43A047`→`#2E7D32`）を追加（`isGreenPin` フラグ）。個人モードの未発見ピン（`undiscovered`）にも `isGrayPin = true` を設定し、既存のグレーグラデーションを適用。ピンサイズを通常時 40→58・拡大時 80→116 に拡大（元サイズの約1.45倍）。
※ 2026-03-07更新（マップ統計サークルタップ対応）: MapViewの右側スタットサークル（発見数/バッジ数/ランキング順位）をタップ可能に変更。各サークルに `GestureDetector` を追加し、タップ時に `showGameDialog` による説明ポップアップ（項目の説明文＋現在値）を表示。発見数（青）・バッジ数（紫）・ランキング順位（黄）それぞれのアイコンカラーをヘッダーカラーに適用。
※ 2026-03-06更新（図鑑カードUI微調整）: ZukanCardWidgetのカード角丸を8→6に縮小。発見済みカードの縁をレア度単色ボーダーからグラデーションborderに変更（星1〜3=シルバー系グラデーション、星4=ゴールド系グラデーション・padding 3.0で内側に食い込む形で枠を太く）。店舗名テキストを fontSize 6→5、説明テキストを fontSize 5→4 に縮小。未発見カードの枠も border width 1.0→2.0 に変更。
※ 2026-03-06更新（マップゲームUI全面刷新）: MapViewのGoogle Mapsスタイルをダークブルー系ゲームスタイル（`_gameMapStyle` 定数）に変更（旧: POI非表示のみ）。店舗情報カードを半透明ダーク背景（`#101E2E` 90%不透明）＋シアン発光ボーダー（`#00E5FF`）のゲーム風パネルに全面変更。パネル内に来店ステータスバッジ（未発見/初発見/探索中/常連/レジェンド）・グラジエントオーバーレイ・オレンジグラジェントボタンを追加。現在地中心のレーダーアニメーション（3つの同心円が20m→200mに拡大フェードアウト）を追加（`TickerProviderStateMixin` + `AnimationController`）。店舗情報非表示時に下部プレイヤーHUD（発見数/スタンプ数/ポイントの3指標・シアンボーダーパネル）を常時表示。マーカータップ時にオレンジ選択リング拡大アニメーション（`getScreenCoordinate()` でスクリーン座標変換）を追加。検索・フィルター・コントロールボタンをダーク背景＋シアンボーダーに変更。マーカータップの `HapticFeedback` を `lightImpact` → `mediumImpact` に強化。閉じるボタンもゲーム風ダークスタイルに変更。
※ 2026-03-06更新（図鑑カードUIポケカ風リデザイン）: ZukanCardWidgetをポケモンカード風UIに全面リデザイン。カード上部にカテゴリカラー帯＋店舗名（左）＋レア度星（右）の固定14px帯、中央に1:1正方形アイコン/画像（`AspectRatio(1.0)`）、下部に説明テキスト最大40文字（`padding: all(4)`余白付き）のレイアウト。レア度カラー（コモン=グレー/レア=ブルー/エピック=パープル/レジェンド=ゴールド）でカード枠ボーダーを色分け。未発見カードをグレー背景（`grey.shade200/300/400`）に変更（旧: 黒系ダーク `#1E1E1E` 等）。未発見カードタップ時はSnackBarを廃止し `showDialog`（AlertDialog「まだ未発見のお店です」）を表示。グリッドの`childAspectRatio`を`0.68`→`0.60`に変更。
※ 2026-03-06更新（マップピン色改善）: 通常モードのピンアクセント色（ボーダー＋尾）を営業中=緑 `#43A047`・営業時間外=グレー `#BDBDBD` に変更。個人モードのピン中心を常に店舗アイコン画像（画像なし時はカテゴリアイコン）表示に変更し、ピンアクセント色をステータスに応じた色（グレー/水色/緑/オレンジ/ゴールドグラデーション）に変更。MapViewの左上に通常モード用凡例カード（緑丸=営業中・グレー丸=営業時間外）を追加。フィルター設定から「営業状況」（営業中のみ表示）セクションを削除。
※ 2026-03-06更新（マップUI改善④）: MapViewのモードトグル（通常/個人/コミュニティ）をカスタムウィジェット `CompactToggleBar`（`compact_toggle_bar.dart`）に置き換え。`TabController`・`TickerProviderStateMixin` を廃止し `_mapMode` 文字列のみで状態管理。コミュニティサブモードトグル（開拓率/賑わい度）も同ウィジェット化。白背景・影あり・プライマリカラー選択の統一されたピル型UIに変更。
※ 2026-03-06更新（マップUI改善③）: MapViewのモードトグルを独自ピルUIから `CustomTopTabBar`（`TabController`ベース）に変更（背景色 `#FBF6F2`・黒テキスト・黒インジケーター・`Material`ラップ＋角丸12・影付き）。マーカータップ時に `HapticFeedback.lightImpact()` を追加（近接自動フォーカス時の `mediumImpact` より弱め）。
※ 2026-03-07更新（図鑑カードUI統一）: `ZukanCardFaceWidget` を新規作成しポケモンカード風デザインを共通化（グリッド小カード・ズームモーダル・NFCチェックイン発見演出で同一UI）。`LayoutBuilder` でカード幅に応じたレスポンシブフォントサイズ。9停止点グラデーション枠（星1〜3=シルバー×白・星4=ゴールド×白）＋カテゴリカラー0.22ブレンド白背景＋左右余白付き画像フレーム。ZukanViewの発見済みカードタップを `showGeneralDialog` ズームモーダルに変更（240px ZukanCardFaceWidget + 「店舗詳細を見る」ボタン）。未発見カードタップを `showGameDialog` に変更。ZukanCardViewの `_CardFront` を `ZukanCardFaceWidget` に統一。
※ 2026-03-06更新（ZukanCardView UI刷新）: カード発見演出画面を全面リニューアル。背景を `Color(0xFF0A0A14)` の深い暗色＋レア度カラーのRadialGradientグロー＋スパークル（光の粒）に変更。アニメーションを3コントローラー構成（`_flipController`・`_glowController`・`_textController`）に拡張。カード裏面に「ぐるまっぷ」ロゴ＋🗺️＋同心円パターンを追加。カード表面をレア度カラーのグラデーション背景＋グロー枠に変更（実店舗画像を円形フレームで表示、画像なし時はカテゴリアイコンでフォールバック）。完了ボタンをレア度カラーのLinearGradientグラデーションボタン（初回「図鑑に登録完了！」/再訪問「ホームに戻る」）に変更。再訪問時は「再訪問」テキストをフェードイン表示。
※ 2026-03-06更新（図鑑UI刷新）: ZukanViewを5列フラットグリッド（`crossAxisCount: 5`）に変更。カテゴリ別グループ・フィルターチップ・ソートメニューを廃止し、zukanOrder番号順の単一グリッドに統一。未発見カードをダーク背景+「?」マーク表示に変更（旧: グレースケール画像+「？？？」）。ZukanCardWidgetにindexパラメータを追加しカード左上に番号表示。
※ 2026-03-06更新（UI調整）: ZukanView・NfcCouponSelectView・NfcCheckinResultView の CommonHeader に `showBack: false` を設定し、左上の戻るボタンを非表示に変更。MapView の店舗情報パネル（ピンタップ時）からスタンプ進捗インジケーター（丸10個のスタンプ状態表示）を削除（スタンプシステム廃止に伴うUI整理）。
※ 2026-03-06更新（マップUI改善）: MapViewの検索バーを折りたたみ式に変更（通常時は左上の検索アイコンのみ表示、タップで展開・←ボタンで折りたたみ）。「開拓・未開拓」トグルを廃止し、フィルターチップ「開拓」を「開拓状況」に統合（選択時にピンのボーダー色切り替えを自動ON）。
※ 2026-03-06更新（マップモードUI刷新）: フィルターチップ列（営業中/ジャンル別/開拓状況/個人マップ/コミュニティ）を廃止し、検索バー直下に3択モードトグルピル（通常/個人/コミュニティ）を常時表示するUIに変更。ジャンル別表示・開拓状況表示はフィルター設定画面の「マップ表示設定」セクションに移動。MapFilterModelに `categoryMode`・`pioneerMode` フィールドを追加し、Firestoreに保存。
※ 2026-03-06更新（近接自動フォーカス）: MapViewにGeolocator位置ストリーム（5m移動ごと更新）を追加し、ユーザーが店舗の半径50m以内に入ると自動でそのピンを拡大・店舗情報パネルを表示（ピンタップと同じ挙動）。同時に`HapticFeedback.mediumImpact()`でスマホを軽く振動させる。100m以上離れるとリセットされ再来接近時に再発火。複数店舗が同時に50m以内になった場合は1店舗のみフォーカス（`_proximityTriggeredStoreIds`で重複防止）。
※ 2026-03-06更新（フェーズ3-D）: MissionsView に「週次」タブを追加（4タブ化: デイリー/ログイン/新規登録/週次）。週次ミッション進捗表示・達成判定ボタン・累計達成バッジ進捗を追加。NfcCheckinResultView に `checkWeeklyMission` Cloud Function 呼び出しを追加（バックグラウンド実行、達成時ダイアログ表示）。
※ 2026-03-06更新（フェーズ3-C）: MonthlyReportView（月次探検レポート画面）・MonthlyReportListView（過去レポート一覧画面）を追加。ProfileViewのゲームセクションに「過去のレポート」メニューを追加。DeepLinkService に `/monthly_report/{yearMonth}` ルート追加（FCM通知タップ→MonthlyReportView直接遷移）。generateMonthlyReport Scheduled Functionが毎月末23:00 JSTに実行。
※ 2026-03-06更新（ウォークスルー改善）: ウォークスルーを4ステップから6ステップに拡張。concept（フルスクリーンコンセプト画面・3アイコン説明）・learnNfcTouch（NFCタッチ説明・フルスクリーン）・tapProfileTab（アカウントタブ案内）を追加。tapClosePanelを削除。WalkthroughStepConfigにsubMessage・requiresActionフィールドを追加。WalkthroughOverlayにフルスクリーンモード・コンセプトレイアウト・次へボタンを追加。
※ 2026-03-06更新（フェーズ2 ②）: MapViewに「個人マップ」「コミュニティ」フィルターチップを追加。個人マップモード（totalVisitsに応じた5段階ピン色：グレー/ライトブルー/グリーン/オレンジ/ゴールド）・コミュニティマップモード（エリアCircleオーバーレイ「開拓率」/ totalVisitCountによる賑わい度Circleオーバーレイ「賑わい度」のサブモードトグル）を追加。_setMapMode()でモード切り替えを一括管理。
※ 2026-03-05更新（フェーズ2 ①）: AreaExplorationView（エリア開拓率一覧画面）を追加。MapViewにエリアCircleオーバーレイ描画（_loadAreas/_buildAreaCircles）を追加。StoreDetailViewに秘境スポットバッジを追加（areaId == null の店舗）。
※ 2026-03-05更新（フェーズ1 ⑥ #14）: 階層図を3タブ構成（マップ/図鑑/アカウント）に更新。旧ホームタブ・投稿タブ・QRタブを主タブから削除。図鑑タブ（ZukanView）を追加。NFCチェックインフローにZukanCardView遷移を追加。ウォークスルー説明を7ステップから4ステップに修正。
※ 2026-03-05更新（フェーズ1 ③）: ナビゲーション3タブ化（マップ/図鑑/アカウント）、FAB廃止。ProfileView強化（探検統計カード・通知ベル・ゲームセクション・QRフォールバックボタン）。ウォークスルーを4ステップに短縮（ステップ④「図鑑タブで発見済み店舗を確認しよう」に変更）。友達紹介UI廃止（home_view.dartから導線削除）。
※ 2026-03-05更新: NFCチェックイン導線を単線化。正規URLを `https://groumapapp.web.app/checkin?...` に統一し、旧ホスト `groumap-ea452.web.app` は互換期間のみ受理。`/checkin` の自動 `groumap://` リダイレクトを廃止し、手動ボタンでのみアプリを開く方式に変更。アプリ側は `storeId:secret` キーで5秒重複抑止 + チェックイン画面表示中の同一キー再push禁止を追加。
※ 2026-03-03更新: NFCチェックイン機能を実装。`DeepLinkService`（`app_links`パッケージ）でNFCタグのURL Deep Linkを受信し、`MainNavigationView`から`NfcCouponSelectView`（クーポン選択画面）経由で`NfcCheckinService`→Cloud Functions `nfcCheckin`を呼び出し、`NfcCheckinResultView`（結果画面・使用済みクーポン確認コード＋スタンプカード表示）に遷移するフローを追加。Universal Links（iOS）/ App Links（Android）設定済み。1日1回スタンプ制限（`lastStampDate`フィールド）を`punchStamp`/`nfcCheckin`の両方に適用。
※ 2026-03-02更新: チュートリアル完了後のインタラクティブウォークスルー（7ステップ）を実装。グレーアウトオーバーレイ＋ハイライト穴あきで操作対象を誘導する `WalkthroughOverlay` を追加。`WalkthroughProvider` でステップ管理。`MainNavigationView`（ステップ1・4: タブ誘導）、`MapView`（ステップ2・3: マーカータップ・パネル閉じ）、`HomeView`（ステップ5・7: FAB・コイン交換）、`MissionsView`（ステップ6: コイン受取）にオーバーレイを配置。Firestore `users/{uid}.walkthroughCompleted` で完了管理。first_mapミッション報酬を1→10コインに変更。
※ 2026-03-01更新（3回目）: 営業時間の複数時間帯（periods）対応。`StoreModel`の`StoreDayHours`に`periods`フィールドを追加。`MapView`の`_isStoreOpenNow()`と`_getTodayHours()`、`StoreDetailView`の営業時間表示・ステータス判定を複数時間帯に対応。ランチ+ディナー等の分割営業時間を正しく表示・判定。
※ 2026-03-01更新（2回目）: `MissionsView` のタブバーからコイン交換タブを削除し、3タブ（デイリー/ログイン/新規登録）に変更。`showCoinExchange` パラメータを追加し、ホーム画面からコイン交換モードで直接遷移可能に。`HomeView` のおすすめ店舗セクション直下にコイン交換カプセルボタンを追加（10コイン以上保有時のみ表示・タップで `MissionsView(showCoinExchange: true)` に遷移）。
※ 2026-03-01更新: `HomeView` の統計カプセルバーのコインアイコンを `icon_coin.png`（旧ゴールド塗りつぶし）から `icon_coin_only.png`（オレンジ色ソリッド塗りつぶし・背景透過）に変更。新アイコンはGrouMapブランドカラー（#FF6B35）のソリッドシルエットスタイルで、内部ディテール（$マーク・円の輪郭）は白い切り抜きで表現。logo-genスキルの新スタイル（ソリッド塗りつぶし）で生成。
※ 2026-02-27更新（4回目）: `StampCardWidget` のカード番号バッジ（「N枚目」紫バッジ）を常時表示に変更。旧仕様では `completedCards > 0` 時のみ「2枚目」以降を表示していたが、新仕様では1枚目から「1枚目」バッジを常時表示し、現在進行中のカード番号を一目で確認できるようにした。また `processAwardAchievement` Cloud Function のスタンプ付与ロジックを累積型（上限なし）に修正（旧仕様は MAX_STAMPS でキャップされていた）。
※ 2026-02-27更新（3回目）: `UserInfoView` に友達紹介コード入力者へのウェルカムお知らせ自動作成処理を追加。紹介者名・双方コイン数・スタンプ獲得手順（4ステップ）・コイン交換方法を含む `social` タイプ通知を `users/{uid}/notifications` に作成し、初回ホーム遷移前に届く。
※ 2026-02-27更新（2回目）: `UserInfoView` の友達紹介コード入力欄を常時表示に変更（キャンペーン期間中のみ・折りたたみ廃止）。ヘッダーの戻るボタンを非表示に変更。`FriendReferralView` の文言を「ポイント」→「コイン」に統一し、コイン付与タイミング（友達の初スタンプ獲得時）の説明を明確化。デフォルト報酬を5コインに修正。
※ 2026-02-27更新: `ProfileEditView` に `showNextButton` パラメータを追加。プロフィール未完成フロー（ProfileViewの「プロフィールを完成させよう」カード経由）では保存ボタンが「次へ」に変わり、保存後に自動で `InterestCategoryView` へ遷移するシームレスなフローを実装。`ProfileView` のプロフィール完成度ゲージを7項目→6項目に変更（プロフィール画像を任意化・ゲージ対象外に）。
※ 2026-02-26更新（5回目）: 友達紹介システム実装。`UserInfoView` に任意の友達紹介コード入力欄（折りたたみ式）を追加。`ProfileView` に友達紹介セクション（自分のコード表示・コピーボタン・紹介件数・特典説明）を追加。Cloud Functions `processFriendReferral` + `punchStamp` で初回スタンプ時に紹介者・被紹介者に各+5コインを付与。
※ 2026-02-26更新（4回目）: スタンプカード無限化対応。`HomeView` の特別クーポンセクションにスタンプカード達成クーポン（`stamp_reward`）を統合。`StampCardsView` に累積スタンプの「○枚目」進行表示を追加。`CouponDetailView` に `stamp_reward` 専用フロー（達成バッジ表示・スタンプ数チェックスキップ・有効期限なし）を追加。
※ 2026-02-26更新（3回目）: `HomeView` のメニューグリッドUIを刷新。従来のオレンジ角丸コンテナを廃止し、スタンプ/バッジ/店舗一覧/クーポンをそれぞれ独立した白い円形ボタン + 背景透過オレンジアイコン（30x30）で表示する構成に変更。統計カプセル用のコイン/スタンプ/バッジアイコンを含む5種アイコンは背景透過済み画像に統一。
※ 2026-02-26更新（2回目）: `TermsPrivacyConsentView` の同意UIを段階同意フローに更新。利用規約/プライバシーポリシーを白枠カード化し、各カード内に青色「確認する（必須）」ボタンを配置。文書画面で最下部までスクロール後に有効化される「同意する」押下でのみ同意済みに遷移し、同意済みカードの確認ボタンはグレーアウト。2項目とも同意済みになった時のみ「同意して次へ」が有効化される仕様に変更。
※ 2026-02-26更新: `StoreDetailView` の上部レイアウトを再構成。店舗イメージ画像の左下に店舗アイコンを重ね表示し、店舗基本情報（店名/お気に入り/フォロー/住所/営業時間/店舗説明）を上部ヘッダーに集約。上部タブ（トップ/店内/メニュー/投稿）はヘッダー直下に固定表示し、トップタブ側の重複ヘッダーを廃止。
※ 2026-02-25更新: `ProfileView` のアカウントセクションから「退会する」メニュー項目を削除。`HelpView` の「よくある質問」末尾に「退会するには？」ExpansionTile を追加。展開時に案内テキスト＋「退会するにはこちら」テキストボタン（赤色・下線付き）を表示し、`AccountDeletionReasonView`（退会理由入力）へ遷移。理由送信後に `AccountDeletionProcessingView` で退会処理を実行するフローに整理。
※ 2026-02-24更新（13回目）: `HomeView` の統計カプセルバーアイコン（コイン/バッジ/スタンプ）とメニューグリッドアイコン（スタンプ/バッジ/店舗一覧/クーポン）を、AIで生成したカスタム画像アイコン（PNG・透明背景）に置き換え。Materialアイコン→`Image.asset`に変更。
※ 2026-02-24更新（12回目）: `HomeView` の「今日のレコメンド」を微調整。見出し文字サイズを「クーポン」「投稿」と同一に統一し、カード内テキストと余白をコンパクト化。カードの表示高さも縮小して縦方向の過密を解消。
※ 2026-02-24更新（11回目）: メール認証後の遷移を統一。`EmailVerificationPendingView` で `users/{uid}` のプロフィール入力状態（`birthDate` / `displayName`）を判定し、未完了時は `UserInfoView` へ遷移。`UserInfoView` 完了後は `TutorialView` を表示してから `MainNavigationView` へ遷移する導線に整理。
※ 2026-02-24更新（10回目）: `MissionsView` のコイン交換タブに表示する未訪問店舗一覧で `stores.isOwner=true` の店舗を除外。表示対象を `isActive=true` かつ `isApproved=true` かつ `isOwner!=true` の未訪問店舗に統一。
※ 2026-02-24更新（9回目）: `HomeView` の「今日のレコメンド」を刷新。おすすめ店舗の表示を1ページ1店舗の全幅カードに変更し、取得件数を5件へ調整。カード下部の円10個インジケータを廃止し、状態表示を「未訪問 / スタンプ X/10 / 満了」に統一。`PageView` を3秒間隔で自動送り（操作中は一時停止）するカルーセルに更新。
※ 2026-02-24更新（8回目）: `MapView` のマップ閲覧報酬カウントを1日1回に制限。Firestore `users/{uid}/daily_missions/{yyyy-MM-dd}.map_open` で日次制御し、同日にマップを複数回開いても報酬加算は初回のみ実行。
※ 2026-02-24更新（7回目）: `HomeView` 右下のミッションフローティングボタンを小型化（72x72）し、影を薄めに調整。受取可能時カラーをティール系から黄色系へ変更。`MissionsView` の達成状態カード・タブアクティブ色・報酬ポップアップも黄色基調に統一。
※ 2026-02-24更新（6回目）: `HomeView` のおすすめ店舗表示ロジックをフォールバック方式に更新。優先順は「未訪問（スタンプ0）」→「開拓中（スタンプ1〜9）」→「達成済み（スタンプ10以上）」で、上位カテゴリが空の場合に次カテゴリを表示。
※ 2026-02-24更新（5回目）: `HomeView` の統計カプセルバー（コイン/バッジ/スタンプ）を「おすすめ店舗」セクションの上へ移動。カプセルUIを白背景・強い丸角・左側の丸アイコン・「数値 + ラベル」表記のコンパクトデザインに更新（全体サイズ/テキスト/アイコンを小型化）。
※ 2026-02-24更新（4回目）: 新規登録後チュートリアル（`TutorialView`）を追加。新規登録後に初めてホーム画面に遷移したとき4枚スライドのチュートリアルを全画面表示（地図発見/スタンプ/コイン/バッジ）。`showTutorial` フラグ（Firestore `users/{uid}.showTutorial`）で初回1回のみ表示。`MainNavigationView` の `_maybeShowDailyRecommendation()` でチュートリアルを最優先表示し、完了後にレコメンドへ流れる順序を維持。
※ 2026-02-24更新（3回目）: 不定休（`isRegularHoliday=true`）の店舗における営業日表示を改善。`StoreDetailView` の7日間スケジュールで、scheduleOverrides（type='open'）がない日は「定休日」表示に統一（従来の「不定休です。営業日は各自ご確認ください。」メッセージを廃止）。type='open' override がある日は「通常営業 HH:mm〜HH:mm」として表示（「臨時営業」ラベルを使わない）。同様に14日バナー・ステータスチップも対応。`MapView` の `_getTodayHours()` で不定休かつ override なしの場合の表示を「不定休」→「定休日」に変更。
※ 2026-02-24更新（2回目）: `StoreDetailView` の営業時間セクションを週別日付表示に変更（今日〜6日後の7日間を `2/24(火)` 形式で表示、scheduleOverrides優先）。`MapView` の店舗吹き出しに今日の具体的な営業時間を表示（臨時休業/時間変更を反映）。`_isStoreOpenNow()` が scheduleOverrides・isRegularHoliday を考慮するよう修正し、「営業中のみ」フィルターにも反映。
※ 2026-02-24更新: 未ログイン起動時の導線を `WelcomeView` 起点に変更。ウェルカム画面に「ログインせずに開始」を追加し、3ボタン（新規登録/ログイン/ログインせずに開始）で遷移できるように更新。
※ 2026-02-24更新: スプラッシュスクリーン（ネイティブ）を追加。`flutter_native_splash` パッケージで背景色 `#FBF6F2` + 中央にGrouMapロゴを表示。Firebase初期化完了までスプラッシュを保持し、完了後に解除。
※ 2026-02-28更新（4回目）: ホーム画面・ミッション画面のアイコン刷新。ホーム画面の統計カプセルバー（コイン/バッジ/スタンプ）・メニューグリッド（スタンプ/バッジ/店舗一覧/クーポン）の5種アイコンをGrouMapブランドカラー（ゴールド/オレンジ系）の新デザインに刷新。Python PILで透明背景PNGを生成して既存ファイルを上書き（`assets/images/icon_coin.png` 等）。ミッション画面（`MissionsView`）の`Icons.monetization_on`を`Image.asset('assets/images/icon_coin.png')`に統一（コイン獲得ポップアップ/所持コイン表示/ミッションカード報酬表示/コイン交換ダイアログの計6箇所）。
※ 2026-02-28更新（3回目）: `PointPaymentDetailView`（スタンプ押印画面）のスタンプアニメーション計算を修正。`stampsAfter % _maxStamps`（サイクル内の位置）で `punchIndex` を算出するよう変更し、10の倍数到達時（カード完了瞬間）は `_maxStamps - 1`（index 9）を使うよう修正。これにより11枚目・21枚目など各カード開始直後の最初のスタンプではなく、最後のスタンプ（10枚目）が正しくアニメーションするようになった。また `StampCardWidget` に `completedCards` パラメータを渡す計算も修正（コンプリートは10の倍数到達の瞬間のみ）。
※ 2026-02-28更新（2回目）: `CouponDetailView` の「使用する」ボタンを廃止。クーポンの直接使用機能を削除し、店舗用アプリからのQRスキャン時にのみクーポンが適用される仕組みに変更。不正利用防止のため。画面下部に「クーポンのご利用方法」3ステップガイド（①店舗に伝える→②QR提示→③店舗がスキャン）と注意事項を新設。
※ 2026-02-28更新: `CommonHeader` のデフォルト背景色をオレンジ（`AppUi.primary` = `#FF6B35`）からアプリ標準背景色（`AppUi.surface` = `#FBF6F2`）に変更し、デフォルト文字色を白から黒（`Colors.black`）に変更。これにより全画面の `CommonHeader` が一括してベージュ背景・黒テキストに統一され、各画面に書かれていた明示的なオレンジ背景・白テキスト指定を一括削除。上部タブ（`CustomTopTabBar`）の配色もオレンジ背景+白文字から画面背景色（`#FBF6F2`）+黒文字+黒インジケーターに変更。
※ 2026-02-23更新: ユーザー用アプリ全画面のUI基盤を統一（共通ThemeData導入、`AppBar` を `CommonHeader` に統一、標準背景色を `#FBF6F2` に統一、共通ボタン/入力/トグル/上部タブのスタイルを統一）。
※ 2026-02-20更新: `MissionsView` の新規登録ミッション「スロット初挑戦」を「スタンプ初獲得」に変更。新規登録ミッション未完了時はデイリー/ログインタブを非活性化し、新規登録タブにガイドメッセージバナーを表示。
※ 2026-02-20更新: スロットキャンペーンボタンを廃止（コードはコメントアウトで保持）。
※ 2026-02-20更新: `UserInfoView` を簡略化（生年月日+性別のみ、都道府県・市区町村・プロフィール画像を削除）。`ProfileView` にプロフィール完成度カード（9項目ベース・100%未満時のみ表示）を追加、プロフィール未完成時は「プロフィール編集」メニューを非表示化。
※ 2026-02-23更新: `MapView` / `StoreListView` / `HomeView` / `DailyRecommendationView` のisOwner店舗除外を簡潔化。`stores.isOwner` フラグのみで判定（`users` コレクションのクロス参照を廃止）。Cloud Functions `setStoreOwnerFlagOnCreate` で店舗作成時に自動フラグ設定。
※ 2026-02-23更新: 法務画面（`TermsView` / `Legal/PrivacyPolicyView`）を最新規約Markdownに同期。サポート内の `TermsOfServiceView` / `Support/PrivacyPolicyView` は法務画面の共通表示を参照する構成に統一。問い合わせ先を `info@groumapapp.com` / `080-6050-7194（平日 11:00-18:00）` に統一。
※ 2026-02-20更新: `MapView` / `StoreListView` の表示対象店舗条件を整理。`isActive=true` かつ `isApproved=true` の店舗のみ表示。
※ 2026-02-19更新: スタンプカード表示を共通ウィジェット（`StampCardWidget`）に統一。スタンプ押印画面・スタンプカード一覧・店舗詳細画面で同一のスタンプカードUIを使用。スタンプ画像取得中はカード中心にローディングインジケーター表示。プログレスバー（ゲージ）を削除。
※ 2026-02-19更新: 投稿画面の追加読み込みを自動スクロールからボタン式に変更、取得件数を51件ずつ最大306件に変更、画像なし投稿のフィルタリング追加。
※ 2026-02-19更新: ホーム画面のミッションフローティングボタンに受取可能ミッション判定を追加（受取可能ミッションがない場合はグレーアウト表示）。
※ 2026-02-23更新: `AppInfoView` を新規追加（アプリ情報・開発者情報・法的リンク・公式アカウント）。`ProfileView` のサポートセクションに「アプリについて」メニューを追加。`HelpView` からアプリ情報セクションを削除（専用画面に移設）。
※ 2026-02-23更新: 興味カテゴリを `ProfileEditView` から分離し `InterestCategoryView` を新規作成。`ProfileView` のプロフィール完成度カードを2段階化（基本プロフィール8項目完成→興味カテゴリ設定→100%完了）。設定リストに「興味カテゴリ設定」メニューを追加。
※ 2026-02-22更新: `BadgesView` でFirestoreから取得済みバッジを取得し、全バッジ定義を表示しつつ未取得バッジは画像を「？」アイコン・名前を「？？？」に置換。詳細ダイアログも取得済み/未取得で表示を分岐。
※ 2026-02-18更新: `BadgesView` の上部カテゴリ一覧を廃止し、ヘッダー右上フィルターに統一。ロック/アンロック表示と詳細ポップアップ内のロック操作UIを削除。
※ 2026-02-10更新: `StoreDetailView` のトップタブにクーポン一覧と投稿プレビュー（新着15件）を追加し、投稿の「全て見る＞」で上部タブ「投稿」へ遷移する導線を追加。`CouponsView` のクーポンリストカードUIを共通化し、`StoreListView` のヘッダーを `CommonHeader` + `CustomTopTabBar` 構成へ統一。
※ 2026-02-08更新: ユーザー用画面の遷移元差分を解消（`StoreListView` / `MapView` / `DailyRecommendationView` から `StoreDetailView` へ渡す店舗データを正規化）。

## 起動・ナビゲーション

### MainNavigationView (`lib/views/main_navigation_view.dart`)
- 構成: ボトムタブ3つ（マップ / 図鑑 / アカウント）、FABなし、Deep Link受信（NFCチェックイン用）
- 説明: アプリ全体のタブ切替と初期データ読込を担うメインナビゲーション。3タブ構成（マップ=index0・起動時のデフォルト / 図鑑=index1 / アカウント=index2）。QR FABは廃止しアカウント画面内のフォールバックボタンに移設。バッジ獲得ポップアップの協調制御を一元管理（本日初ログイン時: レコメンドポップアップ→2秒→バッジポップアップ、2回目以降: 2秒後にバッジポップアップ）。`DeepLinkService`（`app_links`パッケージ）でNFCタグURL（`groumapapp.web.app/checkin?storeId=xxx&secret=yyy`）のDeep Linkをコールドスタート/ウォームスタートの両方で受信し、`NfcCouponSelectView`に遷移。同一リンクは `storeId:secret` をキーに5秒間の重複抑止を行い、チェックイン画面表示中は同一キーの再pushを無効化して二重遷移を防止

## 認証・登録

### WelcomeView (`lib/views/auth/welcome_view.dart`)
- 構成: ロゴ画像（`splash_logo`）/サービス名/キャッチフレーズ、新規アカウント登録ボタン、ログインボタン、ログインせずに開始ボタン（青字・太字のテキストボタン）、補助文言（「一部機能はログインが必要です」）、フッター
- 説明: 未ログイン時の起動導線となるウェルカム画面。認証あり/なしを選択して先に進める

### SignInView (`lib/views/auth/sign_in_view.dart`)
- 構成: AppBar、Apple/Googleサインイン、メール/パスワード入力、ログインボタン、パスワード再設定導線
- 説明: 既存ユーザーのログイン画面

### TermsPrivacyConsentView (`lib/views/auth/terms_privacy_consent_view.dart`)
- 構成: イントロ説明、白枠カード（利用規約/プライバシーポリシー）×2、各カード内の青色「確認する（必須）」ボタン、各カードの同意状態表示（未同意/同意済み）、下部固定「同意して次へ」ボタン（2項目同意済み時のみ有効）
- 説明: 登録前の規約同意画面。各「確認する（必須）」から文書画面を開き、最下部までスクロール後に有効化される「同意する」を押して戻ると該当カードが同意済みに切り替わる。同意済みカードの確認ボタンはグレーアウトされる

### SignUpView (`lib/views/auth/sign_up_view.dart`)
- 構成: AppBar、Apple/Googleサインアップ、メール/パスワード/確認入力、登録ボタン
- 説明: 新規アカウント作成画面

### EmailVerificationPendingView (`lib/views/auth/email_verification_pending_view.dart`)
- 構成: 認証案内、注意事項、6桁コード入力、認証/再送ボタン
- 説明: メール認証コード入力・再送画面。認証成功後は `goToUserInfoAfterVerify` フラグに加えて Firestore `users/{uid}` のプロフィール入力状態を判定し、未入力項目がある場合は `UserInfoView`、入力済みなら `MainNavigationView` へ遷移

### UserInfoView (`lib/views/auth/user_info_view.dart`)
- 構成: ヘッダー（戻るボタン非表示）、ユーザー名入力（メール/Apple登録時のみ）、生年月日選択（年/月/日ドロップダウン）、性別選択（4択ドロップダウン）、友達紹介コード入力欄（キャンペーン期間中のみ常時表示・任意入力）、送信ボタン
- 説明: 初回登録時のユーザー情報入力画面（簡略化済み：都道府県・市区町村・プロフィール画像は後からプロフィール編集で入力）。友達紹介キャンペーン期間中は紹介コード入力欄を常時表示（折りたたみ不要）。紹介コードが入力された場合は Firestore に `friendCode` として保存し、Cloud Functions `processFriendReferral` が自動処理。さらに紹介コード入力者に対してウェルカムお知らせ（`users/{uid}/notifications`・`type: social`・`tags: ['referral', 'welcome']`）を自動作成し、紹介者名・双方コイン数・スタンプ獲得手順を通知する。入力完了後は `TutorialView` を表示してから `MainNavigationView` に遷移

### AccountDeletionReasonView (`lib/views/auth/account_deletion_views.dart`)
- 構成: 共通ヘッダー、警告メッセージカード、退会理由入力欄（6行）、バリデーションメッセージ（10文字以上必須）、送信ボタン、キャンセルボタン
- 説明: 退会理由を入力して送信する画面。送信成功後に `AccountDeletionProcessingView` へ遷移

### AccountDeletionProcessingView (`lib/views/auth/account_deletion_views.dart`)
- 構成: 共通ヘッダー、進行中メッセージ、ローディング表示
- 説明: 退会処理中の進捗画面

### AccountDeletionCompleteView (`lib/views/auth/account_deletion_views.dart`)
- 構成: 完了アイコン、完了メッセージ、ログインへボタン
- 説明: 退会処理完了画面

## チュートリアル

### TutorialView (`lib/views/tutorial/tutorial_view.dart`)
- 構成: 全画面スライド4枚（PageView）、左上 × スキップボタン、下部ドットインジケーター（アクティブ時は横長・オレンジ）、右下 → 次へボタン（最終スライドは「はじめる」オレンジボタン）。スライド: ①地図発見 / ②スタンプ収集 / ③コイン獲得 / ④バッジコレクション。各スライドはイラスト画像（`assets/images/tutorial_1〜4.png`）＋タイトル（太字22px）＋説明文（14px）で構成。完了・スキップ時に Firestore `users/{uid}.showTutorial = false, walkthroughCompleted = false` を更新（ウォークスルー未完了を明示）
- 説明: 新規登録後に初回のみ表示するオンボーディングチュートリアル画面。基本導線は `UserInfoView` 完了直後に `MaterialPageRoute`（fullscreenDialog）で表示し、保険として `MainNavigationView` 側でも `showTutorial == true` 時に表示可能。セッション内重複防止のための `static bool _tutorialShown` フラグあり。完了後はインタラクティブウォークスルー（WalkthroughOverlay）が自動開始される

## ウォークスルー（インタラクティブガイド）

### WalkthroughOverlay (`lib/views/walkthrough/walkthrough_overlay.dart`)
- 構成: グレーアウトオーバーレイ（`Colors.black.withOpacity(0.6)`）＋操作対象を穴あきハイライト表示（`CustomPaint` + `Path.combine(PathOperation.difference)`）、白文字説明テキスト（太字・サブテキスト付き）、右上「スキップ」テキストボタン、ハイライト枠のパルスアニメーション
- パラメータ: `targetKey`（GlobalKey）/ `targetRect`（Rect直接指定）/ `message`（説明テキスト）/ `subMessage`（補足テキスト）/ `onSkip`（スキップ時コールバック）/ `allowTapThrough`（ハイライト部分のタップ透過）/ `messagePosition`（テキスト位置: top/center/aboveTarget）/ `requiresAction`（ユーザー操作が必要か。falseなら「次へ」ボタン表示）/ `onNext`（次へボタンコールバック）/ `showConceptLayout`（コンセプト画面レイアウトを表示するか）
- フルスクリーンモード: `requiresAction=false` かつターゲットなしの場合、画面全体を暗黒背景で覆い中央にメッセージ＋「次へ」ボタンを表示。`showConceptLayout=true` の場合は3アイコン説明レイアウト（マップで未発見の店を探す→NFCタッチで図鑑GET→コレクション達成）を表示
- 説明: チュートリアル4ページ完了後に自動開始される6ステップのインタラクティブウォークスルー。各画面（MainNavigationView/MapView）のStackに配置。ウォークスルー開始セッション中（`_walkthroughStarted = true`）は「今日のレコメンド」ポップアップとバッジ獲得ポップアップを非表示にする（ウォークスルー完了済みユーザーは従来通り表示）

### WalkthroughProvider (`lib/providers/walkthrough_provider.dart`)
- 説明: ウォークスルーの状態管理。`WalkthroughStep` enum（none/concept/tapMapTab/tapMarker/learnNfcTouch/tapZukanTab/tapProfileTab）、`WalkthroughState`（step/isActive/userId）、`WalkthroughNotifier`（startWalkthrough/nextStep/completeWalkthrough/skipWalkthrough/resetState）を提供。完了・スキップ時に Firestore `users/{uid}.walkthroughCompleted = true` を更新。`tapProfileTab` 完了時は `completeWalkthrough()` を呼び出してウォークスルーを終了

### ウォークスルーフロー（6ステップ）

| # | ステップ | 形式 | テキスト | サブテキスト | ユーザー操作 |
|---|---------|------|---------|------------|-----------|
| 0 | concept | フルスクリーン（3アイコン） | 街を舞台にした探検ゲームへようこそ。 | ただし、実際に行かないと進まない。 | 「はじめる」ボタン |
| 1 | tapMapTab | タブハイライト | マップを開いてみよう！ | グレーのマーカーが"まだ誰も発見していない"お店です | マップタブをタップ |
| 2 | tapMarker | マップオーバーレイ | 気になるお店をタップしてみよう！ | ★の数がレア度。少ない発見者数ほどレアなお店です | 店舗マーカーをタップ |
| 3 | learnNfcTouch | フルスクリーン | 実際のお店でNFCタッチしてみよう！ | レジ近くのスタンドにスマホをかざすと図鑑カードが発見できます。何のレア度が出るかはお楽しみ✦ | 「次へ」ボタン |
| 4 | tapZukanTab | タブハイライト | 図鑑タブを開いてみよう！ | ？？？のシルエットは、まだ行っていないお店。コンプリートを目指そう！ | 図鑑タブをタップ |
| 5 | tapProfileTab | タブハイライト | アカウントタブもチェック！ | バッジ・ランキング・毎月の探検レポートが見られます | アカウントタブをタップ → 完了 |

## ホーム・メインタブ

### HomeView (`lib/views/home_view.dart`)
- 構成: ログアウト時のみログイン/新規登録カード、統計カプセルバー（コイン・バッジ・スタンプの保有数を「おすすめ店舗」セクションの上に横並びで表示。白背景・丸角・カスタム画像アイコン（`assets/images/icon_coin.png` / `icon_badge.png` / `icon_stamp.png`・20×20・透明背景PNG）付きのコンパクトカプセルで「数値 + ラベル」を表示。値はFirestoreリアルタイム取得、コイン有効期限をカプセル下に表示、期限切れ時は赤文字）、`今日のレコメンド` セクション（見出しは「クーポン」「投稿」と同一サイズ。候補優先順は未訪問（スタンプ0）→開拓中（スタンプ1〜9）→達成済み（スタンプ10以上）のフォールバック。最大5件を取得し、1ページ1店舗の全幅カードで表示。3秒ごとに次ページへ自動送りし、ユーザー操作中は一時停止。カード上部は店舗画像、下部はコンパクト化したテキストで「未訪問 / スタンプ X/10 / 満了」の状態バッジ＋カテゴリ、店舗名、左下に「現在地から 距離」を表示。距離未取得時は `--` を表示。タップで店舗詳細へ遷移）、メニューグリッド（スタンプ・バッジ・店舗一覧・クーポンの4項目を、独立した白い円形ボタンで横一列に表示。各円形内に背景透過したオレンジ系カスタム画像アイコン（`icon_stamp.png` / `icon_badge.png` / `icon_store.png` / `icon_coupon.png`・30×30）を配置し、下部ラベルは濃いグレーで表示。各項目タップで対応画面へ遷移）、コイン交換カプセルボタン（ログインユーザーかつ10コイン以上保有時のみ表示・おすすめ店舗セクション直下に横幅いっぱいのオレンジグラデーション丸角ボタンで配置・コインアイコン+「コインをクーポンに交換しよう！」+矢印・タップで `MissionsView(showCoinExchange: true)` に遷移）、スロットキャンペーンボタン（※廃止・コードはコメントアウトで保持）、ニュースセクション（掲載期間内・画像のみ1:1横スクロール・最大7件）、特別クーポンセクション（コイン交換クーポン＋スタンプカード達成クーポン（`stamp_reward`）を合わせて横スクロールカードで表示・1枚以上ある場合のみ表示・ヘッダーに枚数バッジ付き・タップでクーポン詳細へ遷移）、クーポン/投稿セクション（Instagram投稿と通常投稿を日付順で混合表示・最大10件・タイトル非表示・テキスト2行表示・Instagram投稿は「Instagram」バッジ（ピンク）、通常投稿は店舗ジャンルバッジ（オレンジ）を表示）、各詳細への導線、ミッションフローティングボタン（ログインユーザーのみ・右下・72x72の小型ボタン・受取可能ミッションがある場合は黄色系グラデーション・ない場合はグレーアウト表示・ミッション画面へ遷移・ミッション画面から戻った時に状態を再判定）
- 説明: 主要情報と、ユーザーのスタンプ進捗に応じたおすすめ店舗レコメンドを集約したダッシュボード

### MapView (`lib/views/map/map_view.dart`)
- 構成: GoogleMap（ダークブルー系ゲームスタイル・現在地ボタンはカスタム実装）、店舗マーカー、検索アイコンボタン（左上・折りたたみ式。ダーク背景＋シアンボーダー）＋フィルターボタン（右上・ダーク背景＋シアンボーダー）、**モードタブ（`CompactToggleBar`）**（検索バー直下・常時表示。「通常」/「個人」/「コミュニティ」の3択・`_mapMode` 文字列で状態管理）、コミュニティサブモードトグル（コミュニティ選択時のみ。「開拓率」/「賑わい度」の2択トグル）、**プレイヤー統計サークル**（右側固定・現在地/北向きボタン下に縦並び。発見数（青）/バッジ数（紫）/ランキング順位（黄）の3つの丸ボタン。各サークルタップで `showGameDialog` による説明＋現在値ポップアップを表示）、店舗情報パネル（ゲーム風）、コントロールボタン（ダーク背景＋シアンボーダー）
- **マップスタイル**: ダークブルー系ゲームスタイル（`#0d1b2a` ベース・水系 `#0a2030`・道路 `#1a3a52`・POI非表示・テキストはシアン系 `#8ec3b9`）。旧: POI非表示のみのデフォルトスタイル
- 通常モード: 店舗のアイコン画像（またはカテゴリアイコン）を白丸ピンに表示。ピンアクセント色（ボーダー＋尾）が営業中=緑グラデーション（`#81C784`→`#43A047`→`#2E7D32`・`isGreenPin`）・営業時間外=グレーグラデーション（`#EEEEEE`→`#BDBDBD`→`#9E9E9E`・`isGrayPin`）で色分けされる。左上に凡例カード（緑丸=営業中・グレー丸=営業時間外）を小さく表示（`_mapMode == 'normal'`）
- 個人モード: ピン中心に常に店舗アイコン画像（画像なし時はカテゴリアイコン・グレー）を表示。ピンアクセント色（ボーダー＋尾）を `users/{uid}/stores/{storeId}.totalVisits` に応じて5段階で変化（0件=グレーグラデーション `isGrayPin` / 1件=ライトブルー `#29B6F6` / 2〜4件=グリーン `#66BB6A` / 5〜9件=オレンジ `#FB8C00` / 10件〜=ゴールドグラデーション `#FFF9C4`→`#FFD700`→`#B8860B`）。モードトグルで「個人」選択時に切り替え（`_mapMode == 'personal'`）
- コミュニティモード: サブモード「開拓率」ではエリアCircleオーバーレイ（`_areaCircles`）を表示。サブモード「賑わい度」では `stores.totalVisitCount` に応じた5段階Circleオーバーレイ（1〜10件=ライトブルー半径40m / 11〜30件=グリーン60m / 31〜100件=オレンジ80m / 101件〜=ゴールド100m）を表示（`_mapMode == 'community'`）
- 開拓状況表示: フィルター設定の「マップ表示設定 > 開拓状況表示」ONで、ピンのボーダー＋尾の色が開拓済み（スタンプ1以上）=青 `#2196F3`、未開拓=グレー `#BDBDBD` に切り替わる（`MapFilterModel.pioneerMode`）
- ジャンル別表示: フィルター設定の「マップ表示設定 > ジャンル別表示」ONで、カテゴリアイコンでマーカーを表示（`MapFilterModel.categoryMode`）
- 近接自動フォーカス: Geolocator位置ストリーム（5m移動ごと更新）で継続的に現在地を監視。店舗の半径50m以内に入ると自動でピンを拡大・店舗情報パネルを表示し、`HapticFeedback.mediumImpact()`で軽くバイブレーション。100m以上離れるとリセット（再来接近で再発火）。一度に1店舗のみフォーカス。
- **ピンアニメーション**: ①ふわふわ: `_pinFloatController`（2.5秒・`repeat(reverse: true)`）で `easeInOut`＋sin波を用いて `anchor.dy` を揺動（1.0〜1.12）。②スピン: `_pinSpinTimer`（5秒ごと）→ `_pinSpinController`（0.7秒）で `rotation` を 0→360度に回転。`_getAnimatedMarkers()` が `Marker.copyWith` で毎フレーム軽量更新。ピンサイズは通常時 58・拡大時 116（dp）
- **レーダーアニメーション**: `TickerProviderStateMixin` + `AnimationController`（2秒ループ）で現在地を中心に3つの同心円（位相ずらし）が20m→200mに拡大しながらフェードアウト。`_buildRadarCircles()` で Google Maps `Circle` として描画し `_getActiveCircles()` に統合
- **マーカータップ**: ピンをタップ時に `HapticFeedback.mediumImpact()` でバイブレーション。`getScreenCoordinate()` でスクリーン座標を取得し、オレンジ選択リングが拡大フェードするアニメーション（`_selectionRingController` 500ms）を表示
- **店舗情報パネル（ゲーム風）**: 半透明ダーク背景（`#101E2E` 90%不透明）＋シアン発光ボーダー（`#00E5FF`）。画像上にグラジエントオーバーレイ・左上ジャンルバッジ・右上営業状況バッジ（ドット付き）。来店ステータスバッジ（未発見/初発見/探索中/常連/レジェンド）を店舗名横に表示。スタンプ数・今日の営業時間を表示。詳細ボタンはオレンジグラジェント（`#FF6B35`→`#FF8C42`）。閉じるボタンはダーク円形＋シアンボーダー
- 説明: 周辺店舗をゲーム感覚で探す画面。`isActive=true` かつ `isApproved=true` の店舗のみ表示し、`stores.isOwner=true` の店舗は表示しない。フィルターボタンから詳細フィルター設定画面へ遷移可能。営業中判定（scheduleOverrides・isRegularHolidayを考慮した複数時間帯対応）はピン色（通常モード）に反映される。マップ閲覧報酬（`mapOpened`）は `daily_missions/{date}.map_open` で1日1回のみカウントする。プレイヤー統計（`discoveredStoreCount`/`badgeCount`/ランキング順位）は `users/{uid}` から読み込み右側スタットサークルに表示。各サークルタップで `showGameDialog` によるポップアップ（説明文＋現在値）を表示

### AreaExplorationView (`lib/views/area/area_exploration_view.dart`)
- 構成: CommonHeader（「エリア開拓率」）、トグルボタン（「マイ開拓率」/「みんなの開拓率」・選択時オレンジ背景・非選択時白背景・シャドウ付き）、エリアカードリスト（`areaExplorationRateProvider` から取得。各カード: エリアカラーの丸ドット+エリア名+パーセント表示（エリアカラー・太字20px）、LinearProgressIndicator（エリアカラー）、「訪問数 / 全店舗数 店舗」テキスト、エリア説明テキスト（末尾省略））
- 説明: エリア別の開拓率を一覧表示する画面。「マイ開拓率」は自分がNFCチェックイン済みの店舗数÷エリア内総店舗数、「みんなの開拓率」は `discoveredCount >= 1`（1人以上が来店した）店舗数÷エリア内総店舗数を表示。`areasProvider`（`areas`コレクション `isActive=true` / `order`昇順）・`zukanAllStoresProvider`（全店舗）・`userVisitedStoreIdsProvider`（自分の訪問済み店舗ID）の3つのプロバイダーを組み合わせて計算する

### FilterSettingsView (`lib/views/map/filter_settings_view.dart`)
- 構成: CommonHeader、各フィルターセクション（**マップ表示設定**/ジャンル/開拓状態/お気に入り/決済方法/クーポン/距離）、リセット＋保存ボタン
- マップ表示設定セクション: 「ジャンル別表示」（カテゴリアイコン表示ON/OFF）・「開拓状況表示」（来店状況アイコン表示ON/OFF）の2つのトグル。相互排他で片方をONにするともう片方は自動OFF。設定は `MapFilterModel.categoryMode` / `MapFilterModel.pioneerMode` に保存
- 説明: マップ表示のフィルター条件・表示モード設定画面。設定はFirestore（users/{userId}/map_filter/settings）に保存

### PostsView (`lib/views/posts/posts_view.dart`)
- 構成: 投稿グリッド（3列）、空/エラー/読み込み状態（`public_instagram_posts` と `public_posts` の統一フィードを日付降順で取得し、画像なし投稿は除外・51件ずつボタン式追加読込・最大306件表示・1店舗あたり最大51件）、グリッド下部に青テキスト「さらに表示する」ボタン（追加データありの場合のみ表示）
- 説明: 投稿の一覧をグリッド形式で閲覧する画面

### PostDetailView (`lib/views/posts/post_detail_view.dart`)
- 構成: 画像カルーセル、店舗アイコン画像+店舗名+投稿日付、タイトル/本文、Instagram投稿時は本文下部に青テキスト「Instagramを開く」ボタン（タップで外部ブラウザ/Instagramアプリに遷移）、いいね、コメント一覧/入力
- 説明: 投稿の詳細表示・反応/コメント画面（店舗アイコンはFirestoreから取得、Instagram投稿の場合タイトルが店舗名と同一なら非表示、Instagram投稿・通常投稿の両方でいいね・コメント・閲覧記録に対応、Instagram投稿はpermalinkフィールドで元投稿にリンク）

### NewsDetailView (`lib/views/news/news_detail_view.dart`)
- 構成: CommonHeader、ニュース画像（1:1）、タイトル、掲載期間、本文
- 説明: ニュース詳細表示画面

### CouponsView (`lib/views/coupons/coupons_view.dart`)
- 構成: タブ（利用可能/使用済み）、クーポンリスト（共通 `CouponListCard` を使用、無制限クーポンの場合は残り枚数非表示）
- 説明: クーポン一覧（状態別）画面

### CouponDetailView (`lib/views/coupons/coupon_detail_view.dart`)
- 構成: ヘッダー画像、クーポン概要、期限/割引/必要スタンプ（`stamp_reward` の場合は「スタンプカード達成で獲得したクーポンです」達成バッジに置換）、残り枚数（無制限クーポンの場合は非表示）、店舗情報、「クーポンのご利用方法」セクション（3ステップガイド: ①店舗スタッフにクーポン利用を伝える→②QRコード画面を提示→③店舗スタッフがスキャンしてクーポン適用）、注意事項（不正利用防止のため店舗側スキャン時のみ適用される旨）
- 説明: クーポンの詳細表示画面。クーポンの直接使用ボタンは廃止し、店舗用アプリからのQRスキャン時にのみクーポンが適用される仕組み（対象外店舗での不正利用防止のため）。`stamp_reward` は閲覧数インクリメントをスキップ

### StoreListView (`lib/views/stores/store_list_view.dart`)
- 構成: `CommonHeader` + 上部タブ（お気に入り/フォロー/店舗一覧）、店舗カードリスト
- 説明: 店舗の一覧・お気に入り・フォロー中店舗の表示。`isActive=true` かつ `isApproved=true` の店舗のみ表示し、`stores.isOwner=true` の店舗は表示しない。フォロータブはユーザーの `followedStoreIds` でフィルタ

### StoreDetailView (`lib/views/stores/store_detail_view.dart`)
- 構成: 上部ヘッダー（店舗イメージ画像 + 左下重ねアイコン + 店舗基本情報: 店名/お気に入り/フォロー/営業状態/カテゴリ/住所/営業時間/店舗説明）、上部タブ固定表示（トップ/店内/メニュー/投稿）、共通スタンプカード（`StampCardWidget`・画像取得中はカード中心にインジケーター表示）、トップタブはクーポン一覧（利用可能のみ）と投稿プレビュー（新着15件・3列グリッド）を表示、投稿グリッド下部の「全て見る＞」ボタンで上部タブ「投稿」へ遷移、投稿タブはInstagram投稿と通常投稿を混合表示（動画除外・最大51件・日付降順）、利用可能な決済方法をカテゴリ別にChip表示（現金/カード/電子マネー/QR決済）、座席数セクション（テキスト直書き「、」区切り、データ未設定時は非表示）、設備・サービス情報セクション（アクセス情報・駐車場/テイクアウト/喫煙/Wi-Fi/バリアフリー/子連れ/ペットをChip表示（利用可能=オレンジ/不可=グレー色分け）、全項目常時表示）、SNS・ウェブサイトセクション（設定済みのサービスのみ円形アイコン（直径48px）を左から横並びで表示。左から順に: Web（地球儀・灰青色）/ X（黒）/ Instagram（ピンク #E1306C）/ Facebook（青 #1877F2）。タップで url_launcher が外部ブラウザ/アプリを起動。font_awesome_flutter の FontAwesomeIcons.globe / xTwitter / instagram / facebook を使用。未設定サービスは非表示）、メニュータブはPillTabBarでカテゴリ別フィルタ（コース/料理/ドリンク/デザート）・sortOrder順にリスト表示（画像あり時のみ左に60x60画像・メニュー名・オプショングループ情報（サイズ・温度等の選択肢と追加料金をグレー小文字で表示）・右端に青太字価格）・メニューが無いカテゴリは非活性
- 営業ステータス判定: `scheduleOverrides[今日]` → `isRegularHoliday`（不定休=定休日） → `businessHours[曜日]` の優先順で判定。臨時休業/通常営業（不定休時）/臨時営業/時間変更のステータスチップ表示に対応。複数時間帯（periods）にも対応し、いずれかの時間帯に該当すれば「営業中」と判定
- 営業時間セクション: 今日〜6日後の7日間を `2/24(火)` 形式の日付付きで表示（scheduleOverrides優先。臨時休業は「臨時」赤バッジ、時間変更は「変更」青バッジを右端に表示。今日の行はオレンジハイライト + 「今日」バッジ）。複数時間帯（periods）がある場合は「11:00〜14:00 / 17:00〜22:00」のように「/」区切りで表示。不定休（`isRegularHoliday=true`）の場合: type='open' override がある日は「通常営業 HH:mm〜HH:mm」（緑・バッジなし）、それ以外は「定休日」を表示（「不定休です。営業日は各自ご確認ください。」メッセージは廃止）
- 今後14日以内にスケジュール変更がある場合は営業時間セクション上部に黄色バナーで一覧表示（臨時休業/通常営業（不定休時）/臨時営業/時間変更ごとにアイコン付き）
- 説明: 店舗の詳細情報と関連コンテンツを表示

### QRGeneratorView (`lib/views/qr/qr_generator_view.dart`)
- 構成: QRトークン表示（JWTベース・60秒自動更新・残り秒数カウントダウン）、ユーザーアイコン＋名前、QRコード文字列コピー
- 説明: 自分のQRコードを提示する画面。画面表示時に輝度をMAXに設定し、他画面への遷移時に元の輝度に復元

## 通知・お知らせ

### NotificationsView (`lib/views/notifications/notifications_view.dart`)
- 構成: お知らせと通知を統合した単一リスト（ListTile形式）、未読/既読表示、空/エラー状態
- 説明: お知らせと個別通知を日時順で統合表示する一覧画面

### AnnouncementDetailView (`lib/views/notifications/announcement_detail_view.dart`)
- 構成: カテゴリ/優先度バッジ、タイトル、公開日時、本文
- 説明: お知らせ詳細画面

### NotificationDetailView (`lib/views/notifications/notification_detail_view.dart`)
- 構成: 種別バッジ、日時、タイトル、本文、画像
- 説明: 通知詳細画面

## ポイント・支払い

### PointsView (`lib/views/points/points_view.dart`)
- 構成: タブ（全て/利用履歴/獲得履歴）、履歴リスト
- 説明: ポイント履歴の一覧画面

### TransactionHistoryView (`lib/views/points/transaction_history_view.dart`)
- 構成: 取引リスト、詳細ダイアログ、スタンプ受取導線
- 説明: 取引履歴を時系列で表示

### PointUsageView (`lib/views/points/point_usage_view.dart`)
- 構成: 残高カード、店舗ID/ポイント数/理由入力、実行ボタン
- 説明: 手動でポイント利用を申請する画面

### PointUsageRequestView (`lib/views/points/point_usage_request_view.dart`)
- 構成: 入力プロンプト、ポイント入力UI、確定/キャンセル
- 説明: 店舗利用ポイントを入力して申請する画面

### PointUsageWaitingView (`lib/views/points/point_usage_waiting_view.dart`)
- 構成: 状態表示、待機メッセージ
- 説明: 店舗側の入力完了を待つ画面

### PointUsageApprovalView (`lib/views/points/point_usage_approval_view.dart`)
- 構成: 利用ポイント確認、承認/拒否ボタン
- 説明: 店舗側入力後のユーザー承認画面

### PointPaymentView (`lib/views/payment/point_payment_view.dart`)
- 構成: 金額入力パッド、残高表示、支払い確認ダイアログ
- 説明: ポイント支払いを実行する画面

### PointRequestConfirmationView (`lib/views/payment/point_request_confirmation_view.dart`)
- 構成: 店舗/金額/ポイントの確認表示、承認待ち/キャンセル
- 説明: ポイント付与リクエストの確認画面

### PointPaymentDetailView (`lib/views/payment/point_payment_detail_view.dart`)
- 構成: 「スタンプ獲得」テキスト、共通スタンプカード（`StampCardWidget`・画像取得中はカード中心にインジケーター表示・押印アニメーション・コンプリートシャインエフェクト対応）、来店ボーナスバナー（+1コイン表示）、使用クーポン、未使用クーポンリスト、完了ボタン
- 説明: ポイント付与・スタンプ押印の結果表示画面。取引履歴からのスタンプ確認にも使用（スタンプカード下に来店ボーナス+1コインバナーを表示、その下に店舗の未使用クーポンをリスト表示）

### PaymentSuccessView (`lib/views/payment/payment_success_view.dart`)
- 構成: 成功メッセージ、店舗情報、支払い詳細、ホーム戻りボタン
- 説明: 支払い完了画面

## NFCチェックイン

### NfcCouponSelectView (`lib/views/checkin/nfc_coupon_select_view.dart`)
- 構成: CommonHeader（「お店を発見」・戻るボタン非表示）、店舗情報カード（アイコン+店舗名+「NFCタッチで発見」ラベル）、クーポン選択セクション（利用可能クーポンがある場合: タイトル「利用するクーポンを選択」+説明文+クーポンカードリスト（チェックボックス+アイコン+タイトル+割引額+取得元ラベル（スタンプ特典/コイン交換）+有効期限）、クーポンなしの場合: 「利用可能なクーポンはありません」+「このままお店を発見しましょう」メッセージ）、下部固定ボタン（選択クーポンありの場合: 「N件のクーポンを利用して発見する」カウント+「発見する」ボタン、選択なしの場合: 「クーポンを使わずに発見する」ボタン）
- パラメータ: `storeId`（店舗ID）/ `sessionToken`（チェックインセッショントークン・10分有効）
- 説明: NFCタグURL Deep Link → `MainNavigationView` が `createCheckinSession` でセッションを発行してから遷移するクーポン選択画面。`user_coupons` コレクションから当該店舗の未使用・有効期限内クーポンを取得し、発見と同時に利用するクーポンを複数選択可能。発見実行時はまず `geolocator` で現在地を取得（権限拒否時は `showGameDialog` でエラー表示しチェックイン不可）し、`NfcCheckinService.checkin()` にセッショントークン＋現在地を渡して呼び出す。成功後 `NfcCheckinResultView` に `pushReplacement` で遷移。`FirebaseFunctionsException` のエラーコード（`already-exists`=本日発見済み / `not-found`=無効セッション / `permission-denied`（距離超過）=「店舗から200m以内でチェックインしてください」 / `permission-denied`（その他）=利用不可 / `deadline-exceeded`=セッション期限切れ（再NFCタッチ案内） / `unauthenticated`=未ログイン）に応じたエラーメッセージを `showGameDialog` で表示

### NfcCheckinResultView (`lib/views/checkin/nfc_checkin_result_view.dart`)
- 構成: CommonHeader（「チェックイン完了」・戻るボタン非表示）、成功アイコン（緑チェック）+「チェックイン成功！」タイトル+店舗名、クーポン利用確認セクション（使用クーポンがある場合のみ: 緑枠カード+「クーポン利用済み」ヘッダー+使用クーポン一覧+6桁確認コード（モノスペース28px）+リアルタイム時計（日付+秒単位更新）+「この画面をスタッフにお見せください」案内）、共通スタンプカード（`StampCardWidget`・押印アニメーション・カード完了時シャインエフェクト、`stampsAfter >= 1` の場合のみ表示）、獲得クーポンセクション（`awardedCoupons` がある場合のみ・オレンジ丸角Chip表示）、利用可能クーポンセクション（店舗の `coupons` サブコレクションから取得・必要スタンプ未達のクーポンは「あとNスタンプ」オーバーレイ表示）、下部固定ボタン（「カードを見る」プライマリボタン + 「ホームに戻る」テキストボタン）
- パラメータ: `result`（`NfcCheckinResult`）/ `storeId`（店舗ID）/ `usedCoupons`（使用クーポン情報リスト）
- 説明: NFCチェックイン結果表示画面。クーポン利用時はスタッフ目視確認用の確認コード（Cloud Functions生成の6桁コード）とリアルタイム時計（1秒間隔更新）を表示し、スクリーンショット不正対策。スタンプカードの押印アニメーション・コンプリートシャインエフェクトは `stampsAfter >= 1` の既存スタンプ保有者のみ表示。`stampsAfter == 0` の場合（新規ユーザー）は店舗詳細取得後に自動的に `ZukanCardView` へ `pushReplacement` で遷移。「カードを見る」ボタンタップでも `ZukanCardView` に遷移

### DeepLinkService (`lib/services/deep_link_service.dart`)
- 説明: `app_links` パッケージを使用したDeep Linkサービス。NFCタグに書き込まれたURL（`https://groumapapp.web.app/checkin?storeId=xxx&secret=yyy`）をUniversal Links（iOS）/ App Links（Android）経由で受信。正規ホストは `groumapapp.web.app`、旧ホスト `groumap-ea452.web.app` は互換期間のみ受理。`/checkin` パスのみを受理し、`storeId` と `secret` が揃う場合だけ `CheckinDeepLink` を生成。手動フォールバック用に `groumap://checkin?...` のパースも維持。`getInitialCheckinLink()`（コールドスタート）と `listenCheckinLinks()`（ウォームスタート）の2系統で対応

### NfcCheckinService (`lib/services/nfc_checkin_service.dart`)
- 説明: Cloud Functions `nfcCheckin` を呼び出すサービス。`storeId`・`tagSecret`・`selectedUserCouponIds`（任意）をパラメータとして送信し、`NfcCheckinResult`（`stampsAfter`/`cardCompleted`/`storeName`/`isFirstVisit`/`awardedCoupons`/`usedCoupons`/`usageVerificationCode`）を返す。`coinsAdded` はコインシステム廃止に伴い削除済み

## 図鑑

### ZukanView (`lib/views/zukan/zukan_view.dart`)
- 構成: CommonHeader（「図鑑」・戻るボタン非表示）、開拓サマリーバー（「発見済み X店舗 / 全Y店舗」+ LinearProgressIndicator）、5列フラットグリッド（`crossAxisCount: 5`・`childAspectRatio: 0.60`・カテゴリグループなし）
- 説明: 全登録店舗を図鑑スタイルで一覧表示するタブ画面。`zukanStoresProvider` から全店舗データと発見済みフラグを取得し、`zukanOrder`順（管理者設定の番号順）でフラット表示。発見済みカードは共通ウィジェット `ZukanCardFaceWidget` でポケモンカード風UIを描画: `LayoutBuilder` でカード幅に応じたフォントサイズ（`clamp` で小カード〜拡大表示まで対応）、上部に店舗名＋レア度星（レア度カラー＋Shadowグロー）、中央に左右余白付き1:1正方形画像（カテゴリカラー0.22ブレンドの白背景にフレーム感）、下部に説明テキスト。カード全体は角丸10・9色停止点シルバー×白グラデーション枠（星1〜3）またはゴールド×白グラデーション枠（星4）＋レア度グロー`boxShadow`。未発見カードはグレー単色枠（`grey.shade400`）＋グレー背景（`grey.shade200/300`）＋「?」マーク表示。発見済みカードタップで `showGeneralDialog`（スケール+フェードアニメーション）によるズームモーダルを表示し、240px幅の `ZukanCardFaceWidget` 拡大表示＋「店舗詳細を見る」ボタン（タップで `StoreDetailView` に遷移）。未発見カードタップで `showGameDialog`（「まだ未発見のお店です / お店に来店してNFCタッチすると、このカードを発見できます。」）を表示。フィルターチップ・ソートメニューは廃止

### ZukanCardView (`lib/views/zukan/zukan_card_view.dart`)
- 構成: 深い暗色背景（`Color(0xFF0A0A14)`）＋レア度カラーのRadialGradientグロー＋スパークル（`_CardBackgroundPainter`）、ヘッダーテキスト（初発見「発見！」/再訪問「再訪問」・レア度カラー＋発光Shadow・フェードイン）、カード本体（幅240・アスペクト比0.60、`ZukanCardFaceWidget`）、レア度星アイコン（`Icons.star` × 4）、レア度ラベルテキスト、発見者数テキスト（「あなたが最初の発見者です！」または「あなたがN人目の発見者です！」）、レア度カラーのLinearGradientグラデーションボタン（初回「図鑑に登録完了！」/再訪問「ホームに戻る」）
- パラメータ: `storeId`（店舗ID）/ `storeName`（店舗名）/ `isFirstVisit`（初来店フラグ）
- 説明: NFCチェックイン後の図鑑カード発見演出画面。3コントローラー構成（`_flipController` 700ms・`_glowController` 2秒ループ・`_textController` 500ms）。初来店（`isFirstVisit=true`）時は600ms遅延後にフリップアニメーション（`Matrix4.rotateY()`・パースペクティブ0.001）でカード裏面（`_CardBack`: シルバー×白9停止点グラデーション枠＋ダーク `#16213E` 背景＋「ぐるまっぷ」ロゴ＋🗺️＋同心円パターン）からカード表面（`_CardFront`）にめくれ、完了後にヘッダー・情報・ボタンがフェードイン。再訪時はカード表面を即表示しテキストのみフェードイン。カード表面（`_CardFront`）は共通ウィジェット `ZukanCardFaceWidget`（幅240・AspectRatio 0.60）を使用し、`AnimatedBuilder`+`DecoratedBox`でグロー強度をパルスアニメーション（`glowAnim` × 0.45 opacity）。レア度・発見者数は `zukanStoresProvider` から取得

## スタンプ・バッジ

### StampCardsView (`lib/views/stamps/stamp_cards_view.dart`)
- 構成: 共通スタンプカード（`StampCardWidget`）のリスト表示（累積スタンプ数から `currentCycleStamps = stamps % 10`・`completedCards = stamps ~/ 10` を計算してウィジェットに渡す）、空/エラー状態
- 説明: ユーザーのスタンプカード一覧。累積スタンプを10で割った余り（サイクル内進捗）と「N枚目」バッジ（常時表示・1枚目から表示）を表示。ホーム画面のスタンプ統計カプセルタップから遷移

### BadgeAwardedView (`lib/views/stamps/badge_awarded_view.dart`)
- 構成: バッジ獲得アニメーション、バッジ情報、次へボタン
- 説明: バッジ獲得の演出画面

### DailyRecommendationView (`lib/views/stamps/daily_recommendation_view.dart`)
- 構成: おすすめ店舗リスト（最大3件）、店舗カード（画像・アイコン・営業時間・説明・レコメンド理由タグ）、「詳細を見る」ボタン、「閉じる」ボタン
- 説明: その日初めてのアプリ起動時にホーム画面から自動表示されるおすすめ店舗画面（MainNavigationView initState → userDataListenerから発火）。スコアリングアルゴリズム（カテゴリ一致+2/エリア一致+1/未訪問+2/訪問済み−1/1km以内+3/3km以内+2/5km以内+1）で上位3件を選定。storesコレクションから最大50件取得（isActive=true, isApproved=true）。レコメンド理由タグ（近く/近距離/好み/未訪問/エリア）を店舗カードに表示。インプレッション・クリックをFirestoreに記録

### BadgesView (`lib/views/badges/badges_view.dart`)
- 構成: ヘッダー右上フィルター、バッジグリッド（内蔵データ全162種＋Firestoreで取得済み判定）、バッジ詳細ポップアップ（取得済み: 名前/カテゴリ/説明、未取得: 「？」アイコン/「？？？」名前/「条件を達成してバッジを獲得しよう！」）
- 説明: アプリ内蔵のバッジ定義（全162種、うちスロット関連8個は廃止・獲得不可）を全て一覧表示。Firestoreの `user_badges` から取得済みバッジを判定し、取得済みバッジは画像・名前を通常表示、未取得バッジは「？」アイコンと「？？？」で表示。ヘッダー右上フィルターでカテゴリ絞り込み可能

## ミッション

### MissionsView (`lib/views/missions/missions_view.dart`)
- 構成: AppBar（通常時「ミッション」、コイン交換モード時「コイン交換」）、コイン残高表示（有効期限日付き・Firestore取得）、通常モード: PillTabBar（デイリー/ログイン/新規登録/週次の4タブ）＋ミッションリスト（3状態: 未達成=グレイアウト / 達成済み未受取=黄色〜アンバーグラデーション背景・タップで報酬受取 / 受取済み=半透明の黄色グラデーション+チェックマーク）。週次タブ: 今週のミッション進捗（未訪問店舗来店数・今週来店合計）・達成時の受取ボタン・達成報酬説明・累計達成バッジ進捗（1/5/10/25回のロック/アンロック表示）。コイン交換モード（`showCoinExchange: true`）: タブバー非表示、交換レート説明+未訪問店舗リスト+交換ボタンを直接表示（未訪問店舗は `isActive=true` かつ `isApproved=true` かつ `stores.isOwner!=true` のみ）。新規登録ミッション未完了時はデイリー/ログイン/週次タブを非活性化（グレーアウト・タップ不可）し新規登録タブを初期選択、新規登録タブ上部にオレンジグラデーションのガイドメッセージバナー表示（「まずは新規登録ミッションを完了しよう!」）
- 説明: ミッション一覧・週次ミッション・コイン交換を管理する画面。週次ミッションは「今週の未訪問店舗に来店（1件）」かつ「今週の来店合計（3回）」が達成条件で、毎週月曜日リセット。達成時に `checkWeeklyMission` Cloud Function を呼び出し、累計達成回数に応じた限定バッジ（`weekly_mission_1/5/10/25`）を付与し発見ヒント通知を送信。コイン獲得ミッション（デイリー/ログイン/新規登録）はFirestore連携でリアルタイム反映し、「受け取る」タップでコインをDBに加算。コイン交換機能は `showCoinExchange: true` で遷移し、10コインで未訪問店舗の100円引きクーポンを取得可能（有効期限30日）。新規登録ミッション（5種）をすべて受取完了するまでデイリー・ログイン・週次タブはロックされる

## スロット（廃止）

### LotteryView (`lib/views/lottery/lottery_view.dart`)（廃止）
- 構成: ※スロット機能廃止に伴い利用停止。コードは保持
- 説明: スロット機能は廃止。ホーム画面からの導線も削除済み

## ランキング・フィードバック

### LeaderboardView (`lib/views/ranking/leaderboard_view.dart`)
- 構成: ランキング種別フィルタ（開拓店舗数 / ポイント / バッジ数 / スタンプ数 / 総支払額 / コイン）、期間フィルタ（日次 / 週次 / 月次 / 全期間）、ランキングリスト（上位3位はアイコン強調表示）
- 説明: 全ユーザー向けに公開済みのランキング画面。デフォルト指標は「開拓店舗数（discoveredStoreCount）」。`ranking_scores/{periodId}/users/{userId}` コレクションから高速取得。`rankingOptOut=true` のユーザーは「名無し探検家」として匿名表示（フェーズ2 ③ ランキング刷新で全公開に変更）

### FeedbackView (`lib/views/feedback/feedback_view.dart`)
- 構成: カテゴリ選択、件名/本文/メール入力、送信ボタン
- 説明: フィードバック送信画面

## 紹介

### FriendReferralView (`lib/views/referral/friend_referral_view.dart`)
- 構成: ヘッダーカード（「友達を招待してコイン獲得」・付与タイミング説明）、紹介コードカード（コード表示・コピーボタン・招待ボタン）、実績カード（招待した友達数・獲得コイン数）、招待方法ガイド（4ステップ）、アプリダウンロードボタン（App Store/Google Play）、特典内容カード（あなたの特典・友達の特典・注意書き）
- 説明: 友達紹介コードの確認と共有画面。「ポイント」ではなく「コイン」で統一表示。コイン付与タイミングは「友達が初めてお店でスタンプを獲得した時点」と明記。付与コイン数は `owner_settings/current` の `friendCampaignInviterPoints` / `friendCampaignInviteePoints` からリアルタイムで取得・表示（未設定時のデフォルトは各5コイン）

### StoreReferralView (`lib/views/referral/store_referral_view.dart`)
- 構成: ヘッダー、紹介コード、手順/注意事項
- 説明: 店舗紹介コードの案内画面

## プロフィール・設定

### ProfileView (`lib/views/profile/profile_view.dart`)
- 構成: `DismissKeyboard` ラップ、**プレイヤーカード**（ダークネイビー背景 `Color(0xE6101E2E)` のヒーローセクション: 右上フローティング通知ベル（`users/{uid}/notifications` の `isRead==false` 件数をStreamBuilderで赤丸バッジ表示）、発見数ベース5段階ランクに応じた**円形プログレスリング付きアバター**（外径92px・内径76px・`_RankProgressPainter` で進捗アーク描画）・プレイヤー名・Lv.Nランクバッジ・3つのstatセル（発見店舗数 / バッジ数 / ランキング順位）・statセルタップで `showGameDialog` 説明ポップアップ）、プロフィール完成度カード（2段階: 基本6項目未完成時→ProfileEditView（`showNextButton=true`）/ 基本完成済み＆興味カテゴリ未設定時→InterestCategoryView、全完了で非表示）、**ゲームコンテンツセクション**（`FloatingMenuItem` リスト形式: バッジ一覧→BadgesView / ランキング→LeaderboardView / 月次レポート→MonthlyReportListView / 通知・お知らせ→NotificationsView / スタンプカード→StampCardsView（スタンプ所持時のみ表示））、アカウント設定リスト（プロフィール編集・興味カテゴリ設定・パスワード変更・メールアドレス変更）、サポートリスト（通知設定・ヘルプ・フィードバック・利用規約・プライバシーポリシー・アプリについて）、QRコード表示ボタン（NFC非対応端末向け）、アカウントセクション（ログアウト（`showGameDialog` 確認））、背景色 `Color(0xFFFBF6F2)`
- 説明: ユーザーアカウントのゲーム的ハブ画面。プレイヤーカード（ダークネイビー）でランクとアバター周りの円形進捗リング（1200ms `Curves.easeOut` アニメーション・`_RankProgressPainter`）を表示。XP進捗カードは廃止しアバターアイコン周りに集約。ゲームコンテンツはFloatingMenuItemリストでバッジ・ランキング・月次レポート・通知への導線を提供。発見数ベース5段階ランク: Lv.1 ルーキー 0-5店舗 / Lv.2 探索者 5-15店舗 / Lv.3 冒険家 15-30店舗 / Lv.4 開拓者 30-50店舗 / Lv.5 レジェンド 50店舗+

### MonthlyReportListView (`lib/views/report/monthly_report_view.dart`)
- 構成: AppBar（タイトル「過去のレポート」）、月別レポートリスト（取得可能な月を新しい順にリスト表示・`availableReportMonthsProvider`で取得・空の場合は「まだレポートはありません」空表示）、各リスト行タップで MonthlyReportView に遷移
- 説明: 過去の月次探検レポートの一覧画面。ProfileViewのゲームセクション「過去のレポート」から遷移

### MonthlyReportView (`lib/views/report/monthly_report_view.dart`)
- 構成: AppBar（タイトル「{yyyy}年{MM}月の探検レポート」・右上シェアボタン）、セクション1（今月のハイライト：発見店舗数大表示・累計発見数・最もよく行ったジャンル・訪問エリアチップ・レジェンド発見数・今月の来店回数）、セクション2（コミュニティへの貢献：コミュニティ発見貢献数・炎マーク店舗数）、セクション3（今月のコミュニティ全体：全体発見数・新規追加店舗数）、セクション4（来月のおすすめ：未訪問レジェンド/エピック店舗の横スクロールカード最大3件）、フッター（SNSシェアテキストプレビュー・「コピーしてシェア」ボタン）、背景色 `Color(0xFFFBF6F2)`
- 説明: ユーザー個人の月次探検レポート表示画面。`monthlyReportProvider(yearMonth)` でFirestore `monthly_reports/{userId}/reports/{yearMonth}` を取得。FCM通知タップ（DeepLink `/monthly_report/{yearMonth}`）からも遷移可能。シェアテキストはクリップボードコピー方式（share_plusパッケージ不使用）。レポートが存在しない月は「まだレポートはありません」空表示

### ProfileEditView (`lib/views/settings/profile_edit_view.dart`)
- 構成: プロフィール編集フォーム（表示名、ユーザーID（@プレフィックス・英数字+アンダースコア・3〜20文字・ユニーク制約）、自己紹介（最大100文字・3行入力）、生年月日、性別、職業（8種ドロップダウン）、都道府県/市区町村、画像選択/アップロード（任意））、ボタン（通常は「保存」・`showNextButton=true`時は「次へ」）
- 説明: プロフィール基本情報の編集画面（興味カテゴリは別画面に分離）。ユーザーIDは`usernames`コレクションで重複防止。Google/Appleユーザーは表示名と画像の編集不可。`showNextButton=true` で呼び出された場合（プロフィール未完成フロー）は保存ボタンが「次へ」に変わり、保存完了後にそのまま InterestCategoryView へ遷移する

### InterestCategoryView (`lib/views/settings/interest_category_view.dart`)
- 構成: 説明テキスト、46カテゴリのチップ形式複数選択（選択時オレンジ色）、保存ボタン
- 説明: 興味カテゴリの設定画面。ProfileEditViewから分離された独立画面。保存時にプロフィール完成ミッション判定を実行

### UserIconCropView (`lib/views/settings/user_icon_crop_view.dart`)
- 構成: 画像プレビュー、切り抜き操作、保存ボタン
- 説明: アイコン画像のトリミング画面

### PasswordChangeView (`lib/views/settings/password_change_view.dart`)
- 構成: 現在/新規/確認パスワード入力、変更ボタン
- 説明: パスワード変更画面

### EmailChangeView (`lib/views/settings/email_change_view.dart`)
- 構成: 現在のメールアドレス表示（読み取り専用）、新しいメールアドレス入力、パスワード入力（再認証用）、認証コード送信ボタン
- 説明: メールアドレス変更画面。パスワード再認証後、新メールアドレスに6桁OTP認証コードを送信し、EmailChangeOtpViewに遷移

### EmailChangeOtpView (`lib/views/settings/email_change_otp_view.dart`)
- 構成: メールアイコン、説明文、6桁認証コード入力フィールド、認証ボタン、再送信ボタン
- 説明: メールアドレス変更用OTP認証画面。新メールアドレスに送信された6桁コードを入力し、Cloud FunctionsでFirebase AuthとFirestoreのメールアドレスを更新

### NotificationSettingsView (`lib/views/settings/notification_settings_view.dart`)
- 構成: プッシュ通知セクション（クーポン発行・投稿）、メール通知セクション（お知らせメール・ニュースレター・キャンペーン）、ランキング設定セクション（ランキング参加ON/OFF）のスイッチ一覧
- 説明: プッシュ通知・メール通知・ランキング参加設定を統合した画面。ランキング参加をOFFにすると「名無し探検家」として匿名表示される（`users/{uid}.rankingOptOut`で管理）

## サポート

### HelpView (`lib/views/support/help_view.dart`)
- 構成: よくある質問（ExpansionTile形式・7件の一般FAQ＋「退会するには？」FAQ）、問い合わせ導線（メールサポート・電話サポート・ライブチャット）。「退会するには？」展開時は案内テキスト＋「退会するにはこちら」赤テキストボタンを表示。FAQは①スタンプ獲得方法（QR提示→累積加算・10個達成ごとに次のカード）②コインの貯め方（デイリーミッション/連続ログインボーナス/来店ボーナス/180日有効期限）③コインの使い方（10コイン=未訪問店舗100円引きクーポン・現金化不可）④新しいお店の見つけ方⑤バッジの獲得方法（全162種）⑥ログインできない場合⑦位置情報が取得できない場合
- 説明: ヘルプ・サポートの入口画面。廃止されたポイント制度に関するFAQを削除し、現行のスタンプ・コインシステムに合わせた内容に更新済み。退会フロー（`AccountDeletionReasonView`→`AccountDeletionProcessingView`）の入り口もここに集約

### ContactView (`lib/views/support/contact_view.dart`)
- 構成: 連絡先（電話/メール/住所）、タップで起動
- 説明: 連絡先一覧画面

### EmailSupportView (`lib/views/support/email_support_view.dart`)
- 構成: お問い合わせフォーム、カテゴリ選択、送信処理
- 説明: メールサポート申請画面

### PhoneSupportView (`lib/views/support/phone_support_view.dart`)
- 構成: 電話番号表示、営業時間、対応内容
- 説明: 電話サポート案内画面

### LiveChatView (`lib/views/support/live_chat_view.dart`)
- 構成: メッセージ一覧、入力欄、送信ボタン
- 説明: ライブチャットによるサポート画面

### PrivacyPolicyView (`lib/views/support/privacy_policy_view.dart`)
- 構成: サポート導線用ラッパー（表示本体は `lib/views/legal/privacy_policy_view.dart` を参照）
- 説明: サポート内のプライバシーポリシー導線画面（法務画面と表示内容を共通化）

### TermsOfServiceView (`lib/views/support/terms_of_service_view.dart`)
- 構成: サポート導線用ラッパー（表示本体は `lib/views/legal/terms_view.dart` を参照）
- 説明: サポート内の利用規約導線画面（法務画面と表示内容を共通化）

## 設定・情報

### AppInfoView (`lib/views/settings/app_info_view.dart`)
- 構成: アプリ情報（名前・バージョン・更新日）、開発者情報（会社名・代表者・設立日・所在地・サポートメール・電話・公式サイト）、ライセンス・法的事項（プライバシーポリシー・利用規約への遷移）、公式アカウント（公式サイト・メールサポートへの遷移）
- 説明: アプリのバージョン情報・開発者情報・法的リンクを表示する画面。ProfileViewのサポートセクションから遷移

## 法務

### TermsView (`lib/views/legal/terms_view.dart`)
- 構成: 利用規約本文（制定日/改定日、条文、事業者情報、問い合わせ先）
- 説明: アプリ内の利用規約画面（`/TERMS_OF_SERVICE.md` 準拠）

### PrivacyPolicyView (`lib/views/legal/privacy_policy_view.dart`)
- 構成: ポリシー本文（制定日/改定日、各章、事業者情報、問い合わせ先）
- 説明: アプリ内のプライバシーポリシー画面（`/PRIVACY_POLICY.md` 準拠）

---

# 階層図（画面構成の全体像）

```
アプリ起動
└─ スプラッシュスクリーン（ネイティブ・背景#FBF6F2+ロゴ中央表示）
   └─ AppUpdateGate
   └─ AuthWrapper
      ├─ 未ログイン（ゲスト）
      │  └─ WelcomeView
      │     ├─ ログインせずに開始
      │     │  └─ MainNavigationView
      │     │     ├─ マップ（MapView）（未ログイン時も閲覧可）
      │     │     ├─ 図鑑（ZukanView）（未ログイン時も閲覧可）
      │     │     └─ アカウント（ProfileView）（未ログイン時: ログイン促進カード表示）
      │     ├─ ログイン（SignInView）
      │     └─ 新規アカウント登録（TermsPrivacyConsentView）
      │
      └─ ログイン済み
         ├─ EmailVerificationPendingView（未認証時）
         │  ├─ UserInfoView（プロフィール未入力時）
         │  │  └─ TutorialView（showTutorial=true）
         │  │     └─ MainNavigationView
         │  └─ MainNavigationView（プロフィール入力済み）
         └─ MainNavigationView
            ├─ マップ（MapView）（index 0・起動時デフォルト）
            │  ├─ フィルター設定（FilterSettingsView）
            │  └─ 店舗詳細（StoreDetailView）
            │     ├─ クーポン詳細（CouponDetailView）
            │     ├─ 投稿詳細（PostDetailView）
            │     └─ 投稿一覧（PostsView）
            │        └─ 投稿詳細（PostDetailView）
            │
            ├─ 図鑑（ZukanView）（index 1）
            │  └─ 店舗詳細（StoreDetailView）（発見済みカードタップ）
            │
            └─ アカウント（ProfileView）（index 2）
               ├─ 通知・お知らせ（NotificationsView）
               │  ├─ お知らせ詳細（AnnouncementDetailView）
               │  └─ 通知詳細（NotificationDetailView）
               ├─ バッジ一覧（BadgesView）
               ├─ ランキング（LeaderboardView）
               ├─ プロフィール編集（ProfileEditView）
               │  ├─ アイコン調整（UserIconCropView）
               │  └─ 興味カテゴリ設定（InterestCategoryView）※プロフィール未完成フロー時のみ（showNextButton=true）
               ├─ 興味カテゴリ設定（InterestCategoryView）
               ├─ パスワード変更（PasswordChangeView）
               ├─ メールアドレス変更（EmailChangeView）
               │  └─ OTP認証（EmailChangeOtpView）
               ├─ 通知設定（NotificationSettingsView）
               ├─ 利用規約（TermsView）
               ├─ プライバシーポリシー（PrivacyPolicyView）
               ├─ ヘルプ・サポート（HelpView）
               │  ├─ メールサポート（EmailSupportView）
               │  ├─ 電話サポート（PhoneSupportView）
               │  ├─ ライブチャット（LiveChatView）
               │  ├─ 利用規約（TermsOfServiceView）
               │  ├─ プライバシーポリシー（Support/PrivacyPolicyView）
               │  └─ 退会（「退会するには？」FAQ）
               │     ├─ 退会理由入力（AccountDeletionReasonView）
               │     ├─ 退会処理中（AccountDeletionProcessingView）
               │     └─ 退会完了（AccountDeletionCompleteView）
               ├─ アプリについて（AppInfoView）
               │  ├─ プライバシーポリシー（Legal/PrivacyPolicyView）
               │  ├─ 利用規約（TermsView）
               │  └─ メールサポート（EmailSupportView）
               ├─ QRコードを表示（QRGeneratorView）※NFC非対応端末向けフォールバック
               │  ├─ 支払い（PointPaymentView）
               │  │  └─ 支払い完了（PaymentSuccessView）
               │  ├─ ポイント付与確認（PointRequestConfirmationView）
               │  │  └─ 付与結果（PointPaymentDetailView）
               │  └─ ポイント利用承認（PointUsageApprovalView）
               └─ お問い合わせ（ContactView）

NFCチェックインフロー（Deep Link経由）
└─ NFCタグタッチ → OS-native URL読取 → Universal Links/App Links
   └─ MainNavigationView（DeepLinkService受信）
      └─ NfcCouponSelectView（クーポン選択）
         └─ NfcCheckinResultView（結果表示・確認コード・スタンプカード）
            ├─ ZukanCardView（図鑑カード発見演出）
            │  └─ MainNavigationView（完了・pushAndRemoveUntil）
            └─ MainNavigationView（「ホームに戻る」ボタン）

その他の単独遷移・演出系
├─ チュートリアル（TutorialView）→ 新規登録後の `UserInfoView` 完了直後に自動表示（showTutorial=true のユーザーのみ、保険でホーム遷移時にも表示可能）
├─ ウォークスルー（WalkthroughOverlay）→ チュートリアル完了後に自動開始（walkthroughCompleted=false のユーザーのみ・6ステップ: コンセプト→マップタブ→マーカータップ→NFCタッチ説明→図鑑タブ→アカウントタブ・ウォークスルー中はバッジ・レコメンドポップアップを非表示）
├─ バッジ獲得（BadgeAwardedView）→ ホーム画面に戻る（ウォークスルー中は表示しない）
├─ おすすめ店舗（DailyRecommendationView）→ その日初回ログイン時に自動表示（ウォークスルー中は表示しない）
├─ ポイント利用入力（PointUsageRequestView）
│  └─ 店舗側入力待ち（PointUsageWaitingView）
└─ 取引履歴（TransactionHistoryView）
   └─ スタンプ確認（PointPaymentDetailView）

認証フロー（入り口）
├─ ウェルカム（WelcomeView）
├─ ログイン（SignInView）
├─ 規約同意（TermsPrivacyConsentView）
├─ 新規登録（SignUpView）
├─ メール認証（EmailVerificationPendingView）
└─ ユーザー情報入力（UserInfoView）
```
