// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static const appcastURL =
      'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast_macos.xml';
  final upgrader = Upgrader(
    storeController: UpgraderStoreController(
        onMacOS: () => UpgraderAppcastStore(appcastURL: appcastURL)),
    debugLogging: true,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: UpgradeAlert(
          upgrader: upgrader,
          child: Scaffold(
            appBar: AppBar(title: const Text('Upgrader Example')),
            body: const Center(child: Text('Checking...')),
          )),
    );
  }
}
