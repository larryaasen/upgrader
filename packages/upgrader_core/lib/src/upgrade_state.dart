import 'package:http/http.dart' as http;
import 'package:version/version.dart';

import 'upgrade_platform.dart';
import 'upgrader_package_info.dart';
import 'upgrader_version_info.dart';

class UpgraderState {
  UpgraderState({
    required this.client,
    this.clientHeaders,
    this.countryCodeOverride,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.debugLogging = false,
    this.durationUntilAlertAgain = const Duration(days: 3),
    this.languageCodeOverride,
    this.minAppVersion,
    this.packageInfo,
    this.showOnlyMandatoryUpdates = false,
    required this.upgraderPlatform,
    this.versionInfo,
  });

  final http.Client client;
  final Map<String, String>? clientHeaders;
  final String? countryCodeOverride;
  final bool debugDisplayAlways;
  final bool debugDisplayOnce;
  final bool debugLogging;
  final Duration durationUntilAlertAgain;
  final String? languageCodeOverride;
  final Version? minAppVersion;
  final UpgraderPackageInfo? packageInfo;
  final bool showOnlyMandatoryUpdates;
  final UpgraderPlatform upgraderPlatform;
  final UpgraderVersionInfo? versionInfo;

  UpgraderState copyWith({
    http.Client? client,
    Map<String, String>? clientHeaders,
    String? countryCodeOverride,
    bool? debugDisplayAlways,
    bool? debugDisplayOnce,
    bool? debugLogging,
    Duration? durationUntilAlertAgain,
    String? languageCodeOverride,
    Version? minAppVersion,
    UpgraderPackageInfo? packageInfo,
    bool? showOnlyMandatoryUpdates,
    UpgraderPlatform? upgraderPlatform,
    UpgraderVersionInfo? versionInfo,
  }) {
    return UpgraderState(
      client: client ?? this.client,
      clientHeaders: clientHeaders ?? this.clientHeaders,
      countryCodeOverride: countryCodeOverride ?? this.countryCodeOverride,
      debugDisplayAlways: debugDisplayAlways ?? this.debugDisplayAlways,
      debugDisplayOnce: debugDisplayOnce ?? this.debugDisplayOnce,
      debugLogging: debugLogging ?? this.debugLogging,
      durationUntilAlertAgain:
          durationUntilAlertAgain ?? this.durationUntilAlertAgain,
      languageCodeOverride: languageCodeOverride ?? this.languageCodeOverride,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      packageInfo: packageInfo ?? this.packageInfo,
      showOnlyMandatoryUpdates:
          showOnlyMandatoryUpdates ?? this.showOnlyMandatoryUpdates,
      upgraderPlatform: upgraderPlatform ?? this.upgraderPlatform,
      versionInfo: versionInfo ?? this.versionInfo,
    );
  }

  UpgraderState copyWithNull({
    bool? countryCodeOverride,
    bool? languageCodeOverride,
    bool? minAppVersion,
    bool? packageInfo,
    bool? versionInfo,
  }) {
    return UpgraderState(
      client: client,
      clientHeaders: clientHeaders,
      countryCodeOverride:
          countryCodeOverride == true ? null : this.countryCodeOverride,
      debugDisplayAlways: debugDisplayAlways,
      debugDisplayOnce: debugDisplayOnce,
      debugLogging: debugLogging,
      durationUntilAlertAgain: durationUntilAlertAgain,
      languageCodeOverride:
          languageCodeOverride == true ? null : this.languageCodeOverride,
      minAppVersion: minAppVersion == true ? null : this.minAppVersion,
      packageInfo: packageInfo == true ? null : this.packageInfo,
      showOnlyMandatoryUpdates: showOnlyMandatoryUpdates,
      upgraderPlatform: upgraderPlatform,
      versionInfo: versionInfo == true ? null : this.versionInfo,
    );
  }
}
