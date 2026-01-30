import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ユーザーデータプロバイダー（usersコレクションから直接取得）
final userDataProvider = StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      return Stream.value(null);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).handleError((error) {
      debugPrint('Error fetching user data: $error');
      return null;
    });
  } catch (e) {
    debugPrint('Error creating user data stream: $e');
    return Stream.value(null);
  }
});

// オーナー設定（current）を取得
final ownerSettingsProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  try {
    return FirebaseFirestore.instance
        .collection('owner_settings')
        .doc('current')
        .snapshots()
        .map((snapshot) => snapshot.data())
        .handleError((error) {
      debugPrint('Error fetching owner settings: $error');
      return null;
    });
  } catch (e) {
    debugPrint('Error creating owner settings stream: $e');
    return Stream.value(null);
  }
});
