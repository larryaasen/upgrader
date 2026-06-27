// Copyright (c) 2024 Larry Aasen. All rights reserved.

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

  final _upgrader = Upgrader(
      debugLogging: true, durationUntilAlertAgain: const Duration(seconds: 10));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example - Alert Again',
      home: UpgradeAlert(
        upgrader: _upgrader,
        child: Scaffold(
          appBar: AppBar(title: const Text('Upgrader Example - Alert Again')),
          body: const Center(child: Text('Checking...')),
        ),
      ),
    );
  }
}
