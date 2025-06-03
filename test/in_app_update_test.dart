/*
 * Copyright (c) 2025 Larry Aasen. All rights reserved.
 * Contributions by [MrRoy121 (2025), ].
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';
import 'package:upgrader/src/in_app_update.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppUpdate', () {
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
                'versionCode': 100
              };
            case 'completeUpdate':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      log.clear();
    });

    test('initialize sets up method channel handler', () async {
      expect(InAppUpdate.initialized, false);
      await InAppUpdate.initialize();
      expect(InAppUpdate.initialized, true);
      
      // Calling initialize again should not cause issues
      await InAppUpdate.initialize();
      expect(InAppUpdate.initialized, true);
    });

    test('isPlayStoreAvailable returns true when Play Store is available', () async {
      final result = await InAppUpdate.isPlayStoreAvailable();
      expect(result, true);
      expect(log.length, 1);
      expect(log[0].method, 'isPlayStoreAvailable');
    });

    test('checkForUpdate with immediateUpdate = true returns correct status', () async {
      final status = await InAppUpdate.checkForUpdate(immediateUpdate: true);
      
      expect(status.updateAvailable, true);
      expect(status.immediateUpdateAllowed, true);
      expect(status.flexibleUpdateAllowed, false);
      expect(status.versionCode, 100);
      
      expect(log.length, 1);
      expect(log[0].method, 'checkForUpdate');
      expect(log[0].arguments['immediateUpdate'], true);
    });

    test('checkForUpdate with immediateUpdate = false returns correct status', () async {
      final status = await InAppUpdate.checkForUpdate(immediateUpdate: false);
      
      expect(status.updateAvailable, true);
      expect(status.immediateUpdateAllowed, false);
      expect(status.flexibleUpdateAllowed, true);
      expect(status.versionCode, 100);
      
      expect(log.length, 1);
      expect(log[0].method, 'checkForUpdate');
      expect(log[0].arguments['immediateUpdate'], false);
    });

    test('checkForUpdate initializes InAppUpdate if not already initialized', () async {
      InAppUpdate.initialized = false;
      
      await InAppUpdate.checkForUpdate(immediateUpdate: true);
      
      expect(InAppUpdate.initialized, true);
    });

    test('completeUpdate successfully completes the update', () async {
      final result = await InAppUpdate.completeUpdate();
      
      expect(result, true);
      expect(log.length, 1);
      expect(log[0].method, 'completeUpdate');
    });

    test('completeUpdate initializes InAppUpdate if not already initialized', () async {
      InAppUpdate.initialized = false;
      
      await InAppUpdate.completeUpdate();
      
      expect(InAppUpdate.initialized, true);
    });

    test('InAppUpdateStatus.fromMap creates correct status object', () {
      final map = {
        'updateAvailable': true,
        'immediateUpdateAllowed': true,
        'flexibleUpdateAllowed': false,
        'versionCode': 100
      };
      
      final status = InAppUpdateStatus.fromMap(map);
      
      expect(status.updateAvailable, true);
      expect(status.immediateUpdateAllowed, true);
      expect(status.flexibleUpdateAllowed, false);
      expect(status.versionCode, 100);
    });

    test('InAppUpdateStatus.fromMap handles missing or null values', () {
      final map = <Object?, Object?>{};
      
      final status = InAppUpdateStatus.fromMap(map);
      
      expect(status.updateAvailable, false);
      expect(status.immediateUpdateAllowed, false);
      expect(status.flexibleUpdateAllowed, false);
      expect(status.versionCode, null);
    });

    test('InAppUpdateStatus.toString returns formatted string', () {
      final status = InAppUpdateStatus(
        updateAvailable: true,
        immediateUpdateAllowed: true,
        flexibleUpdateAllowed: false,
        versionCode: 100,
      );
      
      final string = status.toString();
      
      expect(string, contains('updateAvailable: true'));
      expect(string, contains('immediateUpdateAllowed: true'));
      expect(string, contains('flexibleUpdateAllowed: false'));
      expect(string, contains('versionCode: 100'));
    });

    test('dispose resets initialized state', () {
      InAppUpdate.initialized = true;
      
      InAppUpdate.dispose();
      
      expect(InAppUpdate.initialized, false);
    });
  });
}
