/*
  Copyright (c) 2025 Larry Aasen. All rights reserved.
  Contributions by [MrRoy121 (2025), ].
*/

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
      debugLogging: true, 
      durationUntilAlertAgain: const Duration(seconds: 10), 
      useInAppUpdate: true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example - Alert In App Update',
      home: UpgradeAlert(
        upgrader: _upgrader,
        child: Scaffold(
          appBar: AppBar(title: const Text('Upgrader Example - Alert In App Update')),
          body: const Center(
            child: Text('In-app update should trigger automatically\n if an update is available'),
          ),
        ),
      ),
    );
  }
}

