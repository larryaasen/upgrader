// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

final dialogKey = GlobalKey(debugLabel: 'gloabl_upgrader_alert_dialog');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  log() => print('$dialogKey mounted=${dialogKey.currentContext?.mounted}');
  unawaited(Future.delayed(const Duration(seconds: 0)).then((value) => log()));
  unawaited(Future.delayed(const Duration(seconds: 3)).then((value) => log()));
  unawaited(Future.delayed(const Duration(seconds: 4)).then((value) => log()));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: UpgradeAlert(
          dialogKey: dialogKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('Upgrader Example')),
            body: const Center(child: Text('Checking...')),
          )),
    );
  }
}
