import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class CheckinDeepLink {
  final String storeId;
  final String tagSecret;

  CheckinDeepLink({required this.storeId, required this.tagSecret});
}

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// コールドスタート時の初期リンクを取得
  Future<CheckinDeepLink?> getInitialCheckinLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) return null;
      return _parseCheckinUri(uri);
    } catch (e) {
      debugPrint('初期Deep Link取得エラー: $e');
      return null;
    }
  }

  /// ウォームスタート時のリンクストリームを監視
  void listenCheckinLinks(void Function(CheckinDeepLink link) onLink) {
    _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        final link = _parseCheckinUri(uri);
        if (link != null) {
          onLink(link);
        }
      },
      onError: (error) {
        debugPrint('Deep Linkストリームエラー: $error');
      },
    );
  }

  /// チェックイン用URLをパース
  CheckinDeepLink? _parseCheckinUri(Uri uri) {
    // https://groumapapp.web.app/checkin?storeId=xxx&secret=yyy
    if (uri.host != 'groumapapp.web.app') return null;
    if (uri.path != '/checkin') return null;

    final storeId = uri.queryParameters['storeId'];
    final secret = uri.queryParameters['secret'];
    if (storeId == null || storeId.isEmpty) return null;
    if (secret == null || secret.isEmpty) return null;

    return CheckinDeepLink(storeId: storeId, tagSecret: secret);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
