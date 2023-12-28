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
  MyApp({Key? key}) : super(key: key);

  static const appcastURL =
      'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast_macos.xml';
  final upgrader = Upgrader(
    appcastConfig:
        AppcastConfiguration(url: appcastURL, supportedOS: ['macos']),
    debugLogging: true,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: UpgradeAlert(
          upgrader: upgrader,
          child: Scaffold(
            appBar: AppBar(title: Text('Upgrader Example')),
            body: Center(child: Text('Checking...')),
          )),
    );
  }
}
