/*
 * Copyright (c) 2025 Larry Aasen. All rights reserved.
 * Contributions by [MrRoy121 (2025), ].
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/src/upgrader_in_app_store.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

import 'appcast_test.dart' as MockITunesSearchClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('UpgraderInAppStore', () {
    late MethodChannel channel;
    final List<MethodCall> log = <MethodCall>[];
    
    setUp(() {
      channel = MethodChannel('com.larryaasen.upgrader/in_app_update');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'isPlayStoreAvailable':
              return true;
            case 'checkForUpdate':
              final immediateUpdate = methodCall.arguments['immediateUpdate'] as bool;
              return {
                'updateAvailable': true,
                'immediateUpdateAllowed': immediateUpdate,
                'flexibleUpdateAllowed': !immediateUpdate,
                'versionCode': 200
              };
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
    
    test('getVersionInfo returns correct version info for available update', () async {
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


      final store = UpgraderInAppStore();
      
      final versionInfo = await store.getVersionInfo(
        state: state,
        installedVersion: installedVersion,
        country: 'US',
        language: 'en',);
      
      // Verify that the version info contains the correct app store version
      expect(versionInfo.appStoreVersion, equals(Version(200, 0, 0)));
      
      // Verify that it's not marked as a critical update by default
      expect(versionInfo.isCriticalUpdate, equals(false));
      
      // Verify that the method calls were made correctly
      expect(log.length, equals(2));
      expect(log[0].method, equals('isPlayStoreAvailable'));
      expect(log[1].method, equals('checkForUpdate'));
      expect(log[1].arguments['immediateUpdate'], equals(false));
    });
    
    test('getVersionInfo marks update as critical when shouldForceImmediateUpdate is true', () async {
      final store = UpgraderInAppStore(shouldForceImmediateUpdate: true);
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


      final versionInfo = await store.getVersionInfo(
        state: state,
        installedVersion: installedVersion,
        country: 'US',
        language: 'en',);
      
      // Verify that the version info contains the correct app store version
      expect(versionInfo.appStoreVersion, equals(Version(200, 0, 0)));
      
      // Verify that it's marked as a critical update
      expect(versionInfo.isCriticalUpdate, equals(true));
      
      // Verify that the method calls were made correctly
      expect(log.length, equals(2));
      expect(log[0].method, equals('isPlayStoreAvailable'));
      expect(log[1].method, equals('checkForUpdate'));
      expect(log[1].arguments['immediateUpdate'], equals(true));
    });
    
    test('getVersionInfo passes language parameter correctly', () async {
      final store = UpgraderInAppStore(language: 'fr');

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


      final versionInfo = await store.getVersionInfo(
        state: state,
        installedVersion: installedVersion,
        country: 'US',
        language: 'en',);
      
      // Verify that the language parameter was passed correctly
      expect(log.length, equals(2));
      expect(log[1].method, equals('checkForUpdate'));
      expect(log[1].arguments['language'], equals('en'));
    });
    
    test('getVersionInfo returns empty version info when Play Store is not available', () async {
      // Override the mock to return false for isPlayStoreAvailable
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'isPlayStoreAvailable') {
            return false;
          }
          return null;
        },
      );
      
      final store = UpgraderInAppStore();
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


      final versionInfo = await store.getVersionInfo(
        state: state,
        installedVersion: installedVersion,
        country: 'US',
        language: 'en',);
      
      // Verify that an empty version info is returned
      expect(versionInfo.appStoreVersion, isNull);
      expect(versionInfo.isCriticalUpdate, isNull);
      
      // Verify that only isPlayStoreAvailable was called
      expect(log.length, equals(1));
      expect(log[0].method, equals('isPlayStoreAvailable'));
    });
    
    test('getVersionInfo handles errors gracefully', () async {
      // Override the mock to throw an exception for checkForUpdate
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'isPlayStoreAvailable') {
            return true;
          } else if (methodCall.method == 'checkForUpdate') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

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


      final store = UpgraderInAppStore();

      final versionInfo = await store.getVersionInfo(
        state: state,
        installedVersion: installedVersion,
        country: 'US',
        language: 'en',);
      
      // Verify that an empty version info is returned on error
      expect(versionInfo.appStoreVersion, isNull);
      expect(versionInfo.isCriticalUpdate, isNull);
      
      // Verify that both methods were called
      expect(log.length, equals(2));
      expect(log[0].method, equals('isPlayStoreAvailable'));
      expect(log[1].method, equals('checkForUpdate'));
    });
  });
}
