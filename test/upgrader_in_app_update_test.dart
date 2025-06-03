/*
 * Copyright (c) 2025 Larry Aasen. All rights reserved.
 * Contributions by [MrRoy121 (2025), ].
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'package:upgrader/src/upgrade_os.dart';
import 'package:upgrader/src/upgrade_device.dart';
import 'package:upgrader/src/upgrader_version_info.dart';
import 'package:version/version.dart';

// Mock classes for testing
class MockUpgraderOS extends UpgraderOS {
  MockUpgraderOS({this.android = false});

  final bool android;

  @override
  bool get isAndroid => android;
}

class MockUpgraderDevice extends UpgraderDevice {
  Future<bool> isRunningOnPhysicalDevice() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Upgrader In-App Update Integration', () {
    late MethodChannel channel;
    final List<MethodCall> log = <MethodCall>[];

    // Setup SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    setUp(() async {
      channel = MethodChannel('com.larryaasen.upgrader/in_app_update');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'isPlayStoreAvailable':
              return true;
            case 'checkForUpdate':
              return {
                'updateAvailable': true,
                'immediateUpdateAllowed': true,
                'flexibleUpdateAllowed': true,
                'versionCode': 100
              };
            case 'completeUpdate':
              return true;
            default:
              return null;
          }
        },
      );

      // Mock the PackageInfo for tests
      PackageInfo.setMockInitialValues(
        appName: 'Upgrader Test',
        packageName: 'com.larryaasen.upgrader.test',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
        installerStore: null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      log.clear();
    });

    test('Upgrader with useInAppUpdate=true on Android triggers in-app update', () async {
      // Create Upgrader with useInAppUpdate enabled and mock Android OS
      final upgrader = Upgrader(
        useInAppUpdate: true,
        upgraderOS: MockUpgraderOS(android: true),
        upgraderDevice: MockUpgraderDevice(),
        debugLogging: true,
      );

      // Skip initialize and set initialized directly to avoid shared preferences issues
      upgrader.updateState(upgrader.state.copyWith());

      // Call sendUserToAppStore which should trigger in-app update on Android
      await upgrader.sendUserToAppStore();

      // Verify that checkForUpdate was called
      expect(log.isNotEmpty, true);
      expect(log.any((call) => call.method == 'checkForUpdate'), true);
    });

    test('Upgrader with useInAppUpdate=false on Android does not trigger in-app update', () async {
      // Create Upgrader with useInAppUpdate disabled and mock Android OS
      final upgrader = Upgrader(
        useInAppUpdate: false,
        upgraderOS: MockUpgraderOS(android: true),
        upgraderDevice: MockUpgraderDevice(),
        debugLogging: true,
      );

      final mockPackageInfo = await PackageInfo.fromPlatform();
      // Skip initialize and set initialized directly to avoid shared preferences issues
      upgrader.updateState(upgrader.state.copyWith(packageInfo: mockPackageInfo));

      // Call sendUserToAppStore which should not trigger in-app update
      await upgrader.sendUserToAppStore();

      // Verify that checkForUpdate was not called
      expect(log.isEmpty, true);
    });

    test('Upgrader with useInAppUpdate=true on non-Android platform does not trigger in-app update', () async {
      final originalPlatform = defaultTargetPlatform;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS; // Mock as non-Android
      // Create Upgrader with useInAppUpdate enabled but on non-Android OS
      final mockOS = MockUpgraderOS(android: false);
      final upgrader = Upgrader(
        useInAppUpdate: true,
        upgraderOS: mockOS,
        upgraderDevice: MockUpgraderDevice(),
        debugLogging: true,
      );

      final mockPackageInfo = await PackageInfo.fromPlatform();
      // Skip initialize and set initialized directly to avoid shared preferences issues
      // Ensure the mockOS is explicitly used in copyWith and state is initialized
      upgrader.updateState(upgrader.state.copyWith(
        packageInfo: mockPackageInfo,
        upgraderOS: mockOS // Explicitly pass the same mockOS instance
      ));

      // Call sendUserToAppStore which should NOT trigger in-app update on non-Android platform
      await upgrader.sendUserToAppStore();

      // Verify that checkForUpdate was NOT called
      expect(log.isEmpty, true);

      debugDefaultTargetPlatformOverride = originalPlatform; // Restore original platform
    });

    test('Upgrader triggers immediate update for critical updates', () async {
      // Create Upgrader with useInAppUpdate enabled and mock Android OS
      final upgrader = Upgrader(
        useInAppUpdate: true,
        upgraderOS: MockUpgraderOS(android: true),
        upgraderDevice: MockUpgraderDevice(),
        debugLogging: true,
      );

      final mockPackageInfo = await PackageInfo.fromPlatform();
      // Skip initialize and set initialized directly to avoid shared preferences issues
      upgrader.updateState(upgrader.state.copyWith(packageInfo: mockPackageInfo));

      // Set a version info with critical update flag
      upgrader.updateState(upgrader.state.copyWith(
        versionInfo: UpgraderVersionInfo(
          appStoreVersion: Version.parse('2.0.0'),
          isCriticalUpdate: true,
        ),
      ));

      // Call sendUserToAppStore which should trigger immediate in-app update
      await upgrader.sendUserToAppStore();

      // Verify that checkForUpdate was called with immediateUpdate=true
      expect(log.isNotEmpty, true);
      final checkForUpdateCall = log.firstWhere((call) => call.method == 'checkForUpdate');
      expect(checkForUpdateCall.arguments['immediateUpdate'], true);
    });

    test('Upgrader triggers immediate update when below minAppVersion', () async {
      // Create Upgrader with useInAppUpdate enabled, mock Android OS, and minAppVersion
      final upgrader = Upgrader(
        useInAppUpdate: true,
        upgraderOS: MockUpgraderOS(android: true),
        upgraderDevice: MockUpgraderDevice(),
        minAppVersion: '2.0.0',
        debugLogging: true,
      );

      final mockPackageInfo = await PackageInfo.fromPlatform();
      // Skip initialize and set initialized directly to avoid shared preferences issues
      upgrader.updateState(upgrader.state.copyWith(packageInfo: mockPackageInfo));

      // Call sendUserToAppStore which should trigger immediate in-app update
      await upgrader.sendUserToAppStore();

      // Verify that checkForUpdate was called with immediateUpdate=true
      expect(log.isNotEmpty, true);
      final checkForUpdateCall = log.firstWhere((call) => call.method == 'checkForUpdate');
      expect(checkForUpdateCall.arguments['immediateUpdate'], true);
    });

    test('Upgrader uses proper language code for in-app update', () async {
      // Create Upgrader with useInAppUpdate enabled, mock Android OS, and language code
      final upgrader = Upgrader(
        useInAppUpdate: true,
        upgraderOS: MockUpgraderOS(android: true),
        upgraderDevice: MockUpgraderDevice(),
        languageCode: 'fr',
        debugLogging: true,
      );

      final mockPackageInfo = await PackageInfo.fromPlatform();
      // Skip initialize and set initialized directly to avoid shared preferences issues
      upgrader.updateState(upgrader.state.copyWith(packageInfo: mockPackageInfo));

      // Call sendUserToAppStore which should trigger in-app update with language code
      await upgrader.sendUserToAppStore();

      // Verify that checkForUpdate was called with correct language code
      expect(log.isNotEmpty, true);
      final checkForUpdateCall = log.firstWhere((call) => call.method == 'checkForUpdate');
      expect(checkForUpdateCall.arguments['language'], 'fr');
    });
  });
}
