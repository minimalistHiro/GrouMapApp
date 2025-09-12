import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/store_model.dart';

// 現在位置プロバイダー
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    return await LocationService.getCurrentPosition();
  } catch (e) {
    throw Exception('位置情報の取得に失敗しました: $e');
  }
});

// 位置情報の権限状態プロバイダー
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  return await LocationService.checkPermission();
});

// 位置情報サービス有効状態プロバイダー
final locationServiceEnabledProvider = FutureProvider<bool>((ref) async {
  return await LocationService.isLocationServiceEnabled();
});

// 現在位置のストリームプロバイダー
final positionStreamProvider = StreamProvider<Position>((ref) {
  return LocationService.getPositionStream();
});

// 現在位置をStoreLocationに変換するプロバイダー
final currentStoreLocationProvider = FutureProvider<StoreLocation?>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) return null;
  
  return StoreLocation(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

// 位置情報の状態管理
class LocationState {
  final Position? currentPosition;
  final bool isLoading;
  final String? error;
  final bool hasPermission;

  const LocationState({
    this.currentPosition,
    this.isLoading = false,
    this.error,
    this.hasPermission = false,
  });

  LocationState copyWith({
    Position? currentPosition,
    bool? isLoading,
    String? error,
    bool? hasPermission,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  // 位置情報を取得
  Future<void> getCurrentPosition() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final position = await LocationService.getCurrentPosition();
      state = state.copyWith(
        currentPosition: position,
        isLoading: false,
        hasPermission: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasPermission: false,
      );
    }
  }

  // 位置情報の権限をリクエスト
  Future<void> requestPermission() async {
    try {
      final permission = await LocationService.requestPermission();
      state = state.copyWith(hasPermission: permission != LocationPermission.denied);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 位置情報サービスを有効にする
  Future<void> enableLocationService() async {
    try {
      final enabled = await LocationService.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 位置情報状態管理プロバイダー
final locationStateProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
