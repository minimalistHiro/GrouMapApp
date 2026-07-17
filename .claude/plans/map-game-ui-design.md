# マップ ゲームUI 設計書

作成日: 2026-03-06

## 背景・目的

現状のマップ画面は Google Maps の素の UIをそのまま活用した「普通の地図アプリ」に見えてしまっている。
ビジネスモデルではゲーム性を重要視したアプリと位置付けており、
ポケモンGO・Ingress のようなゲーム的没入感・ワクワク感を持つ UI に近づけることが目的。

---

## 現状の問題

- マップスタイルが標準の Google Maps（明るい・無機質）
- 店舗情報カードが白背景・薄いシャドウのシンプルなカード（普通のビジネスアプリ風）
- マーカーはサイズ変化のみでアニメーションなし
- 現在地は Google Maps 標準の青丸のみ（ゲーム感なし）
- プレイヤーの状況（ランク・発見数・ポイント）が画面上に一切見えない

---

## 設計・計画内容

### ゲームUI テーマ設計

アプリのブランドカラー（`#FF6B35` オレンジ）を維持しつつ、以下のテーマを採用：

- **ベースマップ**: 暗めのダークブルー系（Ingressライク）
- **アクセント**: オレンジ `#FF6B35` + シアン `#00E5FF` + ゴールド `#FFB300`
- **UI素材**: 半透明の暗い背景 + 発光ボーダー（グロー効果）
- **フォント色**: 白系・ライトグレー

---

## 実装内容

### 1. ダークマップスタイルの適用

**ファイル**: `lib/views/map/map_view.dart`

**変更箇所**: `build()` → `GoogleMap(style: ...)` (L1932)

現在の style は POI 非表示のみ。以下のゲーム調ダークスタイルに置き換える。

```dart
// ゲーム調ダークスタイル JSON（定数として _MapViewState に定義）
static const String _gameMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3a4a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2a4a6a"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9ec3b9"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#c4d8dd"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a3a52"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0d2a3a"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#7ea3b9"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e4a6e"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#0d2a3a"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#a0c8d8"}]},
  {"featureType":"transit","stylers":[{"visibility":"simplified"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#7ea3b9"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a2030"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]''';
```

GoogleMap ウィジェットで使用：
```dart
GoogleMap(
  style: _gameMapStyle,
  // ... 既存のパラメータ
)
```

---

### 2. 店舗情報パネルのゲーム風デザイン変更

**ファイル**: `lib/views/map/map_view.dart`

**変更箇所**: `_buildStoreInfoCard()` (L2018-2271)

#### 現状
- 白背景・角丸12・薄いシャドウ
- 店舗画像 → 店舗名 → 営業状況 → 詳細ボタン のシンプル構成

#### 変更後の設計

```
┌─────────────────────────────────────────────────┐  ← 半透明暗背景 + シアンボーダー発光
│ [店舗画像]  2:1比率                              │
│ ┌────────────────────────────────────────────┐  │
│ │ [ジャンルバッジ]                            │  │
│ │                              [営業中/外]    │  │
│ └────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│ 店舗名  ★★★☆☆ (来店ランク)                    │
│ [スタンプ数アイコン] × N   [発見バッジ]         │
│ ─────────────────────────────────────────────   │
│ [  詳細を見る  →  ]   (ゲーム風ボタン)          │
└─────────────────────────────────────────────────┘
```

#### 実装コード設計

```dart
Widget _buildStoreInfoCard() {
  // ... 既存のデータ取得ロジックはそのまま流用 ...

  return Positioned(
    bottom: 20,
    left: 20,
    right: 20,
    child: Stack(
      children: [
        // ゲームパネル本体
        Container(
          decoration: BoxDecoration(
            // 半透明ダーク背景
            color: const Color(0xE6101E2E), // #101E2E + 90%透明度
            borderRadius: BorderRadius.circular(16),
            // シアン発光ボーダー
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              // 外側グロー
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 店舗画像（既存ロジック流用、グラデーションオーバーレイ追加）
              _buildGamePanelImage(selectedStore, category),
              // ゲーム風情報セクション
              _buildGamePanelInfo(selectedStore, userStamp, stamps, isOpenNow, categoryDisplay),
            ],
          ),
        ),
        // 閉じるボタン（ゲーム風）
        Positioned(
          top: 8,
          right: 8,
          child: _buildGameCloseButton(),
        ),
      ],
    ),
  );
}

Widget _buildGamePanelImage(Map<String, dynamic> store, String category) {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    child: AspectRatio(
      aspectRatio: 2.0,
      child: Stack(
        children: [
          // 既存の画像表示ロジック
          // ...
          // グラデーションオーバーレイ（下部を暗くしてテキストを読みやすく）
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0x80101E2E),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          // 営業状況バッジ（右上）
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOpenNow
                    ? const Color(0xFF00E676).withOpacity(0.9)
                    : Colors.black54,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOpenNow
                      ? const Color(0xFF00E676)
                      : Colors.grey[600]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOpenNow ? const Color(0xFF00E676) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOpenNow ? '営業中' : '営業時間外',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOpenNow ? Colors.white : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ジャンルバッジ（左上）
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppUi.primary.withOpacity(0.7),
                  width: 1,
                ),
              ),
              child: Text(
                categoryDisplay,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildGamePanelInfo(
  Map<String, dynamic> store,
  Map<String, dynamic>? userStamp,
  int stamps,
  bool isOpenNow,
  String categoryDisplay,
) {
  final totalVisits = (userStamp?['totalVisits'] as num?)?.toInt() ?? 0;
  final status = _getPersonalMapStatus(totalVisits);

  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 店舗名 + ランクアイコン
        Row(
          children: [
            Expanded(
              child: Text(
                store['name'] ?? '店舗名なし',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // 来店ステータスアイコン
            _buildVisitStatusBadge(status, totalVisits),
          ],
        ),
        const SizedBox(height: 8),
        // スタンプ数表示
        Row(
          children: [
            Icon(Icons.stars_rounded, color: AppUi.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              'スタンプ $stamps 個',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 12),
            // 今日の営業時間
            Icon(Icons.schedule, color: Colors.grey[500], size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                () {
                  final hours = _getTodayHours(store);
                  return hours.isNotEmpty ? hours : '---';
                }(),
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 区切り線
        Container(
          height: 1,
          color: const Color(0xFF00E5FF).withOpacity(0.2),
        ),
        const SizedBox(height: 12),
        // ゲーム風アクションボタン
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StoreDetailView(store: store),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppUi.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '詳細を見る',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildVisitStatusBadge(String status, int totalVisits) {
  final color = _getPersonalMapColor(status);
  final label = switch (status) {
    'undiscovered' => '未発見',
    'discovered'   => '初発見',
    'exploring'    => '探索中',
    'regular'      => '常連',
    'legend'       => 'レジェンド',
    _ => '',
  };
  if (label.isEmpty) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.6), width: 1),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildGameCloseButton() {
  return GestureDetector(
    key: _closeBtnKey,
    onTap: () async {
      setState(() {
        _isShowStoreInfo = false;
        _expandedMarkerId = '';
      });
      await _createMarkers();
    },
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: const Icon(Icons.close, size: 18, color: Colors.white70),
    ),
  );
}
```

---

### 3. 現在地レーダー（スキャン）アニメーション

**ファイル**: `lib/views/map/map_view.dart`

**方針**: `AnimationController` で 0→1 を繰り返すアニメーションを作り、
拡大しながら透明になる同心円を `CustomPaint` または `Stack` で描画する。
Google Maps の `Circle` は非同期描画のため、Flutterオーバーレイウィジェット側で実装する。

#### フィールド追加

```dart
// レーダーアニメーション
late AnimationController _radarController;
late Animation<double> _radarAnimation;
```

#### initState に追加

```dart
_radarController = AnimationController(
  vsync: this, // with TickerProviderStateMixin を追加
  duration: const Duration(seconds: 2),
)..repeat();
_radarAnimation = CurvedAnimation(
  parent: _radarController,
  curve: Curves.easeOut,
);
```

#### StateMixin 変更

```dart
// ConsumerState<MapView> with TickerProviderStateMixin
class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
```

#### レーダーウィジェット

現在地 `_currentLocation` が取得できている場合のみ表示。
マップ上の現在地座標をスクリーン座標に変換して重ねる方式ではなく、
`GoogleMap` の `myLocationEnabled` に加えて Stack 内に配置する。
実装上は `_currentLocation` のスクリーン上の位置が取れないため、
**現在地ボタンタップ時にカメラを現在地に移動して画面中央に表示している状態** のみ
アニメーションを有効にする (`_isFollowingUser` フラグ追加)、
または `GoogleMap` の `onCameraMove` を活用する方式で対応。

**シンプル実装案（推奨）**: Google Maps の `Circle` API にアニメーションを適用。
`_radarController` の値に応じて `_radarCircles` を再計算し `setState()` する。

```dart
// レーダー Circle の生成（_currentLocation が存在する場合）
Set<Circle> _buildRadarCircles() {
  if (_currentLocation == null) return {};
  final t = _radarAnimation.value; // 0.0 ~ 1.0

  final circles = <Circle>{};
  // 3つの同心円を位相をずらして生成
  for (int i = 0; i < 3; i++) {
    final phase = (t + i / 3) % 1.0;
    final radius = 20.0 + phase * 180.0; // 20m → 200m に拡大
    final opacity = (1.0 - phase) * 0.5;  // フェードアウト

    circles.add(Circle(
      circleId: CircleId('radar_$i'),
      center: _currentLocation!,
      radius: radius,
      fillColor: const Color(0xFF00E5FF).withOpacity(opacity * 0.3),
      strokeColor: const Color(0xFF00E5FF).withOpacity(opacity),
      strokeWidth: 2,
    ));
  }
  return circles;
}
```

`_getActiveCircles()` に追加：
```dart
Set<Circle> _getActiveCircles() {
  // ... 既存コード ...
  // レーダーを常時追加
  return {...existingCircles, ..._buildRadarCircles()};
}
```

`_radarController` のリスナーで setState：
```dart
_radarController.addListener(() {
  if (mounted) setState(() {});
});
```

> **注意**: `setState` が頻繁に呼ばれるため、マーカーの再生成は行わない。
> `_buildRadarCircles()` のみを `_getActiveCircles()` 内で呼び出す。

---

### 4. プレイヤーHUD（下部固定）

**ファイル**: `lib/views/map/map_view.dart`

**方針**: 画面下部（店舗情報カード非表示時のみ）に、プレイヤーのステータスを表示する
コンパクトなHUDバーを配置する。

#### 表示する情報

| 表示項目 | データソース |
|---------|------------|
| 発見した店舗数 | `users/{uid}` コレクション → `discoveredStoreCount` |
| 累計ポイント | `users/{uid}` → `totalPoints` |
| 現在のスタンプ数（全店舗合計） | `users/{uid}` → `stampCount` |

#### データ取得

`_initializeMapData()` の中で `_loadPlayerStats()` を追加。
`_userStamps` ロード時に集計するか、`users/{uid}` ドキュメントの統計フィールドを使用。

```dart
int _playerDiscoveredCount = 0;
int _playerTotalPoints = 0;
int _playerStampCount = 0;

Future<void> _loadPlayerStats() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!mounted || !doc.exists) return;
    final data = doc.data()!;
    setState(() {
      _playerDiscoveredCount = (data['discoveredStoreCount'] as num?)?.toInt() ?? 0;
      _playerTotalPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
      _playerStampCount = (data['stampCount'] as num?)?.toInt() ?? 0;
    });
  } catch (e) {
    debugPrint('プレイヤー統計の読み込み失敗: $e');
  }
}
```

#### HUD ウィジェット

```dart
Widget _buildPlayerHUD() {
  if (_isShowStoreInfo) return const SizedBox.shrink();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const SizedBox.shrink();

  return Positioned(
    bottom: 20,
    left: 20,
    right: 20,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xE6101E2E), // 90% 不透明
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHUDStat(
            icon: Icons.explore,
            iconColor: const Color(0xFF29B6F6),
            label: '発見',
            value: '$_playerDiscoveredCount',
          ),
          _buildHUDDivider(),
          _buildHUDStat(
            icon: Icons.stars_rounded,
            iconColor: AppUi.primary,
            label: 'スタンプ',
            value: '$_playerStampCount',
          ),
          _buildHUDDivider(),
          _buildHUDStat(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFFB300),
            label: 'ポイント',
            value: '$_playerTotalPoints',
          ),
        ],
      ),
    ),
  );
}

Widget _buildHUDStat({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String value,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
        ),
      ),
    ],
  );
}

Widget _buildHUDDivider() {
  return Container(
    width: 1,
    height: 36,
    color: const Color(0xFF00E5FF).withOpacity(0.2),
  );
}
```

`build()` の Stack に追加：
```dart
// プレイヤーHUD
_buildPlayerHUD(),
```

---

### 5. マーカーアニメーション強化

**ファイル**: `lib/views/map/map_view.dart`

**現状**: マーカータップ時にサイズが 40px → 80px に変わるだけ（即座に変わる、アニメーションなし）

**変更方針**:
Google Maps Flutter の `Marker` はネイティブレンダリングのため、
Flutter の AnimationController は直接適用できない。
以下の2つのアプローチを組み合わせる。

#### アプローチA: 拡大時に段階的サイズ変化（疑似アニメーション）

マーカータップ時に小 → 中 → 大 と3段階で `setState` を連続呼び出し、
スケール変化を演出する。

```dart
Future<void> _animateMarkerExpand(String storeId) async {
  // 中間サイズで一瞬表示
  setState(() => _expandedMarkerId = '${storeId}_mid'); // 専用フラグではなくサイズ管理を変更
  await _createMarkersWithSize(storeId, 56.0); // 中間サイズ
  await Future.delayed(const Duration(milliseconds: 80));
  await _createMarkersWithSize(storeId, 80.0); // 最終サイズ
}
```

> 実装上の複雑度が高いため、フェーズ2 以降で対応。

#### アプローチB: タップ時の HapticFeedback + 選択リングオーバーレイ

マーカータップ時に Flutter Widget レイヤーで「選択リング」アニメーションを表示する。
選択された店舗の座標をスクリーン座標に変換するには `GoogleMapController.getScreenCoordinate()` を使用。

```dart
// マーカータップ時の選択エフェクト
Offset? _selectedMarkerScreenPos;
bool _showSelectionRing = false;
late AnimationController _selectionRingController;

// マーカータップ時
onTap: () async {
  HapticFeedback.mediumImpact(); // 強めのフィードバックに変更
  // スクリーン座標取得
  final screenPos = await _mapController?.getScreenCoordinate(store['position']);
  if (screenPos != null && mounted) {
    setState(() {
      _selectedMarkerScreenPos = Offset(
        screenPos.x.toDouble(),
        screenPos.y.toDouble(),
      );
      _showSelectionRing = true;
    });
    _selectionRingController
      ..reset()
      ..forward();
  }
  // 既存の展開ロジック
  // ...
}
```

選択リングウィジェット（Stack 内に追加）：
```dart
if (_showSelectionRing && _selectedMarkerScreenPos != null)
  Positioned(
    left: _selectedMarkerScreenPos!.dx - 60,
    top: _selectedMarkerScreenPos!.dy - 60,
    child: AnimatedBuilder(
      animation: _selectionRingController,
      builder: (context, child) {
        final t = _selectionRingController.value;
        return Opacity(
          opacity: (1.0 - t).clamp(0.0, 1.0),
          child: Container(
            width: 120 * (0.5 + t * 0.5),
            height: 120 * (0.5 + t * 0.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppUi.primary,
                width: 2.0 * (1.0 - t),
              ),
            ),
          ),
        );
      },
    ),
  ),
```

---

### 6. UIコントロールのゲーム風スタイル更新

**ファイル**: `lib/views/map/map_view.dart`

#### 検索ボタン・フィルターボタンのダーク化

現在の白背景ボタンを、ダーク背景 + シアンボーダーに変更。

```dart
// _buildSearchBar() 内の boxDecoration を変更
BoxDecoration(
  color: const Color(0xE6101E2E),
  shape: BoxShape.circle,
  border: Border.all(
    color: const Color(0xFF00E5FF).withOpacity(0.4),
    width: 1,
  ),
  boxShadow: [/* ... */],
)
```

#### 現在地ボタン・北向きボタンのダーク化

`_buildMapControls()` (L2689) のボタン色も合わせる。
現在の `Colors.black` 背景はほぼそのままで、ボーダーのみ追加。

```dart
BoxDecoration(
  color: const Color(0xFF0D1B2A),
  shape: BoxShape.circle,
  border: Border.all(
    color: const Color(0xFF00E5FF).withOpacity(0.5),
    width: 1,
  ),
  // ... shadow
)
```

---

## ファイル変更一覧

| ファイル | 変更内容 |
|---|---|
| `lib/views/map/map_view.dart` | マップスタイル定数追加・GoogleMapのstyle変更・`_MapViewState` に `TickerProviderStateMixin` 追加・レーダーAnimation追加・HUDフィールド追加・`_buildStoreInfoCard()`をゲーム風に全面変更・`_buildPlayerHUD()`新規追加・`_buildGameCloseButton()`追加・`_buildHUDStat()`/`_buildHUDDivider()`追加・`_buildRadarCircles()`追加・`_getActiveCircles()`にレーダー追加・選択リングアニメーション追加・検索・フィルター・コントロールボタンのスタイル変更 |
| `lib/theme/app_ui.dart` | ゲームUI用カラー定数追加（`gameBackground`, `gameBorder`, `gameAccent`）|

---

## 実装優先順位

1. **フェーズ1（最小実装・視覚変化大）**
   - ダークマップスタイルの適用（JSON変更のみ）
   - 検索・フィルター・コントロールボタンのダーク化
   - 店舗情報カードのゲーム風デザイン変更

2. **フェーズ2（インタラクション強化）**
   - `app_ui.dart` にゲームUIカラー定数追加
   - レーダーアニメーション実装（`TickerProviderStateMixin` 追加）
   - プレイヤーHUD実装・プレイヤー統計読み込み追加

3. **フェーズ3（演出細部）**
   - マーカータップ時の選択リングアニメーション
   - マーカー拡大の疑似アニメーション

---

## 注意事項

- `TickerProviderStateMixin` 追加時、既存の `super.dispose()` より前に `_radarController.dispose()` / `_selectionRingController.dispose()` を必ず呼ぶ
- レーダー Circle の `setState` は `_radarController.addListener()` から呼ぶが、マーカーの `_createMarkers()` を呼ばないこと（重い処理のため）
- `_buildRadarCircles()` の `_getActiveCircles()` への追加は、`_communityMapMode` の円との競合に注意（ID が被らないよう `radar_0`, `radar_1`, `radar_2` を使用する）
- ダークマップスタイルにより現在地の青丸が見えにくくなる場合は、`myLocationButtonEnabled: false` + 独自の現在地マーカーを検討
- プレイヤーHUDは `_isShowStoreInfo == true` 時に非表示にすることで画面の重複を防ぐ
- AppUiカラー定数は `app_ui.dart` に追加するが、既存の `primary` / `surface` / `card` は変更しないこと（他画面への影響を避ける）
- マップ画面固有のゲームカラーは定数として `map_view.dart` 内に `static const` で定義する方法でも可（app_ui.dart 変更を最小化できる）

---

## 参考: ゲームUIカラーパレット

| 用途 | カラーコード |
|------|------------|
| パネル背景 | `#101E2E` (90%不透明) |
| ボーダー/グロー | `#00E5FF` (シアン) |
| プレイヤー（発見） | `#29B6F6` (ライトブルー) |
| 営業中 | `#00E676` (明るいグリーン) |
| ランク: 探索中 | `#66BB6A` (グリーン) |
| ランク: 常連 | `#FB8C00` (オレンジ) |
| ランク: レジェンド | `#FFB300` (ゴールド) |
| アクション背景 | `#FF6B35` (ブランドオレンジ) |
