import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // 位置情報の取得
  static Future<Position?> getCurrentPosition() async {
    try {
      // 位置情報の権限を確認
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        throw Exception('位置情報の権限が許可されていません');
      }

      // 位置情報サービスが有効かチェック
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('位置情報サービスが無効です');
      }

      // 現在位置を取得
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      throw Exception('位置情報の取得に失敗しました: $e');
    }
  }

  // 位置情報の権限状態を確認
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // 位置情報の権限をリクエスト
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // 位置情報サービスが有効かチェック
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // 位置情報の変更を監視
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10メートル移動したら更新
      ),
    );
  }

  // 2点間の距離を計算（メートル）
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // 位置情報の権限状態を文字列で取得
  static String getPermissionStatusString(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return '位置情報の権限が拒否されています';
      case LocationPermission.deniedForever:
        return '位置情報の権限が永続的に拒否されています';
      case LocationPermission.whileInUse:
        return '位置情報の権限が許可されています（使用中のみ）';
      case LocationPermission.always:
        return '位置情報の権限が許可されています（常時）';
      case LocationPermission.unableToDetermine:
        return '位置情報の権限状態を確認できません';
    }
  }
}
