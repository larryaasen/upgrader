// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'upgrader_version_info.dart';

/// The [Upgrader] state.
class UpgraderState {
  /// Creates an [Upgrader] state.
  UpgraderState({
    required this.client,
    required this.debugLogging,
    this.packageInfo,
    this.versionInfo,
  });

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client client;

  /// Enable print statements for debugging.
  final bool debugLogging;

  /// The app package metadata information.
  final PackageInfo? packageInfo;

  /// The latest version info for this app.
  final UpgraderVersionInfo? versionInfo;

  /// Creates a new state object by copying existing data and modifying selected fields.
  UpgraderState copyWith({
    http.Client? client,
    bool? debugLogging,
    PackageInfo? packageInfo,
    UpgraderVersionInfo? versionInfo,
  }) {
    return UpgraderState(
      client: client ?? this.client,
      debugLogging: debugLogging ?? this.debugLogging,
      packageInfo: packageInfo ?? this.packageInfo,
      versionInfo: versionInfo ?? this.versionInfo,
    );
  }
}
