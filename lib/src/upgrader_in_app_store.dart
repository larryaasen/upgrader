/*
 * Copyright (c) 2025 Larry Aasen. All rights reserved.
 * Contributions by [MrRoy121 (2025), ].
 */

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

import '../upgrader.dart';

/// An implementation of [UpgraderStore] that uses the Android in-app update feature.
/// This is used on Android to trigger the native in-app update flow from Google Play.
class UpgraderInAppStore implements UpgraderStore {
  /// Creates a new instance of [UpgraderInAppStore].
  UpgraderInAppStore({
    this.shouldForceImmediateUpdate = false,
    this.language,
  });

  /// If true, the update will be an immediate update that interrupts the app.
  /// If false, the update will be a flexible update that allows the user to continue using the app.
  final bool shouldForceImmediateUpdate;

  /// The language code to use for the update UI. If null, the system locale will be used.
  final String? language;

  @override
  Future<UpgraderVersionInfo> getVersionInfo(
      {required UpgraderState state,
      required Version installedVersion,
      required String? country,
      required String? language}) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        // Initialize the in-app update
        await InAppUpdate.initialize();

        // Check if Play Store is available
        final isPlayStoreAvailable = await InAppUpdate.isPlayStoreAvailable();
        if (!isPlayStoreAvailable) {
          debugPrint('UpgraderInAppStore: Google Play Store not available');
          return UpgraderVersionInfo();
        }

        // Get the package info
        final packageInfo = await PackageInfo.fromPlatform();

        // Check for update
        final updateStatus = await InAppUpdate.checkForUpdate(
          immediateUpdate: shouldForceImmediateUpdate,
          language: language,
        );

        if (updateStatus.updateAvailable) {
          // If an update is available, return version info with the update details
          final version =
              updateStatus.versionCode != null ? Version(updateStatus.versionCode!, 0, 0) : Version(1, 0, 0);

          return UpgraderVersionInfo(
            appStoreVersion: version,
            // Set critical update if immediate update is required
            isCriticalUpdate: shouldForceImmediateUpdate || updateStatus.immediateUpdateAllowed,
          );
        }
      } catch (e) {
        debugPrint('UpgraderInAppStore: Error getting version info: $e');
      }
    }

    // Return empty version info if not on Android or if there was an error
    return UpgraderVersionInfo();
  }
}
