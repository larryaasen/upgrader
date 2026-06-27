// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(const MyApp());
}

final routerConfig = GoRouter(
  initialLocation: '/page2',
  routes: [
    GoRoute(
        path: '/page1',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen('page1')),
    GoRoute(
        path: '/page2',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen('page2')),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Upgrader GoRouter Example',
      routerConfig: routerConfig,
      builder: (context, child) {
        return UpgradeAlert(
          navigatorKey: routerConfig.routerDelegate.navigatorKey,
          child: child ?? const Text('child'),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrader GoRouter Example')),
      body: Center(child: Text('Checking... $title')),
    );
  }
}
