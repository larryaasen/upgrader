// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/src/upgrade_os.dart';

UpgraderOS? _upgraderOS;

class MockDeviceInfo {
  UpgraderOS? get upgraderOS => _upgraderOS;
  set upgraderOS(UpgraderOS? value) => _upgraderOS = value;

  void setup() {
    const channel = MethodChannel('dev.fluttercommunity.plus/device_info');

    handler(MethodCall methodCall) async {
      print('MockDeviceInfo.setup.methodCall: ${methodCall.method}');

      String method = methodCall.method;
      if (methodCall.method == 'getDeviceInfo') {
        assert(upgraderOS != null);
        if (_upgraderOS == null) {
          return null;
        }
        switch (_upgraderOS!.current) {
          case 'android':
            method = 'getAndroidDeviceInfo';
            break;
          case 'fuchsia':
            method = '';
            break;
          case 'ios':
            method = 'getIosDeviceInfo';
            break;
          case 'linux':
            method = 'getLinuxInfo';
            break;
          case 'macos':
            method = 'getMacosDeviceInfo';
            break;
          case 'web':
            method = '';
            break;
          case 'windows':
            method = '';
            break;
          default:
        }
        method = '';
      }

      switch (method) {
        case 'getAndroidDeviceInfo':
          const fakeAndroidBuildVersion = <String, dynamic>{
            'sdkInt': 16,
            'baseOS': 'baseOS',
            'previewSdkInt': 30,
            'release': 'release',
            'codename': 'codename',
            'incremental': 'incremental',
            'securityPatch': 'securityPatch',
          };
          const fakeDisplayMetrics = <String, dynamic>{
            'widthPx': 1080.0,
            'heightPx': 2220.0,
            'xDpi': 530.0859,
            'yDpi': 529.4639,
          };
          return <String, dynamic>{
            'id': 'id',
            'host': 'host',
            'tags': 'tags',
            'type': 'type',
            'model': 'model',
            'board': 'board',
            'brand': 'Google',
            'device': 'device',
            'product': 'product',
            'display': 'display',
            'hardware': 'hardware',
            'isPhysicalDevice': true,
            'bootloader': 'bootloader',
            'fingerprint': 'fingerprint',
            'manufacturer': 'manufacturer',
            'version': fakeAndroidBuildVersion,
            'displayMetrics': fakeDisplayMetrics,
            'serialNumber': 'SERIAL',
          };
        case 'getIosDeviceInfo':
          const iosUtsnameMap = <String, dynamic>{
            'release': 'release',
            'version': 'version',
            'machine': 'machine',
            'sysname': 'sysname',
            'nodename': 'nodename',
          };
          return <String, dynamic>{
            'name': 'name',
            'model': 'model',
            'utsname': iosUtsnameMap,
            'systemName': 'systemName',
            'isPhysicalDevice': 'true',
            'systemVersion': '16.2',
            'localizedModel': 'localizedModel',
            'identifierForVendor': 'identifierForVendor',
          };
        case 'getLinuxInfo':
          return <String, dynamic>{
            'name': 'name',
            'version': 'version',
            'id': 'id',
            'idLike': 'idLike',
            'versionCodename': 'versionCodename',
            'versionId': 'versionId',
            'prettyName': 'prettyName',
            'buildId': 'buildId',
            'variant': 'variant',
            'variantId': 'variantId',
            'machineId': 'machineId',
          };
        case 'getMacosDeviceInfo':
          return <String, dynamic>{
            'arch': 'arch',
            'model': 'model',
            'activeCPUs': 4,
            'memorySize': 16,
            'cpuFrequency': 2,
            'hostName': 'hostName',
            'osRelease': 'Version 13.2.1 (Build 22D68)',
            'computerName': 'computerName',
            'kernelVersion': 'kernelVersion',
            'systemGUID': null,
          };

        default:
          assert(false);
      }
      return null;
    }

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }
}
