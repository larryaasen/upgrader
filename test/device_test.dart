// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

    // Verify invalid OS version
    deviceInfo = _androidInfo(baseOS: '.');
    expect(
        await device.getOsVersionString(MockUpgraderOS(android: true)), isNull);
  });

  test('testing UpgraderDevice iOS', () async {
    deviceInfo = _iosInfo(baseOS: '1.2.3');
    final device = UpgraderDevice();
    expect(await device.getOsVersionString(MockUpgraderOS(ios: true)), '1.2.3');

    // Verify invalid OS version
    deviceInfo = _iosInfo(baseOS: '.');
    expect(await device.getOsVersionString(MockUpgraderOS(ios: true)), isNull);
  });

  // Note: this test causes exception in DeviceInfoPlugin
  // test('testing UpgraderDevice Linux', () async {
  //   deviceInfo = _linuxInfo(baseOS: '1.2.3');
  //   final device = UpgraderDevice();
  //   expect(
  //       await device.getOsVersionString(MockUpgraderOS(linux: true)), '1.2.3');
  //   // Verify invalid OS version
  //   deviceInfo = _linuxInfo(baseOS: '.');
  //   expect(
  //       await device.getOsVersionString(MockUpgraderOS(linux: true)), isNull);
  // });

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

  test('testing UpgraderDevice Web', () async {
    final device = UpgraderDevice();
    expect(await device.getOsVersionString(MockUpgraderOS(web: true)), '0.0.0');
  });

  // Note: this test causes exception in DeviceInfoPlugin
  // test('testing UpgraderDevice Windows', () async {
  //   deviceInfo = _windowsInfo(baseOS: '1.2.3');
  //   final device = UpgraderDevice();
  //   expect(await device.getOsVersionString(MockUpgraderOS(windows: true)),
  //       '1.2.3');
  //   // Verify invalid OS version
  //   deviceInfo = _windowsInfo(baseOS: '.');
  //   expect(
  //       await device.getOsVersionString(MockUpgraderOS(windows: true)), isNull);
  // });
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

Map _iosInfo({required String baseOS}) {
  const iosUtsnameMap = <String, dynamic>{
    'release': 'release',
    'version': 'version',
    'machine': 'machine',
    'sysname': 'sysname',
    'nodename': 'nodename',
  };
  final info = {
    'name': 'name',
    'model': 'model',
    'utsname': iosUtsnameMap,
    'systemName': 'systemName',
    'isPhysicalDevice': 'false',
    'systemVersion': baseOS,
    'localizedModel': 'localizedModel',
    'identifierForVendor': 'identifierForVendor',
  };
  return info;
}

// Map _linuxInfo({required String baseOS}) {
//   return {
//     'name': 'a',
//     'version': baseOS,
//     'id': 'a',
//     'idLike': ['a'],
//     'versionCodename': 'a',
//     'versionId': 'a',
//     'prettyName': 'a',
//     'buildId': 'a',
//     'variant': 'a',
//     'variantId': 'a',
//     'machineId': 'a',
//   };
// }

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

// Map _windowsInfo({required String baseOS}) {
//   final info = {
//     'computerName': 'a',
//     'numberOfCores': 'a',
//     'systemMemoryInMegabytes': 'a',
//     'userName': 'a',
//     'majorVersion': 'a',
//     'minorVersion': 'a',
//     'buildNumber': 'a',
//     'platformId': 'a',
//     'csdVersion': 'a',
//     'servicePackMajor': 'a',
//     'servicePackMinor': 'a',
//     'suitMask': 'a',
//     'productType': 'a',
//     'reserved': 'a',
//     'buildLab': 'a',
//     'buildLabEx': 'a',
//     'digitalProductId': 'a',
//     'displayVersion': baseOS,
//     'editionId': 'a',
//     'installDate': 'a',
//     'productId': 'a',
//     'productName': 'a',
//     'registeredOwner': 'a',
//     'releaseId': 'a',
//     'deviceId': 'a',
//   };
//   return info;
// }
