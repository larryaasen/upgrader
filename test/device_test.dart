// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/src/upgrader_device.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map deviceInfo;

  // Makes getApplicationDocumentsDirectory work.
  const MethodChannel channelDeviceInfo =
      MethodChannel('dev.fluttercommunity.plus/device_info');
  // ignore: deprecated_member_use
  channelDeviceInfo.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getDeviceInfo') {
      return deviceInfo;
    }
    return 'unknown';
  });

  test('testing UpgraderDevice Android', () async {
    deviceInfo = _androidInfo(baseOS: '1.2.3');
    final device = UpgraderDevice();
    expect(await device.getOsVersionString(MockUpgraderOS(android: true)),
        '1.2.3');
    expect(await device.getPreferredAbi(MockUpgraderOS(android: true)),
        'arm64-v8a');

    // Verify invalid OS version
    deviceInfo = _androidInfo(baseOS: '.');
    expect(
        await device.getOsVersionString(MockUpgraderOS(android: true)), isNull);
    // only Android supports ABI
    expect(
        await device.getPreferredAbi(MockUpgraderOS(android: false)), isNull);
  });

  test('testing UpgraderDevice macOS', () async {
    deviceInfo = _macOSInfo(baseOS: '1.2.3');
    final device = UpgraderDevice();
    expect(
        await device.getOsVersionString(MockUpgraderOS(macos: true)), '1.2.3');

    // Verify invalid OS version
    deviceInfo = _macOSInfo(baseOS: '.');
    expect(
        await device.getOsVersionString(MockUpgraderOS(macos: true)), isNull);
  });
}

Map _androidInfo({required String baseOS}) {
  final displayMetrics = {
    'widthPx': 0.0,
    'heightPx': 0.0,
    'xDpi': 0.0,
    'yDpi': 0.0,
  };
  final version = {
    'baseOS': baseOS, // This is the only value used in the test.
    'codename': 'a',
    'incremental': 'a',
    'previewSdkInt': 1,
    'release': 'a',
    'sdkInt': 1,
    'securityPatch': 'a',
  };

  final build = <String, dynamic>{
    'board': 'a',
    'bootloader': 'a',
    'brand': 'a',
    'device': 'a',
    'display': 'a',
    'fingerprint': 'a',
    'hardware': 'a',
    'host': 'a',
    'id': 'a',
    'manufacturer': 'a',
    'model': 'a',
    'product': 'a',
    'supported32BitAbis': ['a'],
    'supported64BitAbis': ['a'],
    'supportedAbis': ['arm64-v8a'], // also used in test
    'tags': 'a',
    'type': 'a',
    'isPhysicalDevice': false,
    'systemFeatures': [],
    'displayMetrics': displayMetrics,
    'serialNumber': 'a',
    'version': version,
  };
  return build;
}

Map _macOSInfo({required String baseOS}) {
  final info = {
    'computerName': 'a',
    'hostName': 'a',
    'arch': 'a',
    'model': 'a',
    'kernelVersion': 'a',
    'osRelease':
        'Version $baseOS (Build 22D68)', // This is the only value used in the test.
    'majorVersion': 0,
    'minorVersion': 0,
    'patchVersion': 0,
    'activeCPUs': 0,
    'memorySize': 0,
    'cpuFrequency': 0,
    'systemGUID': 'a',
  };

  return info;
}
