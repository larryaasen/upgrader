/*
 * Copyright (c) 2025 Larry Aasen. All rights reserved.
 * Contributions by [MrRoy121 (2025), ].
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

class MockUpgraderOS extends UpgraderOS {
  MockUpgraderOS({
    this.android = false,
    this.fuchsia = false,
    this.ios = false,
    this.linux = false,
    this.macos = false,
    this.web = false,
    this.windows = false,
    this.customOS = '',
    this.customOSVersion = '',
  });

  final bool android;
  final bool fuchsia;
  final bool ios;
  final bool linux;
  final bool macos;
  final bool web;
  final bool windows;
  final String customOS;
  final String customOSVersion;

  @override
  String get operatingSystem => customOS;

  @override
  String get operatingSystemVersion => customOSVersion;

  @override
  bool get isAndroid => android;

  @override
  bool get isFuchsia => fuchsia;

  @override
  bool get isIOS => ios;

  @override
  bool get isLinux => linux;

  @override
  bool get isMacOS => macos;

  @override
  bool get isWeb => web;

  @override
  bool get isWindows => windows;
}

void main() {
  group('UpgraderOS InAppUpdate Tests', () {
    test('UpgraderOS correctly identifies Android platform for in-app updates', () {
      final androidOS = MockUpgraderOS(android: true);
      final iosOS = MockUpgraderOS(ios: true);
      final webOS = MockUpgraderOS(web: true);
      
      expect(androidOS.isAndroid, true);
      expect(iosOS.isAndroid, false);
      expect(webOS.isAndroid, false);
    });
    
    test('UpgraderOS provides correct current platform for in-app update decisions', () {
      final androidOS = MockUpgraderOS(android: true);
      final iosOS = MockUpgraderOS(ios: true);
      
      expect(androidOS.current, 'android');
      expect(iosOS.current, 'ios');
    });
    
    test('UpgraderOS provides correct formatted platform name', () {
      final androidOS = MockUpgraderOS(android: true);
      final iosOS = MockUpgraderOS(ios: true);
      
      expect(androidOS.currentTypeFormatted, 'Android');
      expect(iosOS.currentTypeFormatted, 'iOS');
    });
    
    test('UpgraderOS provides correct OS type enum', () {
      final androidOS = MockUpgraderOS(android: true);
      final iosOS = MockUpgraderOS(ios: true);
      
      expect(androidOS.currentOSType, UpgraderOSType.android);
      expect(iosOS.currentOSType, UpgraderOSType.ios);
    });
  });
}
