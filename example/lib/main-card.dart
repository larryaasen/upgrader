/*
 * Copyright (c) 2019 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({
    Key key,
  }) : super(key: key) {
    Upgrader().clearSavedSettings();
    Upgrader().installAppStoreVersion('1.1.0');
    Upgrader().installAppStoreListingURL(
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: Scaffold(
          appBar: AppBar(
            title: Text('Upgrader Example'),
          ),
          body: Center(
              child: Container(
                  margin: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
                  child: UpgradeCard(debugAlwaysUpgrade: true)))),
    );
  }
}
