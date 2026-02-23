import 'package:cloud_firestore/cloud_firestore.dart';

class CoinStatus {
  final int rawCoins;
  final int availableCoins;
  final DateTime? expiresAt;
  final bool isExpired;

  const CoinStatus({
    required this.rawCoins,
    required this.availableCoins,
    required this.expiresAt,
    required this.isExpired,
  });

  CoinStatus copyWith({
    int? rawCoins,
    int? availableCoins,
    DateTime? expiresAt,
    bool? isExpired,
  }) {
    return CoinStatus(
      rawCoins: rawCoins ?? this.rawCoins,
      availableCoins: availableCoins ?? this.availableCoins,
      expiresAt: expiresAt ?? this.expiresAt,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

class CoinService {
  static const int coinExpiryDays = 180;
  final FirebaseFirestore _firestore;

  CoinService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static DateTime calculateExpiryDate(DateTime earnedAt) {
    return earnedAt.add(const Duration(days: coinExpiryDays));
  }

  static CoinStatus resolveCoinStatusFromUserData(
    Map<String, dynamic>? userData, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final rawCoins = _toInt(userData?['coins']);
    final expiresAt = _toDateTime(userData?['coinExpiresAt']);
    final isExpired =
        rawCoins > 0 && expiresAt != null && !expiresAt.isAfter(currentTime);
    final availableCoins = isExpired ? 0 : rawCoins;

    return CoinStatus(
      rawCoins: rawCoins,
      availableCoins: availableCoins,
      expiresAt: expiresAt,
      isExpired: isExpired,
    );
  }

  static int resolveAvailableCoinsFromUserData(
    Map<String, dynamic>? userData, {
    DateTime? now,
  }) {
    return resolveCoinStatusFromUserData(userData, now: now).availableCoins;
  }

  static Map<String, Object?> buildCoinEarnUpdate({
    required int currentCoins,
    required int earnedCoins,
    DateTime? earnedAt,
  }) {
    final baseCoins = currentCoins < 0 ? 0 : currentCoins;
    final reward = earnedCoins < 0 ? 0 : earnedCoins;
    final nextCoins = baseCoins + reward;
    final now = earnedAt ?? DateTime.now();
    final expiresAt = calculateExpiryDate(now);

    return {
      'coins': nextCoins,
      'coinLastEarnedAt': Timestamp.fromDate(now),
      'coinExpiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  static Map<String, Object?> buildCoinSpendUpdate({
    required int currentCoins,
    required int spentCoins,
  }) {
    final baseCoins = currentCoins < 0 ? 0 : currentCoins;
    final spend = spentCoins < 0 ? 0 : spentCoins;
    final nextCoins = baseCoins - spend < 0 ? 0 : baseCoins - spend;
    return {
      'coins': nextCoins,
    };
  }

  Future<CoinStatus> getCoinStatus(
    String userId, {
    bool expireIfNeeded = false,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      return const CoinStatus(
        rawCoins: 0,
        availableCoins: 0,
        expiresAt: null,
        isExpired: false,
      );
    }

    final userData = userDoc.data();
    final status = resolveCoinStatusFromUserData(userData);

    if (expireIfNeeded && status.rawCoins > 0 && status.expiresAt == null) {
      final now = DateTime.now();
      final expiresAt = calculateExpiryDate(now);
      await userRef.update({
        'coinLastEarnedAt': Timestamp.fromDate(now),
        'coinExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return status.copyWith(expiresAt: expiresAt, isExpired: false);
    }

    if (expireIfNeeded && status.isExpired && status.rawCoins > 0) {
      await userRef.update({
        'coins': 0,
        'coinExpiredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return status.copyWith(rawCoins: 0, availableCoins: 0);
    }

    return status;
  }

  Future<int> getAvailableCoins(
    String userId, {
    bool expireIfNeeded = false,
  }) async {
    final status = await getCoinStatus(userId, expireIfNeeded: expireIfNeeded);
    return status.availableCoins;
  }

  Future<void> expireCoinsIfNeeded(String userId) async {
    await getCoinStatus(userId, expireIfNeeded: true);
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      if (value <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed;
    }
    return null;
  }
}
