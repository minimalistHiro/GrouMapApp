import 'package:flutter_test/flutter_test.dart';
import 'package:groumapapp/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.parseCheckinUri', () {
    test('accepts canonical host checkin URL', () {
      final uri = Uri.parse(
        'https://groumapapp.web.app/checkin?storeId=store_1&secret=secret_1',
      );

      final result = DeepLinkService.parseCheckinUri(uri);

      expect(result, isNotNull);
      expect(result!.storeId, 'store_1');
      expect(result.tagSecret, 'secret_1');
    });

    test('accepts legacy host checkin URL for compatibility', () {
      final uri = Uri.parse(
        'https://groumap-ea452.web.app/checkin?storeId=store_legacy&secret=secret_legacy',
      );

      final result = DeepLinkService.parseCheckinUri(uri);

      expect(result, isNotNull);
      expect(result!.storeId, 'store_legacy');
      expect(result.tagSecret, 'secret_legacy');
    });

    test('accepts custom scheme checkin URL', () {
      final uri = Uri.parse(
        'groumap://checkin?storeId=store_custom&secret=secret_custom',
      );

      final result = DeepLinkService.parseCheckinUri(uri);

      expect(result, isNotNull);
      expect(result!.storeId, 'store_custom');
      expect(result.tagSecret, 'secret_custom');
    });

    test('rejects URLs with non-checkin path', () {
      final uri = Uri.parse(
        'https://groumapapp.web.app/not-checkin?storeId=store_1&secret=secret_1',
      );

      final result = DeepLinkService.parseCheckinUri(uri);

      expect(result, isNull);
    });

    test('rejects URL without storeId', () {
      final uri = Uri.parse(
        'https://groumapapp.web.app/checkin?secret=secret_1',
      );

      final result = DeepLinkService.parseCheckinUri(uri);

      expect(result, isNull);
    });

    test('rejects URL without secret', () {
      final uri = Uri.parse(
        'https://groumapapp.web.app/checkin?storeId=store_1',
      );

      final result = DeepLinkService.parseCheckinUri(uri);

      expect(result, isNull);
    });

    test('rejects unsupported custom scheme host', () {
      final uri = Uri.parse(
        'groumap://open?storeId=store_1&secret=secret_1',
      );

      final result = DeepLinkService.parseCheckinUri(uri);

      expect(result, isNull);
    });
  });
}
