import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader_core/upgrader_core.dart' as core;
import 'package:version/version.dart';

import 'upgrade_messages.dart';
import 'upgrade_os.dart';
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
    this.messages,
    this.minAppVersion,
    this.packageInfo,
    this.showOnlyMandatoryUpdates = false,
    required this.upgraderOS,
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
  final UpgraderMessages? messages;
  final Version? minAppVersion;
  final PackageInfo? packageInfo;
  final bool showOnlyMandatoryUpdates;
  final UpgraderOS upgraderOS;
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
    UpgraderMessages? messages,
    Version? minAppVersion,
    PackageInfo? packageInfo,
    bool? showOnlyMandatoryUpdates,
    UpgraderOS? upgraderOS,
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
      messages: messages ?? this.messages,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      packageInfo: packageInfo ?? this.packageInfo,
      showOnlyMandatoryUpdates:
          showOnlyMandatoryUpdates ?? this.showOnlyMandatoryUpdates,
      upgraderOS: upgraderOS ?? this.upgraderOS,
      versionInfo: versionInfo ?? this.versionInfo,
    );
  }

  UpgraderState copyWithNull({
    bool? countryCodeOverride,
    bool? languageCodeOverride,
    bool? messages,
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
      messages: messages == true ? null : this.messages,
      minAppVersion: minAppVersion == true ? null : this.minAppVersion,
      packageInfo: packageInfo == true ? null : this.packageInfo,
      showOnlyMandatoryUpdates: showOnlyMandatoryUpdates,
      upgraderOS: upgraderOS,
      versionInfo: versionInfo == true ? null : this.versionInfo,
    );
  }

  core.UpgraderState toCoreState() {
    return core.UpgraderState(
      client: client,
      clientHeaders: clientHeaders,
      countryCodeOverride: countryCodeOverride,
      debugDisplayAlways: debugDisplayAlways,
      debugDisplayOnce: debugDisplayOnce,
      debugLogging: debugLogging,
      durationUntilAlertAgain: durationUntilAlertAgain,
      languageCodeOverride: languageCodeOverride,
      minAppVersion: minAppVersion,
      packageInfo: packageInfo == null
          ? null
          : core.UpgraderPackageInfo(
              appName: packageInfo!.appName,
              packageName: packageInfo!.packageName,
              version: packageInfo!.version,
              buildNumber: packageInfo!.buildNumber,
            ),
      showOnlyMandatoryUpdates: showOnlyMandatoryUpdates,
      upgraderPlatform: upgraderOS.toCorePlatform(),
      versionInfo: versionInfo,
    );
  }
}
