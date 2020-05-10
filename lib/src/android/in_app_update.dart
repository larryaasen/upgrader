import 'dart:async';

import 'package:flutter/services.dart';

import 'app_update_info.dart';

class InAppUpdate {
  static const MethodChannel _channel = const MethodChannel('in_app_update');

  /// Has to be called before being able to start any update.
  ///
  /// Returns [AppUpdateInfo], which can be used to decide if
  /// [startFlexibleUpdate] or [performImmediateUpdate] should be called.
  static Future<AppUpdateInfo> checkForUpdate() async {
    final result = await _channel.invokeMethod('checkForUpdate');
    return AppUpdateInfo(result['updateAvailable'], result['availableVersionCode']);
  }
}