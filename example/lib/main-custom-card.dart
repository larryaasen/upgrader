// Copyright (c) 2023 Larry Aasen. All rights reserved.

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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: Scaffold(
        appBar: AppBar(title: Text('Upgrader Custom Card Example')),
        body: Container(
          margin: EdgeInsets.only(left: 12.0, right: 12.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _simpleCard,
                _simpleCard,
                MyUpgradeCard(),
                _simpleCard,
                _simpleCard,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get _simpleCard => Card(
        child: SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Text('Card')),
        ),
      );
}

class MyUpgradeCard extends UpgradeCard {
  MyUpgradeCard({super.upgrader});

  /// Override the [createState] method to provide a custom class
  /// with overridden methods.
  @override
  UpgradeCardState createState() => MyUpgradeCardState();
}

class MyUpgradeCardState extends UpgradeCardState {
  @override
  Widget buildUpgradeCard(BuildContext context, Key? key) {
    final appMessages = widget.upgrader.determineMessages(context);
    final title = appMessages.message(UpgraderMessage.title);
    return Card(
      color: Colors.greenAccent,
      child: AlertStyleWidget(
        actions: [
          TextButton(
            child: Text(
                appMessages.message(UpgraderMessage.buttonTitleUpdate) ?? ''),
            onPressed: () {
              widget.upgrader.saveLastAlerted();
              onUserUpdated();
            },
          ),
        ],
        content: Text(''),
        title: Text(title ?? ''),
      ),
    );
  }
}
