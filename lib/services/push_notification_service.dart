import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Push notifications are not configured for web.');
      return;
    }

    try {
      await _messaging.setAutoInitEnabled(true);
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Push notifications initialized.');
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  void clearCurrentUser() {
    _currentUserId = null;
  }

  Future<void> registerForUser(String userId) async {
    _currentUserId = userId;
    await _ensureTokenListener();
    await _saveCurrentToken();
    await _subscribeToDefaultTopics();
  }

  Future<void> _ensureTokenListener() async {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      if (_currentUserId == null) {
        return;
      }
      _saveToken(_currentUserId!, token);
    });
  }

  Future<void> _saveCurrentToken() async {
    if (kIsWeb) {
      return;
    }
    final userId = _currentUserId ?? _auth.currentUser?.uid;
    if (userId == null) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token is empty for user $userId');
        return;
      }
      await _saveToken(userId, token);
    } catch (e) {
      debugPrint('Failed to get/save FCM token: $e');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('Saved FCM token for user $userId');
    } catch (e) {
      debugPrint('Failed to save FCM token for user $userId: $e');
    }
  }

  Future<void> _subscribeToDefaultTopics() async {
    try {
      await _messaging.subscribeToTopic('announcements');
      debugPrint('Subscribed to announcements topic.');
    } catch (e) {
      debugPrint('Failed to subscribe to announcements topic: $e');
    }
  }
}
