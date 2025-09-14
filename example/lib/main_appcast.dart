/*
 * Copyright (c) 2019-2025 Larry Aasen. All rights reserved.
 */

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  final osVersion = await getCurrentOSVersion();

  const appcastURL =
      'https://raw.githubusercontent.com/larryaasen/upgrader/main/test/testappcast.xml';
  final upgrader = Upgrader(
    client: http.Client(),
    clientHeaders: {'header1': 'value1'},
    storeController: UpgraderStoreController(
      onAndroid: () =>
          UpgraderAppcastStore(appcastURL: appcastURL, osVersion: osVersion),
      oniOS: () =>
          UpgraderAppcastStore(appcastURL: appcastURL, osVersion: osVersion),
    ),
  );

  runApp(MyApp(upgrader: upgrader));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.upgrader});

  final Upgrader upgrader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: Scaffold(
          appBar: AppBar(title: const Text('Upgrader Appcast Example')),
          body: UpgradeAlert(
            upgrader: upgrader,
            child: const Center(child: Text('Checking...')),
          )),
    );
  }
}

class UpgraderDevice {
  Future<String?> getOsVersionString(UpgraderOS upgraderOS) async {
    final deviceInfo = DeviceInfoPlugin();
    String? osVersionString;
    if (upgraderOS.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      osVersionString = androidInfo.version.baseOS;
    } else if (upgraderOS.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osVersionString = iosInfo.systemVersion;
    } else if (upgraderOS.isFuchsia) {
      osVersionString = '';
    } else if (upgraderOS.isLinux) {
      final info = await deviceInfo.linuxInfo;
      osVersionString = info.version;
    } else if (upgraderOS.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      final release = info.osRelease;

      // For macOS the release string looks like: Version 13.2.1 (Build 22D68)
      // We need to parse out the actual OS version number.

      String regExpSource = r"[\w]*[\s]*(?<version>[^\s]+)";
      final regExp = RegExp(regExpSource, caseSensitive: false);
      final match = regExp.firstMatch(release);
      final version = match?.namedGroup('version');
      osVersionString = version;
    } else if (upgraderOS.isWeb) {
      osVersionString = '0.0.0';
    } else if (upgraderOS.isWindows) {
      final info = await deviceInfo.windowsInfo;
      osVersionString = info.displayVersion;
    }

    // If the OS version string is not valid, don't use it.
    try {
      Version.parse(osVersionString!);
    } catch (e) {
      osVersionString = null;
    }

    return osVersionString;
  }
}

Future<Version> getCurrentOSVersion() async {
  final upgraderDevice = UpgraderDevice();
  final osVersionString = await upgraderDevice.getOsVersionString(UpgraderOS());

  Version osVersion;

  try {
    osVersion = osVersionString?.isNotEmpty == true
        ? Version.parse(osVersionString!)
        : Version(0, 0, 0);
  } catch (e) {
    osVersion = Version(0, 0, 0);
  }
  return osVersion;
}
