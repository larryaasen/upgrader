/*
 * Copyright (c) 2019-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, the default behavior will be to use the Google Play Store
  // version of the app.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final upgrader = MyUpgrader();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Subclass Example',
      home: Scaffold(
          appBar: AppBar(title: Text('Upgrader Subclass Example')),
          body: UpgradeAlert(
            upgrader: upgrader,
            child: Center(child: Text('Checking...')),
          )),
    );
  }
}

/// This class extends / subclasses Upgrader.
class MyUpgrader extends Upgrader {
  MyUpgrader() : super(debugLogging: true);
}
