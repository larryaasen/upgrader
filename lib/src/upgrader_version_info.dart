// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:version/version.dart';

class UpgraderVersionInfo {
  final String? appStoreListingURL;
  final Version? appStoreVersion;
  final Version? appStoreDisplayVersion;
  final Version? installedVersion;
  final bool? isCriticalUpdate;
  final Version? minAppVersion;
  final String? releaseNotes;

  UpgraderVersionInfo({
    this.appStoreListingURL,
    this.appStoreVersion,
    this.appStoreDisplayVersion,
    this.installedVersion,
    this.isCriticalUpdate,
    this.minAppVersion,
    this.releaseNotes,
  });

  @override
  String toString() {
    return 'appStoreListingURL: $appStoreListingURL, '
        'appStoreVersion: $appStoreVersion, '
        'appStoreDisplayVersion: $appStoreDisplayVersion, '
        'installedVersion: $installedVersion, '
        'isCriticalUpdate: $isCriticalUpdate, '
        'minAppVersion: $minAppVersion, '
        'releaseNotes: $releaseNotes';
  }
}
