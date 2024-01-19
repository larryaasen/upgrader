/*
 * Copyright (c) 2020-2022 Larry Aasen. All rights reserved.
 */

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
      title: 'Upgrader Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Upgrader Cupertino Example')),
        body: UpgradeAlert(
          dialogStyle: UpgradeDialogStyle.cupertino,
          child: const Center(child: Text('Checking...')),
        ),
      ),
    );
  }
}
