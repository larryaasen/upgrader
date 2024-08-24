// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/src/upgrader_version_info.dart';
import 'package:version/version.dart';

void main() {
  test('create_instance_with_all_parameters_null', () {
    UpgraderVersionInfo versionInfo = UpgraderVersionInfo(
      appStoreListingURL: null,
      appStoreVersion: null,
      installedVersion: null,
      isCriticalUpdate: null,
      minAppVersion: null,
      releaseNotes: null,
    );

    expect(versionInfo.appStoreListingURL, isNull);
    expect(versionInfo.appStoreVersion, isNull);
    expect(versionInfo.installedVersion, isNull);
    expect(versionInfo.isCriticalUpdate, isNull);
    expect(versionInfo.minAppVersion, isNull);
    expect(versionInfo.releaseNotes, isNull);
  });

  test('create_instance_with_all_parameters_valid', () {
    Version appStoreVersion = Version.parse('1.0.0');
    Version installedVersion = Version.parse('1.0.0');
    Version minAppVersion = Version.parse('1.0.0');

    UpgraderVersionInfo versionInfo = UpgraderVersionInfo(
      appStoreListingURL: 'https://example.com',
      appStoreVersion: appStoreVersion,
      installedVersion: installedVersion,
      isCriticalUpdate: true,
      minAppVersion: minAppVersion,
      releaseNotes: 'New features and bug fixes',
    );

    expect(versionInfo.appStoreListingURL, equals('https://example.com'));
    expect(versionInfo.appStoreVersion, equals(appStoreVersion));
    expect(versionInfo.installedVersion, equals(installedVersion));
    expect(versionInfo.isCriticalUpdate, isTrue);
    expect(versionInfo.minAppVersion, equals(minAppVersion));
    expect(versionInfo.releaseNotes, equals('New features and bug fixes'));
  });

  test('to_string_with_all_parameters_null', () {
    UpgraderVersionInfo versionInfo = UpgraderVersionInfo(
      appStoreListingURL: null,
      appStoreVersion: null,
      installedVersion: null,
      isCriticalUpdate: null,
      minAppVersion: null,
      releaseNotes: null,
    );

    String result = versionInfo.toString();

    expect(
        result,
        equals(
            'appStoreListingURL: null, appStoreVersion: null, installedVersion: null, isCriticalUpdate: null, minAppVersion: null, releaseNotes: null'));
  });
  test('create_instance_with_one_parameter_null', () {
    Version appStoreVersion = Version.parse('1.0.0');

    UpgraderVersionInfo versionInfo = UpgraderVersionInfo(
      appStoreListingURL: null,
      appStoreVersion: appStoreVersion,
      installedVersion: null,
      isCriticalUpdate: null,
      minAppVersion: null,
      releaseNotes: null,
    );

    expect(versionInfo.appStoreListingURL, isNull);
    expect(versionInfo.appStoreVersion, equals(appStoreVersion));
    expect(versionInfo.installedVersion, isNull);
    expect(versionInfo.isCriticalUpdate, isNull);
    expect(versionInfo.minAppVersion, isNull);
    expect(versionInfo.releaseNotes, isNull);
  });

  test('create_instance_with_valid_version_objects', () {
    Version appStoreVersion = Version.parse('1.0.0');
    Version installedVersion = Version.parse('1.0.0');
    Version minAppVersion = Version.parse('1.0.0');

    UpgraderVersionInfo versionInfo = UpgraderVersionInfo(
      appStoreListingURL: null,
      appStoreVersion: appStoreVersion,
      installedVersion: installedVersion,
      isCriticalUpdate: null,
      minAppVersion: minAppVersion,
      releaseNotes: null,
    );

    expect(versionInfo.appStoreListingURL, isNull);
    expect(versionInfo.appStoreVersion, equals(appStoreVersion));
    expect(versionInfo.installedVersion, equals(installedVersion));
    expect(versionInfo.isCriticalUpdate, isNull);
    expect(versionInfo.minAppVersion, equals(minAppVersion));
    expect(versionInfo.releaseNotes, isNull);
  });
}
