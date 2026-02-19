import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../stores/store_detail_view.dart';
import '../../widgets/custom_button.dart';
import '../../services/location_service.dart';
import '../../services/mission_service.dart';
import '../../providers/badge_provider.dart';

class DailyRecommendationView extends ConsumerStatefulWidget {
  const DailyRecommendationView({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyRecommendationView> createState() =>
      _DailyRecommendationViewState();
}

class _DailyRecommendationViewState
    extends ConsumerState<DailyRecommendationView> {
  final Map<String, String> _impressionIds = {};
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  bool _impressionsLogged = false;
  String? _error;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadRecommendedStores();

    // バッジカウンター: レコメンド閲覧
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      BadgeService().incrementBadgeCounter(userId, 'recommendViewed');
    }
  }

  Map<String, dynamic> _toStoreDetailStore(
    String id,
    Map<String, dynamic> data,
  ) {
    final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
    final phoneNumber = (data['phoneNumber'] ?? data['phone'] ?? '').toString();

    final rawBusinessHours = data['businessHours'];
    final businessHours = rawBusinessHours is Map
        ? Map<String, dynamic>.from(rawBusinessHours)
        : null;

    final rawTags = data['tags'];
    final tags = rawTags is List
        ? rawTags.map((tag) => tag.toString()).toList()
        : <String>[];

    final rawSocialMedia = data['socialMedia'];
    final socialMedia = rawSocialMedia is Map
        ? Map<String, dynamic>.from(rawSocialMedia)
        : <String, dynamic>{};

    final rawLocation = data['location'];
    Map<String, dynamic>? location;
    if (rawLocation is GeoPoint) {
      location = {
        'latitude': rawLocation.latitude,
        'longitude': rawLocation.longitude,
      };
    } else if (rawLocation is Map) {
      location = Map<String, dynamic>.from(rawLocation);
    }

    return {
      'id': id,
      'name': data['name'] ?? '店舗名なし',
      'category': data['category'] ?? 'その他',
      'subCategory': data['subCategory'] ?? '',
      'description': data['description'] ?? '',
      'address': data['address'] ?? '',
      'iconImageUrl': data['iconImageUrl'],
      'storeImageUrl': data['storeImageUrl'],
      'backgroundImageUrl': data['backgroundImageUrl'],
      'phone': phone,
      'phoneNumber': phoneNumber,
      'businessHours': businessHours,
      'isActive': data['isActive'] ?? true,
      'isApproved': data['isApproved'] ?? true,
      'location': location,
      'tags': tags,
      'socialMedia': socialMedia,
      'facilityInfo': data['facilityInfo'],
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
      'isVisited': false,
    };
  }

  Future<void> _loadRecommendedStores() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      final userProfile =
          user == null ? null : await _loadUserProfile(user.uid);
      final preferredCategories = await _loadPreferredCategories(userProfile);
      final regionKeywords = _buildRegionKeywords(userProfile);
      final visitedStoreIds =
          user == null ? <String>{} : await _loadVisitedStoreIds(user.uid);
      _currentPosition = await _tryGetCurrentPosition();

      final snapshot =
          await FirebaseFirestore.instance.collection('stores').limit(50).get();

      final List<Map<String, dynamic>> stores = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'];
        final isApproved = data['isApproved'];
        if (isActive == false || isApproved == false) {
          continue;
        }
        stores.add(_toStoreDetailStore(doc.id, data));
      }

      final selected = _selectRecommendedStores(
        stores: stores,
        preferredCategories: preferredCategories,
        regionKeywords: regionKeywords,
        visitedStoreIds: visitedStoreIds,
        currentPosition: _currentPosition,
      );

      if (!mounted) return;
      setState(() {
        _stores = selected;
        _isLoading = false;
      });

      try {
        await _recordImpressions(selected);
      } catch (_) {
        // インプレッション記録の失敗は店舗表示に影響させない
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _recordImpressions(List<Map<String, dynamic>> stores) async {
    if (_impressionsLogged) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || stores.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final store in stores) {
      final storeId = store['id']?.toString();
      if (storeId == null || storeId.isEmpty) continue;
      final reason = (store['recommendReason'] ?? 'general').toString();
      final distance = store['distanceMeters'];
      final docRef = FirebaseFirestore.instance
          .collection('recommendation_impressions')
          .doc();
      _impressionIds[storeId] = docRef.id;
      batch.set(docRef, {
        'userId': user.uid,
        'targetStoreId': storeId,
        'triggerType': 'daily_login_recommendation',
        'algorithmVersion': 'v1',
        'reason': reason,
        'shownAt': FieldValue.serverTimestamp(),
        if (distance is num) 'distanceMeters': distance,
      });
    }

    await batch.commit();
    _impressionsLogged = true;

    // デイリーミッション: レコメンドを見る
    MissionService().markDailyMission(user.uid, 'recommendation_view');
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      return await LocationService.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> _loadVisitedStoreIds(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stores')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> _loadUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _loadPreferredCategories(
      Map<String, dynamic>? userProfile) async {
    if (userProfile == null) return [];
    final favoriteRaw = userProfile['favoriteStoreIds'];
    if (favoriteRaw is! List) return [];
    final favoriteIds = favoriteRaw.whereType<String>().take(8).toList();
    if (favoriteIds.isEmpty) return [];

    final Map<String, int> counter = {};
    for (final storeId in favoriteIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
        if (!doc.exists) continue;
        final data = doc.data();
        final category = (data?['category'] ?? '').toString();
        if (category.isEmpty) continue;
        counter[category] = (counter[category] ?? 0) + 1;
      } catch (_) {}
    }

    final entries = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList();
  }

  List<String> _buildRegionKeywords(Map<String, dynamic>? userProfile) {
    if (userProfile == null) return [];
    final prefecture = (userProfile['prefecture'] ?? '').toString().trim();
    final city = (userProfile['city'] ?? '').toString().trim();
    final List<String> keywords = [];
    if (prefecture.isNotEmpty) keywords.add(prefecture);
    if (city.isNotEmpty) keywords.add(city);
    return keywords;
  }

  List<Map<String, dynamic>> _selectRecommendedStores({
    required List<Map<String, dynamic>> stores,
    required List<String> preferredCategories,
    required List<String> regionKeywords,
    required Set<String> visitedStoreIds,
    required Position? currentPosition,
  }) {
    if (stores.isEmpty) return [];
    final random = Random();

    final scored = stores.map((store) {
      final category = (store['category'] ?? '').toString();
      final address = (store['address'] ?? '').toString();
      final storeId = (store['id'] ?? '').toString();
      final distance =
          _calculateDistanceMeters(currentPosition, store['location']);
      final isNearby = distance != null && distance <= 3000;
      final isVeryNearby = distance != null && distance <= 1000;
      final isUnvisited =
          storeId.isNotEmpty && !visitedStoreIds.contains(storeId);
      final isCategoryMatch = preferredCategories.contains(category);
      final isRegionMatch = regionKeywords.isNotEmpty &&
          regionKeywords.any((keyword) => address.contains(keyword));
      int score = 0;
      if (isCategoryMatch) {
        score += 2;
      }
      if (isRegionMatch) {
        score += 1;
      }
      if (isUnvisited) {
        score += 2;
      } else if (storeId.isNotEmpty) {
        score -= 1;
      }
      if (distance != null) {
        if (isVeryNearby) {
          score += 3;
        } else if (isNearby) {
          score += 2;
        } else if (distance <= 5000) {
          score += 1;
        }
      }
      final reason = _buildRecommendReason(
        isNearby: isNearby,
        isVeryNearby: isVeryNearby,
        isCategoryMatch: isCategoryMatch,
        isRegionMatch: isRegionMatch,
        isUnvisited: isUnvisited,
      );

      return {
        ...store,
        'score': score,
        'recommendReason': reason,
        if (distance != null) 'distanceMeters': distance,
      };
    }).toList();

    scored.shuffle(random);
    scored.sort((a, b) {
      final scoreA = a['score'] as int? ?? 0;
      final scoreB = b['score'] as int? ?? 0;
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      final distanceA = a['distanceMeters'] as num?;
      final distanceB = b['distanceMeters'] as num?;
      if (distanceA != null && distanceB != null) {
        return distanceA.compareTo(distanceB);
      }
      if (distanceA != null) return -1;
      if (distanceB != null) return 1;
      return 0;
    });

    final selected = scored.take(3).toList();
    if (selected.length < 3) {
      final existingIds = selected.map((e) => e['id']).toSet();
      final fallback =
          stores.where((store) => !existingIds.contains(store['id'])).toList();
      fallback.shuffle(random);
      selected.addAll(fallback.take(3 - selected.length));
    }
    return selected;
  }

  double? _calculateDistanceMeters(Position? current, dynamic location) {
    if (current == null || location == null) return null;
    if (location is GeoPoint) {
      return LocationService.calculateDistance(
        current.latitude,
        current.longitude,
        location.latitude,
        location.longitude,
      );
    }
    if (location is Map) {
      final latValue = location['latitude'];
      final lngValue = location['longitude'];
      if (latValue is num && lngValue is num) {
        return LocationService.calculateDistance(
          current.latitude,
          current.longitude,
          latValue.toDouble(),
          lngValue.toDouble(),
        );
      }
    }
    return null;
  }

  String _buildRecommendReason({
    required bool isNearby,
    required bool isVeryNearby,
    required bool isCategoryMatch,
    required bool isRegionMatch,
    required bool isUnvisited,
  }) {
    if (isVeryNearby && isCategoryMatch) {
      return 'nearby_category_match';
    }
    if (isVeryNearby && isUnvisited) {
      return 'nearby_unvisited';
    }
    if (isNearby) {
      return 'nearby';
    }
    if (isCategoryMatch) {
      return 'category_match';
    }
    if (isRegionMatch) {
      return 'region_match';
    }
    if (isUnvisited) {
      return 'unvisited';
    }
    return 'general';
  }

  Future<void> _handleStoreTap(Map<String, dynamic> store) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final storeId = store['id']?.toString();
      if (storeId != null && storeId.isNotEmpty) {
        final distance = store['distanceMeters'];
        await FirebaseFirestore.instance
            .collection('recommendation_clicks')
            .add({
          'userId': user.uid,
          'targetStoreId': storeId,
          'triggerType': 'daily_login_recommendation',
          'impressionId': _impressionIds[storeId],
          'clickedAt': FieldValue.serverTimestamp(),
          if (distance is num) 'distanceMeters': distance,
        });
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoreDetailView(store: store),
      ),
    );
  }

  void _finishFlow() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
        : _error != null
            ? Center(
                child: Text(
                  'おすすめ店舗の取得に失敗しました',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : _stores.isEmpty
                ? const Center(
                    child: Text(
                      'おすすめ店舗が見つかりませんでした',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final store = _stores[index];
                      final name = (store['name'] ?? '').toString();
                      final description =
                          (store['description'] ?? '').toString();
                      final hours =
                          _formatBusinessHours(store['businessHours']);
                      final iconUrl = (store['iconImageUrl'] ?? '').toString();
                      final imageUrl = (store['storeImageUrl'] ??
                              store['backgroundImageUrl'] ??
                              '')
                          .toString();
                      final reason =
                          (store['recommendReason'] ?? '').toString();
                      final distance = store['distanceMeters'];
                      final tags = _buildReasonTags(reason, distance);
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStoreImage(imageUrl),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      _buildStoreIcon(iconUrl),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hours.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      hours,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (tags.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children:
                                          tags.map(_buildTagChip).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  CustomButton(
                                    text: '詳細を見る',
                                    backgroundColor: Colors.blue,
                                    onPressed: () => _handleStoreTap(store),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'おすすめのお店',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '気になるお店をチェックしてみましょう',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: '閉じる',
                onPressed: _finishFlow,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildReasonTags(String reason, dynamic distance) {
    final List<String> tags = [];
    final distanceMeters = distance is num ? distance.toDouble() : null;
    if (distanceMeters != null) {
      if (distanceMeters <= 1000) {
        tags.add('近く');
      } else if (distanceMeters <= 3000) {
        tags.add('近距離');
      }
    }
    switch (reason) {
      case 'nearby_category_match':
        tags.add('好み');
        break;
      case 'nearby_unvisited':
        tags.add('未訪問');
        break;
      case 'category_match':
        tags.add('好み');
        break;
      case 'region_match':
        tags.add('エリア');
        break;
      case 'unvisited':
        tags.add('未訪問');
        break;
      default:
        break;
    }
    return tags;
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFF6B35),
        ),
      ),
    );
  }

  String _formatBusinessHours(dynamic businessHours) {
    if (businessHours is String) {
      return businessHours.trim();
    }
    if (businessHours is! Map) {
      return '';
    }

    const dayNames = {
      'monday': '月',
      'tuesday': '火',
      'wednesday': '水',
      'thursday': '木',
      'friday': '金',
      'saturday': '土',
      'sunday': '日',
    };

    String? openTime;
    String? closeTime;
    final List<String> closedDays = [];

    for (final entry in dayNames.entries) {
      final dayData = businessHours[entry.key];
      if (dayData is! Map) {
        continue;
      }
      final isOpen = dayData['isOpen'] == true;
      final dayOpen = (dayData['open'] ?? '').toString();
      final dayClose = (dayData['close'] ?? '').toString();
      if (!isOpen) {
        closedDays.add(entry.value);
        continue;
      }
      if (openTime == null &&
          closeTime == null &&
          dayOpen.isNotEmpty &&
          dayClose.isNotEmpty) {
        openTime = dayOpen;
        closeTime = dayClose;
      }
    }

    if (openTime == null || closeTime == null) {
      return '';
    }

    final closedText =
        closedDays.isEmpty ? '定休日なし' : '${closedDays.join('、')}定休日';
    return '$openTime〜$closeTime（$closedText）';
  }

  Widget _buildStoreImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.photo, size: 48, color: Colors.grey),
      );
    }
    return Image.network(
      imageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.photo, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildStoreIcon(String iconUrl) {
    if (iconUrl.isEmpty) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFFFF6B35),
        child: Icon(Icons.store, color: Colors.white, size: 18),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey[200],
      backgroundImage: NetworkImage(iconUrl),
      onBackgroundImageError: (_, __) {},
    );
  }
}
