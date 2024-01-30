// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

import 'upgrade_device.dart';
import 'upgrade_os.dart';
import 'upgrader_version_info.dart';

/// The [Upgrader] state.
class UpgraderState {
  /// Creates an [Upgrader] state.
  UpgraderState({
    required this.client,
    this.countryCodeOverride,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.debugLogging = false,
    this.languageCodeOverride,
    this.minAppVersion,
    this.packageInfo,
    required this.upgraderDevice,
    required this.upgraderOS,
    this.versionInfo,
  });

  /// Provide an HTTP Client that can be replaced during testing.
  final http.Client client;

  /// The country code that will override the system locale. Optional.
  final String? countryCodeOverride;

  /// For debugging, always force the upgrade to be available.
  final bool debugDisplayAlways;

  /// For debugging, display the upgrade at least once once.
  final bool debugDisplayOnce;

  /// Enable print statements for debugging.
  final bool debugLogging;

  /// The country code that will override the system locale. Optional. Used only for Android.
  final String? languageCodeOverride;

  /// The minimum app version supported by this app. Earlier versions of this app
  /// will be forced to update to the current version. Optional.
  final Version? minAppVersion;

  /// The app package metadata information.
  final PackageInfo? packageInfo;

  /// Provide [UpgraderDevice] that ca be replaced during testing.
  final UpgraderDevice upgraderDevice;

  /// Provides information on which OS this code is running on, and can be
  /// replaced during testing.
  final UpgraderOS upgraderOS;

  /// The latest version info for this app.
  final UpgraderVersionInfo? versionInfo;

  /// Creates a new state object by copying existing data and modifying selected fields.
  UpgraderState copyWith({
    http.Client? client,
    String? countryCodeOverride,
    bool? debugDisplayAlways,
    bool? debugDisplayOnce,
    bool? debugLogging,
    String? languageCodeOverride,
    Version? minAppVersion,
    PackageInfo? packageInfo,
    UpgraderDevice? upgraderDevice,
    UpgraderOS? upgraderOS,
    UpgraderVersionInfo? versionInfo,
  }) {
    return UpgraderState(
      client: client ?? this.client,
      countryCodeOverride: countryCodeOverride ?? this.countryCodeOverride,
      debugDisplayAlways: debugDisplayAlways ?? this.debugDisplayAlways,
      debugDisplayOnce: debugDisplayOnce ?? this.debugDisplayOnce,
      debugLogging: debugLogging ?? this.debugLogging,
      languageCodeOverride: languageCodeOverride ?? this.languageCodeOverride,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      packageInfo: packageInfo ?? this.packageInfo,
      upgraderDevice: upgraderDevice ?? this.upgraderDevice,
      upgraderOS: upgraderOS ?? this.upgraderOS,
      versionInfo: versionInfo ?? this.versionInfo,
    );
  }

  /// Creates a new state object by copying existing data and modifying selected fields,
  /// but true parameters will null out values in the state object.
  UpgraderState copyWithNull({
    bool? countryCodeOverride,
    bool? languageCodeOverride,
    bool? minAppVersion,
    bool? packageInfo,
    bool? versionInfo,
  }) {
    return UpgraderState(
      client: client,
      countryCodeOverride:
          countryCodeOverride == true ? null : this.countryCodeOverride,
      debugDisplayAlways: debugDisplayAlways,
      debugDisplayOnce: debugDisplayOnce,
      debugLogging: debugLogging,
      languageCodeOverride:
          languageCodeOverride == true ? null : this.languageCodeOverride,
      minAppVersion: minAppVersion == true ? null : this.minAppVersion,
      packageInfo: packageInfo == true ? null : this.packageInfo,
      upgraderDevice: upgraderDevice,
      upgraderOS: upgraderOS,
      versionInfo: versionInfo == true ? null : this.versionInfo,
    );
  }
}
