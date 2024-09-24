// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:async';

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
  final _upgrader = Upgrader();

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), _updateMessages);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Card Update Example',
      theme: ThemeData(colorScheme: const ColorScheme.light()),
      home: Scaffold(
        appBar: AppBar(title: const Text('Upgrader Card Update Example')),
        body: Container(
          margin: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _simpleCard,
                _simpleCard,
                UpgradeCard(upgrader: _upgrader),
                _simpleCard,
                _simpleCard,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get _simpleCard => const Card(
        child: SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Text('Card')),
        ),
      );

  void _updateMessages() {
    _upgrader
        .updateState(_upgrader.state.copyWith(messages: MyUpgraderMessages()));
  }
}

class MyUpgraderMessages extends UpgraderMessages {
  @override
  String get body => 'The message has been updated.';
}
