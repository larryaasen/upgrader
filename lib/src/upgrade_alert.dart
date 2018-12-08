/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'upgrader.dart';

/// A widget to display the upgrade dialog.
class UpgradeAlert extends StatelessWidget {
  /// The [child] contained by the widget.
  final Widget child;

  /// The ignore button title, which defaults to ```Ignore```
  final String buttonTitleIgnore;

  /// The remind button title, which defaults to ```Later```
  final String buttonTitleRemind;

  /// The update button title, which defaults to ```Update Now```
  final String buttonTitleUpdate;

  /// Days until alerting user again after remind.
  final int daysToAlertAgain;

  /// Enable print statements for debugging.
  final bool debugEnabled;

  /// The call to action message, which defaults to: Would you like to update it now?
  final String prompt;

  /// The title of the alert dialog. Defaults to: Update App?
  final String title;

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client client;

  UpgradeAlert({
    Key key,
    this.buttonTitleIgnore,
    this.buttonTitleRemind,
    this.buttonTitleUpdate,
    this.child,
    this.daysToAlertAgain = 3,
    this.debugEnabled = false,
    this.prompt,
    this.title,
    this.client,
  }) : super(key: key) {
    if (this.buttonTitleIgnore != null) {
      Upgrader().buttonTitleIgnore = this.buttonTitleIgnore;
    }
    if (this.buttonTitleRemind != null) {
      Upgrader().buttonTitleRemind = this.buttonTitleRemind;
    }
    if (this.buttonTitleUpdate != null) {
      Upgrader().buttonTitleUpdate = this.buttonTitleUpdate;
    }
    if (this.client != null) {
      Upgrader().client = this.client;
    }
    Upgrader().daysUntilAlertAgain = this.daysToAlertAgain;
    Upgrader().debugEnabled = this.debugEnabled;
    if (this.prompt != null) {
      Upgrader().prompt = this.prompt;
    }
    if (this.title != null) {
      Upgrader().title = this.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Upgrader().debugEnabled) {
      print('upgrader: build UpgradeWidget');
    }

    return FutureBuilder(
        future: Upgrader().initialize(),
        builder: (BuildContext context, AsyncSnapshot<bool> processed) {
          if (processed.connectionState == ConnectionState.done) {
            Upgrader().checkVersion(context: context);
          }
          return child;
        });
  }
}
