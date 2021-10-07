/*
 * Copyright (c) 2019 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only call clearSavedSettings() during testing to reset internal values.
    Upgrader().clearSavedSettings(); // REMOVE this for release builds

    // On Android, the default behavior will be to use the Google Play Store
    // version of the app.
    // On iOS, the default behavior will be to use the App Store version of
    // the app, so update the Bundle Identifier in example/ios/Runner with a
    // valid identifier already in the App Store.

    return MaterialApp(
      title: 'Upgrader Example',
      home: Scaffold(
          appBar: AppBar(
            title: Text('Upgrader Example'),
          ),
          body: UpgradeAlert(
            debugLogging: true,
            child: Center(child: Text('Checking...')),
            getCustomDialog: getCustomDialog,
          )),
    );
  }
}

/// Example Custom Dialog Widget
Widget getCustomDialog(BuildContext context,
    {String title,
    String message,
    String releaseNotes,
    void Function() onUserIgnored,
    void Function() onUserLater,
    void Function() onUserUpdated}) {
  return Center(
    child: Container(
      height: 124,
      width: MediaQuery.of(context).size.width * 0.8,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Your Custom Upgrader Dialog',
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onUserIgnored, child: Text('IGNORE')),
              TextButton(onPressed: onUserLater, child: Text('LATER')),
              TextButton(
                onPressed: onUserUpdated,
                child: Text(
                  'UPDATE',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
