// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

import 'fake_appcast.dart';
import 'mock_itunes_client.dart';
import 'mock_play_store_client.dart';

void main() {
  test('UpgraderAppStore returns UpgraderVersionInfo', () async {
    final installedVersion = Version(1, 9, 6);
    final state = UpgraderState(
      debugLogging: true,
      client: MockITunesSearchClient.setupMockClient(),
      packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: installedVersion.toString(),
        buildNumber: '42',
      ),
      upgraderDevice: MockUpgraderDevice(),
      upgraderOS: MockUpgraderOS(ios: true),
    );

    final upgraderAppStore = UpgraderAppStore();

    final versionInfo = await upgraderAppStore.getVersionInfo(
      state: state,
      installedVersion: installedVersion,
      country: 'US',
      language: 'en',
    );

    // Assert
    expect(versionInfo.appStoreListingURL, 'https://example.com/app');
    expect(versionInfo.appStoreVersion, Version(5, 6, 0));
    expect(versionInfo.installedVersion, installedVersion);
    expect(versionInfo.isCriticalUpdate, isNull);
    expect(versionInfo.minAppVersion, isNull);
    expect(versionInfo.releaseNotes, 'Bug fixes.');
  });

  test('UpgraderPlayStore returns UpgraderVersionInfo', () async {
    final installedVersion = Version(1, 9, 6);
    final state = UpgraderState(
      debugLogging: true,
      client: await MockPlayStoreSearchClient.setupMockClient(),
      packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.kotoko.express',
        version: installedVersion.toString(),
        buildNumber: '42',
      ),
      upgraderDevice: MockUpgraderDevice(),
      upgraderOS: MockUpgraderOS(android: true),
    );

    final upgraderPlayStore = UpgraderPlayStore();

    // Act
    final versionInfo = await upgraderPlayStore.getVersionInfo(
      state: state,
      installedVersion: installedVersion,
      country: 'US',
      language: 'en',
    );

    // Assert
    expect(versionInfo.appStoreListingURL, isNotNull);
    expect(
        versionInfo.appStoreListingURL!.startsWith(
            'https://play.google.com/store/apps/details?id=com.kotoko.express&gl=US&hl=en&_cb='),
        isTrue);
    expect(versionInfo.appStoreVersion, Version(1, 23, 0));
    expect(versionInfo.installedVersion, equals(installedVersion));
    expect(versionInfo.isCriticalUpdate, isNull);
    expect(versionInfo.minAppVersion, isNull);
    expect(versionInfo.releaseNotes, 'Minor updates and improvements.');
  });

  test('UpgraderAppcastStore returns UpgraderVersionInfo', () async {
    final installedVersion = Version.parse('1.9.6');
    final state = UpgraderState(
      debugLogging: true,
      client: await MockPlayStoreSearchClient.setupMockClient(),
      packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.kotoko.express',
        version: installedVersion.toString(),
        buildNumber: '42',
      ),
      upgraderDevice: MockUpgraderDevice(),
      upgraderOS: MockUpgraderOS(android: true),
    );

    const appcastURL = 'https://sparkle-project.org/test/testappcast.xml';
    final fakeAppcast = FakeAppcast();

    final upgraderAppcastStore = UpgraderAppcastStore(
      appcastURL: appcastURL,
      appcast: fakeAppcast,
    );

    // Act
    final versionInfo = await upgraderAppcastStore.getVersionInfo(
      state: state,
      installedVersion: installedVersion,
      country: 'US',
      language: 'en',
    );

    // Assert
    expect(
        versionInfo.appStoreListingURL, equals('http://some.fakewebsite.com'));
    expect(versionInfo.appStoreVersion, equals(Version.parse('1.0.0')));
    expect(versionInfo.installedVersion, installedVersion);
    expect(versionInfo.isCriticalUpdate, isNull);
    expect(versionInfo.releaseNotes, isNull);
  });
}
