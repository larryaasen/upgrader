// Copyright (c) 2023 Larry Aasen. All rights reserved.

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

  final dark = ThemeData.dark(useMaterial3: true);

  final light = ThemeData(
    cardTheme: const CardTheme(color: Colors.greenAccent),
    // Change the text buttons.
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        // Change the color of the text buttons.
        foregroundColor: WidgetStatePropertyAll(Colors.orange),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Card Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Upgrader Card Theme Example')),
        body: Container(
          margin: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _simpleCard,
                _simpleCard,
                UpgradeCard(),
                _simpleCard,
                _simpleCard,
              ],
            ),
          ),
        ),
      ),
      theme: light,
      darkTheme: dark,
    );
  }

  Widget get _simpleCard => const Card(
        child: SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Text('Card')),
        ),
      );
}
