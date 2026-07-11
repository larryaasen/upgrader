/*
 * Copyright (c) 2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration()).then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader StatefulWidget Example',
      home: UpgradeAlert(
          child: Scaffold(
        appBar: AppBar(title: const Text('Upgrader StatefulWidget Example')),
        body: const Center(child: Text('Checking...')),
      )),
    );
  }
}
