/*
  Copyright (c) 2025 Larry Aasen. All rights reserved.
  Contributions by [MrRoy121 (2025), ].
*/

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Handler for Android in-app updates using the Play Core library.
/// This is only available on Android platform.
class InAppUpdate {
  static const MethodChannel _channel =
      MethodChannel('com.larryaasen.upgrader/in_app_update');

  /// Stream for update events from the platform side
  static final StreamController<InAppUpdateEvent> _eventStreamController =
      StreamController<InAppUpdateEvent>.broadcast();

  /// Stream to listen for update events
  static Stream<InAppUpdateEvent> get eventStream => _eventStreamController.stream;

  static bool _initialized = false;

  /// Initialize the in-app update handler
  static Future<void> initialize() async {
    if (_initialized) return;
    
    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;
  }

  /// Handle method calls from the platform side
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onUpdateDownloaded':
        _eventStreamController.add(InAppUpdateEvent.downloaded);
        break;
      case 'onUpdateInstalled':
        _eventStreamController.add(InAppUpdateEvent.installed);
        break;
      case 'onUpdateFailure':
        final errorCode = call.arguments['errorCode'] as int?;
        _eventStreamController.add(InAppUpdateEvent.failed);
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'The method ${call.method} is not implemented',
        );
    }
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
      try {
        final result = await _channel.invokeMethod<Map<Object?, Object?>>('checkForUpdate', {
          'immediateUpdate': immediateUpdate,
          'language': language,
        });
        
        if (result != null) {
          return InAppUpdateStatus.fromMap(result);
        }
      } on PlatformException catch (e) {
        debugPrint('InAppUpdate: Error checking for update: ${e.message}');
      }
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
      try {
        final result = await _channel.invokeMethod<bool>('completeUpdate');
        return result ?? false;
      } on PlatformException catch (e) {
        debugPrint('InAppUpdate: Error completing update: ${e.message}');
      }
    }
    return false;
  }

  /// Dispose the in-app update handler
  static void dispose() {
    _initialized = false;
  }
}

/// Status of an in-app update check
class InAppUpdateStatus {
  /// Whether an update is available
  final bool updateAvailable;
  
  /// Whether an immediate update is allowed
  final bool immediateUpdateAllowed;
  
  /// Whether a flexible update is allowed
  final bool flexibleUpdateAllowed;
  
  /// The version code of the update, if available
  final int? versionCode;

  InAppUpdateStatus({
    required this.updateAvailable,
    required this.immediateUpdateAllowed,
    required this.flexibleUpdateAllowed,
    this.versionCode,
  });

  /// Create an [InAppUpdateStatus] from a map
  factory InAppUpdateStatus.fromMap(Map<Object?, Object?> map) {
    return InAppUpdateStatus(
      updateAvailable: map['updateAvailable'] as bool? ?? false,
      immediateUpdateAllowed: map['immediateUpdateAllowed'] as bool? ?? false,
      flexibleUpdateAllowed: map['flexibleUpdateAllowed'] as bool? ?? false,
      versionCode: map['versionCode'] as int?,
    );
  }

  @override
  String toString() {
    return 'InAppUpdateStatus(updateAvailable: $updateAvailable, '
        'immediateUpdateAllowed: $immediateUpdateAllowed, '
        'flexibleUpdateAllowed: $flexibleUpdateAllowed, '
        'versionCode: $versionCode)';
  }
}

/// Events that can be received from the platform side during an in-app update
enum InAppUpdateEvent {
  /// The update has been downloaded and is ready to install
  downloaded,
  
  /// The update has been installed
  installed,
  
  /// The update failed
  failed,
}
