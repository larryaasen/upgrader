/*
 * Copyright (c) 2021 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  test('testing UpgradeIO', () async {
    expect(UpgradeIO.isAndroid, UpgradeIO.isAndroid);
    expect(UpgradeIO.isIOS, UpgradeIO.isIOS);
    expect(UpgradeIO.isLinux, UpgradeIO.isLinux);
    expect(UpgradeIO.isMacOS, UpgradeIO.isMacOS);
    expect(UpgradeIO.isWindows, UpgradeIO.isWindows);
    expect(UpgradeIO.isFuchsia, UpgradeIO.isFuchsia);
    expect(UpgradeIO.isWeb, UpgradeIO.isWeb);
  });
}
