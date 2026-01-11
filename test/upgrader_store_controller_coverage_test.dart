// Copyright (c) 2026 Larry Aasen. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('UpgraderStoreController', () {
    test('getUpgraderStore returns correct store for each OS', () {
      final controller = UpgraderStoreController(
        onAndroid: () => UpgraderPlayStore(),
        onFuchsia: () => UpgraderPlayStore(),
        oniOS: () => UpgraderAppStore(),
        onLinux: () => UpgraderAppStore(),
        onMacOS: () => UpgraderAppStore(),
        onWeb: () => UpgraderAppStore(),
        onWindows: () => UpgraderAppStore(),
      );

      final androidOS = MockUpgraderOS(android: true);
      expect(controller.getUpgraderStore(androidOS), isA<UpgraderPlayStore>());

      final iosOS = MockUpgraderOS(ios: true);
      expect(controller.getUpgraderStore(iosOS), isA<UpgraderAppStore>());

      final fuchsiaOS = MockUpgraderOS(fuchsia: true);
      expect(controller.getUpgraderStore(fuchsiaOS), isA<UpgraderPlayStore>());

      final linuxOS = MockUpgraderOS(linux: true);
      expect(controller.getUpgraderStore(linuxOS), isA<UpgraderAppStore>());

      final macosOS = MockUpgraderOS(macos: true);
      expect(controller.getUpgraderStore(macosOS), isA<UpgraderAppStore>());

      final webOS = MockUpgraderOS(web: true);
      expect(controller.getUpgraderStore(webOS), isA<UpgraderAppStore>());

      final windowsOS = MockUpgraderOS(windows: true);
      expect(controller.getUpgraderStore(windowsOS), isA<UpgraderAppStore>());
    });
  });

  group('UpgraderAppStore', () {
    test('getVersionInfo handles invalid version string with debugLogging',
        () async {
      final store = UpgraderAppStore();
      final client = MockClient((request) async {
        return http.Response(
            '{"resultCount": 1, "results": [{"version": "invalid", "bundleId": "com.example.app"}]}',
            200);
      });

      final state = UpgraderState(
        client: client,
        debugLogging: true,
        packageInfo: PackageInfo(
            appName: 'App',
            packageName: 'com.example.app',
            version: '1.0.0',
            buildNumber: '1'),
        upgraderOS: MockUpgraderOS(ios: true),
      );

      final info = await store.getVersionInfo(
          state: state,
          installedVersion: Version.parse('1.0.0'),
          country: 'US',
          language: 'en');

      expect(info.appStoreVersion, isNull);
    });
  });
}
