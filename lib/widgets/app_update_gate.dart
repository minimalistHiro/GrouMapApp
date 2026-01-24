import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_info_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/owner_settings_provider.dart';
import 'custom_button.dart';

class AppUpdateGate extends ConsumerWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).maybeWhen(
          data: (user) => user?.uid,
          orElse: () => null,
        );
    if (userId != null) {
      final userData = ref.watch(userDataProvider(userId)).maybeWhen(
            data: (value) => value,
            orElse: () => null,
          );
      if (userData?['isOwner'] == true) {
        return child;
      }
    }
    final settings = ref.watch(ownerSettingsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    final resolvedSettings = _resolveCurrentSettings(settings);
    final minRequiredVersion =
        _parseString(resolvedSettings['userMinRequiredVersion']);
    if (minRequiredVersion == null || minRequiredVersion.isEmpty) {
      return child;
    }
    final appVersionAsync = ref.watch(appVersionProvider);
    return appVersionAsync.when(
      data: (currentVersion) {
        final isOutdated = _compareVersions(currentVersion, minRequiredVersion) < 0;
        if (!isOutdated) {
          return child;
        }
        final storeUrl = _resolveStoreUrl(resolvedSettings);
        return ForceUpdateScreen(
          currentVersion: currentVersion,
          minRequiredVersion: minRequiredVersion,
          latestVersion: _parseString(resolvedSettings['userLatestVersion']),
          storeUrl: storeUrl,
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => child,
    );
  }

  Map<String, dynamic> _resolveCurrentSettings(Map<String, dynamic>? ownerSettings) {
    final rawCurrent = ownerSettings?['current'];
    if (rawCurrent is Map<String, dynamic>) {
      return rawCurrent;
    }
    return ownerSettings ?? <String, dynamic>{};
  }

  String? _resolveStoreUrl(Map<String, dynamic> settings) {
    final iosUrl = _parseString(settings['userIosStoreUrl']);
    final androidUrl = _parseString(settings['userAndroidStoreUrl']);
    if (kIsWeb) {
      return androidUrl ?? iosUrl;
    }
    if (Platform.isIOS) {
      return iosUrl;
    }
    if (Platform.isAndroid) {
      return androidUrl;
    }
    return androidUrl ?? iosUrl;
  }

  String? _parseString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  int _compareVersions(String current, String required) {
    final currentParts = _parseVersionParts(current);
    final requiredParts = _parseVersionParts(required);
    final maxLength = currentParts.length > requiredParts.length
        ? currentParts.length
        : requiredParts.length;
    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final requiredValue = i < requiredParts.length ? requiredParts[i] : 0;
      if (currentValue != requiredValue) {
        return currentValue.compareTo(requiredValue);
      }
    }
    return 0;
  }

  List<int> _parseVersionParts(String version) {
    final cleaned = version.split('+').first.trim();
    final parts = cleaned.split('.');
    final values = <int>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed == null) {
        return const <int>[];
      }
      values.add(parsed);
    }
    return values;
  }
}

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.latestVersion,
    required this.storeUrl,
  });

  final String currentVersion;
  final String minRequiredVersion;
  final String? latestVersion;
  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    final targetVersion = latestVersion?.trim().isNotEmpty == true
        ? latestVersion!.trim()
        : minRequiredVersion;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update,
                  size: 72,
                  color: Color(0xFFE75B41),
                ),
                const SizedBox(height: 16),
                const Text(
                  'アップデートが必要です',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '最新バージョンへ更新してからご利用ください。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '現在: $currentVersion / 必須: $minRequiredVersion',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE75B41),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '最新: $targetVersion',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'ストアで更新',
                  onPressed: storeUrl == null ? null : () async => _openStore(context),
                  backgroundColor: const Color(0xFFE75B41),
                ),
                if (storeUrl == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'ストアURLが未設定です',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    if (storeUrl == null) {
      return;
    }
    final uri = Uri.tryParse(storeUrl!);
    if (uri == null || !(await canLaunchUrl(uri))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ストアURLを開けませんでした'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
