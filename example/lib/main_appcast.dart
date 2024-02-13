/*
 * Copyright (c) 2019-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, setup the Appcast.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static const appcastURL =
      'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast.xml';
  final upgrader = Upgrader(
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL),
    ),
  );

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