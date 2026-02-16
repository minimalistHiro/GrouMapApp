import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

/// 掲載期間内のニュースプロバイダー（ホーム用、最大7件）
final activeNewsProvider = StreamProvider<List<NewsModel>>((ref) {
  final now = DateTime.now();
  return FirebaseFirestore.instance
      .collection('news')
      .where('publishStartDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .orderBy('publishStartDate', descending: true)
      .limit(7)
      .snapshots()
      .map((snapshot) {
    final currentTime = DateTime.now();
    return snapshot.docs
        .map((doc) => NewsModel.fromMap(doc.data(), doc.id))
        .where((news) => news.publishEndDate.isAfter(currentTime))
        .toList();
  });
});
