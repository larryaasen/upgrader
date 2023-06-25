// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/src/upgrader_device.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map _useAndroidInfo;

  // Makes getApplicationDocumentsDirectory work.
  const MethodChannel channelDeviceInfo =
      MethodChannel('dev.fluttercommunity.plus/device_info');
  // ignore: deprecated_member_use
  channelDeviceInfo.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getDeviceInfo') {
      return _useAndroidInfo;
    }
    return 'unknown';
  });

  test('testing UpgraderDevice', () async {
    _useAndroidInfo = _androidInfo(baseOS: '1.2.3');
    final device = UpgraderDevice();
    expect(await device.getOsVersionString(MockUpgraderOS(android: true)),
        '1.2.3');

    // Verify invalid OS version
    _useAndroidInfo = _androidInfo(baseOS: '.');
    expect(
        await device.getOsVersionString(MockUpgraderOS(android: true)), isNull);
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
    'supportedAbis': ['a'],
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
