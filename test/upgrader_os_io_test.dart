/*
 * Copyright (c) 2026 Larry Aasen. All rights reserved.
 */

@TestOn('vm')
library;

import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

/// Tests the real `dart:io` backend of [UpgraderOS].
void main() {
  test('UpgraderOS matches dart:io Platform', () {
    final upgraderOS = UpgraderOS();

    expect(upgraderOS.operatingSystem, Platform.operatingSystem);
    expect(upgraderOS.operatingSystemVersion, Platform.operatingSystemVersion);

    expect(upgraderOS.isWeb, isFalse);
    expect(upgraderOS.isAndroid, Platform.isAndroid);
    expect(upgraderOS.isFuchsia, Platform.isFuchsia);
    expect(upgraderOS.isIOS, Platform.isIOS);
    expect(upgraderOS.isLinux, Platform.isLinux);
    expect(upgraderOS.isMacOS, Platform.isMacOS);
    expect(upgraderOS.isWindows, Platform.isWindows);
  });
}
