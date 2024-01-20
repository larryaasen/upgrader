// Copyright (c) 2024 Larry Aasen. All rights reserved.

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
      home: MyUpgradeAlert(
        child: Scaffold(
          appBar: AppBar(title: const Text('Upgrader Alert Theme Example')),
          body: const Center(child: Text('Checking...')),
        ),
      ),
    );
  }
}

class MyUpgradeAlert extends UpgradeAlert {
  MyUpgradeAlert({super.key, super.upgrader, super.child});

  /// Override the [createState] method to provide a custom class
  /// with overridden methods.
  @override
  UpgradeAlertState createState() => MyUpgradeAlertState();
}

class MyUpgradeAlertState extends UpgradeAlertState {
  @override
  Widget alertDialog(
      Key? key,
      String title,
      String message,
      String? releaseNotes,
      BuildContext context,
      bool cupertino,
      UpgraderMessages messages) {
    return Theme(
      data: ThemeData(
        dialogTheme: const DialogTheme(
          titleTextStyle: TextStyle(color: Colors.red, fontSize: 48),
          contentTextStyle: TextStyle(color: Colors.green, fontSize: 18),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            // Change the color of the text buttons.
            foregroundColor: MaterialStatePropertyAll(Colors.orange),
          ),
        ),
      ),
      child: super.alertDialog(
          key, title, message, releaseNotes, context, cupertino, messages),
    );
  }
}
