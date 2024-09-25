/*
 * Copyright (c) 2019-2024 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:huawei_hmsavailability/huawei_hmsavailability.dart';
import 'package:upgrader/upgrader.dart';

//Add Your App id , clientId , clientSecret to Your Env file
String appId = "your_app_id";
String clientId = "your_client_id";
String clientSecret = "your_client_secret";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HmsApiAvailability client = HmsApiAvailability();

// 0: HMS Core (APK) is available.
// 1: No HMS Core (APK) is found on device.
// 2: HMS Core (APK) installed is out of date.
// 3: HMS Core (APK) installed on the device is unavailable.
// 9: HMS Core (APK) installed on the device is not the official version.
// 21: The device is too old to support HMS Core (APK).
  int status = await client.isHMSAvailable();

  // Clear any saved settings for testing purposes (REMOVE this line in production).
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // Start the app with the appropriate store controller based on Google Play availability.
  runApp(MyApp(
    isHuawei: status == 0, //change this as your need
  ));
}

class MyApp extends StatelessWidget {
  final bool isHuawei;
  const MyApp({
    super.key,
    required this.isHuawei,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Huawei Example',
      home: UpgradeAlert(
        upgrader: Upgrader(
          storeController: UpgraderStoreController(
            onAndroid: () {
              // If Google Play Services are unavailable, use Huawei AppGallery.
              if (isHuawei) {
                return UpgraderHuaweiStore(
                  appId: appId,
                  clientId: clientId,
                  clientSecret: clientSecret,
                );
              }
              // Otherwise, default to Google Play Store.
              return UpgraderPlayStore();
            },
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Upgrader Huawei Example'),
          ),
          body: const Center(
            child: Text('Checking for updates...'),
          ),
        ),
      ),
    );
  }
}
