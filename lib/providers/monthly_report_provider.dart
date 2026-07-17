import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_report_model.dart';

/// 指定月のレポートデータを取得
final monthlyReportProvider =
    FutureProvider.family<MonthlyReportModel?, String>((ref, yearMonth) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('monthly_reports')
      .doc(user.uid)
      .collection('reports')
      .doc(yearMonth)
      .get();

  if (!doc.exists) return null;
  return MonthlyReportModel.fromFirestore(doc);
});

/// 利用可能なレポート月一覧（新しい月順）
final availableReportMonthsProvider =
    FutureProvider<List<String>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final snap = await FirebaseFirestore.instance
      .collection('monthly_reports')
      .doc(user.uid)
      .collection('reports')
      .orderBy(FieldPath.documentId, descending: true)
      .get();

  return snap.docs.map((d) => d.id).toList();
});
