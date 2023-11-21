// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, setup the Appcast.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: Locale('ar'), // Arabic language shows right to left.
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ar', ''), // Arabic, no country code
        const Locale('he', ''), // Hebrew, no country code
      ],
      title: 'Upgrader Left to Right Example',
      home: UpgradeAlert(
          child: Scaffold(
        appBar: AppBar(title: Text('Upgrader Left to Right Example')),
        body: Center(child: Text('Checking...')),
      )),
    );
  }
}
