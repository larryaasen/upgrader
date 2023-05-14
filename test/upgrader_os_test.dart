/*
 * Copyright (c) 2021-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  test('testing UpgraderOS', () async {
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

  test('testing UpgraderOS current', () async {
    // FYI: Platform.operatingSystem can be "macos" or "linux" in a unit test.
    final upgraderOS = UpgraderOS();
    expect(upgraderOS.current, 'macos');
  });

  test('testing MockUpgraderOS current', () async {
    expect(MockUpgraderOS().current, '');
    expect(MockUpgraderOS(android: true).current, 'android');
    expect(MockUpgraderOS(fuchsia: true).current, 'fuchsia');
    expect(MockUpgraderOS(ios: true).current, 'ios');
    expect(MockUpgraderOS(linux: true).current, 'linux');
    expect(MockUpgraderOS(macos: true).current, 'macos');
    expect(MockUpgraderOS(web: true).current, 'web');
    expect(MockUpgraderOS(windows: true).current, 'windows');
  });
}
