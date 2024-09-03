/*
 * Copyright (c) 2019-2024 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast.xml';
  final upgrader = Upgrader(
    client: http.Client(),
    clientHeaders: {'header1': 'value1'},
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL),
      oniOS: () => UpgraderAppcastStore(appcastURL: appcastURL),
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
