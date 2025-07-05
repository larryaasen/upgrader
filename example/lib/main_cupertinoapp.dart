// Copyright (c) 2025 Larry Aasen. All rights reserved.

import 'package:flutter/cupertino.dart';
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
    return CupertinoApp(
      title: 'Upgrader Example',
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Upgrader CupertinoApp Example'),
        ),
        child: UpgradeAlert(
          dialogStyle: UpgradeDialogStyle.cupertino,
          child: const Center(child: Text('Checking...')),
        ),
      ),
    );
  }
}
