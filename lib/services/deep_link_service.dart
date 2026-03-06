import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class CheckinDeepLink {
  final String storeId;
  final String tagSecret;

  CheckinDeepLink({required this.storeId, required this.tagSecret});

  String get dedupeKey => '$storeId:$tagSecret';
}

class MonthlyReportDeepLink {
  final String yearMonth;

  MonthlyReportDeepLink({required this.yearMonth});
}

class DeepLinkService {
  // Canonical host (current) + one-release legacy host compatibility.
  static const String canonicalCheckinHost = 'groumapapp.web.app';
  static const String legacyCheckinHost = 'groumap-ea452.web.app';

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

  /// コールドスタート時の月次レポートDeepLinkを取得
  Future<MonthlyReportDeepLink?> getInitialMonthlyReportLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) return null;
      return DeepLinkService.parseMonthlyReportUri(uri);
    } catch (e) {
      debugPrint('月次レポートDeepLink取得エラー: $e');
      return null;
    }
  }

  /// ウォームスタート時の月次レポートDeepLinkを監視
  void listenMonthlyReportLinks(
      void Function(MonthlyReportDeepLink link) onLink) {
    _appLinks.uriLinkStream.listen(
      (uri) {
        final link = DeepLinkService.parseMonthlyReportUri(uri);
        if (link != null) {
          onLink(link);
        }
      },
      onError: (error) {
        debugPrint('月次レポートDeepLinkストリームエラー: $error');
      },
    );
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

  /// 月次レポートDeepLinkをパース（/monthly_report/{yearMonth}）
  static MonthlyReportDeepLink? parseMonthlyReportUri(Uri uri) {
    // https://groumapapp.web.app/monthly_report/2026-03
    final isCanonicalHost = uri.host == canonicalCheckinHost;
    final isLegacyHost = uri.host == legacyCheckinHost;
    if (uri.scheme != 'https' || (!isCanonicalHost && !isLegacyHost)) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'monthly_report') {
      final yearMonth = segments[1];
      // 簡易バリデーション: YYYY-MM 形式
      final regex = RegExp(r'^\d{4}-\d{2}$');
      if (regex.hasMatch(yearMonth)) {
        return MonthlyReportDeepLink(yearMonth: yearMonth);
      }
    }
    return null;
  }

  /// チェックイン用URLをパース
  CheckinDeepLink? _parseCheckinUri(Uri uri) {
    return parseCheckinUri(uri);
  }

  @visibleForTesting
  static CheckinDeepLink? parseCheckinUri(Uri uri) {
    final isCheckinPath = uri.path == '/checkin';
    final isCanonicalHost = uri.host == canonicalCheckinHost;
    final isLegacyHost = uri.host == legacyCheckinHost;

    // Canonical URL:
    // https://groumapapp.web.app/checkin?storeId=xxx&secret=yyy
    // Legacy URL (one-release compatibility):
    // https://groumap-ea452.web.app/checkin?storeId=xxx&secret=yyy
    final isUniversalLink = uri.scheme == 'https' &&
        isCheckinPath &&
        (isCanonicalHost || isLegacyHost);

    // Manual fallback button URL on /checkin page.
    final isCustomScheme = uri.scheme == 'groumap' && uri.host == 'checkin';
    if (!isUniversalLink && !isCustomScheme) return null;

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
