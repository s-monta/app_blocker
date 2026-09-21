import 'package:flutter/services.dart';

import 'models.dart';

class PlatformBridge {
  static const _channel = MethodChannel('jp.smonta.app_blocker/platform');

  static Future<List<InstalledApp>> installedApps() async {
    final raw =
        await _channel.invokeListMethod<Object?>('getInstalledApps') ?? [];
    return raw
        .map(
          (item) =>
              InstalledApp.fromMap(Map<Object?, Object?>.from(item! as Map)),
        )
        .toList();
  }

  static Future<bool> isAccessibilityEnabled() async =>
      await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;

  static Future<void> openAccessibilitySettings() =>
      _channel.invokeMethod<void>('openAccessibilitySettings');
}
