import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PostView extends StatefulWidget {
  final bool isShowCouponView;
  final Function(bool) onCouponViewChanged;

  const PostView({
    super.key,
    required this.isShowCouponView,
    required this.onCouponViewChanged,
  });

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  Tab _selectedTab = Tab.post;
  
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;
  
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoadingCoupons = true;

  @override
  void initState() {
    super.initState();
    if (widget.isShowCouponView) {
      _selectedTab = Tab.coupon;
    } else {
      _selectedTab = Tab.post;
    }
    _loadPosts();
    _loadCoupons();
  }
  
  @override
  void didUpdateWidget(PostView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShowCouponView != oldWidget.isShowCouponView) {
      setState(() {
        if (widget.isShowCouponView) {
          _selectedTab = Tab.coupon;
        } else {
          _selectedTab = Tab.post;
        }
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPosts();
  }
  
  Future<void> _loadPosts() async {
    try {
      print('投稿一覧読み込み開始');
      
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      print('投稿一覧取得数: ${postsSnapshot.docs.length}');

      if (mounted) {
        setState(() {
          _posts = postsSnapshot.docs
              .where((doc) {
                final data = doc.data();
                return (data['isActive'] ?? false) == true && 
                       (data['isPublished'] ?? false) == true;
              })
              .map((doc) {
                final data = doc.data();
                return {
                  'postId': data['postId'] ?? doc.id,
                  'title': data['title'] ?? 'タイトルなし',
                  'content': data['content'] ?? '',
                  'storeName': data['storeName'] ?? '店舗名なし',
                  'category': data['category'] ?? 'お知らせ',
                  'createdAt': data['createdAt'],
                  'imageUrls': data['imageUrls'] ?? [],
                  'images': data['images'] ?? [],
                  'imageCount': data['imageCount'] ?? 0,
                  'storeIconImageUrl': data['storeIconImageUrl'],
                };
              })
              .toList();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('投稿一覧読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }
  
  Future<void> _loadCoupons() async {
    try {
      print('クーポン一覧読み込み開始');
      
      final couponsSnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      print('クーポン一覧取得数: ${couponsSnapshot.docs.length}');

      if (mounted) {
        setState(() {
          _coupons = couponsSnapshot.docs.map((doc) {
            final data = doc.data();
            final endDate = data['endDate'];
            final now = DateTime.now();
            
            bool isAvailable = false;
            DateTime? startDateTime;
            DateTime? endDateTime;
            
            try {
              if (data['startDate'] != null) {
                startDateTime = (data['startDate'] as Timestamp).toDate();
              }
              
              if (endDate != null) {
                endDateTime = (endDate as Timestamp).toDate();
              }
              
              final today = DateTime(now.year, now.month, now.day);
              
              if (startDateTime != null && endDateTime != null) {
                final startDateOnly = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
                final endDateOnly = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
                isAvailable = today.isAfter(startDateOnly.subtract(const Duration(days: 1))) && 
                             today.isBefore(endDateOnly.add(const Duration(days: 1)));
              } else if (startDateTime != null) {
                final startDateOnly = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
                isAvailable = today.isAfter(startDateOnly.subtract(const Duration(days: 1)));
              } else if (endDateTime != null) {
                final endDateOnly = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
                isAvailable = today.isBefore(endDateOnly.add(const Duration(days: 1)));
              } else {
                isAvailable = true;
              }
              
              if (isAvailable) {
                final usedUserIds = List<String>.from(data['usedUserIds'] ?? []);
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && usedUserIds.contains(currentUser.uid)) {
                  isAvailable = false;
                }
              }
            } catch (e) {
              print('日付変換エラー: $e');
              isAvailable = false;
            }
            
            return {
              'couponId': doc.id,
              'title': data['title'] ?? 'タイトルなし',
              'description': data['description'] ?? '',
              'discountType': data['discountType'] ?? '割引率',
              'discountValue': data['discountValue'] ?? '',
              'startDate': data['startDate'],
              'endDate': data['endDate'],
              'startDateTime': startDateTime,
              'endDateTime': endDateTime,
              'imageUrl': data['imageUrl'],
              'storeName': data['storeName'] ?? '店舗名なし',
              'conditions': data['conditions'] ?? '',
              'isAvailable': isAvailable,
            };
          })
          .where((coupon) => coupon['isAvailable'] == true)
          .toList()
          ..sort((a, b) {
            final aEndDate = a['endDateTime'] as DateTime?;
            final bEndDate = b['endDateTime'] as DateTime?;
            
            if (aEndDate == null && bEndDate == null) return 0;
            if (aEndDate == null) return 1;
            if (bEndDate == null) return -1;
            
            return aEndDate.compareTo(bEndDate);
          });
          _isLoadingCoupons = false;
        });
      }
    } catch (e) {
      print('クーポン一覧読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingCoupons = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '投稿・クーポン',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCustomTabBar(Tab.post, '投稿', Icons.grid_on),
              ),
              Expanded(
                child: _buildCustomTabBar(Tab.coupon, 'クーポン', Icons.qr_code),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _selectedTab == Tab.post
                ? _buildPostView()
                : _buildCouponView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(Tab tab, String text, IconData icon) {
    bool isSelected = _selectedTab == tab;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            child: Icon(
              icon,
              color: isSelected 
                  ? const Color(0xFFFF6B35)
                  : Colors.black.withOpacity(0.3),
              size: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected 
                  ? const Color(0xFFFF6B35)
                  : Colors.black.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            color: isSelected 
                ? const Color(0xFFFF6B35)
                : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildPostView() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }
    
    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          '投稿がありません',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 170 / 325,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_posts[index]);
      },
    );
  }

  Widget _buildCouponView() {
    if (_isLoadingCoupons) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }
    
    if (_coupons.isEmpty) {
      return const Center(
        child: Text(
          '利用可能なクーポンがありません',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 170 / 280,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _coupons.length,
      itemBuilder: (context, index) {
        return _buildCouponCard(_coupons[index]);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    String formatDate() {
      final createdAt = post['createdAt'];
      if (createdAt == null) return '日付不明';
      
      try {
        final date = (createdAt as Timestamp).toDate();
        return '${date.year}年${date.month}月${date.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    Widget buildImage() {
      final imageUrls = post['imageUrls'] as List?;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final imageUrl = imageUrls[0] as String;
        
        if (imageUrl.startsWith('data:image/')) {
          try {
            final base64String = imageUrl.split(',')[1];
            final imageBytes = base64Decode(base64String);
            return ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                imageBytes,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            );
          } catch (e) {
            print('Base64デコードエラー: $e');
          }
        } else {
          print('投稿一覧でFirebase Storage URL検出: $imageUrl');
          
          try {
            if (imageUrl.isEmpty || !Uri.tryParse(imageUrl)!.isAbsolute) {
              print('無効な画像URL: $imageUrl');
              return _buildDefaultImage();
            }
            
            return ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: FutureBuilder<Widget>(
                future: _loadImageWithFallback(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    print('画像読み込みエラー: $imageUrl, エラー: ${snapshot.error}');
                    return _buildDefaultImage();
                  }
                  
                  return snapshot.data!;
                },
              ),
            );
          } catch (e) {
            print('画像読み込みで例外が発生: $e');
            return _buildDefaultImage();
          }
        }
      }
      
      final images = post['images'] as List?;
      if (images != null && images.isNotEmpty) {
        try {
          final base64String = images[0] as String;
          final imageBytes = base64Decode(base64String);
          return ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.memory(
              imageBytes,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          );
        } catch (e) {
          print('旧形式画像デコードエラー: $e');
        }
      }
      
      return _buildDefaultImage();
    }
    
    return GestureDetector(
      onTap: () {
        final postId = post['postId'];
        if (postId != null) {
          print('投稿詳細に遷移: $postId');
        }
      },
      child: Container(
        width: 170,
        height: 325,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              child: buildImage(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post['content'] ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 0.5,
              color: Colors.grey,
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: post['storeIconImageUrl'] != null
                          ? Image.network(
                              post['storeIconImageUrl'],
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  color: Colors.grey,
                                  size: 10,
                                );
                              },
                            )
                          : const Icon(
                              Icons.store,
                              color: Colors.grey,
                              size: 10,
                            ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      post['storeName'] ?? '店舗名なし',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  formatDate(),
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    String formatEndDate() {
      final endDate = coupon['endDate'];
      if (endDate == null) return '期限不明';
      
      try {
        final date = (endDate as Timestamp).toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(date.year, date.month, date.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${date.month}月${date.day}日';
        }
        
        return '$dateText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    String getDiscountText() {
      final discountType = coupon['discountType'] ?? '割引率';
      final discountValue = coupon['discountValue'] ?? '';
      
      if (discountType == '割引率') {
        return '$discountValue%OFF';
      } else if (discountType == '割引額') {
        return '${discountValue}円OFF';
      } else if (discountType == '固定価格') {
        return '${discountValue}円';
      }
      return '特典あり';
    }

    return GestureDetector(
      onTap: () {
        final couponId = coupon['couponId'];
        if (couponId != null) {
          print('クーポン詳細に遷移: $couponId');
        }
      },
      child: Container(
        width: 170,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: coupon['imageUrl'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        coupon['imageUrl'],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                formatEndDate(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                getDiscountText(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon['storeName'] ?? '店舗名なし',
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefaultImage() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.image,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
  
  Future<Widget> _loadImageWithFallback(String imageUrl) async {
    try {
      String optimizedUrl = _optimizeImageUrlForWeb(imageUrl);
      
      return FutureBuilder<Widget>(
        future: _tryMultipleImageLoadingMethods(optimizedUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFFF6B35),
                ),
              ),
            );
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            print('画像読み込みでエラー: ${snapshot.error}');
            return _buildDefaultImage();
          }
          
          return snapshot.data!;
        },
      );
    } catch (e) {
      print('画像読み込みで例外が発生: $e');
      return _buildDefaultImage();
    }
  }
  
  Future<Widget> _tryMultipleImageLoadingMethods(String imageUrl) async {
    try {
      return Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        cacheWidth: 300,
        cacheHeight: 300,
        errorBuilder: (context, error, stackTrace) {
          print('方法1でエラー: $error');
          return _buildDefaultImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFFFF6B35),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('方法1で例外: $e');
    }
    
    try {
      return GestureDetector(
        onTap: () {
          _openImageInNewTab(imageUrl);
        },
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 4),
              const Text(
                '画像をタップして表示',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('方法2で例外: $e');
    }
    
    return _buildDefaultImage();
  }
  
  void _openImageInNewTab(String imageUrl) {
    try {
      if (kIsWeb) {
        print('Web用画像表示: $imageUrl');
      }
    } catch (e) {
      print('画像表示でエラー: $e');
    }
  }
  
  String _createProxyUrl(String originalUrl) {
    return originalUrl;
  }
  
  String _optimizeImageUrlForWeb(String originalUrl) {
    try {
      if (originalUrl.contains('firebasestorage.googleapis.com')) {
        if (originalUrl.contains('?')) {
          return '$originalUrl&alt=media&token=${_extractToken(originalUrl)}';
        } else {
          return '$originalUrl?alt=media&token=${_extractToken(originalUrl)}';
        }
      }
      return originalUrl;
    } catch (e) {
      print('URL最適化でエラー: $e');
      return originalUrl;
    }
  }
  
  String _extractToken(String url) {
    try {
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      return token ?? '';
    } catch (e) {
      print('トークン抽出でエラー: $e');
      return '';
    }
  }
}

enum Tab {
  post,
  coupon,
}