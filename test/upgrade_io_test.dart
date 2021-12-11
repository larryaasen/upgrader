/*
 * Copyright (c) 2021 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  test('testing UpgradeIO', () async {
    expect(UpgradeIO.isAndroid, isFalse);
    expect(UpgradeIO.isIOS, isFalse);
    expect(UpgradeIO.isLinux, isFalse);
    expect(UpgradeIO.isMacOS, isTrue);
    expect(UpgradeIO.isWindows, isFalse);
    expect(UpgradeIO.isFuchsia, isFalse);
    expect(UpgradeIO.isWeb, isFalse);
  });
}
