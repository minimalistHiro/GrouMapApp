import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/map_filter_model.dart';

class MapFilterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// フィルター設定のドキュメント参照を取得
  static DocumentReference? _getFilterDocRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('map_filter')
        .doc('settings');
  }

  /// フィルター設定を保存
  static Future<void> saveFilter(MapFilterModel filter) async {
    final docRef = _getFilterDocRef();
    if (docRef == null) return;
    await docRef.set(filter.toMap());
  }

  /// フィルター設定を読み込み
  static Future<MapFilterModel> loadFilter() async {
    final docRef = _getFilterDocRef();
    if (docRef == null) return const MapFilterModel();

    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) {
      return const MapFilterModel();
    }
    return MapFilterModel.fromMap(doc.data()! as Map<String, dynamic>);
  }

  /// フィルター設定をリセット
  static Future<void> resetFilter() async {
    final docRef = _getFilterDocRef();
    if (docRef == null) return;
    await docRef.delete();
  }
}
