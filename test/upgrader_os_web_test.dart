/*
 * Copyright (c) 2026 Larry Aasen. All rights reserved.
 */

@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

@JS('navigator.appVersion')
external String get _navigatorAppVersion;

/// Tests the real browser backend of [UpgraderOS].
/// Run with: flutter test --platform chrome test/upgrader_os_web_test.dart
void main() {
  test('UpgraderOS reports the browser on web', () {
    final upgraderOS = UpgraderOS();

    expect(upgraderOS.operatingSystem, 'browser');
    expect(upgraderOS.operatingSystemVersion, isNotEmpty);
    expect(upgraderOS.operatingSystemVersion, _navigatorAppVersion);

    expect(upgraderOS.isWeb, isTrue);
    expect(upgraderOS.isAndroid, isFalse);
    expect(upgraderOS.isFuchsia, isFalse);
    expect(upgraderOS.isIOS, isFalse);
    expect(upgraderOS.isLinux, isFalse);
    expect(upgraderOS.isMacOS, isFalse);
    expect(upgraderOS.isWindows, isFalse);

    expect(upgraderOS.current, 'web');
    expect(upgraderOS.currentOSType, UpgraderOSType.web);
  });
}
