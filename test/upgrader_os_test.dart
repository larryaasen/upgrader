/*
 * Copyright (c) 2021-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  group('testing UpgraderOS', () {
    test('all methods work', () {
      final upgraderOS = UpgraderOS();
      expect(upgraderOS.operatingSystem, upgraderOS.operatingSystem);
      expect(
          upgraderOS.operatingSystemVersion, upgraderOS.operatingSystemVersion);
      expect(upgraderOS.isAndroid, upgraderOS.isAndroid);
      expect(upgraderOS.isFuchsia, upgraderOS.isFuchsia);
      expect(upgraderOS.isIOS, upgraderOS.isIOS);
      expect(upgraderOS.isLinux, upgraderOS.isLinux);
      expect(upgraderOS.isMacOS, upgraderOS.isMacOS);
      expect(upgraderOS.isWindows, upgraderOS.isWindows);
      expect(upgraderOS.isWeb, upgraderOS.isWeb);
    });
    test('no OS', () {
      final mock1 = MockUpgraderOS();
      expect(mock1.operatingSystem, '');
      expect(mock1.operatingSystemVersion, '');
      expect(mock1.isAndroid, false);
      expect(mock1.isFuchsia, false);
      expect(mock1.isIOS, false);
      expect(mock1.isLinux, false);
      expect(mock1.isMacOS, false);
      expect(mock1.isWindows, false);
      expect(mock1.isWeb, false);
    });
    test('Android', () {
      final mock2 = MockUpgraderOS(android: true);
      expect(mock2.operatingSystem, '');
      expect(mock2.operatingSystemVersion, '');
      expect(mock2.isAndroid, true);
      expect(mock2.isFuchsia, false);
      expect(mock2.isIOS, false);
      expect(mock2.isLinux, false);
      expect(mock2.isMacOS, false);
      expect(mock2.isWindows, false);
      expect(mock2.isWeb, false);
    });
    test('Fuchsia', () {
      final mock3 = MockUpgraderOS(fuchsia: true);
      expect(mock3.operatingSystem, '');
      expect(mock3.operatingSystemVersion, '');
      expect(mock3.isAndroid, false);
      expect(mock3.isFuchsia, true);
      expect(mock3.isIOS, false);
      expect(mock3.isLinux, false);
      expect(mock3.isMacOS, false);
      expect(mock3.isWindows, false);
      expect(mock3.isWeb, false);
    });
    test('iOS', () {
      final mock3 = MockUpgraderOS(ios: true);
      expect(mock3.operatingSystem, '');
      expect(mock3.operatingSystemVersion, '');
      expect(mock3.isAndroid, false);
      expect(mock3.isFuchsia, false);
      expect(mock3.isIOS, true);
      expect(mock3.isLinux, false);
      expect(mock3.isMacOS, false);
      expect(mock3.isWindows, false);
      expect(mock3.isWeb, false);
    });

    test('Linux', () {
      final mock3 = MockUpgraderOS(linux: true);
      expect(mock3.operatingSystem, '');
      expect(mock3.operatingSystemVersion, '');
      expect(mock3.isAndroid, false);
      expect(mock3.isFuchsia, false);
      expect(mock3.isIOS, false);
      expect(mock3.isLinux, true);
      expect(mock3.isMacOS, false);
      expect(mock3.isWindows, false);
      expect(mock3.isWeb, false);
    });
    test('macOS', () {
      final mock3 = MockUpgraderOS(macos: true);
      expect(mock3.operatingSystem, '');
      expect(mock3.operatingSystemVersion, '');
      expect(mock3.isAndroid, false);
      expect(mock3.isFuchsia, false);
      expect(mock3.isIOS, false);
      expect(mock3.isLinux, false);
      expect(mock3.isMacOS, true);
      expect(mock3.isWindows, false);
      expect(mock3.isWeb, false);
    });
    test('Windows', () {
      final mock3 = MockUpgraderOS(windows: true);
      expect(mock3.operatingSystem, '');
      expect(mock3.operatingSystemVersion, '');
      expect(mock3.isAndroid, false);
      expect(mock3.isFuchsia, false);
      expect(mock3.isIOS, false);
      expect(mock3.isLinux, false);
      expect(mock3.isMacOS, false);
      expect(mock3.isWindows, true);
      expect(mock3.isWeb, false);
    });
    test('Web', () {
      final mock3 = MockUpgraderOS(web: true);
      expect(mock3.operatingSystem, '');
      expect(mock3.operatingSystemVersion, '');
      expect(mock3.isAndroid, false);
      expect(mock3.isFuchsia, false);
      expect(mock3.isIOS, false);
      expect(mock3.isLinux, false);
      expect(mock3.isMacOS, false);
      expect(mock3.isWindows, false);
      expect(mock3.isWeb, true);
    });

    test('MockUpgraderOS current', () async {
      expect(MockUpgraderOS().current, '');
      expect(MockUpgraderOS(android: true).current, 'android');
      expect(MockUpgraderOS(fuchsia: true).current, 'fuchsia');
      expect(MockUpgraderOS(ios: true).current, 'ios');
      expect(MockUpgraderOS(linux: true).current, 'linux');
      expect(MockUpgraderOS(macos: true).current, 'macos');
      expect(MockUpgraderOS(web: true).current, 'web');
      expect(MockUpgraderOS(windows: true).current, 'windows');
    });

    test('MockUpgraderOS currentTypeFormatted', () async {
      expect(MockUpgraderOS().currentTypeFormatted, 'Android');
      expect(MockUpgraderOS(android: true).currentTypeFormatted, 'Android');
      expect(MockUpgraderOS(fuchsia: true).currentTypeFormatted, 'Fuchsia');
      expect(MockUpgraderOS(ios: true).currentTypeFormatted, 'iOS');
      expect(MockUpgraderOS(linux: true).currentTypeFormatted, 'Linux');
      expect(MockUpgraderOS(macos: true).currentTypeFormatted, 'macOS');
      expect(MockUpgraderOS(web: true).currentTypeFormatted, 'Web');
      expect(MockUpgraderOS(windows: true).currentTypeFormatted, 'Windows');
    });

    test('MockUpgraderOS currentOSType', () async {
      expect(MockUpgraderOS().currentOSType, UpgraderOSType.android);
      expect(
          MockUpgraderOS(android: true).currentOSType, UpgraderOSType.android);
      expect(
          MockUpgraderOS(fuchsia: true).currentOSType, UpgraderOSType.fuchsia);
      expect(MockUpgraderOS(ios: true).currentOSType, UpgraderOSType.ios);
      expect(MockUpgraderOS(linux: true).currentOSType, UpgraderOSType.linux);
      expect(MockUpgraderOS(macos: true).currentOSType, UpgraderOSType.macos);
      expect(MockUpgraderOS(web: true).currentOSType, UpgraderOSType.web);
      expect(
          MockUpgraderOS(windows: true).currentOSType, UpgraderOSType.windows);
    });
  });
}
