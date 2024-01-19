// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example - Multiple',
      home: UpgradeAlert(
          child: Scaffold(
        appBar: AppBar(title: const Text('Upgrader Example - Multiple')),
        body: Center(child: UpgradeAlert(child: const Text('Checking...'))),
      )),
    );
  }
}
