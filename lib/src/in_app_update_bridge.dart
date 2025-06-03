/*
  Copyright (c) 2025 Larry Aasen. All rights reserved.
  Contributions by [MrRoy121 (2025), ].
*/

import 'package:flutter/foundation.dart';

import '../upgrader.dart';

/// A bridge class that handles interactions with the In-App Update plugin.
/// This provides a clean separation between the upgrader package and the plugin implementation.
class InAppUpdateBridge {
  /// Initialize the in-app update bridge
  static Future<void> initialize() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await InAppUpdate.initialize();
    }
  }
  
  /// Check if Google Play Store is available on the device
  /// Returns true if Google Play Store is available and working
  static Future<bool> isPlayStoreAvailable() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await InAppUpdate.isPlayStoreAvailable();
    }
    return false;
  }
  
  /// Check if an update is available
  ///
  /// [immediateUpdate] If true, show the immediate update UI, otherwise show the flexible update UI
  /// [language] Optional language code to use for the update UI
  static Future<InAppUpdateStatus> checkForUpdate({
    required bool immediateUpdate,
    String? language,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await InAppUpdate.checkForUpdate(
        immediateUpdate: immediateUpdate,
        language: language,
      );
    }
    
    return InAppUpdateStatus(
      updateAvailable: false,
      immediateUpdateAllowed: false,
      flexibleUpdateAllowed: false,
    );
  }
  
  /// Complete the update. Call this when the update is downloaded and ready to install.
  /// This is only needed for flexible updates.
  static Future<bool> completeUpdate() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await InAppUpdate.completeUpdate();
    }
    return false;
  }
  
  /// Get the stream of in-app update events
  static Stream<InAppUpdateEvent> get eventStream {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return InAppUpdate.eventStream;
    }
    return Stream.empty();
  }
  
  /// Dispose the in-app update bridge
  static void dispose() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      InAppUpdate.dispose();
    }
  }
}
