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

  /// Performs an immediate update that is entirely handled by the Play API.
  ///
  /// [checkForUpdate] has to be called first to be able to run this.
  static Future<void> performImmediateUpdate() async {
    return await _channel.invokeMethod('performImmediateUpdate');
  }

  /// Starts the download of the app update.
  ///
  /// Throws a [PlatformException] if the download fails.
  /// When the returned [Future] is completed without any errors,
  /// [completeFlexibleUpdate] can be called to install the update.
  ///
  /// [checkForUpdate] has to be called first to be able to run this.
  static Future<void> startFlexibleUpdate() async {
    return await _channel.invokeMethod('startFlexibleUpdate');
  }

  /// Installs the update downloaded via [startFlexibleUpdate].
  /// [startFlexibleUpdate] has to be completed successfully.
  static Future<void> completeFlexibleUpdate() async {
    return await _channel.invokeMethod('completeFlexibleUpdate');
  }
}